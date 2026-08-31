import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest, error } from '../../utils/response';

const JP_SLOTS: { kode: string; mulai: string; selesai: string; tipe: string }[] = [
  { kode: 'JP1', mulai: '07:00', selesai: '07:40', tipe: 'pelajaran' },
  { kode: 'JP2', mulai: '07:40', selesai: '08:20', tipe: 'pelajaran' },
  { kode: 'JP3', mulai: '08:20', selesai: '09:00', tipe: 'pelajaran' },
  { kode: 'JP4', mulai: '09:00', selesai: '09:20', tipe: 'istirahat' },
  { kode: 'JP5', mulai: '09:20', selesai: '09:40', tipe: 'pelajaran' },
  { kode: 'JP6', mulai: '09:40', selesai: '10:00', tipe: 'istirahat' },
  { kode: 'JP7', mulai: '10:00', selesai: '10:40', tipe: 'pelajaran' },
  { kode: 'JP8', mulai: '10:40', selesai: '11:20', tipe: 'pelajaran' },
  { kode: 'JP9', mulai: '11:20', selesai: '12:00', tipe: 'pelajaran' },
  { kode: 'JP10', mulai: '12:00', selesai: '12:40', tipe: 'istirahat' },
  { kode: 'JP11', mulai: '12:40', selesai: '13:20', tipe: 'pelajaran' },
  { kode: 'JP12', mulai: '13:20', selesai: '14:00', tipe: 'pelajaran' },
];
const HARI = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
const JP_PER_HARI = 12;
const KEGIATAN_TETAP = [
  { nama: 'Istirahat RG', tipe: 'istirahat' },
  { nama: 'Istirahat UG', tipe: 'istirahat' },
  { nama: 'Tahfidz & Tahsin', tipe: 'kegiatan' },
  { nama: 'Murojaah', tipe: 'kegiatan' },
  { nama: "Ba'at", tipe: 'kegiatan' },
];

