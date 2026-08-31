import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest, error } from '../../utils/response';

export async function handleNilaiWK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // Bobot nilai
  if (subPath.startsWith('bobot-nilai')) {
    if (request.method === 'GET') {
      const id = subPath.split('/').length > 1 ? parseInt(subPath.split('/')[1]) : null;
      if (id) {
        const row = await env.DB.prepare('SELECT * FROM bobot_nilai WHERE id = ?').bind(id).first();
        if (!row) return notFound('Bobot nilai');
        return success(row);
      }
      const rows = await env.DB.prepare(
        `SELECT bn.*, mp.nama as mapel_nama FROM bobot_nilai bn
         LEFT JOIN mata_pelajaran mp ON bn.mata_pelajaran_id = mp.id
         ORDER BY bn.tahun_ajaran_id DESC`
      ).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { mata_pelajaran_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen } = body;

      if (!tahun_ajaran_id) return badRequest('tahun_ajaran_id wajib diisi');

      // Validasi FK: tahun_ajaran harus ada
      const taExists = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE id = ?').bind(tahun_ajaran_id).first();
      if (!taExists) return badRequest('Tahun ajaran tidak ditemukan');

      const hp = Number(harian_persen ?? 20), tp = Number(tugas_persen ?? 20), up = Number(uts_persen ?? 30), uap = Number(uas_persen ?? 30);
      const total = hp + tp + up + uap;
      if (total != 100) return badRequest('Total persentase harus 100%');

      const result = await env.DB.prepare(
        `INSERT INTO bobot_nilai (mata_pelajaran_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen)
         VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(mata_pelajaran_id || null, tahun_ajaran_id, harian_persen ?? 20, tugas_persen ?? 20, uts_persen ?? 30, uas_persen ?? 30).run();

      await logAktivitas(env, user.sub, 'create', 'bobot_nilai', `Tambah bobot nilai ta=${tahun_ajaran_id}`, ip);
      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      const existing = await env.DB.prepare('SELECT id FROM bobot_nilai WHERE id = ?').bind(id).first();
      if (!existing) return notFound('Bobot nilai');

      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['mata_pelajaran_id', 'tahun_ajaran_id', 'harian_persen', 'tugas_persen', 'uts_persen', 'uas_persen']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);

      await env.DB.prepare(`UPDATE bobot_nilai SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      await logAktivitas(env, user.sub, 'update', 'bobot_nilai', `Update bobot nilai id=${id}`, ip);
      return success({ id });
    }

    if (request.method === 'DELETE') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      const existing = await env.DB.prepare('SELECT id FROM bobot_nilai WHERE id = ?').bind(id).first();
      if (!existing) return notFound('Bobot nilai');

      await env.DB.prepare('DELETE FROM bobot_nilai WHERE id = ?').bind(id).run();
      await logAktivitas(env, user.sub, 'delete', 'bobot_nilai', `Hapus bobot nilai id=${id}`, ip);
      return success({ message: 'Bobot nilai berhasil dihapus' });
    }
  }

  // Monitoring nilai (with pagination & filters)
  if (subPath === 'monitoring-nilai' && request.method === 'GET') {
    try {
    const page = parseInt(url.searchParams.get('page') || '1');
    const perPage = parseInt(url.searchParams.get('per_page') || '20');
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    const statusFilter = url.searchParams.get('status');
    const search = url.searchParams.get('search');
    const offset = (page - 1) * perPage;

    let whereClause = 'WHERE 1=1';
    const params: unknown[] = [];

    if (kelasId) {
      whereClause += ' AND n.kelas_id = ?';
      params.push(parseInt(kelasId));
    }
    if (mapelId) {
      whereClause += ' AND n.mata_pelajaran_id = ?';
      params.push(parseInt(mapelId));
    }
    if (statusFilter) {
      whereClause += ' AND n.status_validasi = ?';
      params.push(statusFilter);
    }
    if (search) {
      whereClause += ' AND (s.nama LIKE ? OR mp.nama LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    // Get total count
    const countResult = await env.DB.prepare(
      `SELECT COUNT(*) as total FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       ${whereClause}`
    ).bind(...params).first<{ total: number }>();

    const total = countResult?.total || 0;
    const totalPages = Math.ceil(total / perPage);

    // Get paginated data
    const rows = await env.DB.prepare(
      `SELECT n.id, n.nilai, n.jenis, n.status_validasi, n.siswa_id, s.nama as siswa_nama,
              mp.nama as mapel_nama, k.nama as kelas_nama, g.nama as guru_nama
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON n.kelas_id = k.id
       LEFT JOIN guru g ON n.diinput_oleh = g.id
       ${whereClause}
       ORDER BY n.created_at DESC
       LIMIT ? OFFSET ?`
    ).bind(...params, perPage, offset).all();

    // Get summary stats
    const statsResult = await env.DB.prepare(
      `SELECT 
         COUNT(*) as total,
         COUNT(CASE WHEN n.status_validasi = 'draft' THEN 1 END) as draft,
         COUNT(CASE WHEN n.status_validasi = 'tervalidasi' THEN 1 END) as tervalidasi,
         ROUND(AVG(CAST(n.nilai AS REAL)), 1) as rata_rata
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       ${whereClause}`
    ).bind(...params).first();

    return success({
      data: rows.results,
      pagination: {
        page,
        per_page: perPage,
        total,
        total_pages: totalPages,
      },
      stats: statsResult || { total: 0, draft: 0, tervalidasi: 0, rata_rata: 0 },
    });
  } catch (e) {
    return error('Gagal mengambil data monitoring nilai', 500);
  }
  }

  // Status pengumpulan nilai per guru
  if (subPath === 'status-pengumpulan' && request.method === 'GET') {
    try {
      const rows = await env.DB.prepare(
        `SELECT g.id as guru_id, g.nama as guru_nama,
                COUNT(DISTINCT n.id) as total_input,
                COUNT(DISTINCT CASE WHEN n.status_validasi = 'draft' THEN n.id END) as draft,
                COUNT(DISTINCT CASE WHEN n.status_validasi = 'tervalidasi' THEN n.id END) as tervalidasi
         FROM guru g
         LEFT JOIN nilai n ON g.id = n.diinput_oleh
         WHERE g.status_aktif = 1
         GROUP BY g.id ORDER BY g.nip ASC`
      ).all();
      return success(rows.results);
    } catch (e) {
      return error('Gagal mengambil data status pengumpulan', 500);
    }
  }

  return badRequest('Endpoint tidak dikenal');
}

function logAktivitas(env: Env, userId: number, aksi: string, modul: string, detail: string, ip: string) {
  return env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(userId, aksi, modul, detail, ip).run();
}
