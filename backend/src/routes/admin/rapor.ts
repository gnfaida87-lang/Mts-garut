import { Env, UserPayload } from '../../types';
import { success, notFound, badRequest } from '../../utils/response';

export async function handleAdminRapor(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/admin/rapor', '');

  // GET /api/admin/rapor - monitoring rapor
  if ((subPath === '' || subPath === '/') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const semesterId = url.searchParams.get('semester_id') || '';
    const statusKirim = url.searchParams.get('status_kirim') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND nr.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (semesterId) { where += ' AND nr.semester_id = ?'; bindings.push(parseInt(semesterId)); }
    if (statusKirim) { where += ' AND nr.status_kirim = ?'; bindings.push(statusKirim); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM nilai_rapor nr ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT nr.*, s.nama as siswa_nama, s.nis as siswa_nis, mp.nama as mapel_nama,
              k.nama as kelas_nama, sem.nama as semester_nama, g.nama as wali_kelas_nama
       FROM nilai_rapor nr
       LEFT JOIN siswa s ON nr.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON nr.kelas_id = k.id
       LEFT JOIN semester sem ON nr.semester_id = sem.id
       LEFT JOIN guru g ON nr.wali_kelas_id = g.id
       ${where} ORDER BY nr.status_kirim, k.nama, s.nama LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // POST /api/admin/rapor/:id/cetak - tandai rapor sebagai dicetak
  const cetakMatch = subPath.match(/^\/(\d+)\/cetak$/);
  if (cetakMatch && request.method === 'POST') {
    const id = parseInt(cetakMatch[1]);
    const existing = await env.DB.prepare('SELECT id FROM nilai_rapor WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Rapor');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

    // Simpan ke arsip
    const rapor = await env.DB.prepare(
      'SELECT siswa_id, kelas_id, semester_id FROM nilai_rapor WHERE id = ?'
    ).bind(id).first<{ siswa_id: number; kelas_id: number; semester_id: number }>();

    if (rapor) {
      await env.DB.prepare(
        "INSERT INTO rapor_arsip (siswa_id, semester_id, file_url) VALUES (?, ?, ?)"
      ).bind(rapor.siswa_id, rapor.semester_id, null).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'cetak', 'rapor', ?, ?)"
    ).bind(user.sub, `Cetak rapor id=${id}`, ip).run();

    return success({ id, message: 'Rapor dicetak dan diarsipkan' });
  }

  // GET /api/admin/rapor/arsip - arsip rapor
  if (subPath === '/arsip' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare('SELECT COUNT(*) as total FROM rapor_arsip').first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT ra.*, s.nama as siswa_nama, s.nis as siswa_nis, sem.nama as semester_nama
       FROM rapor_arsip ra
       LEFT JOIN siswa s ON ra.siswa_id = s.id
       LEFT JOIN semester sem ON ra.semester_id = sem.id
       ORDER BY ra.dicetak_pada DESC LIMIT ? OFFSET ?`
    ).bind(perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET /api/admin/rapor/analisis - analisis rapor
  if (subPath === '/analisis' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    if (!semesterId) return badRequest('semester_id wajib diisi');

    let filterKelas = '';
    const bindings: unknown[] = [parseInt(semesterId)];
    if (kelasId) { filterKelas = ' AND nr.kelas_id = ?'; bindings.push(parseInt(kelasId)); }

    // Per mapel
    const perMapel = await env.DB.prepare(
      `SELECT mp.nama as mapel_nama,
              ROUND(AVG(nr.nilai_akhir), 2) as avg_nilai,
              COUNT(*) as count,
              SUM(CASE WHEN nr.predikat = 'A' THEN 1 ELSE 0 END) as predikat_a,
              SUM(CASE WHEN nr.predikat = 'B' THEN 1 ELSE 0 END) as predikat_b,
              SUM(CASE WHEN nr.predikat = 'C' THEN 1 ELSE 0 END) as predikat_c,
              SUM(CASE WHEN nr.predikat = 'D' THEN 1 ELSE 0 END) as predikat_d
       FROM nilai_rapor nr
       LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
       WHERE nr.semester_id = ?${filterKelas}
       GROUP BY nr.mata_pelajaran_id
       ORDER BY avg_nilai DESC`
    ).bind(...bindings).all();

    // Per kelas
    const perKelas = await env.DB.prepare(
      `SELECT k.nama as kelas_nama,
              ROUND(AVG(nr.nilai_akhir), 2) as avg_nilai,
              COUNT(*) as count,
              COUNT(DISTINCT nr.siswa_id) as jumlah_siswa
       FROM nilai_rapor nr
       LEFT JOIN kelas k ON nr.kelas_id = k.id
       WHERE nr.semester_id = ?${filterKelas}
       GROUP BY nr.kelas_id
       ORDER BY k.nama`
    ).bind(...bindings).all();

    // Overview
    const overview = await env.DB.prepare(
      `SELECT COUNT(*) as total_entries,
              COUNT(DISTINCT nr.siswa_id) as total_siswa,
              COUNT(DISTINCT nr.mata_pelajaran_id) as total_mapel,
              ROUND(AVG(nr.nilai_akhir), 2) as rata_rata,
              MAX(nr.nilai_akhir) as nilai_tertinggi,
              MIN(nr.nilai_akhir) as nilai_terendah
       FROM nilai_rapor nr
       WHERE nr.semester_id = ?${filterKelas}`
    ).bind(...bindings).first();

    return success({ per_mapel: perMapel.results, per_kelas: perKelas.results, overview });
  }

  // GET /api/admin/rapor/audit - audit trail rapor
  if (subPath === '/audit' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      "SELECT COUNT(*) as total FROM log_aktivitas WHERE modul = 'rapor'"
    ).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT la.*, u.username
       FROM log_aktivitas la
       LEFT JOIN users u ON la.user_id = u.id
       WHERE la.modul = 'rapor'
       ORDER BY la.created_at DESC LIMIT ? OFFSET ?`
    ).bind(perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET /api/admin/rapor/status-publikasi - cek status publikasi nilai semester aktif
  if (subPath === '/status-publikasi' && request.method === 'GET') {
    const semester = await env.DB.prepare(
      'SELECT id, nama, tahun_ajaran_id, nilai_published FROM semester WHERE is_aktif = 1 LIMIT 1'
    ).first<{ id: number; nama: string; tahun_ajaran_id: number; nilai_published: number }>();

    if (!semester) return badRequest('Tidak ada semester aktif');

    return success({
      semester_id: semester.id,
      semester_nama: semester.nama,
      nilai_published: semester.nilai_published === 1,
    });
  }

  // PUT /api/admin/rapor/:semesterId/publikasi-nilai - toggle ON/OFF publikasi nilai
  const publikasiMatch = subPath.match(/^\/(\d+)\/publikasi-nilai$/);
  if (publikasiMatch && request.method === 'PUT') {
    const semesterId = parseInt(publikasiMatch[1]);
    const body = await request.json<{ nilai_published?: boolean }>();

    const semester = await env.DB.prepare('SELECT id FROM semester WHERE id = ?').bind(semesterId).first();
    if (!semester) return notFound('Semester');

    const newValue = body.nilai_published === true ? 1 : 0;
    await env.DB.prepare('UPDATE semester SET nilai_published = ? WHERE id = ?').bind(newValue, semesterId).run();

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'rapor', ?, ?)"
    ).bind(user.sub, `Publikasi nilai semester ${semesterId}: ${newValue ? 'ON' : 'OFF'}`, ip).run();

    return success({ semester_id: semesterId, nilai_published: newValue === 1 });
  }

  // ── Publikasi per Jenis Ujian ──

  // GET /api/admin/rapor/status-publikasi-jenis - status semua jenis per semester aktif
  if (subPath === '/status-publikasi-jenis' && request.method === 'GET') {
    const sem = await env.DB.prepare(
      'SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1'
    ).first<{ id: number }>();
    if (!sem) return badRequest('Tidak ada semester aktif');

    const rows = await env.DB.prepare(
      'SELECT jenis, is_published FROM publikasi_jenis WHERE semester_id = ? ORDER BY CASE jenis WHEN \'harian\' THEN 1 WHEN \'tugas\' THEN 2 WHEN \'pts1\' THEN 3 WHEN \'pts2\' THEN 4 WHEN \'pas\' THEN 5 WHEN \'uts\' THEN 6 WHEN \'pat\' THEN 7 WHEN \'uas\' THEN 8 WHEN \'akhir\' THEN 9 END'
    ).bind(sem.id).all();

    return success({
      semester_id: sem.id,
      jenis: rows.results.map((r: any) => ({
        jenis: r.jenis,
        is_published: r.is_published === 1,
      })),
    });
  }

  // PUT /api/admin/rapor/publikasi-jenis - toggle publish per jenis
  if (subPath === '/publikasi-jenis' && request.method === 'PUT') {
    const body = await request.json<{ semester_id?: number; jenis?: string; is_published?: boolean }>();
    if (!body.semester_id || !body.jenis) return badRequest('semester_id dan jenis wajib diisi');

    const validJenis = ['harian','tugas','pts1','pts2','pas','uts','pat','uas','akhir'];
    if (!validJenis.includes(body.jenis)) return badRequest('Jenis tidak valid');

    const sem = await env.DB.prepare('SELECT id FROM semester WHERE id = ?').bind(body.semester_id).first();
    if (!sem) return notFound('Semester');

    const newValue = body.is_published === true ? 1 : 0;
    await env.DB.prepare(
      'INSERT INTO publikasi_jenis (semester_id, jenis, is_published) VALUES (?, ?, ?) ON CONFLICT(semester_id, jenis) DO UPDATE SET is_published = ?'
    ).bind(body.semester_id, body.jenis, newValue, newValue).run();

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'rapor', ?, ?)"
    ).bind(user.sub, `Publikasi jenis ${body.jenis}: ${newValue ? 'ON' : 'OFF'}`, ip).run();

    return success({ semester_id: body.semester_id, jenis: body.jenis, is_published: newValue === 1 });
  }

  // ── Publikasi per Kelas ──

  // GET /api/admin/rapor/status-publikasi-kelas - status semua kelas per semester aktif
  if (subPath === '/status-publikasi-kelas' && request.method === 'GET') {
    const sem = await env.DB.prepare(
      'SELECT id, tahun_ajaran_id FROM semester WHERE is_aktif = 1 LIMIT 1'
    ).first<{ id: number; tahun_ajaran_id: number }>();
    if (!sem) return badRequest('Tidak ada semester aktif');

    const rows = await env.DB.prepare(
      `SELECT k.id as kelas_id, k.nama as kelas_nama,
              COALESCE(pk.is_published, 0) as is_published
       FROM kelas k
       LEFT JOIN publikasi_kelas pk ON pk.kelas_id = k.id AND pk.semester_id = ?
       WHERE k.tahun_ajaran_id = ?
       ORDER BY k.nama`
    ).bind(sem.id, sem.tahun_ajaran_id).all();

    return success({
      semester_id: sem.id,
      kelass: rows.results.map((r: any) => ({
        kelas_id: r.kelas_id,
        kelas_nama: r.kelas_nama,
        is_published: r.is_published === 1,
      })),
    });
  }

  // PUT /api/admin/rapor/publikasi-kelas - toggle publish per kelas
  if (subPath === '/publikasi-kelas' && request.method === 'PUT') {
    const body = await request.json<{ semester_id?: number; kelas_id?: number; is_published?: boolean }>();
    if (!body.semester_id || !body.kelas_id) return badRequest('semester_id dan kelas_id wajib diisi');

    const sem = await env.DB.prepare('SELECT id FROM semester WHERE id = ?').bind(body.semester_id).first();
    if (!sem) return notFound('Semester');

    const kelas = await env.DB.prepare('SELECT id FROM kelas WHERE id = ?').bind(body.kelas_id).first();
    if (!kelas) return notFound('Kelas');

    const newValue = body.is_published === true ? 1 : 0;
    await env.DB.prepare(
      'INSERT INTO publikasi_kelas (semester_id, kelas_id, is_published) VALUES (?, ?, ?) ON CONFLICT(semester_id, kelas_id) DO UPDATE SET is_published = ?'
    ).bind(body.semester_id, body.kelas_id, newValue, newValue).run();

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'rapor', ?, ?)"
    ).bind(user.sub, `Publikasi kelas ${body.kelas_id}: ${newValue ? 'ON' : 'OFF'}`, ip).run();

    return success({ semester_id: body.semester_id, kelas_id: body.kelas_id, is_published: newValue === 1 });
  }

  return badRequest('Endpoint tidak dikenal');
}
