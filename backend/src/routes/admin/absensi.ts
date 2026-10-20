import { Env, UserPayload } from '../../types';
import { success, badRequest, notFound } from '../../utils/response';
import {
  WaktuAbsensiGuru,
  WAKTU_GURU_FIELD_KEYS,
  getWaktuAbsensiGuru,
  normalizeJam,
  validateWaktuAbsensi,
} from '../../utils/absensi_waktu';

function buildStatusMap(results: { status: string; count: number }[]): Record<string, number> {
  const map: Record<string, number> = {};
  for (const r of results) map[r.status] = r.count;
  return map;
}

export async function handleAdminAbsensi(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/admin/absensi', '');

  // GET /api/admin/absensi/guru - monitoring absensi guru
  if ((subPath === '' || subPath === '/guru') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
    const offset = (page - 1) * perPage;
    const tanggal = url.searchParams.get('tanggal') || '';
    const status = url.searchParams.get('status') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (tanggal) { where += ' AND a.tanggal = ?'; bindings.push(tanggal); }
    if (status) { where += ' AND a.status = ?'; bindings.push(status); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM absensi_guru a ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT a.*, g.nama as guru_nama, g.nip as guru_nip
       FROM absensi_guru a LEFT JOIN guru g ON a.guru_id = g.id
       ${where} ORDER BY g.nip ASC, a.tanggal DESC LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // PUT /api/admin/absensi/guru/:id - koreksi absensi guru oleh admin
  const guruEditMatch = subPath.match(/^\/guru\/(\d+)$/);
  if (guruEditMatch && request.method === 'PUT') {
    const id = parseInt(guruEditMatch[1]);
    const existing = await env.DB.prepare('SELECT id, tanggal FROM absensi_guru WHERE id = ?').bind(id).first<{ id: number; tanggal: string }>();
    if (!existing) return notFound('Absensi Guru');

    const body = await request.json().catch(() => null) as Record<string, unknown> | null;
    if (!body) return badRequest('Body JSON tidak valid');

    const timeRe = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;
    const normalize = (t: string | null) => (t && t.length === 5) ? `${t}:00` : t;

    const jamMasuk = body.jam_masuk != null ? String(body.jam_masuk).trim() : null;
    const jamKeluar = body.jam_keluar != null ? String(body.jam_keluar).trim() : null;
    const status = body.status != null ? String(body.status).trim() : null;
    const keterangan = body.keterangan != null ? String(body.keterangan).trim() : null;

    if (jamMasuk !== null && (jamMasuk === '' || !timeRe.test(jamMasuk))) {
      return badRequest('jam_masuk harus format HH:MM atau HH:MM:SS');
    }
    if (jamKeluar !== null && (jamKeluar === '' || !timeRe.test(jamKeluar))) {
      return badRequest('jam_keluar harus format HH:MM atau HH:MM:SS');
    }
    if (status !== null && !['hadir', 'izin', 'sakit', 'alpa'].includes(status)) {
      return badRequest('status harus hadir, izin, sakit, atau alpa');
    }

    await env.DB.prepare(
      `UPDATE absensi_guru SET
         jam_masuk = COALESCE(?, jam_masuk),
         jam_keluar = COALESCE(?, jam_keluar),
         status = COALESCE(?, status),
         keterangan = COALESCE(?, keterangan)
       WHERE id = ?`
    ).bind(normalize(jamMasuk), normalize(jamKeluar), status, keterangan, id).run();

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'absensi', ?, ?)"
    ).bind(user.sub, `Koreksi absensi guru id=${id} (${existing.tanggal})`, ip).run();

    return success({ id, updated: true });
  }

  // GET /api/admin/absensi/siswa - monitoring absensi siswa
  if (subPath === '/siswa' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const tanggal = url.searchParams.get('tanggal') || '';
    const statusFilter = url.searchParams.get('status') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (tanggal) { where += ' AND a.tanggal = ?'; bindings.push(tanggal); }
    if (statusFilter) { where += ' AND a.status = ?'; bindings.push(statusFilter); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM absensi_siswa a ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT a.*, s.nama as siswa_nama, s.nis as siswa_nis, k.nama as kelas_nama, mp.nama as mapel_nama
       FROM absensi_siswa a
       LEFT JOIN siswa s ON a.siswa_id = s.id
       LEFT JOIN kelas k ON a.kelas_id = k.id
       LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
       ${where} ORDER BY s.nis ASC, a.tanggal DESC LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET /api/admin/absensi/rekap - rekap absensi
  if (subPath === '/rekap' && request.method === 'GET') {
    const tanggalMulai = url.searchParams.get('tanggal_mulai') || '';
    const tanggalSelesai = url.searchParams.get('tanggal_selesai') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    let whereSiswa = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { whereSiswa += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (tanggalMulai) { whereSiswa += ' AND a.tanggal >= ?'; bindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereSiswa += ' AND a.tanggal <= ?'; bindings.push(tanggalSelesai); }

    const rekapSiswa = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_siswa a ${whereSiswa} GROUP BY a.status`
    ).bind(...bindings).all<{ status: string; count: number }>();

    let whereGuru = 'WHERE 1=1';
    const guruBindings: unknown[] = [];
    if (tanggalMulai) { whereGuru += ' AND a.tanggal >= ?'; guruBindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereGuru += ' AND a.tanggal <= ?'; guruBindings.push(tanggalSelesai); }

    const rekapGuru = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_guru a ${whereGuru} GROUP BY a.status`
    ).bind(...guruBindings).all<{ status: string; count: number }>();

    const rekapSiswaMap: Record<string, number> = {};
    for (const r of rekapSiswa.results) rekapSiswaMap[r.status] = r.count;

    const rekapGuruMap: Record<string, number> = {};
    for (const r of rekapGuru.results) rekapGuruMap[r.status] = r.count;

    return success({
      siswa: rekapSiswaMap,
      guru: rekapGuruMap,
      total_siswa: rekapSiswa.results.reduce((sum, r) => sum + r.count, 0),
      total_guru: rekapGuru.results.reduce((sum, r) => sum + r.count, 0),
    });
  }

  // GET /api/admin/absensi/analisis - analisis absensi
  if (subPath === '/analisis' && request.method === 'GET') {
    const tanggalMulai = url.searchParams.get('tanggal_mulai') || '';
    const tanggalSelesai = url.searchParams.get('tanggal_selesai') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    let whereSiswa = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { whereSiswa += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (tanggalMulai) { whereSiswa += ' AND a.tanggal >= ?'; bindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereSiswa += ' AND a.tanggal <= ?'; bindings.push(tanggalSelesai); }

    // Siswa per status
    const siswaStatus = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_siswa a ${whereSiswa} GROUP BY a.status`
    ).bind(...bindings).all<{ status: string; count: number }>();

    // Siswa per kelas
    let whereKelas = 'WHERE 1=1';
    const kelasBindings: unknown[] = [];
    if (tanggalMulai) { whereKelas += ' AND a.tanggal >= ?'; kelasBindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereKelas += ' AND a.tanggal <= ?'; kelasBindings.push(tanggalSelesai); }
    if (kelasId) { whereKelas += ' AND a.kelas_id = ?'; kelasBindings.push(parseInt(kelasId)); }

    const siswaPerKelas = await env.DB.prepare(
      `SELECT k.nama as kelas_nama, a.status, COUNT(*) as count
       FROM absensi_siswa a LEFT JOIN kelas k ON a.kelas_id = k.id
       ${whereKelas} GROUP BY a.kelas_id, a.status ORDER BY k.nama, a.status`
    ).bind(...kelasBindings).all<{ kelas_nama: string; status: string; count: number }>();

    // Siswa per bulan
    const perBulan = await env.DB.prepare(
      `SELECT substr(a.tanggal, 1, 7) as bulan,
              SUM(CASE WHEN a.status = 'hadir' THEN 1 ELSE 0 END) as hadir,
              SUM(CASE WHEN a.status = 'izin' THEN 1 ELSE 0 END) as izin,
              SUM(CASE WHEN a.status = 'sakit' THEN 1 ELSE 0 END) as sakit,
              SUM(CASE WHEN a.status = 'alpa' THEN 1 ELSE 0 END) as alpa,
              COUNT(*) as total
       FROM absensi_siswa a ${whereSiswa}
       GROUP BY substr(a.tanggal, 1, 7) ORDER BY bulan`
    ).bind(...bindings).all();

    // Guru per status
    let whereGuru = 'WHERE 1=1';
    const guruBindings: unknown[] = [];
    if (tanggalMulai) { whereGuru += ' AND a.tanggal >= ?'; guruBindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereGuru += ' AND a.tanggal <= ?'; guruBindings.push(tanggalSelesai); }

    const guruStatus = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_guru a ${whereGuru} GROUP BY a.status`
    ).bind(...guruBindings).all<{ status: string; count: number }>();

    // Overview
    const [siswaTotal, guruTotal] = await Promise.all([
      env.DB.prepare(`SELECT COUNT(*) as total FROM absensi_siswa a ${whereSiswa}`).bind(...bindings).first<{ total: number }>(),
      env.DB.prepare(`SELECT COUNT(*) as total FROM absensi_guru a ${whereGuru}`).bind(...guruBindings).first<{ total: number }>(),
    ]);

    return success({
      overview: {
        total_siswa_entry: siswaTotal?.total || 0,
        total_guru_entry: guruTotal?.total || 0,
      },
      siswa_per_status: buildStatusMap(siswaStatus.results),
      guru_per_status: buildStatusMap(guruStatus.results),
      siswa_per_kelas: siswaPerKelas.results,
      per_bulan: perBulan.results,
    });
  }

  // GET /api/admin/absensi/audit - audit trail absensi
  if (subPath === '/audit' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      "SELECT COUNT(*) as total FROM log_aktivitas WHERE modul IN ('absensi', 'absensi_guru')"
    ).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT la.*, u.username
       FROM log_aktivitas la
       LEFT JOIN users u ON la.user_id = u.id
       WHERE la.modul IN ('absensi', 'absensi_guru')
       ORDER BY la.created_at DESC LIMIT ? OFFSET ?`
    ).bind(perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET/PUT /api/admin/absensi/pengaturan-waktu - pengaturan jam masuk & keluar absensi guru
  if (subPath === '/pengaturan-waktu' && request.method === 'GET') {
    const waktu = await getWaktuAbsensiGuru(env);
    return success(waktu);
  }

  if (subPath === '/pengaturan-waktu' && request.method === 'PUT') {
    const body = await request.json().catch(() => null) as Record<string, unknown> | null;
    if (!body) return badRequest('Body JSON tidak valid');

    const waktu: WaktuAbsensiGuru = {
      jam_masuk_mulai: normalizeJam(body.jam_masuk_mulai as string),
      jam_masuk_selesai: normalizeJam(body.jam_masuk_selesai as string),
      jam_keluar_mulai: normalizeJam(body.jam_keluar_mulai as string),
      jam_keluar_selesai: normalizeJam(body.jam_keluar_selesai as string),
    };

    const validationError = validateWaktuAbsensi(waktu);
    if (validationError) return badRequest(validationError);

    for (const field of Object.keys(WAKTU_GURU_FIELD_KEYS) as (keyof WaktuAbsensiGuru)[]) {
      await env.DB.prepare(
        "INSERT INTO pengaturan (key, value, updated_at) VALUES (?, ?, datetime('now')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at"
      ).bind(WAKTU_GURU_FIELD_KEYS[field], waktu[field]).run();
    }

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'absensi', ?, ?)"
    ).bind(
      user.sub,
      `Update jam absensi guru: masuk ${waktu.jam_masuk_mulai.slice(0, 5)}-${waktu.jam_masuk_selesai.slice(0, 5)}, keluar ${waktu.jam_keluar_mulai.slice(0, 5)}-${waktu.jam_keluar_selesai.slice(0, 5)}`,
      ip
    ).run();

    return success({ message: 'Pengaturan waktu absensi tersimpan', ...waktu });
  }

  return badRequest('Endpoint tidak dikenal');
}
