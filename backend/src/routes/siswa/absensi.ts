import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleAbsensi(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const bulan = url.searchParams.get('bulan');
  const tahun = url.searchParams.get('tahun');
  const tanggal = url.searchParams.get('tanggal');
  const page = parseInt(url.searchParams.get('page') ?? '1');
  const perPage = parseInt(url.searchParams.get('per_page') ?? '20');
  const offset = (page - 1) * perPage;

  // Hitung total
  let countQuery = 'SELECT COUNT(*) as total FROM absensi_siswa WHERE siswa_id = ?';
  const countParams: any[] = [user.siswa_id];

  if (tanggal) {
    countQuery += " AND tanggal = ?";
    countParams.push(tanggal);
  } else if (bulan && tahun) {
    countQuery += " AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?";
    countParams.push(bulan.padStart(2, '0'), tahun);
  }

  const { results: countResult } = await env.DB.prepare(countQuery).bind(...countParams).all();
  const total = (countResult[0] as any).total;

  // Ambil data
  let dataQuery = `
    SELECT a.*, mp.nama as mapel_nama
    FROM absensi_siswa a
    LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
    WHERE a.siswa_id = ?
  `;
  const dataParams: any[] = [user.siswa_id];

  if (tanggal) {
    dataQuery += " AND a.tanggal = ?";
    dataParams.push(tanggal);
  } else if (bulan && tahun) {
    dataQuery += " AND strftime('%m', a.tanggal) = ? AND strftime('%Y', a.tanggal) = ?";
    dataParams.push(bulan.padStart(2, '0'), tahun);
  }

  dataQuery += ' ORDER BY a.tanggal DESC LIMIT ? OFFSET ?';
  dataParams.push(perPage, offset);

  const { results } = await env.DB.prepare(dataQuery).bind(...dataParams).all();

  // Hitung statistik
  let statsQuery = `
    SELECT status, COUNT(*) as jumlah
    FROM absensi_siswa
    WHERE siswa_id = ?
  `;
  const statsParams: any[] = [user.siswa_id];

  if (tanggal) {
    statsQuery += " AND tanggal = ?";
    statsParams.push(tanggal);
  } else if (bulan && tahun) {
    statsQuery += " AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?";
    statsParams.push(bulan.padStart(2, '0'), tahun);
  }

  statsQuery += ' GROUP BY status';

  const { results: stats } = await env.DB.prepare(statsQuery).bind(...statsParams).all();

  const statistik: Record<string, number> = {};
  for (const row of stats) {
    statistik[row.status as string] = row.jumlah as number;
  }

  return success({
    data: results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
    statistik,
  });
}
