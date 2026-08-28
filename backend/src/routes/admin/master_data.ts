import { Env, UserPayload } from '../../types';
import { CrudConfig, list, getById, create, update, remove, success, notFound } from '../../utils/crud';
import { json, badRequest, corsHeaders, error } from '../../utils/response';
import bcrypt from 'bcryptjs';
import * as XLSX from 'xlsx';

function jabatanToRole(jabatan: string): string {
  if (jabatan.includes('guru_bk')) return 'guru_bk';
  if (jabatan.includes('wakil_kurikulum')) return 'wakil_kurikulum';
  if (jabatan.includes('kepala_sekolah')) return 'kepala_sekolah';
  return 'guru_mapel_wali_kelas';
}

async function upsertUserForGuru(env: Env, guruId: number, username: string, password: string, jabatan: string, adminId: number, ip: string) {
  const role = jabatanToRole(jabatan);
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await env.DB.prepare('SELECT id FROM users WHERE guru_id = ?').bind(guruId).first<{ id: number }>();
  if (existing) {
    await env.DB.prepare('UPDATE users SET username = ?, password_hash = ?, role = ? WHERE guru_id = ?')
      .bind(username, passwordHash, role, guruId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'users', ?, ?)")
      .bind(adminId, `Update user untuk guru id=${guruId}`, ip).run();
  } else {
    await env.DB.prepare("INSERT INTO users (username, password_hash, role, guru_id, is_active) VALUES (?, ?, ?, ?, 1)")
      .bind(username, passwordHash, role, guruId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'users', ?, ?)")
      .bind(adminId, `Buat user untuk guru id=${guruId} (${username})`, ip).run();
  }
}

async function upsertUserForSiswa(env: Env, siswaId: number, username: string, password: string, adminId: number, ip: string) {
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await env.DB.prepare('SELECT id FROM users WHERE siswa_id = ?').bind(siswaId).first<{ id: number }>();
  if (existing) {
    await env.DB.prepare('UPDATE users SET username = ?, password_hash = ? WHERE siswa_id = ?')
      .bind(username, passwordHash, siswaId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'users', ?, ?)")
      .bind(adminId, `Update user untuk siswa id=${siswaId}`, ip).run();
  } else {
    await env.DB.prepare("INSERT INTO users (username, password_hash, role, siswa_id, is_active) VALUES (?, ?, 'siswa', ?, 1)")
      .bind(username, passwordHash, siswaId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'users', ?, ?)")
      .bind(adminId, `Buat user untuk siswa id=${siswaId} (${username})`, ip).run();
  }
}

const configs: Record<string, CrudConfig> = {
  'tahun-ajaran': { table: 'tahun_ajaran', columns: ['nama', 'is_aktif'], label: 'Tahun Ajaran', searchFields: ['nama'], sortBy: 'id DESC' },
  'semester': { table: 'semester', columns: ['tahun_ajaran_id', 'nama', 'is_aktif'], label: 'Semester', searchFields: ['nama'], sortBy: 'id DESC' },
  'jurusan': { table: 'jurusan', columns: ['nama', 'kode'], label: 'Jurusan', searchFields: ['nama', 'kode'], sortBy: 'nama ASC' },
  'tingkat': { table: 'tingkat', columns: ['nama', 'jenjang'], label: 'Tingkat', searchFields: ['nama'], sortBy: `CASE nama WHEN 'VII' THEN 7 WHEN 'VIII' THEN 8 WHEN 'IX' THEN 9 WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 ELSE 99 END` },
  'kelas': { table: 'kelas', columns: ['nama', 'tingkat_id', 'jurusan_id', 'tahun_ajaran_id'], label: 'Kelas', searchFields: ['nama'],
    sortJoin: ' LEFT JOIN tingkat ON kelas.tingkat_id = tingkat.id',
    sortBy: `CASE tingkat.nama WHEN 'VII' THEN 7 WHEN 'VIII' THEN 8 WHEN 'IX' THEN 9 WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 ELSE 99 END, kelas.nama` },
  'mata-pelajaran': { table: 'mata_pelajaran', columns: ['nama', 'kode'], label: 'Mata Pelajaran', searchFields: ['nama', 'kode'], sortBy: 'kode ASC' },
  'guru': {
    table: 'guru', columns: ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'], label: 'Asatidz', searchFields: ['nama', 'nip'], filterFields: ['jabatan'],
    sortBy: 'nip ASC',
    leftJoin: { table: 'users', on: 'users.guru_id = guru.id', select: ["users.username"] },
  },
  'siswa': {
    table: 'siswa', columns: ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'tahun_ajaran_id', 'status', 'nama_ayah', 'nama_ibu', 'pekerjaan_ayah', 'pekerjaan_ibu', 'whatsapp'], label: 'Santri', searchFields: ['nama', 'nis', 'nisn'], filterFields: ['kelas_id', 'status'],
    sortJoin: ' LEFT JOIN kelas ON siswa.kelas_id = kelas.id LEFT JOIN tingkat ON kelas.tingkat_id = tingkat.id',
    sortBy: `CASE tingkat.nama WHEN 'VII' THEN 7 WHEN 'VIII' THEN 8 WHEN 'IX' THEN 9 WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12 ELSE 99 END, kelas.nama, siswa.nama`,
    leftJoin: { table: 'users', on: 'users.siswa_id = siswa.id', select: ["users.username"] },
  },
  'ruangan': { table: 'ruangan', columns: ['nama', 'kapasitas'], label: 'Ruangan', searchFields: ['nama'] },
};