export async function handlePenjadwalan(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // ── JP Slots ──
  if (subPath === 'jp-slots' && request.method === 'GET') {
    const rows = await env.DB.prepare('SELECT kode, mulai, selesai, tipe FROM jp_slot ORDER BY urutan')
      .all<{ kode: string; mulai: string; selesai: string; tipe: string }>();
    const slots = rows.results.length > 0
      ? rows.results
      : JP_SLOTS.map(s => ({ ...s }));
    return success(slots);
  }

  // ── Tambah JP Slot (manual) ──
  if (subPath === 'jp-slots' && request.method === 'POST') {
    const body = await request.json() as { mulai?: string; selesai?: string };
    const mulai = body.mulai?.trim() ?? '';
    const selesai = body.selesai?.trim() ?? '';

    if (!/^\d{2}:\d{2}$/.test(mulai) || !/^\d{2}:\d{2}$/.test(selesai)) {
      return badRequest('Format waktu harus HH:MM (contoh: 07:00)');
    }
    if (mulai >= selesai) {
      return badRequest('Jam mulai harus lebih awal dari jam selesai');
    }

    const existingTime = await env.DB.prepare('SELECT kode FROM jp_slot WHERE mulai = ?').bind(mulai).first<{ kode: string }>();
    if (existingTime) {
      return badRequest(`Waktu mulai ${mulai} sudah dipakai oleh ${existingTime.kode}. Gunakan waktu mulai yang berbeda.`);
    }

    const maxRow = await env.DB.prepare('SELECT MAX(urutan) AS maxUrt FROM jp_slot').first<{ maxUrt: number }>();
    const nextUrutan = (maxRow?.maxUrt ?? 0) + 1;
    const kode = `JP${nextUrutan}`;

    await env.DB.prepare('INSERT OR IGNORE INTO jp_slot (kode, mulai, selesai, urutan) VALUES (?, ?, ?, ?)')
      .bind(kode, mulai, selesai, nextUrutan).run();
    return created({ kode, mulai, selesai });
  }

  // ── Update Waktu JP Slot ──
  if (subPath.startsWith('jp-slots/') && request.method === 'PUT') {
    const kode = subPath.split('/')[1];
    const body = await request.json() as { mulai?: string; selesai?: string };
    const mulai = body.mulai?.trim() ?? '';
    const selesai = body.selesai?.trim() ?? '';

    if (!/^\d{2}:\d{2}$/.test(mulai) || !/^\d{2}:\d{2}$/.test(selesai)) {
      return badRequest('Format waktu harus HH:MM (contoh: 07:00)');
    }
    if (mulai >= selesai) {
      return badRequest('Jam mulai harus lebih awal dari jam selesai');
    }

    const existing = await env.DB.prepare('SELECT mulai, selesai FROM jp_slot WHERE kode = ?').bind(kode).first<{ mulai: string; selesai: string }>();
    if (!existing) return notFound('JP Slot');

    const existingTime = await env.DB.prepare('SELECT kode FROM jp_slot WHERE mulai = ? AND kode != ?').bind(mulai, kode).first<{ kode: string }>();
    if (existingTime) {
      return badRequest(`Waktu mulai ${mulai} sudah dipakai oleh ${existingTime.kode}. Gunakan waktu mulai yang berbeda.`);
    }

    await env.DB.prepare('UPDATE jp_slot SET mulai = ?, selesai = ? WHERE kode = ?')
      .bind(mulai, selesai, kode).run();

    // Sinkronkan waktu ke SEMUA entri jadwal yang memakai waktu lama (semua kelas & semester)
    const sync = await env.DB.prepare(
      'UPDATE jadwal_pelajaran SET jam_mulai = ?, jam_selesai = ? WHERE jam_mulai = ? AND jam_selesai = ?'
    ).bind(mulai, selesai, existing.mulai, existing.selesai).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'jp_slot', ?, ?)"
    ).bind(user.sub, `Ubah waktu ${kode} dari ${existing.mulai}-${existing.selesai} ke ${mulai}-${selesai} (${sync.meta?.changes ?? 0} jadwal disinkronkan)`, ip).run();

    return success({ kode, mulai, selesai, jadwal_synced: sync.meta?.changes ?? 0 });
  }

  // ── Hapus JP Slot ──
  if (subPath.startsWith('jp-slots/') && request.method === 'DELETE') {
    const kode = subPath.split('/')[1];

    const existing = await env.DB.prepare('SELECT mulai, selesai FROM jp_slot WHERE kode = ?').bind(kode).first<{ mulai: string; selesai: string }>();
    if (!existing) return notFound('JP Slot');

    // Proteksi: jangan hapus jika masih ada jadwal (draft/tervalidasi) yang memakai jam ini
    const used = await env.DB.prepare(
      'SELECT COUNT(*) AS total FROM jadwal_pelajaran WHERE jam_mulai = ? AND jam_selesai = ?'
    ).bind(existing.mulai, existing.selesai).first<{ total: number }>();
    const usedTotal = used?.total ?? 0;
    if (usedTotal > 0) {
      return badRequest(`Slot ${kode} masih dipakai ${usedTotal} jadwal. Ubah waktu slot tersebut atau hapus jadwal terkait terlebih dahulu.`);
    }

    await env.DB.prepare('DELETE FROM jp_slot WHERE kode = ?').bind(kode).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'jp_slot', ?, ?)"
    ).bind(user.sub, `Hapus JP slot ${kode} (${existing.mulai}-${existing.selesai})`, ip).run();

    return success({ kode });
  }

  // ── Kegiatan Tetap ──
  if (subPath === 'kegiatan-tetap' && request.method === 'GET') {
    const rows = await env.DB.prepare('SELECT id, nama, tipe FROM kegiatan_tetap ORDER BY urutan, id')
      .all<{ id: number; nama: string; tipe: string }>();
    return success(rows.results.length > 0 ? rows.results : KEGIATAN_TETAP);
  }

  // ── Tambah Kegiatan Tetap ──
  if (subPath === 'kegiatan-tetap' && request.method === 'POST') {
    const body = await request.json() as { nama?: string; tipe?: string };
    const nama = body.nama?.trim() ?? '';
    const tipe = body.tipe === 'istirahat' ? 'istirahat' : 'kegiatan';

    if (!nama) return badRequest('Nama kegiatan tidak boleh kosong');
    if (nama.length > 100) return badRequest('Nama kegiatan maksimal 100 karakter');

    const maxRow = await env.DB.prepare('SELECT MAX(urutan) AS maxUrt FROM kegiatan_tetap').first<{ maxUrt: number | null }>();
    const urutan = (maxRow?.maxUrt ?? 0) + 1;

    const res = await env.DB.prepare('INSERT INTO kegiatan_tetap (nama, tipe, urutan) VALUES (?, ?, ?)')
      .bind(nama, tipe, urutan).run();
    const id = Number(res.meta?.last_row_id);

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'kegiatan_tetap', ?, ?)"
    ).bind(user.sub, `Tambah kegiatan tetap: ${nama}`, ip).run();

    return created({ id, nama, tipe });
  }

  // ── Update Kegiatan Tetap ──
  if (subPath.startsWith('kegiatan-tetap/') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1], 10);
    if (!Number.isInteger(id)) return badRequest('ID kegiatan tidak valid');

    const existing = await env.DB.prepare('SELECT nama FROM kegiatan_tetap WHERE id = ?').bind(id).first<{ nama: string }>();
    if (!existing) return notFound('Kegiatan Tetap');

    const body = await request.json() as { nama?: string; tipe?: string };
    const nama = body.nama?.trim() ?? '';
    const tipe = body.tipe === 'istirahat' ? 'istirahat' : 'kegiatan';

    if (!nama) return badRequest('Nama kegiatan tidak boleh kosong');
    if (nama.length > 100) return badRequest('Nama kegiatan maksimal 100 karakter');

    await env.DB.prepare('UPDATE kegiatan_tetap SET nama = ?, tipe = ? WHERE id = ?')
      .bind(nama, tipe, id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'kegiatan_tetap', ?, ?)"
    ).bind(user.sub, `Ubah kegiatan tetap: ${existing.nama} → ${nama}`, ip).run();

    return success({ id, nama, tipe });
  }

  // ── Hapus Kegiatan Tetap ──
  if (subPath.startsWith('kegiatan-tetap/') && request.method === 'DELETE') {
    const id = parseInt(subPath.split('/')[1], 10);
    if (!Number.isInteger(id)) return badRequest('ID kegiatan tidak valid');

    const existing = await env.DB.prepare('SELECT nama FROM kegiatan_tetap WHERE id = ?').bind(id).first<{ nama: string }>();
    if (!existing) return notFound('Kegiatan Tetap');

    await env.DB.prepare('DELETE FROM kegiatan_tetap WHERE id = ?').bind(id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'kegiatan_tetap', ?, ?)"
    ).bind(user.sub, `Hapus kegiatan tetap: ${existing.nama}`, ip).run();

    return success({ id });
  }

  // ── Kelas Gabungan ──
  if (subPath === 'kelas-gabungan' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT kg.id, kg.nama, kg.semester_id, kg.tingkat_id,
              COALESCE((SELECT GROUP_CONCAT(k.nama, ', ') FROM kelas_gabungan_anggota kga
                         JOIN kelas k ON k.id = kga.kelas_id
                        WHERE kga.gabungan_id = kg.id ORDER BY kga.id), '') as kelas_nama
       FROM kelas_gabungan kg
       ORDER BY kg.id`
    ).all();

    const anggotaRows = await env.DB.prepare(
      'SELECT gabungan_id, kelas_id FROM kelas_gabungan_anggota ORDER BY id'
    ).all<{ gabungan_id: number; kelas_id: number }>();
    const kelasMap = new Map<number, number[]>();
    for (const a of anggotaRows.results) {
      if (!kelasMap.has(a.gabungan_id)) kelasMap.set(a.gabungan_id, []);
      kelasMap.get(a.gabungan_id)!.push(a.kelas_id);
    }

    return success(rows.results.map((g: any) => ({ ...g, kelas_ids: kelasMap.get(g.id) || [] })));
  }

  // ── Tambah Kelas Gabungan ──
  if (subPath === 'kelas-gabungan' && request.method === 'POST') {
    const body = await request.json() as { nama?: string; semester_id?: number; tingkat_id?: number; kelas_ids?: number[] };
    const nama = body.nama?.trim() ?? '';
    const semesterId = body.semester_id;
    const kelasIds = Array.isArray(body.kelas_ids)
      ? body.kelas_ids.filter((x) => Number.isInteger(x) && x > 0)
      : [];

    if (!nama) return badRequest('Nama gabungan tidak boleh kosong');
    if (nama.length > 100) return badRequest('Nama gabungan maksimal 100 karakter');
    if (!semesterId) return badRequest('semester_id diperlukan');
    if (kelasIds.length < 2) return badRequest('Pilih minimal 2 kelas untuk digabung');

    const placeholders = kelasIds.map(() => '?').join(',');
    const kelasRows = await env.DB.prepare(`SELECT id FROM kelas WHERE id IN (${placeholders})`).bind(...kelasIds).all<{ id: number }>();
    if (kelasRows.results.length !== kelasIds.length) return badRequest('Ada kelas yang tidak ditemukan');

    const res = await env.DB.prepare('INSERT INTO kelas_gabungan (nama, semester_id, tingkat_id) VALUES (?, ?, ?)')
      .bind(nama, semesterId, body.tingkat_id ?? null).run();
    const gabId = Number(res.meta?.last_row_id);

    for (const kid of kelasIds) {
      await env.DB.prepare('INSERT INTO kelas_gabungan_anggota (gabungan_id, kelas_id) VALUES (?, ?)').bind(gabId, kid).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'kelas_gabungan', ?, ?)"
    ).bind(user.sub, `Tambah gabungan: ${nama} (${kelasIds.length} kelas)`, ip).run();

    return created({ id: gabId, nama, semester_id: semesterId, kelas_ids: kelasIds });
  }

  // ── Update Kelas Gabungan ──
  if (subPath.startsWith('kelas-gabungan/') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1], 10);
    if (!Number.isInteger(id)) return badRequest('ID gabungan tidak valid');

    const existing = await env.DB.prepare('SELECT nama FROM kelas_gabungan WHERE id = ?').bind(id).first<{ nama: string }>();
    if (!existing) return notFound('Kelas Gabungan');

    const body = await request.json() as { nama?: string; kelas_ids?: number[] };
    if (body.nama !== undefined) {
      const nama = body.nama.trim();
      if (!nama) return badRequest('Nama gabungan tidak boleh kosong');
      if (nama.length > 100) return badRequest('Nama gabungan maksimal 100 karakter');
      await env.DB.prepare('UPDATE kelas_gabungan SET nama = ? WHERE id = ?').bind(nama, id).run();
    }

    if (Array.isArray(body.kelas_ids)) {
      const kelasIds = body.kelas_ids.filter((x) => Number.isInteger(x) && x > 0);
      if (kelasIds.length < 2) return badRequest('Pilih minimal 2 kelas untuk digabung');

      const placeholders = kelasIds.map(() => '?').join(',');
      const kelasRows = await env.DB.prepare(`SELECT id FROM kelas WHERE id IN (${placeholders})`).bind(...kelasIds).all<{ id: number }>();
      if (kelasRows.results.length !== kelasIds.length) return badRequest('Ada kelas yang tidak ditemukan');

      await env.DB.prepare('DELETE FROM kelas_gabungan_anggota WHERE gabungan_id = ?').bind(id).run();
      for (const kid of kelasIds) {
        await env.DB.prepare('INSERT INTO kelas_gabungan_anggota (gabungan_id, kelas_id) VALUES (?, ?)').bind(id, kid).run();
      }
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'kelas_gabungan', ?, ?)"
    ).bind(user.sub, `Ubah gabungan id=${id}`, ip).run();

    return success({ id });
  }

  // ── Hapus Kelas Gabungan ──
  if (subPath.startsWith('kelas-gabungan/') && request.method === 'DELETE') {
    const id = parseInt(subPath.split('/')[1], 10);
    if (!Number.isInteger(id)) return badRequest('ID gabungan tidak valid');

    const existing = await env.DB.prepare('SELECT nama FROM kelas_gabungan WHERE id = ?').bind(id).first<{ nama: string }>();
    if (!existing) return notFound('Kelas Gabungan');

    // Jadwal milik gabungan dilepas (gabungan_id = NULL), data tidak dihapus
    await env.DB.prepare('UPDATE jadwal_pelajaran SET gabungan_id = NULL WHERE gabungan_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM kelas_gabungan_anggota WHERE gabungan_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM kelas_gabungan WHERE id = ?').bind(id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'kelas_gabungan', ?, ?)"
    ).bind(user.sub, `Hapus gabungan: ${existing.nama}`, ip).run();

    return success({ id });
  }

  // ── Referensi ──
  if (subPath === 'referensi' && request.method === 'GET') {
    const [kelas, guru, mapel, ruangan, semester, tingkat, guruMapel, tahunAjaran, kegiatanTetap, kelasGabungan, guruMapelTingkat] = await Promise.all([
      env.DB.prepare('SELECT id, nama, ruangan_id, tingkat_id FROM kelas ORDER BY nama').all(),
      env.DB.prepare("SELECT DISTINCT g.id, g.nama, g.nip FROM guru g INNER JOIN guru_mapel gm ON g.id = gm.guru_id WHERE g.status_aktif = 1 ORDER BY g.nama").all(),
      env.DB.prepare('SELECT id, nama, kode FROM mata_pelajaran ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama FROM ruangan ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama, tahun_ajaran_id FROM semester ORDER BY tahun_ajaran_id DESC, id').all(),
      env.DB.prepare('SELECT id, nama FROM tingkat ORDER BY nama').all(),
      env.DB.prepare(
        `SELECT gm.guru_id, gm.mata_pelajaran_id, g.nama AS guru_nama, g.nip, mp.nama AS mapel_nama, mp.kode AS mapel_kode
         FROM guru_mapel gm
         INNER JOIN guru g ON g.id = gm.guru_id
         INNER JOIN mata_pelajaran mp ON mp.id = gm.mata_pelajaran_id
         WHERE g.status_aktif = 1
         ORDER BY mp.nama, g.nama`
      ).all(),
      env.DB.prepare('SELECT id, nama FROM tahun_ajaran ORDER BY id DESC').all(),
      env.DB.prepare('SELECT id, nama, tipe FROM kegiatan_tetap ORDER BY urutan, id').all(),
      env.DB.prepare(
        `SELECT kg.id, kg.nama, kg.semester_id, kg.tingkat_id,
                COALESCE((SELECT GROUP_CONCAT(k.nama, ', ') FROM kelas_gabungan_anggota kga
                           JOIN kelas k ON k.id = kga.kelas_id
                          WHERE kga.gabungan_id = kg.id ORDER BY kga.id), '') as kelas_nama
         FROM kelas_gabungan kg
         ORDER BY kg.id`
      ).all(),
      // Tingkat per (guru, mapel): prioritas guru_mapel_kelas (spesifik) +
      // fallback guru_kelas × mapel_kelas. Dipakai untuk filter "Daftar Mapel" per tingkat.
      env.DB.prepare(
        `SELECT guru_id, mata_pelajaran_id, tingkat_id FROM (
           SELECT DISTINCT gmk.guru_id, gmk.mata_pelajaran_id, k.tingkat_id
           FROM guru_mapel_kelas gmk
           JOIN kelas k ON k.id = gmk.kelas_id
           UNION
           SELECT DISTINCT gm.guru_id, gm.mata_pelajaran_id, k.tingkat_id
           FROM guru_mapel gm
           JOIN guru_kelas gk ON gk.guru_id = gm.guru_id
           JOIN kelas k ON k.id = gk.kelas_id
           JOIN mapel_kelas mk ON mk.kelas_id = k.id AND mk.mata_pelajaran_id = gm.mata_pelajaran_id
         )`
      ).all<{ guru_id: number; mata_pelajaran_id: number; tingkat_id: number }>(),
    ]);

    // Ambil mapel per kelas dari mapel_kelas
    const mapelKelasRows = await env.DB.prepare(
      'SELECT kelas_id, mata_pelajaran_id FROM mapel_kelas'
    ).all<{ kelas_id: number; mata_pelajaran_id: number }>();
    const kelasMapelMap = new Map<number, number[]>();
    for (const row of mapelKelasRows.results) {
      if (!kelasMapelMap.has(row.kelas_id)) kelasMapelMap.set(row.kelas_id, []);
      kelasMapelMap.get(row.kelas_id)!.push(row.mata_pelajaran_id);
    }
    const kelasWithMapel = kelas.results.map((k: any) => ({
      ...k,
      mapel_ids: kelasMapelMap.get(k.id) || [],
    }));

    // Kelas id per gabungan
    const gabAnggotaRows = await env.DB.prepare(
      'SELECT gabungan_id, kelas_id FROM kelas_gabungan_anggota ORDER BY id'
    ).all<{ gabungan_id: number; kelas_id: number }>();
    const gabKelasMap = new Map<number, number[]>();
    for (const a of gabAnggotaRows.results) {
      if (!gabKelasMap.has(a.gabungan_id)) gabKelasMap.set(a.gabungan_id, []);
      gabKelasMap.get(a.gabungan_id)!.push(a.kelas_id);
    }
    const kelasGabunganWithAnggota = kelasGabungan.results.map((g: any) => ({
      ...g,
      kelas_ids: gabKelasMap.get(g.id) || [],
    }));

    // tingkat_ids per (guru, mapel) agar "Daftar Mapel" bisa difilter per tingkat
    const guruMapelTingkatMap = new Map<string, number[]>();
    for (const r of guruMapelTingkat.results) {
      const key = `${r.guru_id}|${r.mata_pelajaran_id}`;
      if (!guruMapelTingkatMap.has(key)) guruMapelTingkatMap.set(key, []);
      const list = guruMapelTingkatMap.get(key)!;
      if (!list.includes(r.tingkat_id)) list.push(r.tingkat_id);
    }
    const guruMapelWithTingkat = guruMapel.results.map((gm: any) => ({
      ...gm,
      tingkat_ids: guruMapelTingkatMap.get(`${gm.guru_id}|${gm.mata_pelajaran_id}`) || [],
    }));

    return success({ kelas: kelasWithMapel, guru: guru.results, mapel: mapel.results, ruangan: ruangan.results, semester: semester.results, tingkat: tingkat.results, hari: HARI, guru_mapel: guruMapelWithTingkat, tahun_ajaran: tahunAjaran.results, kegiatan_tetap: kegiatanTetap.results.length > 0 ? kegiatanTetap.results : KEGIATAN_TETAP, kelas_gabungan: kelasGabunganWithAnggota });
  }

  // ── Guru by Kelas + Mapel ──
  if (subPath === 'guru-by-kelas-mapel' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    if (!kelasId || !mapelId) return badRequest('kelas_id dan mata_pelajaran_id diperlukan');

    // Prioritas: gunakan guru_mapel_kelas (spesifik), fallback ke guru_mapel × guru_kelas
    const rowsSpesifik = await env.DB.prepare(
      `SELECT DISTINCT g.id, g.nama, g.nip
       FROM guru g
       INNER JOIN guru_mapel_kelas gmk ON g.id = gmk.guru_id
       WHERE gmk.mata_pelajaran_id = ? AND gmk.kelas_id = ? AND g.status_aktif = 1
       ORDER BY g.nip ASC`
    ).bind(parseInt(mapelId), parseInt(kelasId)).all();

    // Jika ada data spesifik, gunakan itu
    if (rowsSpesifik.results.length > 0) {
      return success(rowsSpesifik.results);
    }

    // Fallback: gunakan guru_mapel × guru_kelas (cross join)
    const rowsFallback = await env.DB.prepare(
      `SELECT DISTINCT g.id, g.nama, g.nip
       FROM guru g
       INNER JOIN guru_kelas gk ON g.id = gk.guru_id AND gk.kelas_id = ?
       INNER JOIN guru_mapel gm ON g.id = gm.guru_id AND gm.mata_pelajaran_id = ?
       WHERE g.status_aktif = 1
       ORDER BY g.nip ASC`
    ).bind(parseInt(kelasId), parseInt(mapelId)).all();

    return success(rowsFallback.results);
  }

  // ═══════════════════════════════════════════════
  // KESIAPAN MENGAJAR GURU
  // ═══════════════════════════════════════════════

  // GET /kesiapan — daftar semua guru + kesiapan
  if (subPath === 'kesiapan' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');
    if (!semesterId) return badRequest('semester_id diperlukan');

    const guruList = await env.DB.prepare(
      `SELECT g.id, g.nip, g.nama, g.jabatan,
              gmp.hari_aktif, gmp.jp_max_per_hari, gmp.jp_max_per_minggu,
              COALESCE((SELECT json_group_array(json_object('kelas_id', gk.kelas_id, 'kelas_nama', k.nama))
                        FROM guru_kelas gk
                        LEFT JOIN kelas k ON gk.kelas_id = k.id
                        WHERE gk.guru_id = g.id), '[]') as kelas_diampu,
              COALESCE((SELECT json_group_array(json_object('mapel_id', gm.mata_pelajaran_id, 'mapel_nama', mp.nama))
                        FROM guru_mapel gm
                        LEFT JOIN mata_pelajaran mp ON gm.mata_pelajaran_id = mp.id
                        WHERE gm.guru_id = g.id), '[]') as mapel_diampu
       FROM guru g
       INNER JOIN guru_mapel gm ON g.id = gm.guru_id
       LEFT JOIN guru_mata_pelajaran gmp ON g.id = gmp.guru_id AND gmp.semester_id = ?
       WHERE g.status_aktif = 1
       GROUP BY g.id
       ORDER BY g.nip ASC`
    ).bind(parseInt(semesterId)).all();

    return success(guruList.results);
  }

  // PUT /kesiapan/:guru_id — upsert kesiapan per guru
  if (subPath.startsWith('kesiapan/') && request.method === 'PUT') {
    const pathParts_local = subPath.split('/');
    const guruId = parseInt(pathParts_local[1]);
    if (!guruId) return badRequest('guru_id tidak valid');

    const body = await request.json() as {
      semester_id: number;
      hari_aktif?: string[];
      jp_max_per_hari?: number;
      jp_max_per_minggu?: number;
    };

    if (!body.semester_id) return badRequest('semester_id diperlukan');

    const hariAktif = JSON.stringify(body.hari_aktif || []);
    const jpMaxHari = body.jp_max_per_hari || 8;
    const jpMaxMinggu = body.jp_max_per_minggu || 24;

    // Cek apakah sudah ada baris kesiapan untuk guru+semester ini
    const existing = await env.DB.prepare(
      `SELECT id FROM guru_mata_pelajaran WHERE guru_id = ? AND semester_id = ? AND hari_aktif IS NOT NULL AND hari_aktif != '[]'`
    ).bind(guruId, body.semester_id).first<{ id: number }>();

    if (existing) {
      await env.DB.prepare(
        `UPDATE guru_mata_pelajaran SET hari_aktif = ?, jp_max_per_hari = ?, jp_max_per_minggu = ? WHERE id = ?`
      ).bind(hariAktif, jpMaxHari, jpMaxMinggu, existing.id).run();
    } else {
      await env.DB.prepare(
        `INSERT INTO guru_mata_pelajaran (guru_id, semester_id, hari_aktif, jp_max_per_hari, jp_max_per_minggu, mata_pelajaran_id, kelas_id)
         VALUES (?, ?, ?, ?, ?, NULL, NULL)`
      ).bind(guruId, body.semester_id, hariAktif, jpMaxHari, jpMaxMinggu).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'kesiapan', ?, ?)"
    ).bind(user.sub, `Update kesiapan guru id=${guruId} semester=${body.semester_id}`, ip).run();

    return success({ guru_id: guruId, semester_id: body.semester_id });
  }

  // PUT /kesiapan — batch upsert
  if (subPath === 'kesiapan' && request.method === 'PUT') {
    const body = await request.json() as {
      semester_id: number;
      data: { guru_id: number; hari_aktif: string[]; jp_max_per_hari: number; jp_max_per_minggu: number }[];
    };

    if (!body.semester_id || !Array.isArray(body.data)) {
      return badRequest('semester_id dan data array diperlukan');
    }

    let updated = 0;
    for (const item of body.data) {
      const hariAktif = JSON.stringify(item.hari_aktif || []);
      const jpMaxHari = item.jp_max_per_hari || 8;
      const jpMaxMinggu = item.jp_max_per_minggu || 24;

      const existing = await env.DB.prepare(
        `SELECT id FROM guru_mata_pelajaran WHERE guru_id = ? AND semester_id = ? AND hari_aktif IS NOT NULL AND hari_aktif != '[]'`
      ).bind(item.guru_id, body.semester_id).first<{ id: number }>();

      if (existing) {
        await env.DB.prepare(
          `UPDATE guru_mata_pelajaran SET hari_aktif = ?, jp_max_per_hari = ?, jp_max_per_minggu = ? WHERE id = ?`
        ).bind(hariAktif, jpMaxHari, jpMaxMinggu, existing.id).run();
      } else {
        await env.DB.prepare(
          `INSERT INTO guru_mata_pelajaran (guru_id, semester_id, hari_aktif, jp_max_per_hari, jp_max_per_minggu, mata_pelajaran_id, kelas_id)
           VALUES (?, ?, ?, ?, ?, NULL, NULL)`
        ).bind(item.guru_id, body.semester_id, hariAktif, jpMaxHari, jpMaxMinggu).run();
      }
      updated++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'batch_update', 'kesiapan', ?, ?)"
    ).bind(user.sub, `Batch update ${updated} kesiapan guru semester=${body.semester_id}`, ip).run();

    return success({ updated });
  }

  // ═══════════════════════════════════════════════
  // JADWAL
  // ═══════════════════════════════════════════════

  // Jadwal per kelas
  if (subPath === 'jadwal-per-kelas' && request.method === 'GET') {
    try {
      const kelasId = url.searchParams.get('kelas_id');
      const semesterId = url.searchParams.get('semester_id');
      if (!kelasId || !semesterId) return badRequest('kelas_id dan semester_id diperlukan');

      const rows = await env.DB.prepare(
        `SELECT jp.*, COALESCE(mp.nama, jp.nama_kegiatan) as mapel_nama, mp.kode as mapel_kode, g.nama as guru_nama, r.nama as ruangan_nama, k.nama as kelas_nama
         FROM jadwal_pelajaran jp
         LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
         LEFT JOIN guru g ON jp.guru_id = g.id
         LEFT JOIN ruangan r ON jp.ruangan_id = r.id
         LEFT JOIN kelas k ON jp.kelas_id = k.id
         WHERE jp.kelas_id = ? AND jp.semester_id = ?
         ORDER BY CASE jp.hari
           WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
           WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
           ELSE 7 END, jp.jam_mulai`
      ).bind(parseInt(kelasId), parseInt(semesterId)).all();
      return success(rows.results);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Gagal mengambil jadwal per kelas';
      return error(msg, 500, 'JADWAL_PER_KELAS_ERROR');
    }
  }

  // Jadwal CRUD
  if (subPath === 'jadwal' || (subPath.startsWith('jadwal/') && !subPath.includes('/generate') && !subPath.includes('/reset') && !subPath.includes('/publikasi') && !subPath.includes('/unpublikasi') && !subPath.includes('/simpan') && !subPath.includes('/cek-bentrok'))) {
    const id = subPath === 'jadwal' ? null : parseInt(subPath.split('/')[1]);

    if (request.method === 'GET') {
      if (id) {
        const row = await env.DB.prepare(
          `SELECT jp.*, COALESCE(mp.nama, jp.nama_kegiatan) as mapel_nama, g.nama as guru_nama, k.nama as kelas_nama, r.nama as ruangan_nama
           FROM jadwal_pelajaran jp
           LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
           LEFT JOIN guru g ON jp.guru_id = g.id
           LEFT JOIN kelas k ON jp.kelas_id = k.id
           LEFT JOIN ruangan r ON jp.ruangan_id = r.id
           WHERE jp.id = ?`
        ).bind(id).first();
        if (!row) return notFound('Jadwal');
        return success(row);
      }

      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(200, Math.max(1, parseInt(url.searchParams.get('per_page') || '100')));
      const offset = (page - 1) * perPage;
      const total = (await env.DB.prepare('SELECT COUNT(*) as total FROM jadwal_pelajaran').first<{ total: number }>())?.total || 0;

      const rows = await env.DB.prepare(
        `SELECT jp.*, COALESCE(mp.nama, jp.nama_kegiatan) as mapel_nama, g.nama as guru_nama, k.nama as kelas_nama, r.nama as ruangan_nama
         FROM jadwal_pelajaran jp
         LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
         LEFT JOIN guru g ON jp.guru_id = g.id
         LEFT JOIN kelas k ON jp.kelas_id = k.id
         LEFT JOIN ruangan r ON jp.ruangan_id = r.id
         ORDER BY jp.semester_id DESC, jp.kelas_id, CASE jp.hari
           WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
           WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
           ELSE 7 END, jp.jam_mulai LIMIT ? OFFSET ?`
      ).bind(perPage, offset).all();

      return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, nama_kegiatan, is_istirahat, gabungan_id } = body;

      if (!kelas_id || !hari || !jam_mulai || !jam_selesai || !semester_id) {
        return badRequest('Semua field wajib diisi');
      }

      // Kegiatan tetap (istirahat/tahfidz/dll) boleh tanpa mapel & guru
      const isKegiatan = Boolean(nama_kegiatan || is_istirahat);
      if (!isKegiatan && (!mata_pelajaran_id || !guru_id)) {
        return badRequest('mata_pelajaran_id dan guru_id wajib diisi untuk jadwal mapel');
      }

      if (!HARI.includes(hari as string)) {
        return badRequest('Hari tidak valid. Hari yang tersedia: ' + HARI.join(', '));
      }

      // Kumpulan kelas yang dijadwalkan: semua anggota gabungan, atau satu kelas biasa
      let targetKelas: number[] = [kelas_id as number];
      const gabunganId = gabungan_id ? Number(gabungan_id) : null;

      if (gabunganId) {
        const gab = await env.DB.prepare(
          'SELECT id FROM kelas_gabungan WHERE id = ? AND semester_id = ?'
        ).bind(gabunganId, semester_id).first();
        if (!gab) return badRequest('Kelas gabungan tidak ditemukan untuk semester ini');

        const anggota = await env.DB.prepare(
          'SELECT kelas_id FROM kelas_gabungan_anggota WHERE gabungan_id = ? ORDER BY id'
        ).bind(gabunganId).all<{ kelas_id: number }>();
        targetKelas = anggota.results.map((a) => a.kelas_id);
        if (targetKelas.length === 0) return badRequest('Kelas gabungan tidak memiliki anggota');

        // Jika sesi gabungan yang sama (gabungan, hari, jam, guru) sudah ada → no-op, hindari duplikat
        const existingSession = await env.DB.prepare(
          `SELECT id FROM jadwal_pelajaran WHERE gabungan_id = ? AND hari = ? AND jam_mulai = ? AND jam_selesai = ? AND guru_id = ? AND semester_id = ? LIMIT 1`
        ).bind(gabunganId, hari, jam_mulai, jam_selesai, guru_id ?? null, semester_id).first<{ id: number }>();
        if (existingSession) {
          return created({ id: existingSession.id, gabungan_id: gabunganId, no_op: true });
        }
      }

      // Validasi guru mengajar mapel (lolos minimal satu kelas dari sesi)
      if (!isKegiatan) {
        let lolos = false;
        for (const kid of targetKelas) {
          if (await validasiGuruMapelKelas(env, guru_id as number, mata_pelajaran_id as number, kid) === null) {
            lolos = true;
            break;
          }
        }
        if (!lolos) {
          return badRequest('Guru tidak terdaftar untuk mengajar mata pelajaran ini di kelas yang dituju');
        }
      }

      const bentrok = await cekBentrok(env, guru_id as number || 0, kelas_id as number, hari as string, jam_mulai as string, jam_selesai as string, semester_id as number, undefined, gabunganId);
      if (bentrok) {
        return badRequest(bentrok);
      }

      let lastId: number | undefined;
      for (const kid of targetKelas) {
        const result = await env.DB.prepare(
          `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, nama_kegiatan, is_istirahat, hari, jam_mulai, jam_selesai, semester_id, gabungan_id, status_validasi)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
        ).bind(kid, mata_pelajaran_id || null, guru_id || null, ruangan_id || null, nama_kegiatan || null, is_istirahat ? 1 : 0, hari, jam_mulai, jam_selesai, semester_id, gabunganId).run();
        lastId = Number(result.meta?.last_row_id);
      }

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'penjadwalan', ?, ?)"
      ).bind(user.sub, `Tambah jadwal kelas ${kelas_id}${gabunganId ? ` (gabungan ${gabunganId})` : ''}`, ip).run();

      return created({ id: lastId, gabungan_id: gabunganId, kelas_ids: targetKelas });
    }

    if (request.method === 'PUT' && id) {
      const existing = await env.DB.prepare('SELECT * FROM jadwal_pelajaran WHERE id = ?').bind(id).first<Record<string, unknown>>();
      if (!existing) return notFound('Jadwal');

      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['kelas_id', 'mata_pelajaran_id', 'guru_id', 'ruangan_id', 'hari', 'jam_mulai', 'jam_selesai', 'semester_id', 'nama_kegiatan', 'gabungan_id']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (body['is_istirahat'] !== undefined) { setClauses.push('is_istirahat = ?'); vals.push(body['is_istirahat'] ? 1 : 0); }

      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');

      // Sesi gabungan dari body atau entri lama
      const gabunganSesi = body['gabungan_id'] !== undefined
        ? (body['gabungan_id'] as number | null)
        : (existing['gabungan_id'] as number | null);

      // Cek bentrok jika field terkait berubah
      const hariFinal = body['hari'] as string || existing['hari'] as string;
      const jamMulaiFinal = body['jam_mulai'] as string || existing['jam_mulai'] as string;
      const jamSelesaiFinal = body['jam_selesai'] as string || existing['jam_selesai'] as string;
      const guruIdFinal = body['guru_id'] as number || existing['guru_id'] as number;
      const kelasIdFinal = body['kelas_id'] as number || existing['kelas_id'] as number;
      const semesterIdFinal = body['semester_id'] as number || existing['semester_id'] as number;
      const mapelIdFinal = body['mata_pelajaran_id'] as number || existing['mata_pelajaran_id'] as number;
      const isKegiatanFinal = Boolean(body['nama_kegiatan'] || body['is_istirahat'] || existing['nama_kegiatan'] || existing['is_istirahat']);

      // Validasi guru mengajar mapel (lolos minimal satu kelas dari sesi)
      if (!isKegiatanFinal && mapelIdFinal && guruIdFinal) {
        let targetKelas: number[] = [kelasIdFinal];
        if (gabunganSesi) {
          const anggota = await env.DB.prepare('SELECT kelas_id FROM kelas_gabungan_anggota WHERE gabungan_id = ?')
            .bind(gabunganSesi).all<{ kelas_id: number }>();
          if (anggota.results.length > 0) targetKelas = anggota.results.map((a) => a.kelas_id);
        }
        let lolos = false;
        for (const kid of targetKelas) {
          if (await validasiGuruMapelKelas(env, guruIdFinal, mapelIdFinal, kid) === null) { lolos = true; break; }
        }
        if (!lolos) {
          return badRequest('Guru tidak terdaftar untuk mengajar mata pelajaran ini di kelas yang dituju');
        }
      }

      const bentrok = await cekBentrok(env, guruIdFinal, kelasIdFinal, hariFinal, jamMulaiFinal, jamSelesaiFinal, semesterIdFinal, id, gabunganSesi);
      if (bentrok) {
        return badRequest(bentrok);
      }

      if (gabunganSesi) {
        // Propagasi hanya bila entri lama memang bagian dari sesi gabungan.
        // Jika entri lama biasa (gabungan_id NULL), jangan propagasi: cukup update baris ini.
        if (existing['gabungan_id']) {
          const sessionIds = await env.DB.prepare(
            `SELECT id FROM jadwal_pelajaran WHERE gabungan_id = ? AND hari = ? AND jam_mulai = ? AND jam_selesai = ? AND guru_id = ?`
          ).bind(existing['gabungan_id'], existing['hari'], existing['jam_mulai'], existing['jam_selesai'], existing['guru_id']).all<{ id: number }>();

          // kelas_id & gabungan_id tiap anggota DIJAGA saat memindah sesi,
          // agar drop pada satu kolom kelas tidak menimpa kelas anggota lainnya.
          const sessionClauses: string[] = [];
          const sessionVals: unknown[] = [];
          for (let i = 0; i < setClauses.length; i++) {
            const clause = setClauses[i];
            if (clause.startsWith('kelas_id') || clause.startsWith('gabungan_id')) continue;
            sessionClauses.push(clause);
            sessionVals.push(vals[i]);
          }

          if (sessionClauses.length > 0) {
            for (const s of sessionIds.results) {
              await env.DB.prepare(`UPDATE jadwal_pelajaran SET ${sessionClauses.join(', ')} WHERE id = ?`).bind(...sessionVals, s.id).run();
            }
          }
        } else {
          vals.push(id);
          await env.DB.prepare(`UPDATE jadwal_pelajaran SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
        }
      } else {
        vals.push(id);
        await env.DB.prepare(`UPDATE jadwal_pelajaran SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      }

      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'penjadwalan', ?, ?)")
        .bind(user.sub, `Update jadwal id=${id}${gabunganSesi ? ` (gabungan ${gabunganSesi})` : ''}`, ip).run();
      return success({ id });
    }

    if (request.method === 'DELETE' && id) {
      const existing = await env.DB.prepare(
        'SELECT gabungan_id, hari, jam_mulai, jam_selesai, guru_id FROM jadwal_pelajaran WHERE id = ?'
      ).bind(id).first<{ gabungan_id: number | null; hari: string; jam_mulai: string; jam_selesai: string; guru_id: number | null }>();
      if (!existing) return notFound('Jadwal');

      if (existing.gabungan_id) {
        // Hapus seluruh anggota sesi gabungan
        await env.DB.prepare(
          `DELETE FROM jadwal_pelajaran WHERE gabungan_id = ? AND hari = ? AND jam_mulai = ? AND jam_selesai = ? AND guru_id = ?`
        ).bind(existing.gabungan_id, existing.hari, existing.jam_mulai, existing.jam_selesai, existing.guru_id).run();
      } else {
        await env.DB.prepare('DELETE FROM jadwal_pelajaran WHERE id = ?').bind(id).run();
      }

      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'penjadwalan', ?, ?)")
        .bind(user.sub, `Hapus jadwal id=${id}`, ip).run();
      return success({ id });
    }
  }

  // ── Cek Bentrok (sebelum simpan) ──
  if (subPath === 'jadwal/cek-bentrok' && request.method === 'POST') {
    const body = await request.json() as {
      guru_id: number; kelas_id: number; mata_pelajaran_id?: number; hari: string;
      jam_mulai: string; jam_selesai: string; semester_id: number;
      exclude_id?: number; exclude_kelas_id?: number; gabungan_id?: number | null;
    };
    const gabunganId = body.gabungan_id ? Number(body.gabungan_id) : null;

    // Validasi guru mengajar mapel (lolos minimal satu kelas dari sesi)
    if (body.mata_pelajaran_id && body.guru_id) {
      let lolos = false;
      if (gabunganId) {
        const anggota = await env.DB.prepare('SELECT kelas_id FROM kelas_gabungan_anggota WHERE gabungan_id = ?')
          .bind(gabunganId).all<{ kelas_id: number }>();
        for (const a of anggota.results) {
          if (await validasiGuruMapelKelas(env, body.guru_id, body.mata_pelajaran_id, a.kelas_id) === null) { lolos = true; break; }
        }
      } else {
        lolos = await validasiGuruMapelKelas(env, body.guru_id, body.mata_pelajaran_id, body.kelas_id) === null;
      }
      if (!lolos) {
        return success({ bentrok: true, message: 'Guru tidak terdaftar untuk mengajar mata pelajaran ini di kelas yang dituju' });
      }
    }

    const msg = body.guru_id
      ? await cekBentrok(env, body.guru_id, body.kelas_id, body.hari, body.jam_mulai, body.jam_selesai, body.semester_id, body.exclude_id, gabunganId)
      : null;
    return success({ bentrok: !!msg, message: msg });
  }

  // ── Simpan jadwal (dengan conflict check) ──
  if (subPath === 'jadwal/simpan' && request.method === 'POST') {
    const body = await request.json() as {
      jadwal: { id?: number; kelas_id: number; mata_pelajaran_id?: number | null; guru_id?: number | null; ruangan_id?: number; hari: string; jam_mulai: string; jam_selesai: string; semester_id: number; nama_kegiatan?: string | null; is_istirahat?: boolean; gabungan_id?: number | null }[];
    };

    if (!Array.isArray(body.jadwal) || body.jadwal.length === 0) {
      return badRequest('Data jadwal diperlukan');
    }

    const errors: string[] = [];
    let saved = 0;
    // Sesi gabungan yang sudah diproses pada batch ini → hindari false-positive bentrok antar anggota
    const processedSession = new Set<string>();

    for (const item of body.jadwal) {
      const isKegiatan = Boolean(item.nama_kegiatan || item.is_istirahat);
      const sessionKey = item.gabungan_id && item.guru_id
        ? `g${item.gabungan_id}|${item.hari}|${item.jam_mulai}|${item.jam_selesai}|${item.guru_id}`
        : null;
      const isDupSession = sessionKey !== null && processedSession.has(sessionKey);

      // Validasi guru mengajar mapel di kelas ini (hanya untuk jadwal mapel, sekali per sesi)
      if (!isDupSession && !isKegiatan && item.guru_id && item.mata_pelajaran_id) {
        const validasiGuru = await validasiGuruMapelKelas(env, item.guru_id, item.mata_pelajaran_id, item.kelas_id);
        if (validasiGuru) {
          errors.push(`Baris ${saved + 1}: ${validasiGuru}`);
          continue;
        }
      }

      if (!isDupSession && item.guru_id) {
        const bentrok = await cekBentrok(env, item.guru_id, item.kelas_id, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id, item.id, item.gabungan_id ?? null);
        if (bentrok) {
          errors.push(`Baris ${saved + 1}: ${bentrok}`);
          continue;
        }
      }
      if (sessionKey !== null) processedSession.add(sessionKey);

      if (item.id) {
        await env.DB.prepare(
          `UPDATE jadwal_pelajaran SET kelas_id=?, mata_pelajaran_id=?, guru_id=?, ruangan_id=?, nama_kegiatan=?, is_istirahat=?, hari=?, jam_mulai=?, jam_selesai=?, semester_id=?, gabungan_id=?
           WHERE id=?`
        ).bind(item.kelas_id, item.mata_pelajaran_id || null, item.guru_id || null, item.ruangan_id || null, item.nama_kegiatan || null, item.is_istirahat ? 1 : 0, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id, item.gabungan_id ?? null, item.id).run();
      } else {
        await env.DB.prepare(
          `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, nama_kegiatan, is_istirahat, hari, jam_mulai, jam_selesai, semester_id, gabungan_id, status_validasi)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
        ).bind(item.kelas_id, item.mata_pelajaran_id || null, item.guru_id || null, item.ruangan_id || null, item.nama_kegiatan || null, item.is_istirahat ? 1 : 0, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id, item.gabungan_id ?? null).run();
      }
      saved++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'simpan', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Simpan ${saved} jadwal (${errors.length} error)`, ip).run();

    return success({ saved, errors: errors.length > 0 ? errors : null });
  }

  // ── Auto-generate ──
  if (subPath === 'jadwal/generate' && request.method === 'POST') {
    return handleGenerateJadwal(request, env, user, ip);
  }

  // ── Reset (hanya draft) ──
  if (subPath === 'jadwal/reset' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    await env.DB.prepare(
      "DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'"
    ).bind(semId).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'reset', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Reset jadwal draft semester ${semId}`, ip).run();

    return success({ message: 'Jadwal draft berhasil direset. Jadwal tervalidasi tetap aman.' });
  }

  // ── Publikasi ──
  if (subPath === 'jadwal/publikasi' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    const result = await env.DB.prepare(
      "UPDATE jadwal_pelajaran SET status_validasi = 'tervalidasi' WHERE semester_id = ? AND status_validasi = 'draft'"
    ).bind(semId).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'publish', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Publikasi jadwal semester ${semId}`, ip).run();

    return success({ message: 'Jadwal berhasil dipublikasikan', affected: result.meta?.changes });
  }

  // ── Unpublikasi (kembalikan tervalidasi → draft untuk revisi) ──
  if (subPath === 'jadwal/unpublikasi' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    const result = await env.DB.prepare(
      "UPDATE jadwal_pelajaran SET status_validasi = 'draft' WHERE semester_id = ? AND status_validasi = 'tervalidasi'"
    ).bind(semId).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'unpublish', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Unpublikasi jadwal semester ${semId}`, ip).run();

    return success({ message: 'Jadwal dikembalikan ke draft. Publikasikan ulang setelah selesai revisi.', affected: result.meta?.changes });
  }

  // ── Beban mengajar ──
  if (subPath === 'beban-mengajar' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');
    if (!semesterId) return badRequest('semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT g.id, g.nama, g.nip,
              COALESCE(gmp.hari_aktif, '[]') as hari_aktif,
              COALESCE(gmp.jp_max_per_hari, 8) as jp_max_per_hari,
              COALESCE(gmp.jp_max_per_minggu, 24) as jp_max_per_minggu,
              (SELECT COUNT(*) FROM jadwal_pelajaran jp WHERE jp.guru_id = g.id AND jp.semester_id = ?) as jp_terisi
       FROM guru g
       LEFT JOIN guru_mata_pelajaran gmp ON g.id = gmp.guru_id AND gmp.semester_id = ?
       WHERE g.status_aktif = 1
       ORDER BY g.nip ASC`
    ).bind(parseInt(semesterId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  // ── Wali Kelas (dari Admin Master Data) ──
  if (subPath === 'wali-kelas' && request.method === 'GET') {
    const rows = await env.DB.prepare(`
      SELECT g.id, g.nip, g.nama, g.jabatan,
             k.id AS kelas_id, k.nama AS kelas_nama,
             (SELECT COUNT(*) FROM siswa WHERE kelas_id = k.id AND status = 'aktif') AS jumlah_siswa
      FROM guru g
      LEFT JOIN kelas k ON k.wali_kelas_id = g.id
      WHERE g.jabatan LIKE '%wali_kelas%'
      ORDER BY g.nip ASC
    `).all();
    return success(rows.results);
  }

  // ── Jadwal Guru (untuk role guru mapel) ──
  if (subPath === 'jadwal-guru' && request.method === 'GET') {
    const guruId = url.searchParams.get('guru_id');
    const semesterId = url.searchParams.get('semester_id');
    if (!guruId || !semesterId) return badRequest('guru_id dan semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT jp.*, mp.nama as mapel_nama, k.nama as kelas_nama
       FROM jadwal_pelajaran jp
       LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON jp.kelas_id = k.id
       WHERE jp.guru_id = ? AND jp.semester_id = ?
       ORDER BY CASE jp.hari
         WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
         WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
         ELSE 7 END, jp.jam_mulai`
    ).bind(parseInt(guruId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}

// ═══════════════════════════════════════════════
// FUNGSI CEK BENTROK
// ═══════════════════════════════════════════════

/**
 * Validasi apakah guru diizinkan mengajar mapel di kelas tersebut
 * Cek dari guru_mapel_kelas (spesifik) atau guru_mapel × guru_kelas (fallback)
 */
async function validasiGuruMapelKelas(
  env: Env, guruId: number, mapelId: number, kelasId: number
): Promise<string | null> {
  // Cek di guru_mapel_kelas (spesifik)
  const spesifik = await env.DB.prepare(
    'SELECT 1 FROM guru_mapel_kelas WHERE guru_id = ? AND mata_pelajaran_id = ? AND kelas_id = ?'
  ).bind(guruId, mapelId, kelasId).first();

  if (spesifik) return null; // Ada data spesifik, lolos

  // Fallback: cek guru_mapel × guru_kelas
  const mapel = await env.DB.prepare(
    'SELECT 1 FROM guru_mapel WHERE guru_id = ? AND mata_pelajaran_id = ?'
  ).bind(guruId, mapelId).first();

  const kelas = await env.DB.prepare(
    'SELECT 1 FROM guru_kelas WHERE guru_id = ? AND kelas_id = ?'
  ).bind(guruId, kelasId).first();

  if (mapel && kelas) return null; // Ada di kedua tabel, lolos

  return 'Guru tidak terdaftar untuk mengajar mata pelajaran ini di kelas ini';
}

async function cekBentrok(
  env: Env, guruId: number, kelasId: number,
  hari: string, jamMulai: string, jamSelesai: string,
  semesterId: number, excludeId?: number, gabunganId?: number | null
): Promise<string | null> {
  // Kumpulan kelas yang dicakup sesi (semua anggota gabungan, atau satu kelas biasa)
  let sessionKelas: number[] = [kelasId];
  if (gabunganId) {
    const anggota = await env.DB.prepare(
      'SELECT kelas_id FROM kelas_gabungan_anggota WHERE gabungan_id = ? ORDER BY id'
    ).bind(gabunganId).all<{ kelas_id: number }>();
    sessionKelas = anggota.results.map((a) => a.kelas_id);
    if (sessionKelas.length === 0) sessionKelas = [kelasId];
  }

  // Klausa pengecualian: entri yang merupakan bagian dari SESI GABUNGAN yang sama.
  // Dua entri dianggap satu sesi bila (gabungan_id, hari, jam, guru) sama.
  let excludeSession = '';
  const excludeSessionParams: unknown[] = [];
  if (gabunganId) {
    excludeSession = ` AND NOT (jp.gabungan_id = ? AND jp.hari = ? AND jp.jam_mulai = ? AND jp.jam_selesai = ? AND jp.guru_id = ?)`;
    excludeSessionParams.push(gabunganId, hari, jamMulai, jamSelesai, guruId);
  }

  // Bentrok guru (guru sama, hari sama, jam overlap) — sesi gabungan yang sama dikecualikan
  let queryGuru = `SELECT jp.kelas_id, k.nama as kelas_nama
    FROM jadwal_pelajaran jp
    LEFT JOIN kelas k ON jp.kelas_id = k.id
    WHERE jp.guru_id = ? AND jp.hari = ? AND jp.semester_id = ?
    AND ((jp.jam_mulai <= ? AND jp.jam_selesai > ?) OR (jp.jam_mulai < ? AND jp.jam_selesai >= ?))`;
  const paramsGuru: unknown[] = [guruId, hari, semesterId, jamMulai, jamMulai, jamSelesai, jamSelesai];
  queryGuru += excludeSession;
  paramsGuru.push(...excludeSessionParams);

  if (excludeId) {
    queryGuru += ' AND jp.id != ?';
    paramsGuru.push(excludeId);
  }

  const bentrokGuru = await env.DB.prepare(queryGuru).bind(...paramsGuru).first<{ kelas_id: number; kelas_nama: string }>();
  if (bentrokGuru) {
    return `BENTROK: Guru ini sudah mengajar di kelas ${bentrokGuru.kelas_nama || '#' + bentrokGuru.kelas_id} di hari dan jam yang sama`;
  }

  // Bentrok kelas — cek tiap kelas dalam sesi (anggota gabungan atau satu kelas)
  for (const kid of sessionKelas) {
    let queryKelas = `SELECT mp.nama as mapel_nama
      FROM jadwal_pelajaran jp
      LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
      WHERE jp.kelas_id = ? AND jp.hari = ? AND jp.semester_id = ?
      AND ((jp.jam_mulai <= ? AND jp.jam_selesai > ?) OR (jp.jam_mulai < ? AND jp.jam_selesai >= ?))`;
    const paramsKelas: unknown[] = [kid, hari, semesterId, jamMulai, jamMulai, jamSelesai, jamSelesai];
    queryKelas += excludeSession;
    paramsKelas.push(...excludeSessionParams);

    if (excludeId) {
      queryKelas += ' AND jp.id != ?';
      paramsKelas.push(excludeId);
    }

    const bentrokKelas = await env.DB.prepare(queryKelas).bind(...paramsKelas).first<{ mapel_nama: string }>();
    if (bentrokKelas) {
      return `BENTROK: Kelas ini sudah memiliki jadwal ${bentrokKelas.mapel_nama || ''} di jam yang sama`;
    }
  }

  return null;
}

// ═══════════════════════════════════════════════
// AUTO-GENERATE JADWAL (Terverifikasi)
// ═══════════════════════════════════════════════

export async function handleGenerateJadwal(request: Request, env: Env, user: UserPayload, ip: string): Promise<Response> {
  const body = await request.json() as { semester_id?: number };
  const semesterId = body.semester_id;
  if (!semesterId) return badRequest('Semester_id diperlukan');

  // 1. Hapus jadwal draft lama
  await env.DB.prepare(
    "DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'"
  ).bind(semesterId).run();

  // 2. Ambil slot jam pelajaran (prioritas dari DB, fallback ke konstanta)
  const slotRows = await env.DB.prepare('SELECT kode, mulai, selesai, tipe FROM jp_slot ORDER BY urutan')
    .all<{ kode: string; mulai: string; selesai: string; tipe: string }>();
  const slots = slotRows.results.length > 0
    ? slotRows.results
    : JP_SLOTS.map(s => ({ ...s }));
  // Slot istirahat (tipe 'istirahat') tidak dipakai untuk mengisi jam pelajaran
  const jpSlots = slots.filter(s => s.tipe !== 'istirahat');

  // 2b. Ambil kesiapan guru
  const kesiapanList = await env.DB.prepare(
    `SELECT gmp.*, g.nama as guru_nama
     FROM guru_mata_pelajaran gmp
     LEFT JOIN guru g ON gmp.guru_id = g.id
     WHERE gmp.semester_id = ? AND gmp.hari_aktif IS NOT NULL AND gmp.hari_aktif != '[]'`
  ).bind(semesterId).all<{
    guru_id: number; hari_aktif: string; jp_max_per_hari: number;
    jp_max_per_minggu: number; guru_nama: string;
  }>();

  if (kesiapanList.results.length === 0) {
    return badRequest('Belum ada data Kesiapan Mengajar Guru untuk semester ini. Silakan isi Kesiapan Mengajar terlebih dahulu.');
  }

  // 3. Ambil guru_mapel, guru_kelas, mapel_kelas
  const [guruMapel, guruKelas, mapelKelas] = await Promise.all([
    env.DB.prepare('SELECT guru_id, mata_pelajaran_id FROM guru_mapel').all<{ guru_id: number; mata_pelajaran_id: number }>(),
    env.DB.prepare('SELECT guru_id, kelas_id FROM guru_kelas').all<{ guru_id: number; kelas_id: number }>(),
    env.DB.prepare('SELECT mata_pelajaran_id, kelas_id FROM mapel_kelas').all<{ mata_pelajaran_id: number; kelas_id: number }>(),
  ]);

  // Bangun lookup maps
  const guruToMapel = new Map<number, Set<number>>();
  for (const gm of guruMapel.results) {
    if (!guruToMapel.has(gm.guru_id)) guruToMapel.set(gm.guru_id, new Set());
    guruToMapel.get(gm.guru_id)!.add(gm.mata_pelajaran_id);
  }

  const guruToKelas = new Map<number, Set<number>>();
  for (const gk of guruKelas.results) {
    if (!guruToKelas.has(gk.guru_id)) guruToKelas.set(gk.guru_id, new Set());
    guruToKelas.get(gk.guru_id)!.add(gk.kelas_id);
  }

  const mapelToKelas = new Map<number, Set<number>>();
  const kelasToMapel = new Map<number, Set<number>>();
  for (const mk of mapelKelas.results) {
    if (!mapelToKelas.has(mk.mata_pelajaran_id)) mapelToKelas.set(mk.mata_pelajaran_id, new Set());
    mapelToKelas.get(mk.mata_pelajaran_id)!.add(mk.kelas_id);
    if (!kelasToMapel.has(mk.kelas_id)) kelasToMapel.set(mk.kelas_id, new Set());
    kelasToMapel.get(mk.kelas_id)!.add(mk.mata_pelajaran_id);
  }

  // 4. Parse kesiapan guru
  interface Kesiapan {
    guruId: number;
    nama: string;
    hariAktif: Set<string>;
    jpMaxHari: number;
    jpMaxMinggu: number;
    mapelIds: Set<number>;
    kelasIds: Set<number>;
  }

  const guruKesiapan: Kesiapan[] = [];
  for (const k of kesiapanList.results) {
    let hariAktif: string[];
    try { hariAktif = JSON.parse(k.hari_aktif as string); }
    catch { hariAktif = []; }

    if (hariAktif.length === 0) continue;

    guruKesiapan.push({
      guruId: k.guru_id,
      nama: k.guru_nama || `Guru #${k.guru_id}`,
      hariAktif: new Set(hariAktif),
      jpMaxHari: k.jp_max_per_hari || 8,
      jpMaxMinggu: k.jp_max_per_minggu || 24,
      mapelIds: guruToMapel.get(k.guru_id) || new Set(),
      kelasIds: guruToKelas.get(k.guru_id) || new Set(),
    });
  }

  // 5. Ambil jadwal tervalidasi (tidak diubah)
  const existingValidated = await env.DB.prepare(
    `SELECT kelas_id, guru_id, hari, jam_mulai, jam_selesai, mata_pelajaran_id
     FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'tervalidasi'`
  ).bind(semesterId).all();

  // 6. Tracker occupancy
  const occupiedKelas = new Set<string>();   // kelas_id|hari|jam_mulai
  const occupiedGuru = new Set<string>();    // guru_id|hari|jam_mulai
  const guruJpCount = new Map<number, Map<string, number>>(); // guru_id -> { hari: count, total: count }
  const guruMingguCount = new Map<number, number>();

  for (const v of existingValidated.results) {
    const row = v as { kelas_id: number; guru_id: number; hari: string; jam_mulai: string; jam_selesai: string; mata_pelajaran_id: number };
    occupiedKelas.add(`${row.kelas_id}|${row.hari}|${row.jam_mulai}`);
    occupiedGuru.add(`${row.guru_id}|${row.hari}|${row.jam_mulai}`);

    if (!guruJpCount.has(row.guru_id)) guruJpCount.set(row.guru_id, new Map());
    const hariCount = guruJpCount.get(row.guru_id)!;
    hariCount.set(row.hari, (hariCount.get(row.hari) || 0) + 1);
    guruMingguCount.set(row.guru_id, (guruMingguCount.get(row.guru_id) || 0) + 1);
  }

  // 7. Bangun daftar kebutuhan (kelas_id, mata_pelajaran_id) dari mapel_kelas
  const needed = new Map<string, { kelasId: number; mapelId: number }[]>();
  // Group by kelas
  for (const [mapelId, kelasIds] of mapelToKelas) {
    for (const kelasId of kelasIds) {
      const key = `${kelasId}`;
      if (!needed.has(key)) needed.set(key, []);
      needed.get(key)!.push({ kelasId, mapelId });
    }
  }

  // Filter hanya kelas yang memiliki kesiapan guru
  const allKelasIds = new Set<number>();
  for (const gk of guruKelas.results) allKelasIds.add(gk.kelas_id);

  // 8. Generate: greedy assignment
  const shuffledKesiapan = [...guruKesiapan].sort(() => Math.random() - 0.5);
  let inserted = 0;
  const errors: string[] = [];

  for (const [kelasKey, needs] of needed) {
    const kelasId = parseInt(kelasKey);
    if (!allKelasIds.has(kelasId)) continue;

    for (const need of needs) {
      let assigned = false;

      // Cari guru yang bisa
      for (const guru of shuffledKesiapan) {
        if (assigned) break;

        // Check: guru bisa ngajar mapel ini?
        if (!guru.mapelIds.has(need.mapelId)) continue;

        // Check: guru bisa ngajar kelas ini?
        if (!guru.kelasIds.has(kelasId)) continue;

        // Coba assign di hari yang aktif
        for (const hari of HARI) {
          if (assigned) break;
          if (!guru.hariAktif.has(hari)) continue;

          const jpCount = guruJpCount.get(guru.guruId);
          const hariCount = jpCount?.get(hari) || 0;
          if (hariCount >= guru.jpMaxHari) continue;

          const mingguCount = guruMingguCount.get(guru.guruId) || 0;
          if (mingguCount >= guru.jpMaxMinggu) continue;

          for (const jp of jpSlots) {
            const time = { mulai: jp.mulai, selesai: jp.selesai };
            const kelasKey = `${kelasId}|${hari}|${time.mulai}`;
            const guruKey = `${guru.guruId}|${hari}|${time.mulai}`;

            if (occupiedKelas.has(kelasKey)) continue;
            if (occupiedGuru.has(guruKey)) continue;

            // Assign!
            await env.DB.prepare(
              `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
            ).bind(kelasId, need.mapelId, guru.guruId, null, hari, time.mulai, time.selesai, semesterId).run();

            occupiedKelas.add(kelasKey);
            occupiedGuru.add(guruKey);

            if (!guruJpCount.has(guru.guruId)) guruJpCount.set(guru.guruId, new Map());
            const hc = guruJpCount.get(guru.guruId)!;
            hc.set(hari, (hc.get(hari) || 0) + 1);
            guruMingguCount.set(guru.guruId, (guruMingguCount.get(guru.guruId) || 0) + 1);

            inserted++;
            assigned = true;
            break;
          }
        }
      }

      if (!assigned) {
        errors.push(`Mapel #${need.mapelId} untuk kelas #${kelasId} — tidak ada guru tersedia`);
      }
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'generate', 'penjadwalan', ?, ?)"
  ).bind(user.sub, `Generate jadwal semester ${semesterId}: ${inserted} berhasil`, ip).run();

  return success({
    message: `Generate selesai. ${inserted} jadwal berhasil dibuat.`,
    inserted,
    errors: errors.length > 0 ? errors : null,
  });
}
