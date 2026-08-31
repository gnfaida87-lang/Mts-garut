import { Env, ApiKeyPayload, ApiKeyRateLimitEntry } from '../types';
import { corsHeaders } from '../utils/response';
import bcrypt from 'bcryptjs';

// ============================================================
// API Key Validation Middleware
// ============================================================

interface RateLimitEntry {
  count: number;
  windowStart: number;
  date: string;
}

const apiKeyRateLimits = new Map<string, RateLimitEntry>();
const DAILY_WINDOW_MS = 24 * 60 * 60 * 1000;
const CLEANUP_INTERVAL_MS = 60_000;
const D1_SYNC_INTERVAL_MS = 60_000;

let lastApiKeyCleanup = Date.now();
let lastApiKeyD1Sync = Date.now();

function cleanupApiKeyLimits() {
  const now = Date.now();
  if (now - lastApiKeyCleanup < CLEANUP_INTERVAL_MS) return;
  lastApiKeyCleanup = now;

  const today = new Date().toISOString().split('T')[0];
  for (const [key, entry] of apiKeyRateLimits) {
    if (entry.date !== today || now - entry.windowStart > DAILY_WINDOW_MS) {
      apiKeyRateLimits.delete(key);
    }
  }
}

async function syncApiKeyRateLimitToD1(env: Env, key: string, entry: RateLimitEntry): Promise<void> {
  try {
    await env.DB.prepare(
      `INSERT INTO api_key_rate_limits (api_key_id, date, count, window_start, updated_at)
       VALUES (?, ?, ?, ?, datetime('now'))
       ON CONFLICT(api_key_id, date) DO UPDATE SET
         count = excluded.count,
         window_start = excluded.window_start,
         updated_at = datetime('now')`
    ).bind(key, entry.date, entry.count, entry.windowStart).run();
  } catch {
    // Sync gagal tidak menggagalkan request
  }
}

async function periodicApiKeySync(env: Env): Promise<void> {
  const now = Date.now();
  if (now - lastApiKeyD1Sync < D1_SYNC_INTERVAL_MS) return;
  lastApiKeyD1Sync = now;

  for (const [key, entry] of apiKeyRateLimits) {
    await syncApiKeyRateLimitToD1(env, key, entry);
  }

  // Cleanup expired D1 entries (data > 7 hari)
  try {
    await env.DB.prepare(
      "DELETE FROM api_key_rate_limits WHERE date < date('now', '-7 days')"
    ).run();
  } catch {
    // cleanup gagal tidak kritis
  }
}

function apiKeyRateLimitResponse(message: string, retryAfter: number): Response {
  return new Response(
    JSON.stringify({ success: false, error: { code: 'RATE_LIMITED', message } }),
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

/**
 * Validate API Key dari header X-API-Key
 * Returns: { valid: true, payload } atau { valid: false, error, status }
 */
export async function validateApiKey(
  request: Request,
  env: Env
): Promise<{ valid: true; payload: ApiKeyPayload } | { valid: false; error: Response }> {
  const apiKey = request.headers.get('X-API-Key');
  if (!apiKey) {
    return {
      valid: false,
      error: new Response(
        JSON.stringify({ success: false, error: { code: 'MISSING_API_KEY', message: 'Header X-API-Key wajib diisi' } }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders('*') } },
      ),
    };
  }

  // Cari API key di database
  const keyRecord = await env.DB.prepare(
    'SELECT id, nama_pihak, api_key_hash, permissions, rate_limit, is_aktif FROM api_keys WHERE is_aktif = 1'
  ).all<{
    id: number;
    nama_pihak: string;
    api_key_hash: string;
    permissions: string;
    rate_limit: number;
    is_aktif: number;
  }>();

  let matchedKey: typeof keyRecord.results[0] | null = null;

  for (const row of keyRecord.results) {
    const isMatch = await bcrypt.compare(apiKey, row.api_key_hash);
    if (isMatch) {
      matchedKey = row;
      break;
    }
  }

  if (!matchedKey) {
    return {
      valid: false,
      error: new Response(
        JSON.stringify({ success: false, error: { code: 'INVALID_API_KEY', message: 'API Key tidak valid atau tidak aktif' } }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders('*') } },
      ),
    };
  }

  // Update last_used_at
  try {
    await env.DB.prepare(
      "UPDATE api_keys SET last_used_at = datetime('now') WHERE id = ?"
    ).bind(matchedKey.id).run();
  } catch {
    // non-blocking
  }

  // Rate limiting per API Key per hari
  cleanupApiKeyLimits();

  const today = new Date().toISOString().split('T')[0];
  const rateLimitKey = `${matchedKey.id}:${today}`;
  let entry = apiKeyRateLimits.get(rateLimitKey);

  if (!entry) {
    // Coba load dari D1 (cold start)
    try {
      const d1Entry = await env.DB.prepare(
        'SELECT count, window_start, date FROM api_key_rate_limits WHERE api_key_id = ? AND date = ?'
      ).bind(matchedKey.id, today).first<{ count: number; window_start: number; date: string }>();

      if (d1Entry) {
        entry = { count: d1Entry.count, windowStart: d1Entry.window_start, date: d1Entry.date };
      }
    } catch {
      // D1 error - fallback
    }
  }

  if (!entry || entry.date !== today) {
    entry = { count: 0, windowStart: Date.now(), date: today };
  }

  entry.count++;
  apiKeyRateLimits.set(rateLimitKey, entry);

  if (entry.count > matchedKey.rate_limit) {
    const retryAfter = Math.ceil((entry.windowStart + DAILY_WINDOW_MS - Date.now()) / 1000);
    return {
      valid: false,
      error: apiKeyRateLimitResponse(
        `Rate limit terlampaui. Maksimal ${matchedKey.rate_limit} request per hari.`,
        retryAfter,
      ),
    };
  }

  // Async D1 sync (non-blocking)
  if (entry.count === 1 || entry.count % 10 === 0) {
    syncApiKeyRateLimitToD1(env, String(matchedKey.id), entry);
  }

  // Periodic sync
  periodicApiKeySync(env);

  const payload: ApiKeyPayload = {
    id: matchedKey.id,
    nama_pihak: matchedKey.nama_pihak,
    permissions: matchedKey.permissions as 'read' | 'write' | 'readwrite',
    rate_limit: matchedKey.rate_limit,
  };

  return { valid: true, payload };
}

/**
 * Middleware untuk endpoint yang memerlukan permission tertentu
 */
export function requirePermission(required: 'read' | 'write' | 'readwrite') {
  return async (request: Request, env: Env): Promise<{ valid: true; payload: ApiKeyPayload } | { valid: false; error: Response }> => {
    const result = await validateApiKey(request, env);
    if (!result.valid) return result;

    const { payload } = result;
    const hasPermission =
      required === 'read' && ['read', 'readwrite'].includes(payload.permissions) ||
      required === 'write' && ['write', 'readwrite'].includes(payload.permissions) ||
      required === 'readwrite' && payload.permissions === 'readwrite';

    if (!hasPermission) {
      return {
        valid: false,
        error: new Response(
          JSON.stringify({
            success: false,
            error: {
              code: 'INSUFFICIENT_PERMISSIONS',
              message: `Permission '${required}' required. Current: '${payload.permissions}'`,
            },
          }),
          { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders('*') } },
        ),
      };
    }

    return result;
  };
}

/**
 * Generate API Key acak (32 karakter)
 */
export function generateApiKey(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = 'sk_live_';
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Hash API Key dengan bcrypt
 */
export async function hashApiKey(apiKey: string): Promise<string> {
  return bcrypt.hash(apiKey, 10);
}