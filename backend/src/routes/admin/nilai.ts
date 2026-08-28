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

  // GET /api/admin/nilai/komplit-per-mapel - status kelengkapan nilai per mapel
  if (subPath === '/komplit-per-mapel' && request.method === 'GET') {
    const reqSemester = url.searchParams.get('semester_id');
    const reqTingkat = url.searchParams.get('tingkat_id');
    const jenis = url.searchParams.get('jenis') || '';

    if (!reqSemester || !reqTingkat) return badRequest('semester_id dan tingkat_id wajib diisi');
    const semesterId = parseInt(reqSemester);
    const tingkatId = parseInt(reqTingkat);

    const sem = await env.DB.prepare(
      'SELECT id, tahun_ajaran_id, nama FROM semester WHERE id = ?'
    ).bind(semesterId).first<{ id: number; tahun_ajaran_id: number; nama: string }>();
    if (!sem) return notFound('Semester');

    const tingkat = await env.DB.prepare('SELECT id, nama FROM tingkat WHERE id = ?').bind(tingkatId).first<{ id: number; nama: string }>();
    if (!tingkat) return notFound('Tingkat');

    // Total santri aktif pada semua kelas dengan tingkat tsb (tahun ajaran semester)
    const totalRow = await env.DB.prepare(
      `SELECT COUNT(*) as total
       FROM siswa s
       JOIN kelas k ON s.kelas_id = k.id
       WHERE s.status = 'aktif' AND k.tingkat_id = ? AND k.tahun_ajaran_id = ?`
    ).bind(tingkatId, sem.tahun_ajaran_id).first<{ total: number }>();
    const totalSantri = totalRow?.total || 0;

    // Daftar mapel yang terdaftar pada kelas-kelas tingkat tsb (basis daftar)
    const mapelRows = await env.DB.prepare(
      `SELECT DISTINCT mp.id as mata_pelajaran_id, mp.nama as mapel_nama
       FROM mapel_kelas mk
       JOIN kelas k ON mk.kelas_id = k.id
       JOIN mata_pelajaran mp ON mk.mata_pelajaran_id = mp.id
       WHERE k.tingkat_id = ? AND k.tahun_ajaran_id = ?
       ORDER BY mp.nama`
    ).bind(tingkatId, sem.tahun_ajaran_id).all();

    // Jumlah santri yang sudah dinilai per mapel (distinct siswa)
    const nilaiRows = await env.DB.prepare(
      `SELECT n.mata_pelajaran_id, COUNT(DISTINCT n.siswa_id) as cnt
       FROM nilai n
       JOIN kelas k ON n.kelas_id = k.id
       WHERE n.semester_id = ? AND n.jenis = ? AND k.tingkat_id = ?
       GROUP BY n.mata_pelajaran_id`
    ).bind(semesterId, jenis, tingkatId).all();
    const nilaiMap = new Map<number, number>();
    for (const r of nilaiRows.results as any[]) { nilaiMap.set(r.mata_pelajaran_id, r.cnt); }

    // Status publikasi per mapel per jenis
    const pubRows = await env.DB.prepare(
      'SELECT mata_pelajaran_id, is_published FROM publikasi_mapel WHERE semester_id = ? AND jenis = ?'
    ).bind(semesterId, jenis).all();
    const pubMap = new Map<number, boolean>();
    for (const r of pubRows.results as any[]) { pubMap.set(r.mata_pelajaran_id, r.is_published === 1); }

    const items = (mapelRows.results as any[]).map((m) => {
      const terisi = nilaiMap.get(m.mata_pelajaran_id) || 0;
      let status = 'kosong';
      if (terisi > 0 && terisi < totalSantri) status = 'sebagian';
      else if (terisi >= totalSantri) status = 'komplit';
      return {
        mata_pelajaran_id: m.mata_pelajaran_id,
        mapel_nama: m.mapel_nama,
        tingkat_id: tingkatId,
        tingkat_nama: tingkat.nama,
        total_santri: totalSantri,
        nilai_terisi: terisi,
        status,
        is_published: pubMap.get(m.mata_pelajaran_id) ?? false,
      };
    });

    return success({ semester_id: semesterId, semester_nama: sem.nama, tingkat_id: tingkatId, tingkat_nama: tingkat.nama, jenis, total_santri: totalSantri, items });
  }

  // PUT /api/admin/nilai/publikasi-mapel - toggle publish/unpublish per mapel
  if (subPath === '/publikasi-mapel' && request.method === 'PUT') {
    const body = await request.json<{ semester_id?: number; mata_pelajaran_id?: number; jenis?: string; is_published?: boolean }>();
    if (!body.semester_id || !body.mata_pelajaran_id || !body.jenis) {
      return badRequest('semester_id, mata_pelajaran_id dan jenis wajib diisi');
    }

    const sem = await env.DB.prepare('SELECT id FROM semester WHERE id = ?').bind(body.semester_id).first();
    if (!sem) return notFound('Semester');

    const mapel = await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE id = ?').bind(body.mata_pelajaran_id).first();
    if (!mapel) return notFound('Mata pelajaran');

    const newValue = body.is_published === true ? 1 : 0;
    await env.DB.prepare(
      'INSERT INTO publikasi_mapel (semester_id, mata_pelajaran_id, jenis, is_published) VALUES (?, ?, ?, ?) ON CONFLICT(semester_id, mata_pelajaran_id, jenis) DO UPDATE SET is_published = ?'
    ).bind(body.semester_id, body.mata_pelajaran_id, body.jenis, newValue, newValue).run();

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'rapor', ?, ?)"
    ).bind(user.sub, `Publikasi mapel ${body.mata_pelajaran_id} (${body.jenis}) : ${newValue ? 'ON' : 'OFF'}`, ip).run();

    return success({ semester_id: body.semester_id, mata_pelajaran_id: body.mata_pelajaran_id, jenis: body.jenis, is_published: newValue === 1 });
  }

  return badRequest('Endpoint tidak dikenal');
}
