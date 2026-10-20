import { Env } from '../../types';
import { success, error } from '../../utils/response';

// ============================================================
// PUBLIC DISPLAY (Kiosk) - Papan Absensi Live
//
// Endpoint publik TANPA login, khusus untuk monitor/TV di pintu
// masuk yang menampilkan daftar hadir live asatidz + musyrifah
// at-Ta'wid. Read-only: hanya nama + jam, tanpa data sensitif.
// Dilindungi general rate limit (100 req/menit/IP) di index.ts.
// ============================================================

const WIB_MS = 7 * 60 * 60 * 1000;
const HARI = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

export async function handlePublicDisplay(
  request: Request,
  env: Env,
  pathParts: string[]
): Promise<Response> {
  if (request.method !== 'GET') return error('Method tidak didukung', 405);

  const subPath = pathParts.slice(2).join('/'); // /api/public/...

  if (subPath === 'absensi-hari-ini') {
    return getAbsensiHariIni(env);
  }

  return error('Endpoint tidak dikenal', 404);
}

async function getAbsensiHariIni(env: Env): Promise<Response> {
  const wibNow = new Date(Date.now() + WIB_MS);
  const today = wibNow.toISOString().split('T')[0];
  const hariIni = HARI[wibNow.getUTCDay()];

  const [absensiRows, totalGuruRow, musyrifahRows, totalMusyrifahRow] =
    await Promise.all([
      env.DB.prepare(`
        SELECT g.nama, a.jam_masuk, a.jam_keluar
        FROM absensi_guru a
        JOIN guru g ON a.guru_id = g.id
        WHERE a.tanggal = ? AND a.jam_masuk IS NOT NULL
        ORDER BY a.jam_masuk DESC
      `).bind(today).all<{ nama: string; jam_masuk: string; jam_keluar: string | null }>(),
      env.DB.prepare(
        'SELECT COUNT(*) as total FROM guru WHERE status_aktif = 1'
      ).first<{ total: number }>(),
      // Absensi musyrifah terikat jadwal (bisa >1 sesi per hari) → diagregat
      // per musyrifah: jam masuk = paling awal, jam keluar = paling akhir dan
      // hanya dianggap keluar bila SEMUA sesi hari ini sudah selesai.
      env.DB.prepare(`
        SELECT m.nama,
               MIN(am.waktu_masuk)  AS jam_masuk,
               MAX(am.waktu_keluar) AS jam_keluar_terakhir,
               SUM(CASE WHEN am.waktu_keluar IS NULL THEN 1 ELSE 0 END) AS sesi_terbuka
        FROM dauroh_absensi_musyrifah am
        JOIN dauroh_musyrifah m ON am.musyrifah_id = m.id
        WHERE am.tanggal = ? AND am.waktu_masuk IS NOT NULL
        GROUP BY am.musyrifah_id, m.nama
        ORDER BY jam_masuk DESC
      `).bind(today).all<{
        nama: string;
        jam_masuk: string;
        jam_keluar_terakhir: string | null;
        sesi_terbuka: number;
      }>(),
      // "Belum hadir" musyrifah dihitung dari yang PUNYA jadwal aktif hari ini
      // (berbeda dari asatidz yang basisnya seluruh guru aktif).
      env.DB.prepare(`
        SELECT COUNT(DISTINCT m.id) AS total
        FROM dauroh_musyrifah m
        JOIN dauroh_jadwal j
          ON (j.musyrifah_1_id = m.id OR j.musyrifah_2_id = m.id)
        WHERE m.is_aktif = 1 AND j.is_aktif = 1 AND j.hari = ?
      `).bind(hariIni).first<{ total: number }>(),
    ]);

  const items = absensiRows.results;
  const totalAsatidz = totalGuruRow?.total ?? 0;
  const hadir = items.length;
  const sudahKeluar = items.filter((i) => i.jam_keluar !== null).length;

  const itemsMusyrifah = musyrifahRows.results.map((r) => ({
    nama: r.nama,
    jam_masuk: r.jam_masuk,
    jam_keluar: r.sesi_terbuka === 0 ? r.jam_keluar_terakhir : null,
  }));
  const totalMusyrifah = totalMusyrifahRow?.total ?? 0;
  const hadirMusyrifah = itemsMusyrifah.length;
  const sudahKeluarMusyrifah = itemsMusyrifah.filter(
    (i) => i.jam_keluar !== null
  ).length;

  return success({
    tanggal: today,
    items,
    statistik: {
      total_asatidz: totalAsatidz,
      hadir,
      sudah_keluar: sudahKeluar,
      belum_hadir: Math.max(0, totalAsatidz - hadir),
    },
    items_musyrifah: itemsMusyrifah,
    statistik_musyrifah: {
      total_musyrifah: totalMusyrifah,
      hadir: hadirMusyrifah,
      sudah_keluar: sudahKeluarMusyrifah,
      belum_hadir: Math.max(0, totalMusyrifah - hadirMusyrifah),
    },
  });
}
