import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';
import {
  WaktuAbsensiMusyrifah,
  WAKTU_MUSYRIFAH_FIELD_KEYS,
  getWaktuAbsensiMusyrifah,
  normalizeJam,
  validateWaktuAbsensi,
} from '../../utils/absensi_waktu';
import bcrypt from 'bcryptjs';

type Row = Record<string, unknown>;

const WIB_MS = 7 * 60 * 60 * 1000;

function wibDate(): string {
  return new Date(Date.now() + WIB_MS).toISOString().split('T')[0];
}

function logAction(env: Env, userId: number, aksi: string, modul: string, detail: string, ip: string) {
  return env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(userId, aksi, modul, detail, ip).run();
}

// ============================================================
// HANDLER: Admin Dauroh Routes
// ============================================================

export async function handleAdminDauroh(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(3).join('/'); // /api/admin/dauroh/...

  // ─── PROGRAM KEGIATAN ───────────────────────────────────────
  if (subPath === 'program' || subPath.startsWith('program/')) {
    return handleProgram(request, env, user, pathParts, url, ip);
  }

  // ─── MUSYRIFAH ──────────────────────────────────────────────
  if (subPath === 'musyrifah' || subPath.startsWith('musyrifah/')) {
    return handleMusyrifah(request, env, user, pathParts, url, ip);
  }

  // ─── JADWAL ─────────────────────────────────────────────────
  if (subPath === 'jadwal' || subPath.startsWith('jadwal/')) {
    return handleJadwal(request, env, user, pathParts, url, ip);
  }

  // ─── QR CODE ────────────────────────────────────────────────
  if (subPath === 'qr') {
    return handleGetQR(env);
  }

  // ─── PENGATURAN WAKTU ABSENSI MUSYRIFAH ─────────────────────
  if (subPath === 'pengaturan-waktu') {
    if (request.method === 'GET') {
      return success(await getWaktuAbsensiMusyrifah(env));
    }
    if (request.method === 'PUT') {
      return handleUpdateWaktuMusyrifah(request, env, user, ip);
    }
    return badRequest('Method tidak didukung');
  }

  // ─── MONITORING ABSENSI ─────────────────────────────────────
  const absensiKoreksiMatch = subPath.match(/^monitoring\/absensi\/(\d+)$/);
  if (absensiKoreksiMatch && request.method === 'PUT') {
    return handleKoreksiAbsensiMusyrifah(request, env, user, parseInt(absensiKoreksiMatch[1]), ip);
  }
  if (subPath === 'monitoring/absensi') {
    return handleMonitoringAbsensi(request, env, url);
  }

  // ─── MONITORING NILAI ───────────────────────────────────────
  if (subPath === 'monitoring/nilai') {
    return handleMonitoringNilai(request, env, url);
  }

  return badRequest('Endpoint tidak dikenal');
}

// ============================================================
// PROGRAM KEGIATAN
// ============================================================

