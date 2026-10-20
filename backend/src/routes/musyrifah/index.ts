import { Env, UserPayload } from '../../types';
import { success, error, badRequest, notFound } from '../../utils/response';
import { getWaktuAbsensiMusyrifah } from '../../utils/absensi_waktu';

type Row = Record<string, unknown>;

const WIB_MS = 7 * 60 * 60 * 1000;

function wibNow(): Date {
  return new Date(Date.now() + WIB_MS);
}

function wibDate(): string {
  return wibNow().toISOString().split('T')[0];
}

function wibTime(): string {
  return wibNow().toISOString().slice(11, 19);
}

// ============================================================
// HANDLER: Musyrifah Routes
// ============================================================

export async function handleMusyrifahRoutes(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const subPath = pathParts.slice(2).join('/'); // /api/musyrifah/...

  // ─── JADWAL ─────────────────────────────────────────────────
  if (subPath === 'jadwal' || subPath.startsWith('jadwal/')) {
    return handleJadwalMusyrifah(request, env, user, pathParts, url);
  }

  // ─── ABSENSI ────────────────────────────────────────────────
  if (subPath === 'absensi' || subPath.startsWith('absensi/')) {
    return handleAbsensiMusyrifah(request, env, user, pathParts, url);
  }

  // ─── NILAI ──────────────────────────────────────────────────
  if (subPath === 'nilai' || subPath.startsWith('nilai/')) {
    return handleNilaiMusyrifah(request, env, user, pathParts, url);
  }

  // ─── SURAT ─────────────────────────────────────────────────
  if (subPath === 'surat' || subPath.startsWith('surat/')) {
    return handleSuratMusyrifah(request, env, user, pathParts, url);
  }

  // ─── SANTRI BY JADWAL ──────────────────────────────────────
  if (subPath === 'santri' && request.method === 'GET') {
    return listSantriByJadwal(env, user, url);
  }

  // ─── RIWAYAT ───────────────────────────────────────────────
  if (subPath.startsWith('riwayat/')) {
    return handleRiwayatSantri(request, env, user, pathParts, url);
  }

  // ─── PROFIL ─────────────────────────────────────────────────
  if (subPath === 'profil' && request.method === 'GET') {
    return handleProfilMusyrifah(env, user);
  }

  // ─── DASHBOARD ──────────────────────────────────────────────
  if (subPath === 'dashboard' && request.method === 'GET') {
    return handleDashboardMusyrifah(env, user);
  }

  return error('Endpoint tidak dikenal', 404);
}

// ============================================================
// DASHBOARD
// ============================================================

async function handleDashboardMusyrifah(env: Env, user: UserPayload): Promise<Response> {
  // Cari musyrifah_id dari username
  const musyrifah = await env.DB.prepare(
    'SELECT id, nama FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number; nama: string }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const today = wibDate();
  const hariIni = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'][wibNow().getUTCDay()];

  const [jadwalHari, absensiHari, nilaiCount] = await Promise.all([
    // Jadwal hari ini
    env.DB.prepare(`
      SELECT j.*, p.nama_program, p.jenis_dauroh,
             m1.nama as musyrifah_1_nama,
             (SELECT GROUP_CONCAT(k.nama, ', ') FROM dauroh_jadwal_kelas jdk JOIN kelas k ON jdk.kelas_id = k.id WHERE jdk.jadwal_id = j.id) as kelas_nama
      FROM dauroh_jadwal j
      JOIN dauroh_program p ON j.program_id = p.id
      JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
      WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
        AND j.hari = ? AND j.is_aktif = 1
      ORDER BY j.jam_mulai
    `).bind(musyrifah.id, musyrifah.id, hariIni).all(),
    // Absensi musyrifah hari ini
    env.DB.prepare(`
      SELECT COUNT(*) as total FROM dauroh_absensi_musyrifah
      WHERE musyrifah_id = ? AND tanggal = ?
    `).bind(musyrifah.id, today).first<{ total: number }>(),
    // Total nilai yang diinput
    env.DB.prepare('SELECT COUNT(*) as total FROM dauroh_nilai WHERE program_id IN (SELECT program_id FROM dauroh_jadwal WHERE musyrifah_1_id = ? OR musyrifah_2_id = ?)')
      .bind(musyrifah.id, musyrifah.id).first<{ total: number }>(),
  ]);

  return success({
    nama: musyrifah.nama,
    jadwal_hari_ini: jadwalHari.results,
    sudah_absen: (absensiHari?.total || 0) > 0,
    total_nilai: nilaiCount?.total || 0,
  });
}

// ============================================================
// PROFIL
// ============================================================

async function handleProfilMusyrifah(env: Env, user: UserPayload): Promise<Response> {
  const musyrifah = await env.DB.prepare(`
    SELECT id, nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, is_aktif
    FROM dauroh_musyrifah WHERE username = ?
  `).bind(user.username).first();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  return success(musyrifah);
}

// ============================================================
// JADWAL MUSYRIFAH
// ============================================================

async function handleJadwalMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/jadwal - List jadwal musyrifah
  if (method === 'GET' && pathParts.length === 3) {
    return listJadwalMusyrifah(env, user, url);
  }

  // GET /api/musyrifah/jadwal/:id - Detail jadwal
  if (method === 'GET' && pathParts.length === 4) {
    const id = parseInt(pathParts[3]);
    return getJadwalDetail(env, id, user);
  }

  return error('Method tidak didukung', 405);
}