export async function handleAdminMasterData(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 3) return badRequest('Resource tidak valid');

  const resource = pathParts[2];

  const isList = pathParts.length === 3 && request.method === 'GET' && !url.searchParams.has('id');
  const isById = pathParts.length === 4 && request.method === 'GET';
  const isCreate = pathParts.length === 3 && request.method === 'POST';
  const isUpdate = pathParts.length === 4 && request.method === 'PUT';
  const isDelete = pathParts.length === 4 && request.method === 'DELETE';

  const cfg = configs[resource];
  if (!cfg) return badRequest(`Resource '${resource}' tidak dikenal`);

  try {
    if (isList) {
      // Siswa: support tingkat_id filter via kelas subquery
      let extraWhere = '';
      const extraBindings: unknown[] = [];
      if (resource === 'siswa') {
        const tingkatId = url.searchParams.get('tingkat_id');
        if (tingkatId) {
          extraWhere += ' AND siswa.kelas_id IN (SELECT kelas.id FROM kelas WHERE kelas.tingkat_id = ?)';
          extraBindings.push(tingkatId);
        }
      }
      return list(env, cfg, url, user, extraWhere || undefined, extraBindings.length > 0 ? extraBindings : undefined);
    }
    if (isById) return getById(env, cfg, parseInt(pathParts[3]));
    if (isCreate) {
      const body = await request.json() as Record<string, unknown>;

      // Auto-fill tahun_ajaran_id untuk siswa dari tahun ajaran aktif
      if (resource === 'siswa' && !body['tahun_ajaran_id']) {
        const taAktif = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1').first<{ id: number }>();
        if (taAktif) body['tahun_ajaran_id'] = taAktif.id;
      }

      const result = await create(env, cfg, body, user, ip);

      // Enforce: hanya 1 tahun ajaran aktif
      if (resource === 'tahun-ajaran' && body['is_aktif'] === 1) {
        const newId = (await result.clone().json() as { data?: { id?: number } })?.data?.id;
        if (newId) await env.DB.prepare('UPDATE tahun_ajaran SET is_aktif = 0 WHERE id != ?').bind(newId).run();
      }
      // Enforce: hanya 1 semester aktif
      if (resource === 'semester' && body['is_aktif'] === 1) {
        const newId = (await result.clone().json() as { data?: { id?: number } })?.data?.id;
        if (newId) await env.DB.prepare('UPDATE semester SET is_aktif = 0 WHERE id != ?').bind(newId).run();
      }

      if (resource === 'guru') {
        const resultBody = await result.clone().json() as { data?: { id?: number } };
        const guruId = resultBody?.data?.id;
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (guruId && username && password) {
          await upsertUserForGuru(env, guruId, username, password, (body['jabatan'] as string) || '', user.sub, ip);
        }
      }
      if (resource === 'siswa') {
        const resultBody = await result.clone().json() as { data?: { id?: number } };
        const siswaId = resultBody?.data?.id;
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (siswaId && username && password) {
          await upsertUserForSiswa(env, siswaId, username, password, user.sub, ip);
        }
      }
      // Auto-copy kelas dari tahun ajaran aktif sebelumnya ke tahun baru
      if (resource === 'tahun-ajaran') {
        const resultBody = await result.clone().json() as { data?: { id?: number } };
        const newTaId = resultBody?.data?.id;
        if (newTaId) {
          // Cari tahun ajaran aktif sebelumnya (bukan yang baru dibuat)
          const prevTa = await env.DB.prepare(
            'SELECT id, nama FROM tahun_ajaran WHERE id != ? ORDER BY id DESC LIMIT 1'
          ).bind(newTaId).first<{ id: number; nama: string }>();

          if (prevTa) {
            // Copy semua kelas dari tahun lama ke tahun baru
            const kelasRows = await env.DB.prepare(
              'SELECT nama, tingkat_id, jurusan_id, wali_kelas_id, ruangan_id FROM kelas WHERE tahun_ajaran_id = ?'
            ).bind(prevTa.id).all<{ nama: string; tingkat_id: number; jurusan_id: number; wali_kelas_id: number | null; ruangan_id: number | null }>();

            let copied = 0;
            for (const k of kelasRows.results) {
              await env.DB.prepare(
                'INSERT INTO kelas (nama, tingkat_id, jurusan_id, wali_kelas_id, ruangan_id, tahun_ajaran_id) VALUES (?, ?, ?, ?, ?, ?)'
              ).bind(k.nama, k.tingkat_id, k.jurusan_id, k.wali_kelas_id || null, k.ruangan_id || null, newTaId).run();
              copied++;
            }

            if (copied > 0) {
              await env.DB.prepare(
                "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'tahun_ajaran', ?, ?)"
              ).bind(user.sub, `Tahun ajaran baru dibuat, ${copied} kelas dicopy dari tahun ${prevTa.nama}`, ip).run();
            }
          }
        }
      }
      return result;
    }
    if (isUpdate) {
      const body = await request.json() as Record<string, unknown>;
      const id = parseInt(pathParts[3]);
      if (isNaN(id)) return badRequest('ID tidak valid');

      // Auto-fill tahun_ajaran_id untuk siswa dari tahun ajaran aktif
      if (resource === 'siswa' && !body['tahun_ajaran_id']) {
        const taAktif = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1').first<{ id: number }>();
        if (taAktif) body['tahun_ajaran_id'] = taAktif.id;
      }

      const result = await update(env, cfg, id, body, user, ip);

      // Enforce: hanya 1 tahun ajaran aktif
      if (resource === 'tahun-ajaran' && body['is_aktif'] === 1) {
        await env.DB.prepare('UPDATE tahun_ajaran SET is_aktif = 0 WHERE id != ?').bind(id).run();
      }
      // Enforce: hanya 1 semester aktif
      if (resource === 'semester' && body['is_aktif'] === 1) {
        await env.DB.prepare('UPDATE semester SET is_aktif = 0 WHERE id != ?').bind(id).run();
      }

      if (resource === 'guru') {
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (username && password) {
          const jabatan = body['jabatan'] as string | undefined;
          const existingGuru = await env.DB.prepare('SELECT jabatan FROM guru WHERE id = ?').bind(id).first<{ jabatan: string }>();
          await upsertUserForGuru(env, id, username, password, jabatan || existingGuru?.jabatan || '', user.sub, ip);
        }
      }
      if (resource === 'siswa') {
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (username && password) {
          await upsertUserForSiswa(env, id, username, password, user.sub, ip);
        }
      }
      return result;
    }
    if (isDelete) {
      const id = parseInt(pathParts[3]);
      if (resource === 'siswa') {
        await env.DB.prepare('DELETE FROM users WHERE siswa_id = ?').bind(id).run();
      }
      return remove(env, cfg, id, user, ip);
    }
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Invalid request');
  }

  return badRequest('Method tidak didukung');
}

export async function handleGuruMapelAmpu(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID asatidz diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT mata_pelajaran_id FROM guru_mapel WHERE guru_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { mata_pelajaran_id: number }).mata_pelajaran_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { mapel_ids?: number[] };
    const mapelIds = body.mapel_ids;
    if (!Array.isArray(mapelIds)) return badRequest('Field mapel_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Asatidz');

    await env.DB.prepare('DELETE FROM guru_mapel WHERE guru_id = ?').bind(id).run();
    for (const mid of mapelIds) {
      await env.DB.prepare('INSERT OR IGNORE INTO guru_mapel (guru_id, mata_pelajaran_id) VALUES (?, ?)').bind(id, mid).run();
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_mapel', ?, ?)")
      .bind(user.sub, `Update mapel guru id=${id} (${mapelIds.length} mapel)`, ip).run();
    return success({ guru_id: id, mapel_ids: mapelIds });
  }

  return badRequest('Method tidak didukung');
}

