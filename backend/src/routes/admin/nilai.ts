import { Env, UserPayload } from '../../types';
import { success, notFound, badRequest } from '../../utils/response';

export async function handleAdminNilai(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/admin/nilai', '');

  // GET /api/admin/nilai - monitoring semua nilai
  if ((subPath === '' || subPath === '/') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const mapelId = url.searchParams.get('mata_pelajaran_id') || '';
    const jenis = url.searchParams.get('jenis') || '';
    const status = url.searchParams.get('status_validasi') || '';
    const semesterId = url.searchParams.get('semester_id') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND n.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (mapelId) { where += ' AND n.mata_pelajaran_id = ?'; bindings.push(parseInt(mapelId)); }
    if (jenis) { where += ' AND n.jenis = ?'; bindings.push(jenis); }
    if (status) { where += ' AND n.status_validasi = ?'; bindings.push(status); }
    if (semesterId) { where += ' AND n.semester_id = ?'; bindings.push(parseInt(semesterId)); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM nilai n ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT n.*, s.nama as siswa_nama, s.nis as siswa_nis, mp.nama as mapel_nama,
              k.nama as kelas_nama, g.nama as guru_nama, sem.nama as semester_nama,
              t.nama as tingkat_nama, ta.nama as tahun_ajaran
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON n.kelas_id = k.id
       LEFT JOIN tingkat t ON k.tingkat_id = t.id
       LEFT JOIN guru g ON n.diinput_oleh = g.id
       LEFT JOIN semester sem ON n.semester_id = sem.id
       LEFT JOIN tahun_ajaran ta ON sem.tahun_ajaran_id = ta.id
       ${where} ORDER BY n.created_at DESC LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // PUT /api/admin/nilai/:id/validasi - validasi nilai
  const validasiMatch = subPath.match(/^\/(\d+)\/validasi$/);
  if (validasiMatch && request.method === 'PUT') {
    const id = parseInt(validasiMatch[1]);
    const existing = await env.DB.prepare('SELECT id FROM nilai WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Nilai');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare("UPDATE nilai SET status_validasi = 'tervalidasi' WHERE id = ?").bind(id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'validate', 'nilai', ?, ?)"
    ).bind(user.sub, `Validasi nilai id=${id}`, ip).run();

    return success({ id, status_validasi: 'tervalidasi' });
  }

  // GET /api/admin/nilai/analisis - analisis nilai
  if (subPath === '/analisis' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';
    const jenis = url.searchParams.get('jenis') || '';

    if (!semesterId) return badRequest('semester_id wajib diisi');

    let filter = '';
    const bindings: unknown[] = [parseInt(semesterId)];
    if (kelasId) { filter += ' AND n.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (jenis) { filter += ' AND n.jenis = ?'; bindings.push(jenis); }

    // Per mapel
    const perMapel = await env.DB.prepare(
      `SELECT mp.nama as mapel_nama,
              ROUND(AVG(n.nilai), 2) as avg_nilai,
              COUNT(*) as count
       FROM nilai n
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       WHERE n.semester_id = ?${filter}
       GROUP BY n.mata_pelajaran_id
       ORDER BY avg_nilai DESC`
    ).bind(...bindings).all();

    // Per kelas
    const perKelas = await env.DB.prepare(
      `SELECT k.nama as kelas_nama,
              ROUND(AVG(n.nilai), 2) as avg_nilai,
              COUNT(*) as count,
              COUNT(DISTINCT n.siswa_id) as jumlah_siswa
       FROM nilai n
       LEFT JOIN kelas k ON n.kelas_id = k.id
       WHERE n.semester_id = ?${filter}
       GROUP BY n.kelas_id
       ORDER BY k.nama`
    ).bind(...bindings).all();

    // Per jenis
    const perJenis = await env.DB.prepare(
      `SELECT n.jenis,
              ROUND(AVG(n.nilai), 2) as avg_nilai,
              COUNT(*) as count
       FROM nilai n
       WHERE n.semester_id = ?${filter}
       GROUP BY n.jenis
       ORDER BY n.jenis`
    ).bind(...bindings).all();

    // Overview
    const overview = await env.DB.prepare(
      `SELECT COUNT(*) as total_entries,
              COUNT(DISTINCT n.siswa_id) as total_siswa,
              COUNT(DISTINCT n.mata_pelajaran_id) as total_mapel,
              ROUND(AVG(n.nilai), 2) as rata_rata,
              MAX(n.nilai) as nilai_tertinggi,
              MIN(n.nilai) as nilai_terendah
       FROM nilai n
       WHERE n.semester_id = ?${filter}`
    ).bind(...bindings).first();

    return success({ per_mapel: perMapel.results, per_kelas: perKelas.results, per_jenis: perJenis.results, overview });
  }

  // GET /api/admin/nilai/audit - audit trail nilai
  if (subPath === '/audit' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      "SELECT COUNT(*) as total FROM log_aktivitas WHERE modul = 'nilai'"
    ).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT la.*, u.username
       FROM log_aktivitas la
       LEFT JOIN users u ON la.user_id = u.id
       WHERE la.modul = 'nilai'
       ORDER BY la.created_at DESC LIMIT ? OFFSET ?`
    ).bind(perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  return badRequest('Endpoint tidak dikenal');
}