async function listJadwalMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const hariFilter = url.searchParams.get('hari');
  const programFilter = url.searchParams.get('program_id');

  let where = 'WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?) AND j.is_aktif = 1';
  const bindings: unknown[] = [musyrifah.id, musyrifah.id];

  if (hariFilter) {
    where += ' AND j.hari = ?';
    bindings.push(hariFilter);
  }
  if (programFilter) {
    where += ' AND j.program_id = ?';
    bindings.push(programFilter);
  }

  const rows = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           p.max_bidang1, p.max_bidang2, p.max_bidang3,
           p.label_bidang1, p.label_bidang2, p.label_bidang3,
           m1.nama as musyrifah_1_nama,
           m2.nama as musyrifah_2_nama,
           (SELECT GROUP_CONCAT(k.nama, ', ') FROM dauroh_jadwal_kelas jdk JOIN kelas k ON jdk.kelas_id = k.id WHERE jdk.jadwal_id = j.id) as kelas_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    ${where}
    ORDER BY j.hari, j.jam_mulai
  `).bind(...bindings).all();

  return success(rows.results);
}

async function getJadwalDetail(env: Env, id: number, user: UserPayload) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const jadwal = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama,
           m2.nama as musyrifah_2_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    WHERE j.id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(id, musyrifah.id, musyrifah.id).first();

  if (!jadwal) return error('Jadwal tidak ditemukan', 404);

  // Ambil kelas
  const kelas = await env.DB.prepare(`
    SELECT k.id, k.nama
    FROM dauroh_jadwal_kelas jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.jadwal_id = ?
  `).bind(id).all();

  // Ambil absensi santri terakhir
  const absensi = await env.DB.prepare(`
    SELECT da.*, s.nama as santri_nama
    FROM dauroh_absensi_santri da
    JOIN siswa s ON da.santri_id = s.id
    WHERE da.jadwal_id = ?
    ORDER BY da.tanggal DESC, s.nama
    LIMIT 50
  `).bind(id).all();

  return success({ ...jadwal, kelas: kelas.results, absensi_terakhir: absensi.results });
}

// ============================================================
// ABSENSI MUSYRIFAH (QR Scan)
// ============================================================

async function handleAbsensiMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // POST /api/musyrifah/absensi/scan - QR Scan absensi musyrifah
  if (method === 'POST' && pathParts[3] === 'scan') {
    return scanAbsensiMusyrifah(request, env, user);
  }

  // GET /api/musyrifah/absensi/pengaturan-waktu - info jam absensi (untuk halaman scan)
  if (method === 'GET' && pathParts[3] === 'pengaturan-waktu') {
    return success(await getWaktuAbsensiMusyrifah(env));
  }

  // GET /api/musyrifah/absensi - Riwayat absensi
  if (method === 'GET' && pathParts.length === 3) {
    return listAbsensiMusyrifah(env, user, url);
  }

  // POST /api/musyrifah/absensi/santri - Input absensi santri manual
  if (method === 'POST' && pathParts[3] === 'santri') {
    return inputAbsensiSantri(request, env, user);
  }

  return error('Method tidak didukung', 405);
}

async function scanAbsensiMusyrifah(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as { token?: string; jadwal_id?: number };
  const { token, jadwal_id } = body;

  const QR_TOKEN = env.QR_DAUROH_TOKEN || 'PPI_DAUROH_QR_2026';
  if (token !== QR_TOKEN) {
    return error('QR token tidak valid', 400);
  }

  const musyrifah = await env.DB.prepare(
    'SELECT id, nama FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number; nama: string }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const wib = wibNow();
  const today = wibDate();
  const currentTime = wibTime();
  const hariIni = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'][wib.getUTCDay()];

  // Window jam absensi musyrifah (diatur admin via tabel `pengaturan`, fallback env DAUROH_JAM_*)
  const waktu = await getWaktuAbsensiMusyrifah(env);
  const masukMulai = waktu.jam_masuk_mulai;
  const masukSelesai = waktu.jam_masuk_selesai;
  const keluarMulai = waktu.jam_keluar_mulai;
  const keluarSelesai = waktu.jam_keluar_selesai;

  const inJamMasuk = currentTime >= masukMulai && currentTime <= masukSelesai;
  const inJamKeluar = currentTime >= keluarMulai && currentTime <= keluarSelesai;

  // Di luar window jam absensi
  if (!inJamMasuk && !inJamKeluar) {
    return error(
      `Di luar jam absensi. Jam masuk ${masukMulai.slice(0, 5)}–${masukSelesai.slice(0, 5)}, jam keluar ${keluarMulai.slice(0, 5)}–${keluarSelesai.slice(0, 5)} WIB`,
      400
    );
  }

  // Cari jadwal aktif hari ini
  let jadwalFilter = '';
  const jadwalBindings: unknown[] = [musyrifah.id, musyrifah.id, hariIni];
  
  if (jadwal_id) {
    jadwalFilter = ' AND j.id = ?';
    jadwalBindings.push(jadwal_id);
  }

  const jadwalList = await env.DB.prepare(`
    SELECT j.id, p.nama_program, j.hari, j.jam_mulai, j.jam_selesai
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
      AND j.hari = ? AND j.is_aktif = 1
      ${jadwalFilter}
    ORDER BY j.jam_mulai
  `).bind(...jadwalBindings).all<{ id: number; nama_program: string; hari: string; jam_mulai: string; jam_selesai: string }>();

  if (jadwalList.results.length === 0) {
    return error(`Tidak ada jadwal dauroh aktif hari ini (${hariIni})`, 400);
  }

  let jadwal: { id: number; nama_program: string; hari: string; jam_mulai: string; jam_selesai: string };
  if (jadwal_id) {
    jadwal = jadwalList.results[0];
  } else if (jadwalList.results.length > 1) {
    // Musyrifah punya >1 jadwal aktif hari ini — minta memilih jadwal
    return success({
      action: 'pilih_jadwal',
      jadwal: jadwalList.results.map((j) => ({
        id: j.id,
        program: j.nama_program,
        hari: j.hari,
        jam_mulai: j.jam_mulai,
        jam_selesai: j.jam_selesai,
      })),
      message: 'Ada lebih dari satu jadwal aktif hari ini. Pilih jadwal yang akan diabsensi.',
    });
  } else {
    jadwal = jadwalList.results[0];
  }

  // Cek absensi hari ini (check-in / check-out)
  const existing = await env.DB.prepare(
    'SELECT id, waktu_masuk, waktu_keluar FROM dauroh_absensi_musyrifah WHERE musyrifah_id = ? AND jadwal_id = ? AND tanggal = ?'
  ).bind(musyrifah.id, jadwal.id, today).first<{ id: number; waktu_masuk: string | null; waktu_keluar: string | null }>();

  const jadwalRes = {
    program: jadwal.nama_program,
    hari: jadwal.hari,
    jam_mulai: jadwal.jam_mulai,
    jam_selesai: jadwal.jam_selesai,
  };

  if (inJamMasuk) {
    if (!existing) {
      // Scan masuk → absen masuk
      await env.DB.prepare(`
        INSERT INTO dauroh_absensi_musyrifah (musyrifah_id, jadwal_id, tanggal, waktu_scan, waktu_masuk, status)
        VALUES (?, ?, ?, ?, ?, 'hadir')
      `).bind(musyrifah.id, jadwal.id, today, currentTime, currentTime).run();

      return success({
        action: 'absen_masuk',
        time: currentTime,
        jadwal: jadwalRes,
        message: `Absensi masuk tercatat pukul ${currentTime}`,
      });
    }
    if (existing.waktu_masuk && !existing.waktu_keluar) {
      return error(`Jam masuk sudah tercatat. Jam keluar dibuka pukul ${keluarMulai.slice(0, 5)} WIB.`, 400);
    }
    return error('Anda sudah melakukan absensi masuk dan keluar hari ini', 400);
  }

  // inJamKeluar
  if (!existing || !existing.waktu_masuk) {
    return error('Belum ada absen masuk hari ini', 400);
  }
  if (existing.waktu_masuk && !existing.waktu_keluar) {
    // Scan keluar → absen keluar
    await env.DB.prepare(
      'UPDATE dauroh_absensi_musyrifah SET waktu_keluar = ? WHERE id = ?'
    ).bind(currentTime, existing.id).run();

    return success({
      action: 'absen_keluar',
      time: currentTime,
      jadwal: jadwalRes,
      message: `Absensi keluar tercatat pukul ${currentTime}`,
    });
  }
  return error('Anda sudah melakukan absensi masuk dan keluar hari ini', 400);
}

async function listAbsensiMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const bulan = url.searchParams.get('bulan'); // format: YYYY-MM
  const offset = (page - 1) * perPage;

  let where = 'WHERE am.musyrifah_id = ?';
  const bindings: unknown[] = [musyrifah.id];

  if (bulan) {
    where += ' AND am.tanggal LIKE ?';
    bindings.push(`${bulan}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_absensi_musyrifah am ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT am.*, j.hari, j.jam_mulai, j.jam_selesai, p.nama_program
    FROM dauroh_absensi_musyrifah am
    JOIN dauroh_jadwal j ON am.jadwal_id = j.id
    JOIN dauroh_program p ON j.program_id = p.id
    ${where}
    ORDER BY am.tanggal DESC, j.jam_mulai
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function inputAbsensiSantri(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as { jadwal_id: number; santri_id: number; status: string; keterangan?: string };
  const { jadwal_id, santri_id, status, keterangan } = body;

  if (!jadwal_id || !santri_id || !status) {
    return error('jadwal_id, santri_id, status wajib diisi', 400);
  }

  if (!['hadir', 'izin', 'sakit', 'alpha'].includes(status)) {
    return error('Status harus hadir/izin/sakit/alpha', 400);
  }

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi jadwal
  const jadwal = await env.DB.prepare(`
    SELECT id FROM dauroh_jadwal 
    WHERE id = ? AND (musyrifah_1_id = ? OR musyrifah_2_id = ?) AND is_aktif = 1
  `).bind(jadwal_id, musyrifah.id, musyrifah.id).first();

  if (!jadwal) return error('Jadwal tidak ditemukan atau bukan jadwal Anda', 404);

  const today = wibDate();

  // Upsert absensi
  await env.DB.prepare(`
    INSERT INTO dauroh_absensi_santri (jadwal_id, santri_id, tanggal, status, keterangan)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(jadwal_id, santri_id, tanggal) 
    DO UPDATE SET status = excluded.status, keterangan = excluded.keterangan
  `).bind(jadwal_id, santri_id, today, status, keterangan || null).run();

  return success({ message: `Absensi santri berhasil diinput` });
}