export async function handleGuruKelasAmpu(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID asatidz diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT kelas_id FROM guru_kelas WHERE guru_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { kelas_id: number }).kelas_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { kelas_ids?: number[] };
    const kelasIds = body.kelas_ids;
    if (!Array.isArray(kelasIds)) return badRequest('Field kelas_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Asatidz');

    await env.DB.prepare('DELETE FROM guru_kelas WHERE guru_id = ?').bind(id).run();
    for (const kid of kelasIds) {
      await env.DB.prepare('INSERT OR IGNORE INTO guru_kelas (guru_id, kelas_id) VALUES (?, ?)').bind(id, kid).run();
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_kelas', ?, ?)")
      .bind(user.sub, `Update kelas guru id=${id} (${kelasIds.length} kelas)`, ip).run();
    return success({ guru_id: id, kelas_ids: kelasIds });
  }

  return badRequest('Method tidak didukung');
}

// ═══════════════════════════════════════════════
// GURU MAPEL KELAS (Gabungan Spesifik)
// ═══════════════════════════════════════════════

/**
 * Sinkronisasi guru_mapel_kelas → guru_mapel + guru_kelas
 * Dipanggil setiap kali data guru_mapel_kelas berubah
 */
export async function syncGuruMapelKelas(env: Env, guruId: number): Promise<void> {
  // Sync guru_mapel: ambil distinct mapel_ids dari guru_mapel_kelas
  const mapelRows = await env.DB.prepare(
    'SELECT DISTINCT mata_pelajaran_id FROM guru_mapel_kelas WHERE guru_id = ?'
  ).bind(guruId).all<{ mata_pelajaran_id: number }>();

  await env.DB.prepare('DELETE FROM guru_mapel WHERE guru_id = ?').bind(guruId).run();
  for (const m of mapelRows.results) {
    await env.DB.prepare('INSERT OR IGNORE INTO guru_mapel (guru_id, mata_pelajaran_id) VALUES (?, ?)')
      .bind(guruId, m.mata_pelajaran_id).run();
  }

  // Sync guru_kelas: ambil distinct kelas_ids dari guru_mapel_kelas
  const kelasRows = await env.DB.prepare(
    'SELECT DISTINCT kelas_id FROM guru_mapel_kelas WHERE guru_id = ?'
  ).bind(guruId).all<{ kelas_id: number }>();

  await env.DB.prepare('DELETE FROM guru_kelas WHERE guru_id = ?').bind(guruId).run();
  for (const k of kelasRows.results) {
    await env.DB.prepare('INSERT OR IGNORE INTO guru_kelas (guru_id, kelas_id) VALUES (?, ?)')
      .bind(guruId, k.kelas_id).run();
  }
}

/**
 * GET /api/admin/guru-mapel-kelas/:guruId
 * POST /api/admin/guru-mapel-kelas/:guruId (bulk replace)
 */
