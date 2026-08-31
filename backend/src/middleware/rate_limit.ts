import { Env } from '../types';
import { corsHeaders } from '../utils/response';

// ============================================================
// Hybrid Rate Limiting: In-Memory + D1
//
// Menggunakan in-memory Map sebagai primary (cepat) dan D1
// sebagai secondary (persist antar instances Workers).
// - In-memory: mengecek limit dalam milidetik
// - D1: menyimpan state untuk koordinasi cross-instance
// - Periodic sync: menulis in-memory state ke D1 setiap N detik
// ============================================================

interface RateLimitEntry {
  count: number;
  windowStart: number;
}

interface BruteForceEntry {
  attempts: number;
  lockUntil: number;
  lastAttempt: number;
}

const generalLimits = new Map<string, RateLimitEntry>();
const bruteForceLimits = new Map<string, BruteForceEntry>();

const GENERAL_WINDOW_MS = 60_000;
const GENERAL_MAX_REQUESTS = 100;
const BRUTE_MAX_ATTEMPTS = 5;
const BRUTE_WINDOW_MS = 15 * 60_000;
const BRUTE_LOCK_MS = 15 * 60_000;
const CLEANUP_INTERVAL_MS = 60_000;
const D1_SYNC_INTERVAL_MS = 30_000; // Sync ke D1 setiap 30 detik

let lastCleanup = Date.now();
let lastD1Sync = Date.now();

function cleanup() {
  const now = Date.now();
  if (now - lastCleanup < CLEANUP_INTERVAL_MS) return;
  lastCleanup = now;

  for (const [key, entry] of generalLimits) {
    if (now - entry.windowStart > GENERAL_WINDOW_MS) generalLimits.delete(key);
  }
  for (const [key, entry] of bruteForceLimits) {
    if (now - entry.lastAttempt > BRUTE_WINDOW_MS && now > entry.lockUntil) bruteForceLimits.delete(key);
  }
}

/**
 * Sync in-memory state ke D1 untuk koordinasi cross-instance.
 * Dipanggil periodik dan saat ada event penting (brute force lock).
 */
async function syncToD1(env: Env, key: string, type: string, count: number, windowStart: number, lockUntil: number, lastAttempt: number): Promise<void> {
  try {
    await env.DB.prepare(
      `INSERT INTO rate_limits (key, type, count, window_start, lock_until, last_attempt, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
       ON CONFLICT(key) DO UPDATE SET
         count = excluded.count,
         window_start = excluded.window_start,
         lock_until = excluded.lock_until,
         last_attempt = excluded.last_attempt,
         updated_at = datetime('now')`
    ).bind(key, type, count, windowStart, lockUntil, lastAttempt).run();
  } catch {
    // Sync gagal tidak menggagalkan request — in-memory tetap berfungsi
  }
}

/**
 * Periodic sync: flush semua state in-memory ke D1.
 */
async function periodicSync(env: Env): Promise<void> {
  const now = Date.now();
  if (now - lastD1Sync < D1_SYNC_INTERVAL_MS) return;
  lastD1Sync = now;

  // Sync general rate limits
  for (const [key, entry] of generalLimits) {
    await syncToD1(env, `rl:${key}`, 'general', entry.count, entry.windowStart, 0, 0);
  }

  // Sync brute force limits
  for (const [key, entry] of bruteForceLimits) {
    await syncToD1(env, `bf:${key}`, 'bruteforce', entry.attempts, 0, entry.lockUntil, entry.lastAttempt);
  }

  // Cleanup expired D1 entries (data > 1 jam)
  try {
    await env.DB.prepare(
      "DELETE FROM rate_limits WHERE updated_at < datetime('now', '-1 hour')"
    ).run();
  } catch {
    // cleanup gagal tidak kritis
  }
}

function rateLimitResponse(message: string, retryAfter: number, code = 'RATE_LIMITED'): Response {
  return new Response(
    JSON.stringify({ success: false, error: { code, message } }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': String(retryAfter),
        ...corsHeaders('*'),
      },
    },
  );
}