// ============================================================
// SURAT MUSYRIFAH
// ============================================================

async function handleSuratMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/surat - List semua surat
  if (method === 'GET' && pathParts.length === 3) {
    return listSurat(env, url);
  }

  // GET /api/musyrifah/surat/:nomor - Detail surat
  if (method === 'GET' && pathParts.length === 4) {
    const nomor = parseInt(pathParts[3]);
    return getSurat(env, nomor);
  }

  return error('Method tidak didukung', 405);
}

async function listSurat(env: Env, url: URL) {
  const juz = url.searchParams.get('juz');
  const type = url.searchParams.get('type');
  const search = url.searchParams.get('search') || '';

  let where = 'WHERE 1=1';
  const bindings: unknown[] = [];

  if (juz) {
    where += ' AND juz = ?';
    bindings.push(parseInt(juz));
  }
  if (type) {
    where += ' AND type = ?';
    bindings.push(type);
  }
  if (search) {
    where += ' AND (nama LIKE ? OR nama_arab LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }

  const rows = await env.DB.prepare(`
    SELECT nomor, nama, nama_arab, jumlah_ayat, juz, type
    FROM dauroh_surat
    ${where}
    ORDER BY nomor ASC
  `).bind(...bindings).all();

  return success(rows.results);
}

async function getSurat(env: Env, nomor: number) {
  const surat = await env.DB.prepare(`
    SELECT nomor, nama, nama_arab, jumlah_ayat, juz, type
    FROM dauroh_surat
    WHERE nomor = ?
  `).bind(nomor).first<Row>();

  if (!surat) return notFound('Surat');

  return success(surat);
}

// ============================================================
// RIWAYAT SANTRI
// ============================================================

async function handleRiwayatSantri(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/riwayat/:santri_id - Riwayat nilai santri
  if (method === 'GET' && pathParts.length === 4) {
    const santriId = parseInt(pathParts[3]);
    return getRiwayatSantri(env, user, santriId, url);
  }

  return error('Method tidak didukung', 405);
}

async function getRiwayatSantri(env: Env, user: UserPayload, santriId: number, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const programId = url.searchParams.get('program_id');
  const limit = Math.min(100, parseInt(url.searchParams.get('limit') || '50'));

  let where = `WHERE dn.santri_id = ? 
    AND dn.program_id IN (SELECT program_id FROM dauroh_jadwal WHERE musyrifah_1_id = ? OR musyrifah_2_id = ?)`;
  const bindings: unknown[] = [santriId, musyrifah.id, musyrifah.id];

  if (programId) {
    where += ' AND dn.program_id = ?';
    bindings.push(programId);
  }

  const rows = await env.DB.prepare(`
    SELECT 
      dn.id,
      dn.program_id,
      dp.nama_program,
      dp.jenis_program,
      dn.santri_id,
      s.nama as santri_nama,
      dn.surat_nomor,
      ds.nama as surat_nama,
      ds.jumlah_ayat,
      dn.dari_ayat,
      dn.sampai_ayat,
      dn.status_hafalan,
      dn.nilai_bidang1,
      dn.nilai_bidang2,
      dn.nilai_bidang3,
      dn.total_nilai,
      dn.catatan_umum,
      dn.rencana_tindak_lanjut,
      dm.nama as musyrifah_nama,
      dn.created_at,
      dn.updated_at
    FROM dauroh_nilai dn
    JOIN siswa s ON dn.santri_id = s.id
    JOIN dauroh_program dp ON dn.program_id = dp.id
    LEFT JOIN dauroh_surat ds ON dn.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON dn.diinput_oleh = dm.id
    ${where}
    ORDER BY dn.created_at DESC
    LIMIT ?
  `).bind(...bindings, limit).all();

  return success({
    santri_id: santriId,
    riwayat: rows.results,
  });
}

// ============================================================
// NILAI MUSYRIFAH
// ============================================================

async function handleNilaiMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/nilai - List nilai santri
  if (method === 'GET' && pathParts.length === 3) {
    return listNilaiMusyrifah(env, user, url);
  }

  // GET /api/musyrifah/nilai/:id - Detail nilai
  if (method === 'GET' && pathParts.length === 4) {
    const id = parseInt(pathParts[3]);
    return getNilaiDetail(env, user, id);
  }

  // POST /api/musyrifah/nilai - Input nilai baru
  if (method === 'POST' && pathParts.length === 3) {
    return inputNilaiBaru(request, env, user);
  }

  // PUT /api/musyrifah/nilai/:id - Update nilai
  if (method === 'PUT' && pathParts.length === 4) {
    const id = parseInt(pathParts[3]);
    return updateNilaiEnhanched(request, env, id, user);
  }

  return error('Method tidak didukung', 405);
}