export async function handleGuruMapelKelas(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 4) return badRequest('URL tidak valid');
  const guruId = parseInt(pathParts[3]);
  if (!guruId) return badRequest('guru_id diperlukan');

  // GET: Ambil semua kombinasi mapel+kelas untuk guru
  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT gmk.id, gmk.guru_id, gmk.mata_pelajaran_id, mp.nama as mapel_nama,
              gmk.kelas_id, k.nama as kelas_nama
       FROM guru_mapel_kelas gmk
       LEFT JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON gmk.kelas_id = k.id
       WHERE gmk.guru_id = ?
       ORDER BY mp.nama, k.nama`
    ).bind(guruId).all();

    return success(rows.results);
  }

  // POST: Bulk replace (delete all + insert baru)
  if (request.method === 'POST') {
    const body = await request.json() as { assignments?: { mata_pelajaran_id: number; kelas_id: number }[] };
    const assignments = body.assignments;
    if (!Array.isArray(assignments)) return badRequest('Field assignments harus array');

    // Cek apakah guru ada
    const existing = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(guruId).first();
    if (!existing) return notFound('Asatidz');

    // Hapus semua data lama
    await env.DB.prepare('DELETE FROM guru_mapel_kelas WHERE guru_id = ?').bind(guruId).run();

    // Insert data baru
    let inserted = 0;
    for (const a of assignments) {
      if (!a.mata_pelajaran_id || !a.kelas_id) continue;
      try {
        await env.DB.prepare(
          'INSERT OR IGNORE INTO guru_mapel_kelas (guru_id, mata_pelajaran_id, kelas_id) VALUES (?, ?, ?)'
        ).bind(guruId, a.mata_pelajaran_id, a.kelas_id).run();
        inserted++;
      } catch (e) {
        // Skip duplicate atau error lain
        continue;
      }
    }

    // Sinkronisasi ke guru_mapel + guru_kelas
    await syncGuruMapelKelas(env, guruId);

    // Log aktivitas
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_mapel_kelas', ?, ?)")
      .bind(user.sub, `Update mapel+kelas guru id=${guruId} (${inserted} kombinasi)`, ip).run();

    return success({ guru_id: guruId, total: inserted });
  }

  return badRequest('Method tidak didukung');
}

/**
 * GET /api/admin/guru-mapel-kelas/guru-by-mapel-kelas?mapel_id=X&kelas_id=Y
 * Ambil guru yang mengajar mapel X di kelas Y
 */
export async function handleGuruByMapelKelas(request: Request, env: Env, url: URL): Promise<Response> {
  const mapelId = url.searchParams.get('mata_pelajaran_id');
  const kelasId = url.searchParams.get('kelas_id');
  if (!mapelId || !kelasId) return badRequest('mata_pelajaran_id dan kelas_id diperlukan');

  const rows = await env.DB.prepare(
    `SELECT DISTINCT g.id, g.nama, g.nip
     FROM guru g
     INNER JOIN guru_mapel_kelas gmk ON g.id = gmk.guru_id
     WHERE gmk.mata_pelajaran_id = ? AND gmk.kelas_id = ? AND g.status_aktif = 1
     ORDER BY g.nip ASC`
  ).bind(parseInt(mapelId), parseInt(kelasId)).all();

  return success(rows.results);
}

/**
 * GET /api/admin/guru-mapel-kelas (list semua kombinasi, join guru+mapel+kelas)
 * POST /api/admin/guru-mapel-kelas (tambah 1 penugasan)
 */
export async function handleGuruMapelKelasAll(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // GET: list semua kombinasi dengan search + pagination
  if (request.method === 'GET') {
    try {
      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
      const search = (url.searchParams.get('search') || '').trim();
      const offset = (page - 1) * perPage;

      let where = '';
      const bindings: unknown[] = [];
      if (search) {
        where = 'WHERE (g.nama LIKE ? OR g.nip LIKE ? OR mp.nama LIKE ? OR k.nama LIKE ?)';
        bindings.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
      }

      const countResult = await env.DB.prepare(
        `SELECT COUNT(*) as total
         FROM guru_mapel_kelas gmk
         LEFT JOIN guru g ON gmk.guru_id = g.id
         LEFT JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
         LEFT JOIN kelas k ON gmk.kelas_id = k.id
         ${where}`
      ).bind(...bindings).first<{ total: number }>();

      const total = countResult?.total || 0;
      bindings.push(perPage, offset);
      const rows = await env.DB.prepare(
        `SELECT gmk.id, gmk.guru_id, g.nama as guru_nama, g.nip as guru_nip, g.jabatan as guru_jabatan,
                gmk.mata_pelajaran_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
                gmk.kelas_id, k.nama as kelas_nama
         FROM guru_mapel_kelas gmk
         LEFT JOIN guru g ON gmk.guru_id = g.id
         LEFT JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
         LEFT JOIN kelas k ON gmk.kelas_id = k.id
         ${where}
         ORDER BY g.nip ASC, mp.kode ASC, k.nama ASC
         LIMIT ? OFFSET ?`
      ).bind(...bindings).all();

      return success({
        items: rows.results,
        pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      return error(`Gagal memuat data guru mapel kelas: ${msg}`, 500);
    }
  }

  // POST: tambah 1 penugasan guru-mapel-kelas
  if (request.method === 'POST') {
    const body = await request.json() as { guru_id?: number; mata_pelajaran_id?: number; kelas_id?: number };
    const guruId = body.guru_id;
    const mapelId = body.mata_pelajaran_id;
    const kelasId = body.kelas_id;
    if (!guruId || !mapelId || !kelasId) return badRequest('guru_id, mata_pelajaran_id, dan kelas_id diperlukan');

    const guruExists = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(guruId).first();
    if (!guruExists) return notFound('Asatidz');
    const mapelExists = await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE id = ?').bind(mapelId).first();
    if (!mapelExists) return notFound('Mata Pelajaran');
    const kelasExists = await env.DB.prepare('SELECT id FROM kelas WHERE id = ?').bind(kelasId).first();
    if (!kelasExists) return notFound('Kelas');

    try {
      const result = await env.DB.prepare(
        'INSERT INTO guru_mapel_kelas (guru_id, mata_pelajaran_id, kelas_id) VALUES (?, ?, ?)'
      ).bind(guruId, mapelId, kelasId).run();

      await syncGuruMapelKelas(env, guruId);
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'guru_mapel_kelas', ?, ?)")
        .bind(user.sub, `Tambah penugasan guru=${guruId}, mapel=${mapelId}, kelas=${kelasId}`, ip).run();

      return success({ id: result.meta?.last_row_id });
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      if (msg.includes('UNIQUE')) return badRequest('Kombinasi guru-mapel-kelas tersebut sudah ada');
      return badRequest(msg);
    }
  }

  return badRequest('Method tidak didukung');
}

/**
 * PUT /api/admin/guru-mapel-kelas/:id (edit 1 baris penugasan)
 * DELETE /api/admin/guru-mapel-kelas/:id (hapus 1 baris penugasan)
 */
export async function handleGuruMapelKelasRow(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 4) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('id diperlukan');

  const existing = await env.DB.prepare(
    'SELECT guru_id, mata_pelajaran_id, kelas_id FROM guru_mapel_kelas WHERE id = ?'
  ).bind(id).first<{ guru_id: number; mata_pelajaran_id: number; kelas_id: number }>();
  if (!existing) return notFound('Penugasan mapel-kelas');

  if (request.method === 'PUT') {
    const body = await request.json() as { guru_id?: number; mata_pelajaran_id?: number; kelas_id?: number };
    const guruId = body.guru_id ?? existing.guru_id;
    const mapelId = body.mata_pelajaran_id ?? existing.mata_pelajaran_id;
    const kelasId = body.kelas_id ?? existing.kelas_id;
    if (!guruId || !mapelId || !kelasId) return badRequest('guru_id, mata_pelajaran_id, dan kelas_id diperlukan');

    const guruExists = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(guruId).first();
    if (!guruExists) return notFound('Asatidz');
    const mapelExists = await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE id = ?').bind(mapelId).first();
    if (!mapelExists) return notFound('Mata Pelajaran');
    const kelasExists = await env.DB.prepare('SELECT id FROM kelas WHERE id = ?').bind(kelasId).first();
    if (!kelasExists) return notFound('Kelas');

    try {
      await env.DB.prepare('UPDATE guru_mapel_kelas SET guru_id = ?, mata_pelajaran_id = ?, kelas_id = ? WHERE id = ?')
        .bind(guruId, mapelId, kelasId, id).run();
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      if (msg.includes('UNIQUE')) return badRequest('Kombinasi guru-mapel-kelas tersebut sudah ada');
      return badRequest(msg);
    }

    await syncGuruMapelKelas(env, existing.guru_id);
    if (existing.guru_id !== guruId) await syncGuruMapelKelas(env, guruId);
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_mapel_kelas', ?, ?)")
      .bind(user.sub, `Update penugasan id=${id} (guru=${guruId}, mapel=${mapelId}, kelas=${kelasId})`, ip).run();

    return success({ id });
  }

  if (request.method === 'DELETE') {
    await env.DB.prepare('DELETE FROM guru_mapel_kelas WHERE id = ?').bind(id).run();

    await syncGuruMapelKelas(env, existing.guru_id);
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'guru_mapel_kelas', ?, ?)")
      .bind(user.sub, `Hapus penugasan id=${id} (guru=${existing.guru_id}, mapel=${existing.mata_pelajaran_id}, kelas=${existing.kelas_id})`, ip).run();

    return success({ id });
  }

  return badRequest('Method tidak didukung');
}

export async function handleMapelKelas(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // /api/admin/mapel-kelas/:id/kelas
  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID mata pelajaran diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT kelas_id FROM mapel_kelas WHERE mata_pelajaran_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { kelas_id: number }).kelas_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { kelas_ids?: number[] };
    const kelasIds = body.kelas_ids;
    if (!Array.isArray(kelasIds)) return badRequest('Field kelas_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Mata Pelajaran');

    await env.DB.prepare('DELETE FROM mapel_kelas WHERE mata_pelajaran_id = ?').bind(id).run();

    for (const kid of kelasIds) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO mapel_kelas (mata_pelajaran_id, kelas_id) VALUES (?, ?)'
      ).bind(id, kid).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'mapel_kelas', ?, ?)"
    ).bind(user.sub, `Update kelas untuk mata pelajaran id=${id} (${kelasIds.length} kelas)`, ip).run();

    return success({ mata_pelajaran_id: id, kelas_ids: kelasIds });
  }

  return badRequest('Method tidak didukung');
}

export async function handleWaliKelasList(request: Request, env: Env, _user: UserPayload): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

  const url = new URL(request.url);
  const search = url.searchParams.get('search')?.trim() || '';

  let query = `
    SELECT g.id, g.nip, g.nama, g.jabatan,
           k.id AS kelas_id, k.nama AS kelas_nama,
           (SELECT COUNT(*) FROM siswa WHERE kelas_id = k.id AND status = 'aktif') AS jumlah_siswa
    FROM guru g
    LEFT JOIN kelas k ON k.wali_kelas_id = g.id
    LEFT JOIN tingkat t ON k.tingkat_id = t.id
    WHERE k.wali_kelas_id IS NOT NULL
       OR g.jabatan LIKE '%wali_kelas%'
  `;
  const bindings: unknown[] = [];

  if (search) {
    query += ` AND (g.nama LIKE ? OR g.nip LIKE ?)`;
    bindings.push(`%${search}%`, `%${search}%`);
  }

  query += ` ORDER BY
    CASE t.nama
      WHEN 'VII' THEN 7 WHEN 'VIII' THEN 8 WHEN 'IX' THEN 9
      WHEN 'X' THEN 10 WHEN 'XI' THEN 11 WHEN 'XII' THEN 12
      ELSE 99
    END,
    k.nama`;

  const rows = await env.DB.prepare(query).bind(...bindings).all();

  return success(rows.results);
}

export async function handleSiswaTemplate(env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  // Ambil tahun ajaran aktif untuk default value
  const taAktif = await env.DB.prepare('SELECT id, nama FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1').first<{ id: number; nama: string }>();
  const taDefault = taAktif?.nama || '';

  const wsData = [
    ['NIS', 'NISN', 'Nama Santri', 'Jenis Kelamin', 'Kelas', 'Status', 'Tahun Ajaran', 'Nama Ayah', 'Nama Ibu', 'Pekerjaan Ayah', 'Pekerjaan Ibu', 'WhatsApp'],
    ['', '', '', 'L/P', '', 'Aktif / Lulus / Pindah / Keluar', taDefault, '', '', '', '', ''],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 15 }, { wch: 15 }, { wch: 25 }, { wch: 15 }, { wch: 20 }, { wch: 25 }, { wch: 20 }, { wch: 25 }, { wch: 25 }, { wch: 20 }, { wch: 20 }, { wch: 20 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Santri');

  const kelas = await env.DB.prepare('SELECT nama FROM kelas ORDER BY nama').all<{ nama: string }>();
  const taList = await env.DB.prepare('SELECT nama FROM tahun_ajaran ORDER BY nama DESC').all<{ nama: string }>();
  const refRows: (string | undefined)[][] = [
    ['Jenis Kelamin', 'Status', 'Tahun Ajaran'],
    ['L', 'Aktif', ''],
    ['P', 'Lulus', ''],
    ['', 'Pindah', ''],
    ['', 'Keluar', ''],
    ['', '', ''],
    ['Daftar Kelas', '', ''],
  ];
  for (const k of kelas.results) refRows.push([k.nama, '', '']);
  refRows.push(['', '', '']);
  refRows.push(['Daftar Tahun Ajaran', '', '']);
  for (const t of taList.results) refRows.push(['', '', t.nama]);
  const wsRef = XLSX.utils.aoa_to_sheet(refRows);
  wsRef['!cols'] = [{ wch: 22 }, { wch: 22 }, { wch: 22 }];
  XLSX.utils.book_append_sheet(wb, wsRef, 'Referensi');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_siswa.xlsx' });
}

export async function handleSiswaPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Santri'];
  if (!sheet) return badRequest('Sheet "Data Santri" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Santri');

  // Load referensi dari database
  const kelasMap = new Map<string, number>();
  const kelasRows = await env.DB.prepare('SELECT id, nama FROM kelas').all<{ id: number; nama: string }>();
  for (const k of kelasRows.results) kelasMap.set(k.nama.toLowerCase().trim(), k.id);

  const taMap = new Map<string, number>();
  const taRows = await env.DB.prepare('SELECT id, nama FROM tahun_ajaran').all<{ id: number; nama: string }>();
  for (const t of taRows.results) taMap.set(t.nama.toLowerCase().trim(), t.id);

  // Tahun ajaran aktif sebagai default
  const taAktif = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1').first<{ id: number }>();
  const defaultTaId = taAktif?.id ?? null;

  // Load existing NIS dan NISN dari database untuk cross-check
  const existingNisSet = new Set<string>();
  const existingNisRows = await env.DB.prepare('SELECT nis FROM siswa').all<{ nis: string }>();
  for (const r of existingNisRows.results) existingNisSet.add((r.nis ?? '').toLowerCase().trim());

  const existingNisnSet = new Set<string>();
  const existingNisnRows = await env.DB.prepare('SELECT nisn FROM siswa WHERE nisn IS NOT NULL AND nisn != ""').all<{ nisn: string }>();
  for (const r of existingNisnRows.results) existingNisnSet.add((r.nisn ?? '').toLowerCase().trim());

  const preview: Record<string, unknown>[] = [];
  const seenNis = new Set<string>();
  const seenNisn = new Set<string>();

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nis = (r['NIS'] ?? '').toString().trim();
    const nisn = (r['NISN'] ?? '').toString().trim();
    const nama = (r['Nama Santri'] ?? '').toString().trim();
    const jk = (r['Jenis Kelamin'] ?? '').toString().trim().toUpperCase();
    const kelasNama = (r['Kelas'] ?? '').toString().trim();
    const status = (r['Status'] ?? '').toString().trim();
    const taNama = (r['Tahun Ajaran'] ?? '').toString().trim();
    const namaAyah = (r['Nama Ayah'] ?? '').toString().trim();
    const namaIbu = (r['Nama Ibu'] ?? '').toString().trim();
    const pekerjaanAyah = (r['Pekerjaan Ayah'] ?? '').toString().trim();
    const pekerjaanIbu = (r['Pekerjaan Ibu'] ?? '').toString().trim();
    const whatsapp = (r['WhatsApp'] ?? '').toString().trim();

    if (!nis) errors.push('NIS harus diisi');
    else if (seenNis.has(nis)) errors.push(`NIS "${nis}" duplikat dalam file`);
    else seenNis.add(nis);

    // NISN duplikat check (dalam file dan di database)
    if (nisn) {
      if (seenNisn.has(nisn.toLowerCase())) errors.push(`NISN "${nisn}" duplikat dalam file`);
      else seenNisn.add(nisn.toLowerCase());
      if (existingNisnSet.has(nisn.toLowerCase())) errors.push(`NISN "${nisn}" sudah ada di database`);
    }

    // NIS sudah ada di database → akan di-update (upsert), bukan error
    const isUpdate = nis ? existingNisSet.has(nis.toLowerCase()) : false;

    if (!nama) errors.push('Nama Santri harus diisi');
    if (jk !== 'L' && jk !== 'P') errors.push('Jenis Kelamin harus L atau P');

    const kelasId = kelasNama ? kelasMap.get(kelasNama.toLowerCase()) : null;
    if (kelasNama && kelasId == null) errors.push(`Kelas "${kelasNama}" tidak ditemukan`);

    if (!status) errors.push('Status harus diisi');
    else if (!['aktif', 'lulus', 'pindah', 'keluar'].includes(status.toLowerCase())) errors.push('Status harus Aktif, Lulus, Pindah, atau Keluar');

    // Tahun ajaran: gunakan dari file atau default ke tahun ajaran aktif
    let taId = defaultTaId;
    if (taNama) {
      const found = taMap.get(taNama.toLowerCase());
      if (found) {
        taId = found;
      } else {
        errors.push(`Tahun Ajaran "${taNama}" tidak ditemukan`);
      }
    }
    if (taId == null) {
      errors.push('Tahun Ajaran aktif tidak tersedia. Isi kolom Tahun Ajaran atau set tahun ajaran aktif di menu Tahun Ajaran');
    }

    preview.push({
      row: i + 2,
      nis,
      nisn,
      nama,
      jenis_kelamin: jk,
      kelas_nama: kelasNama,
      kelas_id: kelasId,
      tahun_ajaran_id: taId,
      status: status.toLowerCase(),
      nama_ayah: namaAyah,
      nama_ibu: namaIbu,
      pekerjaan_ayah: pekerjaanAyah,
      pekerjaan_ibu: pekerjaanIbu,
      whatsapp,
      is_update: isUpdate,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleSiswaBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // Tahun ajaran aktif sebagai default
  const taAktif = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1').first<{ id: number }>();
  const defaultTaId = taAktif?.id ?? null;

  const cols = ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'tahun_ajaran_id', 'status', 'nama_ayah', 'nama_ibu', 'pekerjaan_ayah', 'pekerjaan_ibu', 'whatsapp'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO siswa (${cols.join(', ')}) VALUES (${placeholders})
    ON CONFLICT(nis) DO UPDATE SET
      nisn = excluded.nisn,
      nama = excluded.nama,
      jenis_kelamin = excluded.jenis_kelamin,
      kelas_id = excluded.kelas_id,
      tahun_ajaran_id = excluded.tahun_ajaran_id,
      status = excluded.status,
      nama_ayah = excluded.nama_ayah,
      nama_ibu = excluded.nama_ibu,
      pekerjaan_ayah = excluded.pekerjaan_ayah,
      pekerjaan_ibu = excluded.pekerjaan_ibu,
      whatsapp = excluded.whatsapp`;

  let inserted = 0;
  let updated = 0;
  let usersCreated = 0;
  const errors: { row: number; nis: string; error: string }[] = [];

  // Validasi dan persiapkan data terlebih dahulu
  const validRows: { index: number; row: Record<string, unknown>; nis: string; nisn: string; taId: number }[] = [];
  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    const nis = (row['nis'] ?? '').toString().trim();
    if (!nis) {
      errors.push({ row: i + 2, nis: '', error: 'NIS kosong' });
      continue;
    }
    const nisn = (row['nisn'] ?? '').toString().trim();
    const taId = (row['tahun_ajaran_id'] as number) || defaultTaId;
    if (taId == null) {
      errors.push({ row: i + 2, nis, error: 'Tahun Ajaran aktif tidak tersedia' });
      continue;
    }
    validRows.push({ index: i, row, nis, nisn, taId });
  }

  // Batch check existing NIS (sekali query untuk semua NIS)
  const nisList = validRows.map(r => r.nis);
  const existingNisSet = new Set<string>();
  if (nisList.length > 0) {
    const placeholdersCheck = nisList.map(() => '?').join(',');
    const existingRows = await env.DB.prepare(
      `SELECT nis FROM siswa WHERE nis IN (${placeholdersCheck})`
    ).bind(...nisList).all<{ nis: string }>();
    for (const r of existingRows.results) existingNisSet.add(r.nis);
  }

  // Proses insert/update dalam batch
  const BATCH_SIZE = 50;
  const newSiswaIds: { siswaId: number; nis: string }[] = [];
  for (let b = 0; b < validRows.length; b += BATCH_SIZE) {
    const batch = validRows.slice(b, b + BATCH_SIZE);
    const statements: ReturnType<typeof env.DB.prepare>[] = [];

    for (const { row, nis, nisn, taId } of batch) {
      statements.push(
        env.DB.prepare(stmt).bind(
          nis, nisn, row['nama'] ?? '', row['jenis_kelamin'] ?? '',
          row['kelas_id'] ?? null, taId, row['status'] ?? '',
          row['nama_ayah'] ?? '', row['nama_ibu'] ?? '',
          row['pekerjaan_ayah'] ?? '', row['pekerjaan_ibu'] ?? '', row['whatsapp'] ?? ''
        )
      );
    }

    try {
      const results = await env.DB.batch(statements);
      for (let j = 0; j < batch.length; j++) {
        const { nis } = batch[j];
        const result = results[j];
        if (existingNisSet.has(nis)) {
          updated++;
        } else {
          inserted++;
          const siswaId = result?.meta?.last_row_id;
          if (siswaId && nis) {
            newSiswaIds.push({ siswaId: siswaId as number, nis });
          }
        }
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      for (const { index, nis } of batch) {
        errors.push({ row: index + 2, nis, error: msg });
      }
    }
  }

  // Batch user creation: check existing + insert/update in bulk
  if (newSiswaIds.length > 0) {
    // Batch check existing users
    const siswaIds = newSiswaIds.map(s => s.siswaId);
    const existingUserMap = new Map<number, number>(); // siswaId -> userId
    const checkPlaceholders = siswaIds.map(() => '?').join(',');
    const existingUsers = await env.DB.prepare(
      `SELECT id, siswa_id FROM users WHERE siswa_id IN (${checkPlaceholders})`
    ).bind(...siswaIds).all<{ id: number; siswa_id: number }>();
    for (const u of existingUsers.results) existingUserMap.set(u.siswa_id, u.id);

    // Hash password once (all siswa use NIS as default password)
    const passwordHash = await bcrypt.hash('ppi123', 10);

    // Batch create/update users
    const userStatements: ReturnType<typeof env.DB.prepare>[] = [];
    for (const { siswaId, nis } of newSiswaIds) {
      if (existingUserMap.has(siswaId)) {
        userStatements.push(
          env.DB.prepare('UPDATE users SET username = ?, password_hash = ? WHERE siswa_id = ?')
            .bind(nis, passwordHash, siswaId)
        );
      } else {
        userStatements.push(
          env.DB.prepare("INSERT INTO users (username, password_hash, role, siswa_id, is_active) VALUES (?, ?, 'siswa', ?, 1)")
            .bind(nis, passwordHash, siswaId)
        );
      }
    }

    // Execute user batch in chunks of 50
    for (let u = 0; u < userStatements.length; u += BATCH_SIZE) {
      const chunk = userStatements.slice(u, u + BATCH_SIZE);
      try {
        await env.DB.batch(chunk);
        usersCreated += chunk.length;
      } catch (_) {}
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'siswa', ?, ?)"
  ).bind(user.sub, `Import ${inserted} siswa baru, ${updated} di-update, ${usersCreated} user dibuat dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, updated, users_created: usersCreated, errors });
}

// ── Mata Pelajaran Bulk ──

export async function handleMapelTemplate(_request: Request, env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  const wsData = [
    ['Nama', 'Kode'],
    ['', ''],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 30 }, { wch: 20 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Mapel');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_mata_pelajaran.xlsx' });
}

export async function handleMapelPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Mapel'];
  if (!sheet) return badRequest('Sheet "Data Mapel" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Mapel');

  const preview: Record<string, unknown>[] = [];
  const seenNama = new Set<string>();
  const seenKode = new Set<string>();

  // Load existing data dari database
  const existingMap = new Map<string, number>();
  const existingRows = await env.DB.prepare('SELECT id, nama FROM mata_pelajaran').all<{ id: number; nama: string }>();
  for (const r of existingRows.results) existingMap.set(r.nama.toLowerCase().trim(), r.id);

  const existingKodeMap = new Map<string, number>();
  const existingKodeRows = await env.DB.prepare('SELECT id, kode FROM mata_pelajaran WHERE kode IS NOT NULL AND kode != ""').all<{ id: number; kode: string }>();
  for (const r of existingKodeRows.results) existingKodeMap.set(r.kode.toLowerCase().trim(), r.id);

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nama = (r['Nama'] ?? '').toString().trim();
    const kode = (r['Kode'] ?? '').toString().trim();

    if (!nama) errors.push('Nama harus diisi');
    else if (seenNama.has(nama.toLowerCase())) errors.push(`Nama "${nama}" duplikat dalam file`);
    else seenNama.add(nama.toLowerCase());

    if (kode && seenKode.has(kode.toLowerCase())) errors.push(`Kode "${kode}" duplikat dalam file`);
    else if (kode) seenKode.add(kode.toLowerCase());

    // Cek apakah akan update (upsert berdasarkan kode)
    const isUpdate = kode ? existingKodeMap.has(kode.toLowerCase()) : existingMap.has(nama.toLowerCase());

    // Nama sudah ada tanpa kode → error (tidak bisa upsert tanpa kode)
    if (!kode && existingMap.has(nama.toLowerCase())) {
      errors.push(`Nama "${nama}" sudah ada di database tanpa kode. Isi kode untuk update.`);
    }

    preview.push({
      row: i + 2,
      nama,
      kode,
      is_update: isUpdate,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleMapelBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const cols = ['nama', 'kode'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO mata_pelajaran (${cols.join(', ')}) VALUES (${placeholders})
    ON CONFLICT(kode) DO UPDATE SET
      nama = excluded.nama`;

  let inserted = 0;
  let updated = 0;
  const errors: { row: number; nama: string; error: string }[] = [];

  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    try {
      // Cek apakah kode sudah ada sebelum upsert
      const kode = (row['kode'] ?? '').toString().trim();
      const existing = kode
        ? await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE kode = ?').bind(kode).first()
        : await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE nama = ?').bind(row['nama'] ?? '').first();

      await env.DB.prepare(stmt).bind(
        row['nama'] ?? '',
        row['kode'] ?? ''
      ).run();

      if (existing) {
        updated++;
      } else {
        inserted++;
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      errors.push({ row: i + 2, nama: (row['nama'] ?? '').toString(), error: msg });
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'mata_pelajaran', ?, ?)"
  ).bind(user.sub, `Import ${inserted} mata pelajaran baru, ${updated} di-update dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, updated, errors });
}

// ── Guru Bulk ──

export async function handleGuruTemplate(_request: Request, env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  const wsData = [
    ['NIP', 'Nama', 'Jenis Kelamin', 'Jabatan', 'Status Aktif', 'Username', 'Password'],
    ['', '', 'L/P', 'guru_mapel / wali_kelas / ...', 'Aktif / Tidak Aktif', '', ''],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 20 }, { wch: 25 }, { wch: 18 }, { wch: 30 }, { wch: 20 }, { wch: 20 }, { wch: 20 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Asatidz');

  const refRows: (string | undefined)[][] = [
    ['Jenis Kelamin', 'Jabatan', 'Status Aktif', ''],
    ['L', 'guru_mapel', 'Aktif', ''],
    ['P', 'wali_kelas', 'Tidak Aktif', ''],
    ['', 'kepala_sekolah', '', ''],
    ['', 'wakil_kurikulum', '', ''],
    ['', 'guru_bk', '', ''],
  ];
  const wsRef = XLSX.utils.aoa_to_sheet(refRows);
  wsRef['!cols'] = [{ wch: 22 }, { wch: 22 }, { wch: 22 }, { wch: 10 }];
  XLSX.utils.book_append_sheet(wb, wsRef, 'Referensi');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_guru.xlsx' });
}

export async function handleGuruPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Asatidz'];
  if (!sheet) return badRequest('Sheet "Data Asatidz" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Asatidz');

  const validJabatan = new Set(['guru_mapel', 'wali_kelas', 'kepala_sekolah', 'wakil_kurikulum', 'guru_bk']);
  const preview: Record<string, unknown>[] = [];
  const seenNip = new Set<string>();
  const seenUsername = new Set<string>();

  const existingNips = await env.DB.prepare('SELECT nip FROM guru').all<{ nip: string }>();
  const existingNipSet = new Set(existingNips.results.map(r => (r.nip ?? '').toLowerCase().trim()));

  const existingUsers = await env.DB.prepare('SELECT username FROM users').all<{ username: string }>();
  const existingUsernameSet = new Set(existingUsers.results.map(r => (r.username ?? '').toLowerCase().trim()));

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nip = (r['NIP'] ?? '').toString().trim();
    const nama = (r['Nama'] ?? '').toString().trim();
    const jk = (r['Jenis Kelamin'] ?? '').toString().trim().toUpperCase();
    const jabatan = (r['Jabatan'] ?? '').toString().trim().toLowerCase();
    const status = (r['Status Aktif'] ?? '').toString().trim();
    const statusNormalized = status.toLowerCase();
    const username = (r['Username'] ?? '').toString().trim();
    const password = (r['Password'] ?? '').toString().trim();

    if (!nip) errors.push('NIP harus diisi');
    else if (seenNip.has(nip.toLowerCase())) errors.push(`NIP "${nip}" duplikat dalam file`);
    else seenNip.add(nip.toLowerCase());

    // NIP sudah ada di database → akan di-update (upsert), bukan error
    const isUpdate = nip ? existingNipSet.has(nip.toLowerCase()) : false;

    if (!nama) errors.push('Nama harus diisi');
    if (jk !== 'L' && jk !== 'P') errors.push('Jenis Kelamin harus L atau P');
    if (jabatan && !validJabatan.has(jabatan)) errors.push(`Jabatan "${jabatan}" tidak dikenal. Pilihan: guru_mapel, wali_kelas, kepala_sekolah, wakil_kurikulum, guru_bk`);
    if (status && !['aktif', 'tidak aktif'].includes(statusNormalized)) errors.push('Status Aktif harus "Aktif" atau "Tidak Aktif"');
    if (!username) errors.push('Username harus diisi');
    else if (seenUsername.has(username.toLowerCase())) errors.push(`Username "${username}" duplikat dalam file`);
    else seenUsername.add(username.toLowerCase());
    if (!password) errors.push('Password harus diisi');

    preview.push({
      row: i + 2,
      nip,
      nama,
      jenis_kelamin: jk,
      jabatan,
      status_aktif: statusNormalized === 'aktif' ? 1 : 0,
      username,
      password,
      is_update: isUpdate,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleGuruBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const cols = ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO guru (${cols.join(', ')}) VALUES (${placeholders})
    ON CONFLICT(nip) DO UPDATE SET
      nama = excluded.nama,
      jenis_kelamin = excluded.jenis_kelamin,
      jabatan = excluded.jabatan,
      status_aktif = excluded.status_aktif`;

  let inserted = 0;
  let updated = 0;
  const errors: { row: number; nip: string; error: string }[] = [];

  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    try {
      // Cek apakah NIP sudah ada sebelum upsert
      const existing = await env.DB.prepare('SELECT id FROM guru WHERE nip = ?').bind(row['nip'] ?? '').first();

      const result = await env.DB.prepare(stmt).bind(
        row['nip'] ?? '',
        row['nama'] ?? '',
        row['jenis_kelamin'] ?? '',
        row['jabatan'] ?? '',
        row['status_aktif'] ?? 1
      ).run();

      // Get guru_id untuk upsert user
      let guruId = result.meta?.last_row_id as number;
      if (!guruId && existing) {
        guruId = (existing as { id: number }).id;
      }

      if (guruId && row['username'] && row['password']) {
        await upsertUserForGuru(
          env, guruId,
          row['username'] as string,
          row['password'] as string,
          (row['jabatan'] as string) || '',
          user.sub, ip
        );
      }

      if (existing) {
        updated++;
      } else {
        inserted++;
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      errors.push({ row: i + 2, nip: (row['nip'] ?? '').toString(), error: msg });
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'guru', ?, ?)"
  ).bind(user.sub, `Import ${inserted} guru baru, ${updated} di-update dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, updated, errors });
}

export async function handleGuruBKList(request: Request, env: Env, _user: UserPayload): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

  const rows = await env.DB.prepare(`
    SELECT g.id, g.nip, g.nama, g.jabatan
    FROM guru g
    WHERE g.jabatan LIKE '%guru_bk%'
    ORDER BY g.nip ASC
  `).all();

  return success(rows.results);
}

// ── Wali Kelas Assignment ──

export async function handleWaliKelasAssign(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const guruId = parseInt(pathParts[3]);
  if (!guruId) return badRequest('guru_id diperlukan');

  if (request.method === 'GET') {
    const kelas = await env.DB.prepare('SELECT id, nama FROM kelas WHERE wali_kelas_id = ?').bind(guruId).first<{ id: number; nama: string }>();
    return success({ kelas_id: kelas?.id ?? null, kelas_nama: kelas?.nama ?? null });
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { kelas_id: number | null };
    const newKelasId = body.kelas_id;

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

    // Clear previous wali_kelas assignment for this guru
    await env.DB.prepare('UPDATE kelas SET wali_kelas_id = NULL WHERE wali_kelas_id = ?').bind(guruId).run();

    // Assign new class if provided
    if (newKelasId) {
      // Also clear any existing wali_kelas for that class
      await env.DB.prepare('UPDATE kelas SET wali_kelas_id = NULL WHERE wali_kelas_id IS NOT NULL AND id = ?').bind(newKelasId).run();
      await env.DB.prepare('UPDATE kelas SET wali_kelas_id = ? WHERE id = ?').bind(guruId, newKelasId).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'wali_kelas', ?, ?)"
    ).bind(user.sub, `Update wali kelas guru id=${guruId} → kelas id=${newKelasId ?? 'null'}`, ip).run();

    return success({ message: 'Wali kelas berhasil diupdate' });
  }

  return badRequest('Method tidak didukung');
}