export async function generalRateLimit(request: Request, env: Env): Promise<Response | null> {
  cleanup();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const now = Date.now();

  // Check in-memory first (fast path)
  let entry = generalLimits.get(ip);
  if (!entry || now - entry.windowStart > GENERAL_WINDOW_MS) {
    entry = { count: 0, windowStart: now };
    generalLimits.set(ip, entry);
  }

  entry.count++;

  if (entry.count > GENERAL_MAX_REQUESTS) {
    const retryAfter = Math.ceil((entry.windowStart + GENERAL_WINDOW_MS - now) / 1000);
    return rateLimitResponse('Terlalu banyak permintaan. Coba lagi dalam beberapa saat.', retryAfter);
  }

  // Async D1 sync (tidak blocking response)
  if (entry.count === 1 || entry.count % 10 === 0) {
    // Sync ke D1 hanya untuk request ke-1 dan setiap 10 request
    syncToD1(env, `rl:${ip}`, 'general', entry.count, entry.windowStart, 0, 0);
  }

  // Periodic sync
  periodicSync(env);

  return null;
}

export async function bruteForceCheck(
  username: string,
  request: Request,
  env: Env,
): Promise<Response | null> {
  cleanup();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const key = `${ip}:${username}`;
  const d1Key = `bf:${key}`;
  const now = Date.now();

  let entry = bruteForceLimits.get(key);

  // Jika tidak ada di in-memory, coba load dari D1 (cold start / instance baru)
  if (!entry) {
    try {
      const d1Entry = await env.DB.prepare(
        'SELECT count, window_start, lock_until, last_attempt FROM rate_limits WHERE key = ? AND type = ?'
      ).bind(d1Key, 'bruteforce').first<{ count: number; window_start: number; lock_until: number; last_attempt: number }>();

      if (d1Entry) {
        entry = {
          attempts: d1Entry.count,
          lockUntil: d1Entry.lock_until,
          lastAttempt: d1Entry.last_attempt,
        };
        bruteForceLimits.set(key, entry);
      }
    } catch {
      // D1 error — fallback ke in-memory default
    }
  }

  if (entry && entry.lockUntil > now) {
    const retryAfter = Math.ceil((entry.lockUntil - now) / 1000);

    try {
      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address, created_at) VALUES (?, 'brute_force_blocked', 'auth', ?, ?, datetime('now'))"
      ).bind(0, `Brute force blocked untuk username=${username}`, ip).run();
    } catch {
      // log gagal tidak menggagalkan response
    }

    return rateLimitResponse(
      'Akun diblokir sementara karena terlalu banyak percobaan gagal. Coba lagi dalam 15 menit.',
      retryAfter,
      'ACCOUNT_LOCKED',
    );
  }

  if (!entry || now - entry.lastAttempt > BRUTE_WINDOW_MS) {
    entry = { attempts: 0, lockUntil: 0, lastAttempt: now };
    bruteForceLimits.set(key, entry);
  }

  return null;
}

export async function bruteForceRecordFailure(
  username: string,
  request: Request,
  env: Env,
): Promise<void> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const key = `${ip}:${username}`;
  const d1Key = `bf:${key}`;
  const now = Date.now();

  let entry = bruteForceLimits.get(key);
  if (!entry || now - entry.lastAttempt > BRUTE_WINDOW_MS) {
    entry = { attempts: 0, lockUntil: 0, lastAttempt: now };
  }

  entry.attempts++;
  entry.lastAttempt = now;

  if (entry.attempts >= BRUTE_MAX_ATTEMPTS) {
    entry.lockUntil = now + BRUTE_LOCK_MS;

    try {
      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address, created_at) VALUES (?, 'brute_force_lock', 'auth', ?, ?, datetime('now'))"
      ).bind(0, `Akun dikunci: username=${username} setelah ${entry.attempts} percobaan gagal`, ip).run();
    } catch {
      // log gagal tidak menggagalkan proses
    }

    // Sync lock state ke D1 segera (kritis untuk cross-instance)
    await syncToD1(env, d1Key, 'bruteforce', entry.attempts, 0, entry.lockUntil, entry.lastAttempt);
  }

  bruteForceLimits.set(key, entry);

  // Sync setiap 5 attempt
  if (entry.attempts % 5 === 0) {
    await syncToD1(env, d1Key, 'bruteforce', entry.attempts, 0, entry.lockUntil, entry.lastAttempt);
  }
}

export async function bruteForceRecordSuccess(username: string, env?: Env): Promise<void> {
  for (const [key] of bruteForceLimits) {
    if (key.endsWith(`:${username}`)) {
      bruteForceLimits.delete(key);
    }
  }

  // Hapus juga dari D1 jika env tersedia
  if (env) {
    try {
      // Hapus semua entry brute force untuk username ini (dari IP mana pun)
      await env.DB.prepare(
        "DELETE FROM rate_limits WHERE key LIKE ? AND type = 'bruteforce'"
      ).bind(`%:${username}`).run();
    } catch {
      // Hapus gagal tidak kritis
    }
  }
}
