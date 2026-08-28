import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleNilai(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const semesterId = url.searchParams.get('semester_id');

  // Ambil semester aktif jika tidak ditentukan
  let semId = semesterId;
  if (!semId) {
    const { results: activeSem } = await env.DB.prepare(
      'SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1'
    ).all();
    if (activeSem.length > 0) semId = String((activeSem[0] as any).id);
  }

  // Cek apakah nilai sudah dipublikasikan untuk semester ini
  let nilaiPublished = true;
  if (semId) {
    const sem = await env.DB.prepare(
      'SELECT nilai_published FROM semester WHERE id = ?'
    ).bind(semId).first<{ nilai_published: number }>();
    if (sem) nilaiPublished = sem.nilai_published === 1;
  }

  // Ambil status publikasi per jenis
  const publishedJenis: Record<string, boolean> = {};
  if (semId) {
    const { results: pubRows } = await env.DB.prepare(
      'SELECT jenis, is_published FROM publikasi_jenis WHERE semester_id = ?'
    ).bind(semId).all();
    for (const r of pubRows as any[]) {
      publishedJenis[r.jenis] = r.is_published === 1;
    }
  }

  // Ambil info semester: nama & tahun ajaran (untuk metadata tampilan santri)
  let semesterNama: string | null = null;
  let semesterTahunAjaran: string | null = null;
  if (semId) {
    const sem = await env.DB.prepare(
      `SELECT sem.nama as semester_nama, ta.nama as tahun_ajaran
       FROM semester sem
       LEFT JOIN tahun_ajaran ta ON sem.tahun_ajaran_id = ta.id
       WHERE sem.id = ?`
    ).bind(semId).first<{ semester_nama: string; tahun_ajaran: string }>();
    semesterNama = sem?.semester_nama ?? null;
    semesterTahunAjaran = sem?.tahun_ajaran ?? null;
  }

  // Ambil data siswa beserta kelas, tingkat, dan tahun ajaran
  const { results: siswaData } = await env.DB.prepare(
    `SELECT s.id, s.kelas_id, k.nama as kelas_nama, t.nama as tingkat_nama,
            ta.nama as tahun_ajaran
     FROM siswa s
     LEFT JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     LEFT JOIN tahun_ajaran ta ON k.tahun_ajaran_id = ta.id
     WHERE s.id = ?`
  ).bind(user.siswa_id).all();

  if (siswaData.length === 0) return error('Data siswa tidak ditemukan', 404);
  const kelasId = (siswaData[0] as any).kelas_id;

  // Meta informasi (kelas/tingkat) dari data siswa
  const kelasNama = (siswaData[0] as any).kelas_nama ?? null;
  const tingkatNama = (siswaData[0] as any).tingkat_nama ?? null;

  // Jika publikasi global OFF dan tidak ada per-jenis publish, kembalikan kosong
  if (!nilaiPublished && Object.values(publishedJenis).every(v => !v)) {
    return success({
      rekap: [],
      rata_rata_keseluruhan: 0,
      semester_id: semId,
      semester_nama: semesterNama,
      tahun_ajaran: semesterTahunAjaran,
      kelas_nama: kelasNama,
      tingkat_nama: tingkatNama,
      published: false,
      published_jenis: publishedJenis,
      message: 'Nilai belum dipublikasikan oleh administrator',
    });
  }

  // Query nilai per mata pelajaran
  let query = `
    SELECT n.*, mp.nama as mapel_nama, mp.kode as mapel_kode
    FROM nilai n
    JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
    WHERE n.siswa_id = ? AND n.kelas_id = ?
  `;
  const params: any[] = [user.siswa_id, kelasId];

  if (semId) {
    query += ' AND n.semester_id = ?';
    params.push(semId);
  }

  query += ' ORDER BY mp.nama, n.jenis';

  const { results } = await env.DB.prepare(query).bind(...params).all();

  // Filter: hanya tampilkan jenis yang dipublikasikan
  const filteredResults = (results as any[]).filter(n => {
    // Jika publikasi global ON → semua jenis tampil
    if (nilaiPublished) return true;
    // Jika publikasi global OFF → hanya jenis yang di-ON-kan per-jenis
    return publishedJenis[n.jenis] === true;
  });

  // Group by mata pelajaran
  const grouped: Record<string, any[]> = {};
  for (const n of filteredResults) {
    if (!grouped[n.mapel_nama]) grouped[n.mapel_nama] = [];
    grouped[n.mapel_nama].push(n);
  }

    // Hitung rata-rata per mapel (simple average, tanpa bobot)
    const rekap = Object.entries(grouped).map(([mapel, nilaiList]) => {
      const countMap: Record<string, number> = { harian: 0, tugas: 0, uts: 0, uas: 0, pts1: 0, pas: 0, pts2: 0, pat: 0 };
      const totalMap: Record<string, number> = { harian: 0, tugas: 0, uts: 0, uas: 0, pts1: 0, pas: 0, pts2: 0, pat: 0 };

      for (const n of nilaiList) {
        const jenis = n.jenis as string;
        if (jenis in countMap) {
          countMap[jenis] += 1;
          totalMap[jenis] += n.nilai;
        }
      }

      const avg = (key: string) => countMap[key] > 0 ? totalMap[key] / countMap[key] : 0;

      const avgHarian = avg('harian');
      const avgTugas = avg('tugas');
      const avgUts = avg('uts');
      const avgUas = avg('uas');
      const avgPts1 = avg('pts1');
      const avgPas = avg('pas');
      const avgPts2 = avg('pts2');
      const avgPat = avg('pat');

      const avgPairs: [number, number][] = [
        [avgHarian, countMap['harian']],
        [avgTugas, countMap['tugas']],
        [avgUts, countMap['uts']],
        [avgUas, countMap['uas']],
        [avgPts1, countMap['pts1']],
        [avgPas, countMap['pas']],
        [avgPts2, countMap['pts2']],
        [avgPat, countMap['pat']],
      ];
      const validAvgs = avgPairs.filter(([, count]) => count > 0).map(([avg]) => avg);
      const avgAkhir = validAvgs.length > 0
        ? Math.round(validAvgs.reduce((s, v) => s + v, 0) / validAvgs.length * 100) / 100
        : 0;

      return {
        mapel_nama: mapel,
        harian: Math.round(avgHarian * 100) / 100,
        tugas: Math.round(avgTugas * 100) / 100,
        uts: Math.round(avgUts * 100) / 100,
        uas: Math.round(avgUas * 100) / 100,
        pts1: Math.round(avgPts1 * 100) / 100,
        pas: Math.round(avgPas * 100) / 100,
        pts2: Math.round(avgPts2 * 100) / 100,
        pat: Math.round(avgPat * 100) / 100,
        rata_rata: avgAkhir,
      };
    });

  // Rata-rata keseluruhan
  const avgKeseluruhan = rekap.length > 0
    ? Math.round(rekap.reduce((sum, r) => sum + r.rata_rata, 0) / rekap.length * 100) / 100
    : 0;

  return success({
    rekap,
    rata_rata_keseluruhan: avgKeseluruhan,
    semester_id: semId,
    semester_nama: semesterNama,
    tahun_ajaran: semesterTahunAjaran,
    kelas_nama: kelasNama,
    tingkat_nama: tingkatNama,
    published: true,
    published_jenis: publishedJenis,
  });
}