async function listNilaiMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const programId = url.searchParams.get('program_id');
  const kelasId = url.searchParams.get('kelas_id');
  const search = url.searchParams.get('search') || '';
  const status = url.searchParams.get('status');

  let where = `WHERE dn.program_id IN (SELECT program_id FROM dauroh_jadwal WHERE musyrifah_1_id = ? OR musyrifah_2_id = ?)`;
  const bindings: unknown[] = [musyrifah.id, musyrifah.id];

  if (programId) {
    where += ' AND dn.program_id = ?';
    bindings.push(programId);
  }
  if (kelasId) {
    where += ' AND s.kelas_id = ?';
    bindings.push(kelasId);
  }
  if (search) {
    where += ' AND (s.nama LIKE ? OR s.nis LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }
  if (status) {
    where += ' AND dn.status_hafalan = ?';
    bindings.push(status);
  }

  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(200, Math.max(1, parseInt(url.searchParams.get('per_page') || '100')));
  const offset = (page - 1) * perPage;

  const totalRow = await env.DB.prepare(`
    SELECT COUNT(*) AS total
    FROM dauroh_nilai dn
    JOIN siswa s ON dn.santri_id = s.id
    ${where}
  `).bind(...bindings).first<{ total: number }>();

  const rows = await env.DB.prepare(`
    SELECT 
      dn.id,
      dn.program_id,
      dp.nama_program,
      dp.jenis_program,
      dp.max_bidang1,
      dp.max_bidang2,
      dp.max_bidang3,
      dp.label_bidang1,
      dp.label_bidang2,
      dp.label_bidang3,
      dn.santri_id,
      s.nis,
      s.nama as santri_nama,
      k.nama as kelas_nama,
      dn.surat_nomor,
      ds.nama as surat_nama,
      ds.jumlah_ayat,
      dn.dari_ayat,
      dn.sampai_ayat,
      dn.status_hafalan,
      dn.kelancaran,
      dn.ketepatan_ayat,
      dn.murojaah_sambung,
      dn.konsistensi_hafalan,
      dn.catatan_bidang1,
      dn.makhorijul_huruf,
      dn.sifatul_huruf,
      dn.ahkamul_huruf,
      dn.ahkamul_madd,
      dn.catatan_bidang2,
      dn.ahkamul_waqfi,
      dn.adabut_tilawah,
      dn.kerapihan_bacaan,
      dn.ketepatan_tempo,
      dn.catatan_bidang3,
      dn.nilai_bidang1,
      dn.nilai_bidang2,
      dn.nilai_bidang3,
      dn.total_nilai,
      dn.catatan_umum,
      dn.rencana_tindak_lanjut,
      dm.nama as musyrifah_nama,
      dn.created_at,
      dn.updated_at
    FROM dauroh_nilai dn
    JOIN siswa s ON dn.santri_id = s.id
    JOIN kelas k ON s.kelas_id = k.id
    JOIN dauroh_program dp ON dn.program_id = dp.id
    LEFT JOIN dauroh_surat ds ON dn.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON dn.diinput_oleh = dm.id
    ${where}
    ORDER BY dp.nama_program, k.nama, s.nama
    LIMIT ? OFFSET ?
  `).bind(...bindings, perPage, offset).all();

  const total = totalRow?.total ?? 0;
  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getNilaiDetail(env: Env, user: UserPayload, id: number) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const nilai = await env.DB.prepare(`
    SELECT 
      dn.*,
      dp.nama_program,
      dp.jenis_program,
      s.nis,
      s.nama as santri_nama,
      k.nama as kelas_nama,
      ds.nama as surat_nama,
      ds.jumlah_ayat,
      dm.nama as musyrifah_nama
    FROM dauroh_nilai dn
    JOIN siswa s ON dn.santri_id = s.id
    JOIN kelas k ON s.kelas_id = k.id
    JOIN dauroh_program dp ON dn.program_id = dp.id
    LEFT JOIN dauroh_surat ds ON dn.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON dn.diinput_oleh = dm.id
    WHERE dn.id = ?
  `).bind(id).first<Row>();

  if (!nilai) return notFound('Data nilai');

  // Validasi akses musyrifah
  const akses = await env.DB.prepare(`
    SELECT 1 FROM dauroh_jadwal j
    WHERE j.program_id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(nilai.program_id, musyrifah.id, musyrifah.id).first();

  if (!akses) return error('Tidak memiliki akses ke data ini', 403);

  return success(nilai);
}

async function inputNilaiBaru(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as {
    program_id: number;
    santri_id: number;
    jadwal_id?: number;
    surat_nomor: number;
    dari_ayat?: number;
    sampai_ayat?: number;
    status_hafalan: string;
    // Bidang 1: Kelancaran Hafalan
    kelancaran?: number;
    ketepatan_ayat?: number;
    murojaah_sambung?: number;
    konsistensi_hafalan?: number;
    catatan_bidang1?: string;
    // Bidang 2: Tajwid
    makhorijul_huruf?: number;
    sifatul_huruf?: number;
    ahkamul_huruf?: number;
    ahkamul_madd?: number;
    catatan_bidang2?: string;
    // Bidang 3: Fashohah dan Adab
    ahkamul_waqfi?: number;
    adabut_tilawah?: number;
    kerapihan_bacaan?: number;
    ketepatan_tempo?: number;
    catatan_bidang3?: string;
    // Catatan
    catatan_umum?: string;
    rencana_tindak_lanjut?: string;
  };

  const {
    program_id, santri_id, jadwal_id, surat_nomor, dari_ayat, sampai_ayat,
    status_hafalan, kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan,
    catatan_bidang1, makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd,
    catatan_bidang2, ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo,
    catatan_bidang3, catatan_umum, rencana_tindak_lanjut
  } = body;

  // Validasi wajib
  if (!program_id || !santri_id || !surat_nomor || !status_hafalan) {
    return badRequest('program_id, santri_id, surat_nomor, status_hafalan wajib diisi');
  }

  // Validasi status_hafalan
  if (!['mengulang', 'melanjutkan', 'selesai'].includes(status_hafalan)) {
    return badRequest('status_hafalan harus mengulang, melanjutkan, atau selesai');
  }

  // Validasi surat
  const surat = await env.DB.prepare('SELECT nomor FROM dauroh_surat WHERE nomor = ?').bind(surat_nomor).first();
  if (!surat) return notFound('Surat');

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi akses program
  const program = await env.DB.prepare(`
    SELECT 1 FROM dauroh_jadwal 
    WHERE program_id = ? AND (musyrifah_1_id = ? OR musyrifah_2_id = ?)
  `).bind(program_id, musyrifah.id, musyrifah.id).first();

  if (!program) return error('Program tidak ditemukan atau bukan program Anda', 404);

  // Validasi jadwal jika disediakan
  if (jadwal_id) {
    const jadwal = await env.DB.prepare(`
      SELECT 1 FROM dauroh_jadwal WHERE id = ? AND program_id = ?
    `).bind(jadwal_id, program_id).first();
    if (!jadwal) return error('Jadwal tidak valid', 400);
  }

  // Insert nilai baru
  const result = await env.DB.prepare(`
    INSERT INTO dauroh_nilai (
      program_id, santri_id, jadwal_id, surat_nomor, dari_ayat, sampai_ayat,
      status_hafalan, kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan,
      catatan_bidang1, makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd,
      catatan_bidang2, ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo,
      catatan_bidang3, catatan_umum, rencana_tindak_lanjut, diinput_oleh
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    program_id, santri_id, jadwal_id || null, surat_nomor, dari_ayat || null, sampai_ayat || null,
    status_hafalan, kelancaran || null, ketepatan_ayat || null, murojaah_sambung || null, konsistensi_hafalan || null,
    catatan_bidang1 || null, makhorijul_huruf || null, sifatul_huruf || null, ahkamul_huruf || null, ahkamul_madd || null,
    catatan_bidang2 || null, ahkamul_waqfi || null, adabut_tilawah || null, kerapihan_bacaan || null, ketepatan_tempo || null,
    catatan_bidang3 || null, catatan_umum || null, rencana_tindak_lanjut || null, musyrifah.id
  ).run();

  const newId = result.meta.last_row_id;

  // Hitung total_nilai
  const totalNilai = (44 - (kelancaran || 0) - (ketepatan_ayat || 0) - (murojaah_sambung || 0) - (konsistensi_hafalan || 0)) +
    (34 - (makhorijul_huruf || 0) - (sifatul_huruf || 0) - (ahkamul_huruf || 0) - (ahkamul_madd || 0)) +
    (34 - (ahkamul_waqfi || 0) - (adabut_tilawah || 0) - (kerapihan_bacaan || 0) - (ketepatan_tempo || 0));

  return success({ 
    id: newId,
    message: 'Nilai berhasil disimpan',
    total_nilai: totalNilai
  });
}

async function updateNilaiEnhanched(request: Request, env: Env, id: number, user: UserPayload) {
  const body = await request.json() as {
    jadwal_id?: number;
    surat_nomor?: number;
    dari_ayat?: number;
    sampai_ayat?: number;
    status_hafalan?: string;
    kelancaran?: number;
    ketepatan_ayat?: number;
    murojaah_sambung?: number;
    konsistensi_hafalan?: number;
    catatan_bidang1?: string;
    makhorijul_huruf?: number;
    sifatul_huruf?: number;
    ahkamul_huruf?: number;
    ahkamul_madd?: number;
    catatan_bidang2?: string;
    ahkamul_waqfi?: number;
    adabut_tilawah?: number;
    kerapihan_bacaan?: number;
    ketepatan_tempo?: number;
    catatan_bidang3?: string;
    catatan_umum?: string;
    rencana_tindak_lanjut?: string;
  };

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi nilai
  const existing = await env.DB.prepare(`
    SELECT n.id, n.program_id FROM dauroh_nilai n
    WHERE n.id = ?
  `).bind(id).first<{ id: number; program_id: number }>();

  if (!existing) return notFound('Data nilai');

  // Validasi akses
  const akses = await env.DB.prepare(`
    SELECT 1 FROM dauroh_jadwal j
    WHERE j.program_id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(existing.program_id, musyrifah.id, musyrifah.id).first();

  if (!akses) return error('Tidak memiliki akses ke data ini', 403);

  await env.DB.prepare(`
    UPDATE dauroh_nilai SET
      jadwal_id = COALESCE(?, jadwal_id),
      surat_nomor = COALESCE(?, surat_nomor),
      dari_ayat = COALESCE(?, dari_ayat),
      sampai_ayat = COALESCE(?, sampai_ayat),
      status_hafalan = COALESCE(?, status_hafalan),
      kelancaran = COALESCE(?, kelancaran),
      ketepatan_ayat = COALESCE(?, ketepatan_ayat),
      murojaah_sambung = COALESCE(?, murojaah_sambung),
      konsistensi_hafalan = COALESCE(?, konsistensi_hafalan),
      catatan_bidang1 = COALESCE(?, catatan_bidang1),
      makhorijul_huruf = COALESCE(?, makhorijul_huruf),
      sifatul_huruf = COALESCE(?, sifatul_huruf),
      ahkamul_huruf = COALESCE(?, ahkamul_huruf),
      ahkamul_madd = COALESCE(?, ahkamul_madd),
      catatan_bidang2 = COALESCE(?, catatan_bidang2),
      ahkamul_waqfi = COALESCE(?, ahkamul_waqfi),
      adabut_tilawah = COALESCE(?, adabut_tilawah),
      kerapihan_bacaan = COALESCE(?, kerapihan_bacaan),
      ketepatan_tempo = COALESCE(?, ketepatan_tempo),
      catatan_bidang3 = COALESCE(?, catatan_bidang3),
      catatan_umum = COALESCE(?, catatan_umum),
      rencana_tindak_lanjut = COALESCE(?, rencana_tindak_lanjut),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(
    body.jadwal_id, body.surat_nomor, body.dari_ayat, body.sampai_ayat,
    body.status_hafalan, body.kelancaran, body.ketepatan_ayat, body.murojaah_sambung, body.konsistensi_hafalan,
    body.catatan_bidang1, body.makhorijul_huruf, body.sifatul_huruf, body.ahkamul_huruf, body.ahkamul_madd,
    body.catatan_bidang2, body.ahkamul_waqfi, body.adabut_tilawah, body.kerapihan_bacaan, body.ketepatan_tempo,
    body.catatan_bidang3, body.catatan_umum, body.rencana_tindak_lanjut, id
  ).run();

  // Hitung total_nilai
  const updated = await env.DB.prepare('SELECT * FROM dauroh_nilai WHERE id = ?').bind(id).first<Row>();
  const totalNilai = updated ? 
    (44 - ((updated.kelancaran as number) || 0) - ((updated.ketepatan_ayat as number) || 0) - ((updated.murojaah_sambung as number) || 0) - ((updated.konsistensi_hafalan as number) || 0)) +
    (34 - ((updated.makhorijul_huruf as number) || 0) - ((updated.sifatul_huruf as number) || 0) - ((updated.ahkamul_huruf as number) || 0) - ((updated.ahkamul_madd as number) || 0)) +
    (34 - ((updated.ahkamul_waqfi as number) || 0) - ((updated.adabut_tilawah as number) || 0) - ((updated.kerapihan_bacaan as number) || 0) - ((updated.ketepatan_tempo as number) || 0))
    : null;

  return success({ 
    id, 
    message: 'Nilai berhasil diupdate',
    total_nilai: totalNilai
  });
}

// ============================================================
// SANTRI BY JADWAL
// ============================================================

async function listSantriByJadwal(env: Env, user: UserPayload, url: URL) {
  const jadwalId = parseInt(url.searchParams.get('jadwal_id') || '0');
  if (!jadwalId) return badRequest('jadwal_id wajib diisi');

  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Pastikan jadwal ini milik musyrifah
  const jadwal = await env.DB.prepare(`
    SELECT j.id FROM dauroh_jadwal j
    WHERE j.id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(jadwalId, musyrifah.id, musyrifah.id).first<{ id: number }>();

  if (!jadwal) return error('Jadwal tidak ditemukan atau bukan milik Anda', 404);

  // Ambil kelas dari jadwal
  const kelasList = await env.DB.prepare(`
    SELECT kelas_id FROM dauroh_jadwal_kelas WHERE jadwal_id = ?
  `).bind(jadwalId).all<{ kelas_id: number }>();

  if (kelasList.results.length === 0) return success([]);

  const kelasIds = kelasList.results.map(k => k.kelas_id);
  const placeholders = kelasIds.map(() => '?').join(',');

  // Ambil santri dari kelas-kelas tersebut
  const santri = await env.DB.prepare(`
    SELECT id, nama, nis FROM siswa 
    WHERE kelas_id IN (${placeholders}) AND status = 'aktif'
    ORDER BY nama
  `).bind(...kelasIds).all<{ id: number; nama: string; nis: string }>();

  return success(santri.results);
}