async function handleProgram(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/program
  if (method === 'GET' && !id) {
    return listProgram(env, url);
  }

  // GET /api/admin/dauroh/program/:id
  if (method === 'GET' && id) {
    return getProgram(env, id);
  }

  // POST /api/admin/dauroh/program
  if (method === 'POST') {
    return createProgram(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/program/:id
  if (method === 'PUT' && id) {
    return updateProgram(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/program/:id
  if (method === 'DELETE' && id) {
    return deleteProgram(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listProgram(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const offset = (page - 1) * perPage;

  let where = '';
  const bindings: unknown[] = [];

  if (search) {
    where = 'WHERE p.nama_program LIKE ?';
    bindings.push(`%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_program p ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT p.*, 
           (SELECT COUNT(*) FROM dauroh_jadwal j WHERE j.program_id = p.id) as jumlah_jadwal
    FROM dauroh_program p
    ${where}
    ORDER BY p.nama_program ASC
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getProgram(env: Env, id: number) {
  const program = await env.DB.prepare(
    'SELECT * FROM dauroh_program WHERE id = ?'
  ).bind(id).first<Row>();

  if (!program) return notFound('Program');

  // Ambil kelas yang terkait
  const kelas = await env.DB.prepare(`
    SELECT DISTINCT k.id, k.nama 
    FROM dauroh_jadwal jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.program_id = ?
  `).bind(id).all();

  // Ambil santri yang terkait (untuk program khusus)
  const santri = await env.DB.prepare(`
    SELECT s.id, s.nis, s.nama, k.nama as kelas_nama
    FROM dauroh_program_santri ps
    JOIN siswa s ON ps.santri_id = s.id
    LEFT JOIN kelas k ON s.kelas_id = k.id
    WHERE ps.program_id = ?
  `).bind(id).all();

  return success({ ...program, kelas: kelas.results, santri: santri.results });
}

async function createProgram(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { 
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
  } = body;

  if (!nama_program || !jenis_program || !jenis_dauroh) {
    return badRequest('nama_program, jenis_program, jenis_dauroh wajib diisi');
  }
  if (!['kelas', 'khusus'].includes(jenis_program as string)) {
    return badRequest('jenis_program harus "kelas" atau "khusus"');
  }
  if (!['murojaah', 'tahfidz'].includes(jenis_dauroh as string)) {
    return badRequest('jenis_dauroh harus "murojaah" atau "tahfidz"');
  }

  const result = await env.DB.prepare(`
    INSERT INTO dauroh_program (
      nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id,
      skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
      label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    nama_program, jenis_program, jenis_dauroh, keterangan || null, tahun_ajaran_id || null,
    skema_penilaian || 'murojaah_tahfidz', max_bidang1 ?? 40, max_bidang2 ?? 30, max_bidang3 ?? 30,
    label_bidang1 || 'Kelancaran Hafalan', label_bidang2 || 'Tajwid', label_bidang3 || 'Fashohah dan Adab',
    konfigurasi_nilai || null
  ).run();

  const newId = result.meta.last_row_id;

  // Simpan santri (untuk program khusus)
  // Catatan: kelas hanya dikaitkan via jadwal (dauroh_jadwal_kelas), bukan di program.
  if (jenis_program === 'khusus' && Array.isArray(body.santri_ids)) {
    for (const santriId of body.santri_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_program_santri (program_id, santri_id) VALUES (?, ?)'
      ).bind(newId, santriId).run();
    }
  }

  await logAction(env, user.sub, 'create', 'dauroh_program', `Buat program: ${nama_program}`, ip);

  return created({ id: newId, nama_program });
}

async function updateProgram(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { 
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id, is_aktif,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
  } = body;

  const existing = await env.DB.prepare('SELECT id FROM dauroh_program WHERE id = ?').bind(id).first();
  if (!existing) return notFound('Program');

  await env.DB.prepare(`
    UPDATE dauroh_program SET
      nama_program = COALESCE(?, nama_program),
      jenis_program = COALESCE(?, jenis_program),
      jenis_dauroh = COALESCE(?, jenis_dauroh),
      keterangan = COALESCE(?, keterangan),
      tahun_ajaran_id = COALESCE(?, tahun_ajaran_id),
      is_aktif = COALESCE(?, is_aktif),
      skema_penilaian = COALESCE(?, skema_penilaian),
      max_bidang1 = COALESCE(?, max_bidang1),
      max_bidang2 = COALESCE(?, max_bidang2),
      max_bidang3 = COALESCE(?, max_bidang3),
      label_bidang1 = COALESCE(?, label_bidang1),
      label_bidang2 = COALESCE(?, label_bidang2),
      label_bidang3 = COALESCE(?, label_bidang3),
      konfigurasi_nilai = COALESCE(?, konfigurasi_nilai),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id, is_aktif,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai, id
  ).run();

  await logAction(env, user.sub, 'update', 'dauroh_program', `Update program id=${id}`, ip);

  return success({ id, message: 'Program berhasil diupdate' });
}

async function deleteProgram(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id, nama_program FROM dauroh_program WHERE id = ?').bind(id).first<Row>();
  if (!existing) return notFound('Program');

  // Hapus data turunan dulu (absensi & nilai) agar tidak ada orphan / gagal FK
  const jadwalRows = await env.DB.prepare('SELECT id FROM dauroh_jadwal WHERE program_id = ?').bind(id).all<{ id: number }>();
  const jadwalIds = jadwalRows.results.map((r) => r.id);

  if (jadwalIds.length > 0) {
    const placeholders = jadwalIds.map(() => '?').join(', ');
    await env.DB.prepare(`DELETE FROM dauroh_absensi_musyrifah WHERE jadwal_id IN (${placeholders})`).bind(...jadwalIds).run();
    await env.DB.prepare(`DELETE FROM dauroh_absensi_santri WHERE jadwal_id IN (${placeholders})`).bind(...jadwalIds).run();
    await env.DB.prepare(`DELETE FROM dauroh_nilai WHERE jadwal_id IN (${placeholders})`).bind(...jadwalIds).run();
  }

  // Hapus relasi
  await env.DB.prepare('DELETE FROM dauroh_program_santri WHERE program_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_jadwal WHERE program_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_program WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_program', `Hapus program: ${existing.nama_program}`, ip);

  return success({ message: 'Program berhasil dihapus' });
}

// ============================================================
// MUSYRIFAH
// ============================================================

async function handleMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/musyrifah
  if (method === 'GET' && !id) {
    return listMusyrifah(env, url);
  }

  // GET /api/admin/dauroh/musyrifah/:id
  if (method === 'GET' && id) {
    return getMusyrifah(env, id);
  }

  // POST /api/admin/dauroh/musyrifah
  if (method === 'POST') {
    return createMusyrifah(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/musyrifah/:id
  if (method === 'PUT' && id) {
    return updateMusyrifah(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/musyrifah/:id
  if (method === 'DELETE' && id) {
    return deleteMusyrifah(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listMusyrifah(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const offset = (page - 1) * perPage;

  let where = '';
  const bindings: unknown[] = [];

  if (search) {
    where = 'WHERE (m.nama LIKE ? OR m.nipmus LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_musyrifah m ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT m.id, m.nipmus, m.nama, m.jenis_kelamin, m.status_pendidikan, m.gelar,
           m.username, m.is_aktif, m.created_at, m.updated_at,
           (SELECT COUNT(*) FROM dauroh_jadwal j WHERE j.musyrifah_1_id = m.id OR j.musyrifah_2_id = m.id) as jumlah_jadwal
    FROM dauroh_musyrifah m
    ${where}
    ORDER BY m.nipmus ASC
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getMusyrifah(env: Env, id: number) {
  const musyrifah = await env.DB.prepare(
    'SELECT id, nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, is_aktif, created_at, updated_at FROM dauroh_musyrifah WHERE id = ?'
  ).bind(id).first<Row>();

  if (!musyrifah) return notFound('Musyrifah');

  // Ambil jadwal yang diampu
  const jadwal = await env.DB.prepare(`
    SELECT j.*, p.nama_program
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    WHERE j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?
    ORDER BY j.hari, j.jam_mulai
  `).bind(id, id).all();

  return success({ ...musyrifah, jadwal: jadwal.results });
}

async function createMusyrifah(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password } = body;

  if (!nipmus || !nama || !jenis_kelamin || !status_pendidikan || !username || !password) {
    return badRequest('nipmus, nama, jenis_kelamin, status_pendidikan, username, password wajib diisi');
  }

  // Cek username duplikat
  const existing = await env.DB.prepare('SELECT id FROM dauroh_musyrifah WHERE username = ? OR nipmus = ?')
    .bind(username, nipmus).first();
  if (existing) {
    return badRequest('Username atau NIPMUS sudah digunakan');
  }

  const passwordHash = await bcrypt.hash(password as string, 10);

  const result = await env.DB.prepare(`
    INSERT INTO dauroh_musyrifah (nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password_hash)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(nipmus, nama, jenis_kelamin, status_pendidikan, gelar || null, username, passwordHash).run();

  const newId = result.meta.last_row_id;

  // Buat user account untuk musyrifah
  await env.DB.prepare(`
    INSERT INTO users (username, password_hash, role, is_active)
    VALUES (?, ?, 'musyrifah', 1)
  `).bind(username, passwordHash).run();

  await logAction(env, user.sub, 'create', 'dauroh_musyrifah', `Buat musyrifah: ${nama}`, ip);

  return created({ id: newId, nama, username });
}

async function updateMusyrifah(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password, is_aktif } = body;

  const existing = await env.DB.prepare('SELECT id, username FROM dauroh_musyrifah WHERE id = ?').bind(id).first<{ id: number; username: string }>();
  if (!existing) return notFound('Musyrifah');

  let passwordHash = null;
  if (password) {
    passwordHash = await bcrypt.hash(password as string, 10);
  }

  await env.DB.prepare(`
    UPDATE dauroh_musyrifah SET
      nipmus = COALESCE(?, nipmus),
      nama = COALESCE(?, nama),
      jenis_kelamin = COALESCE(?, jenis_kelamin),
      status_pendidikan = COALESCE(?, status_pendidikan),
      gelar = COALESCE(?, gelar),
      username = COALESCE(?, username),
      password_hash = COALESCE(?, password_hash),
      is_aktif = COALESCE(?, is_aktif),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, passwordHash, is_aktif, id).run();

  // Update user account jika ada perubahan username/password
  if (username || password) {
    const newUsername = username || existing.username;
    if (passwordHash) {
      await env.DB.prepare('UPDATE users SET username = ?, password_hash = ? WHERE username = ?')
        .bind(newUsername, passwordHash, existing.username).run();
    } else {
      await env.DB.prepare('UPDATE users SET username = ? WHERE username = ?')
        .bind(newUsername, existing.username).run();
    }
  }

  await logAction(env, user.sub, 'update', 'dauroh_musyrifah', `Update musyrifah id=${id}`, ip);

  return success({ id, message: 'Musyrifah berhasil diupdate' });
}

async function deleteMusyrifah(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id, nama, username FROM dauroh_musyrifah WHERE id = ?').bind(id).first<Row>();
  if (!existing) return notFound('Musyrifah');

  // Hapus jadwal terkait
  await env.DB.prepare('UPDATE dauroh_jadwal SET musyrifah_1_id = NULL WHERE musyrifah_1_id = ?').bind(id).run();
  await env.DB.prepare('UPDATE dauroh_jadwal SET musyrifah_2_id = NULL WHERE musyrifah_2_id = ?').bind(id).run();

  // Hapus user account
  await env.DB.prepare("DELETE FROM users WHERE username = ? AND role = 'musyrifah'").bind(existing.username).run();

  // Hapus musyrifah
  await env.DB.prepare('DELETE FROM dauroh_musyrifah WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_musyrifah', `Hapus musyrifah: ${existing.nama}`, ip);

  return success({ message: 'Musyrifah berhasil dihapus' });
}

// ============================================================
// JADWAL
// ============================================================

async function handleJadwal(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/jadwal
  if (method === 'GET' && !id) {
    return listJadwal(env, url);
  }

  // GET /api/admin/dauroh/jadwal/:id
  if (method === 'GET' && id) {
    return getJadwal(env, id);
  }

  // POST /api/admin/dauroh/jadwal
  if (method === 'POST') {
    return createJadwal(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/jadwal/:id
  if (method === 'PUT' && id) {
    return updateJadwal(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/jadwal/:id
  if (method === 'DELETE' && id) {
    return deleteJadwal(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listJadwal(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const filterProgram = url.searchParams.get('program_id');
  const filterHari = url.searchParams.get('hari');
  const offset = (page - 1) * perPage;

  let where = 'WHERE 1=1';
  const bindings: unknown[] = [];

  if (search) {
    where += ' AND (p.nama_program LIKE ? OR m1.nama LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }
  if (filterProgram) {
    where += ' AND j.program_id = ?';
    bindings.push(filterProgram);
  }
  if (filterHari) {
    where += ' AND j.hari = ?';
    bindings.push(filterHari);
  }

  const countResult = await env.DB.prepare(`
    SELECT COUNT(*) as total 
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    ${where}
  `).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama,
           m2.nama as musyrifah_2_nama,
           (SELECT GROUP_CONCAT(k.nama, ', ') FROM dauroh_jadwal_kelas jdk JOIN kelas k ON jdk.kelas_id = k.id WHERE jdk.jadwal_id = j.id) as kelas_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    ${where}
    ORDER BY j.hari, j.jam_mulai
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getJadwal(env: Env, id: number) {
  const jadwal = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama, m1.nipmus as musyrifah_1_nipmus,
           m2.nama as musyrifah_2_nama, m2.nipmus as musyrifah_2_nipmus
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    WHERE j.id = ?
  `).bind(id).first<Row>();

  if (!jadwal) return notFound('Jadwal');

  // Ambil kelas
  const kelas = await env.DB.prepare(`
    SELECT k.id, k.nama
    FROM dauroh_jadwal_kelas jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.jadwal_id = ?
  `).bind(id).all();

  return success({ ...jadwal, kelas: kelas.results });
}

async function createJadwal(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, kelas_ids } = body;

  const hariList = Array.isArray(hari)
    ? (hari as unknown[]).filter((h): h is string => typeof h === 'string' && h.trim().length > 0)
    : (typeof hari === 'string' && hari.trim() ? [hari.trim()] : []);

  if (!program_id || !musyrifah_1_id || hariList.length === 0 || !jam_mulai || !jam_selesai) {
    return badRequest('program_id, musyrifah_1_id, hari (minimal 1), jam_mulai, jam_selesai wajib diisi');
  }

  // Validasi program
  const program = await env.DB.prepare('SELECT id FROM dauroh_program WHERE id = ?').bind(program_id).first();
  if (!program) return notFound('Program');

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare('SELECT id FROM dauroh_musyrifah WHERE id = ?').bind(musyrifah_1_id).first();
  if (!musyrifah) return notFound('Musyrifah 1');

  const createdIds: number[] = [];
  for (const h of hariList) {
    const result = await env.DB.prepare(`
      INSERT INTO dauroh_jadwal (program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(program_id, musyrifah_1_id, musyrifah_2_id || null, jenjang || null, h, jam_mulai, jam_selesai).run();

    const newId = Number(result.meta.last_row_id);
    createdIds.push(newId);

    // Simpan kelas
    if (Array.isArray(kelas_ids)) {
      for (const kelasId of kelas_ids) {
        await env.DB.prepare(
          'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
        ).bind(newId, kelasId).run();
      }
    }
  }

  await logAction(env, user.sub, 'create', 'dauroh_jadwal', `Buat ${createdIds.length} jadwal program id=${program_id}`, ip);

  return created({ ids: createdIds, count: createdIds.length });
}

async function updateJadwal(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, kelas_ids, is_aktif } = body;

  const existing = await env.DB.prepare('SELECT id, hari FROM dauroh_jadwal WHERE id = ?').bind(id).first<{ id: number; hari: string }>();
  if (!existing) return notFound('Jadwal');

  const hariList = Array.isArray(hari)
    ? (hari as unknown[]).filter((h): h is string => typeof h === 'string' && h.trim().length > 0)
    : (typeof hari === 'string' && hari.trim() ? [hari.trim()] : []);

  const hariFinal = hariList[0] ?? existing.hari;

  await env.DB.prepare(`
    UPDATE dauroh_jadwal SET
      program_id = COALESCE(?, program_id),
      musyrifah_1_id = COALESCE(?, musyrifah_1_id),
      musyrifah_2_id = COALESCE(?, musyrifah_2_id),
      jenjang = COALESCE(?, jenjang),
      hari = ?,
      jam_mulai = COALESCE(?, jam_mulai),
      jam_selesai = COALESCE(?, jam_selesai),
      is_aktif = COALESCE(?, is_aktif),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(
    program_id ?? null,
    musyrifah_1_id ?? null,
    musyrifah_2_id ?? null,
    jenjang ?? null,
    hariFinal,
    jam_mulai ?? null,
    jam_selesai ?? null,
    is_aktif ?? null,
    id
  ).run();

  // Update kelas
  if (Array.isArray(kelas_ids)) {
    await env.DB.prepare('DELETE FROM dauroh_jadwal_kelas WHERE jadwal_id = ?').bind(id).run();
    for (const kelasId of kelas_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
      ).bind(id, kelasId).run();
    }
  }

  // Hari tambahan (di luar hari baris yang di-update) → buat jadwal baru
  const createdIds: number[] = [];
  for (const h of hariList.slice(1)) {
    const result = await env.DB.prepare(`
      INSERT INTO dauroh_jadwal (program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, is_aktif)
      SELECT program_id, musyrifah_1_id, musyrifah_2_id, jenjang, ?, jam_mulai, jam_selesai, is_aktif
      FROM dauroh_jadwal WHERE id = ?
    `).bind(h, id).run();

    const newId = Number(result.meta.last_row_id);
    createdIds.push(newId);

    if (Array.isArray(kelas_ids)) {
      for (const kelasId of kelas_ids) {
        await env.DB.prepare(
          'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
        ).bind(newId, kelasId).run();
      }
    }
  }

  await logAction(env, user.sub, 'update', 'dauroh_jadwal', `Update jadwal id=${id}${createdIds.length ? ` + ${createdIds.length} hari baru` : ''}`, ip);

  return success({ id, created_ids: createdIds, message: 'Jadwal berhasil diupdate' });
}

async function deleteJadwal(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id FROM dauroh_jadwal WHERE id = ?').bind(id).first();
  if (!existing) return notFound('Jadwal');

  // Hapus data turunan dulu agar tidak ada orphan / gagal FK
  await env.DB.prepare('DELETE FROM dauroh_absensi_musyrifah WHERE jadwal_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_absensi_santri WHERE jadwal_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_nilai WHERE jadwal_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_jadwal_kelas WHERE jadwal_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_jadwal WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_jadwal', `Hapus jadwal id=${id}`, ip);

  return success({ message: 'Jadwal berhasil dihapus' });
}

// ============================================================
// QR CODE
// ============================================================

const DEFAULT_QR_TOKEN = 'PPI_DAUROH_QR_2026';

async function handleGetQR(env: Env) {
  const token = env.QR_DAUROH_TOKEN || DEFAULT_QR_TOKEN;
  return success({
    token,
    message: 'QR Code Dauroh - Token untuk absensi musyrifah',
  });
}

// ============================================================
// PENGATURAN WAKTU ABSENSI MUSYRIFAH
// ============================================================

async function handleUpdateWaktuMusyrifah(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return badRequest('Body JSON tidak valid');

  const waktu: WaktuAbsensiMusyrifah = {
    jam_masuk_mulai: normalizeJam(body.jam_masuk_mulai as string),
    jam_masuk_selesai: normalizeJam(body.jam_masuk_selesai as string),
    jam_keluar_mulai: normalizeJam(body.jam_keluar_mulai as string),
    jam_keluar_selesai: normalizeJam(body.jam_keluar_selesai as string),
  };

  const validationError = validateWaktuAbsensi(waktu);
  if (validationError) return badRequest(validationError);

  for (const field of Object.keys(WAKTU_MUSYRIFAH_FIELD_KEYS) as (keyof WaktuAbsensiMusyrifah)[]) {
    await env.DB.prepare(
      "INSERT INTO pengaturan (key, value, updated_at) VALUES (?, ?, datetime('now')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at"
    ).bind(WAKTU_MUSYRIFAH_FIELD_KEYS[field], waktu[field]).run();
  }

  await logAction(
    env, user.sub, 'update', 'dauroh',
    `Update jam absensi musyrifah: masuk ${waktu.jam_masuk_mulai.slice(0, 5)}-${waktu.jam_masuk_selesai.slice(0, 5)}, keluar ${waktu.jam_keluar_mulai.slice(0, 5)}-${waktu.jam_keluar_selesai.slice(0, 5)}`,
    ip
  );

  return success({ message: 'Pengaturan waktu absensi musyrifah tersimpan', ...waktu });
}

// ============================================================
// MONITORING
// ============================================================

const HARI_INDONESIA = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

function wibHari(tanggal: string): string {
  const d = new Date(`${tanggal}T00:00:00Z`);
  return HARI_INDONESIA[d.getUTCDay()];
}

async function handleMonitoringAbsensi(request: Request, env: Env, url: URL) {
  const tanggal = url.searchParams.get('tanggal') || wibDate();
  const programId = url.searchParams.get('program_id');
  const hari = wibHari(tanggal);

  // Bindings: [tanggal] utk LEFT JOIN, lalu [hari], lalu [programId]
  const bindings: unknown[] = [tanggal];
  let where = 'WHERE j.is_aktif = 1 AND j.hari = ?';
  bindings.push(hari);

  if (programId) {
    where += ' AND j.program_id = ?';
    bindings.push(programId);
  }

  const rows = await env.DB.prepare(`
    SELECT
      m.nipmus, m.nama, m.jenis_kelamin,
      j.id AS jadwal_id, j.hari, j.jam_mulai, j.jam_selesai,
      p.nama_program,
      am.id AS absensi_id,
      am.waktu_masuk, am.waktu_keluar, am.status,
      CASE WHEN am.id IS NULL THEN 1 ELSE 0 END AS belum_absen
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m ON (m.id = j.musyrifah_1_id OR m.id = j.musyrifah_2_id)
    LEFT JOIN dauroh_absensi_musyrifah am
      ON am.musyrifah_id = m.id AND am.jadwal_id = j.id AND am.tanggal = ?
    ${where}
    ORDER BY m.nipmus ASC, j.jam_mulai ASC
  `).bind(...bindings).all();

  // Rekap (ikut JOIN agar filter program_id valid)
  const rekap = await env.DB.prepare(`
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN am.status = 'hadir' THEN 1 ELSE 0 END) as hadir,
      SUM(CASE WHEN am.status = 'izin' THEN 1 ELSE 0 END) as izin,
      SUM(CASE WHEN am.status = 'sakit' THEN 1 ELSE 0 END) as sakit,
      SUM(CASE WHEN am.status = 'alpha' THEN 1 ELSE 0 END) as alpha,
      SUM(CASE WHEN am.id IS NULL THEN 1 ELSE 0 END) as belum_absen
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m ON (m.id = j.musyrifah_1_id OR m.id = j.musyrifah_2_id)
    LEFT JOIN dauroh_absensi_musyrifah am
      ON am.musyrifah_id = m.id AND am.jadwal_id = j.id AND am.tanggal = ?
    ${where}
  `).bind(...bindings).first();

  return success({
    tanggal,
    data: rows.results,
    rekap,
  });
}

// PUT /api/admin/dauroh/monitoring/absensi/:id - koreksi absensi musyrifah oleh admin
async function handleKoreksiAbsensiMusyrifah(request: Request, env: Env, user: UserPayload, id: number, ip: string) {
  const existing = await env.DB.prepare(
    'SELECT id, tanggal FROM dauroh_absensi_musyrifah WHERE id = ?'
  ).bind(id).first<{ id: number; tanggal: string }>();
  if (!existing) return notFound('Absensi Musyrifah');

  const body = await request.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return badRequest('Body JSON tidak valid');

  const timeRe = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;
  const normalize = (t: string | null) => (t && t.length === 5) ? `${t}:00` : t;

  const waktuMasuk = body.waktu_masuk != null ? String(body.waktu_masuk).trim() : null;
  const waktuKeluar = body.waktu_keluar != null ? String(body.waktu_keluar).trim() : null;
  const status = body.status != null ? String(body.status).trim() : null;

  if (waktuMasuk !== null && (waktuMasuk === '' || !timeRe.test(waktuMasuk))) {
    return badRequest('waktu_masuk harus format HH:MM atau HH:MM:SS');
  }
  if (waktuKeluar !== null && (waktuKeluar === '' || !timeRe.test(waktuKeluar))) {
    return badRequest('waktu_keluar harus format HH:MM atau HH:MM:SS');
  }
  if (status !== null && !['hadir', 'izin', 'sakit', 'alpha'].includes(status)) {
    return badRequest('status harus hadir, izin, sakit, atau alpha');
  }

  await env.DB.prepare(
    `UPDATE dauroh_absensi_musyrifah SET
       waktu_masuk = COALESCE(?, waktu_masuk),
       waktu_keluar = COALESCE(?, waktu_keluar),
       status = COALESCE(?, status)
     WHERE id = ?`
  ).bind(normalize(waktuMasuk), normalize(waktuKeluar), status, id).run();

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'dauroh_absensi', ?, ?)"
  ).bind(user.sub, `Koreksi absensi musyrifah id=${id} (${existing.tanggal})`, ip).run();

  return success({ id, updated: true });
}

async function handleMonitoringNilai(request: Request, env: Env, url: URL) {
  const jenjang = url.searchParams.get('jenjang');
  const kelasId = url.searchParams.get('kelas_id');
  const programId = url.searchParams.get('program_id');
  const status = url.searchParams.get('status');

  let where = 'WHERE 1=1';
  const bindings: unknown[] = [];

  if (jenjang) {
    where += ' AND t.jenjang = ?';
    bindings.push(jenjang);
  }
  if (kelasId) {
    where += ' AND s.kelas_id = ?';
    bindings.push(kelasId);
  }
  if (programId) {
    where += ' AND n.program_id = ?';
    bindings.push(programId);
  }
  if (status) {
    where += ' AND n.status_hafalan = ?';
    bindings.push(status);
  }

  const rows = await env.DB.prepare(`
    SELECT 
      s.nis, s.nama, s.jenis_kelamin,
      k.nama as kelas_nama,
      p.nama_program, p.jenis_program, p.jenis_dauroh,
      p.max_bidang1, p.max_bidang2, p.max_bidang3,
      n.surat_nomor,
      ds.nama as surat_nama,
      n.dari_ayat,
      n.sampai_ayat,
      n.status_hafalan,
      n.nilai_bidang1,
      n.nilai_bidang2,
      n.nilai_bidang3,
      n.total_nilai,
      n.catatan_umum,
      n.rencana_tindak_lanjut,
      dm.nama as musyrifah_nama,
      n.created_at
    FROM dauroh_nilai n
    JOIN siswa s ON n.santri_id = s.id
    JOIN kelas k ON s.kelas_id = k.id
    JOIN tingkat t ON k.tingkat_id = t.id
    JOIN dauroh_program p ON n.program_id = p.id
    LEFT JOIN dauroh_surat ds ON n.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON n.diinput_oleh = dm.id
    ${where}
    ORDER BY s.nis ASC
  `).bind(...bindings).all();

  return success(rows.results);
}
