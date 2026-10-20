import '../../../core/network/api_client.dart';

class MusyrifahService {
  // ─── DASHBOARD ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/musyrifah/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  // ─── PROFIL ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfil() async {
    final res = await ApiClient.get('/musyrifah/profil');
    return res['data'] as Map<String, dynamic>;
  }

  // ─── JADWAL ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getJadwal({String? hari, String? programId}) async {
    final params = <String, String>{};
    if (hari != null && hari.isNotEmpty) params['hari'] = hari;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    final res = await ApiClient.get('/musyrifah/jadwal', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ─── ABSENSI ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanAbsensi({
    required String token,
    int? jadwalId,
  }) async {
    final body = <String, dynamic>{'token': token};
    if (jadwalId != null) body['jadwal_id'] = jadwalId;
    final res = await ApiClient.post('/musyrifah/absensi/scan', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  /// Jam masuk/keluar absensi at-Ta'wid (untuk info di halaman scan).
  static Future<Map<String, dynamic>> getPengaturanWaktuAbsensi() async {
    final res = await ApiClient.get('/musyrifah/absensi/pengaturan-waktu');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> listAbsensi({
    int page = 1,
    int perPage = 20,
    String? bulan,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (bulan != null && bulan.isNotEmpty) params['bulan'] = bulan;
    final res = await ApiClient.get('/musyrifah/absensi', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> inputAbsensiSantri({
    required int jadwalId,
    required int santriId,
    required String status,
    String? keterangan,
  }) async {
    final body = <String, dynamic>{
      'jadwal_id': jadwalId,
      'santri_id': santriId,
      'status': status,
    };
    if (keterangan != null) body['keterangan'] = keterangan;
    await ApiClient.post('/musyrifah/absensi/santri', body: body);
  }

  // ─── SANTRI ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listSantriByJadwal(int jadwalId) async {
    final res = await ApiClient.get('/musyrifah/santri', queryParams: {'jadwal_id': '$jadwalId'});
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ─── SURAT ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listSurat({
    int? juz,
    String? type,
    String? search,
  }) async {
    final params = <String, String>{};
    if (juz != null) params['juz'] = '$juz';
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/musyrifah/surat', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getSurat(int nomor) async {
    final res = await ApiClient.get('/musyrifah/surat/$nomor');
    return res['data'] as Map<String, dynamic>;
  }

  // ─── NILAI ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listNilai({
    String? programId,
    String? kelasId,
    String? search,
    String? status,
  }) async {
    final all = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final params = <String, String>{'page': '$page', 'per_page': '100'};
      if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
      if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status.isNotEmpty) params['status'] = status;
      final res = await ApiClient.get('/musyrifah/nilai', queryParams: params);
      final data = res['data'] as Map<String, dynamic>;
      all.addAll((data['items'] as List? ?? []).cast<Map<String, dynamic>>());
      final pagination = (data['pagination'] as Map?) ?? const {};
      final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;
      if (page >= totalPages) break;
      page++;
    }
    return all;
  }

  static Future<Map<String, dynamic>> getNilaiDetail(int id) async {
    final res = await ApiClient.get('/musyrifah/nilai/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> inputNilai({
    required int programId,
    required int santriId,
    required int suratNomor,
    required String statusHafalan,
    int? jadwalId,
    int? dariAyat,
    int? sampaiAyat,
    // Bidang 1: Kelancaran Hafalan
    int? kelancaran,
    int? ketepatanAyat,
    int? murojaahSambung,
    int? konsistensiHafalan,
    String? catatanBidang1,
    // Bidang 2: Tajwid
    int? makhorijulHuruf,
    int? sifatulHuruf,
    int? ahkamulHuruf,
    int? ahkamulMadd,
    String? catatanBidang2,
    // Bidang 3: Fashohah dan Adab
    int? ahkamulWaqfi,
    int? adabutTilawah,
    int? kerapihanBacaan,
    int? ketepatanTempo,
    String? catatanBidang3,
    // Catatan
    String? catatanUmum,
    String? rencanaTindakLanjut,
  }) async {
    final body = <String, dynamic>{
      'program_id': programId,
      'santri_id': santriId,
      'surat_nomor': suratNomor,
      'status_hafalan': statusHafalan,
    };
    if (jadwalId != null) body['jadwal_id'] = jadwalId;
    if (dariAyat != null) body['dari_ayat'] = dariAyat;
    if (sampaiAyat != null) body['sampai_ayat'] = sampaiAyat;
    // Bidang 1
    if (kelancaran != null) body['kelancaran'] = kelancaran;
    if (ketepatanAyat != null) body['ketepatan_ayat'] = ketepatanAyat;
    if (murojaahSambung != null) body['murojaah_sambung'] = murojaahSambung;
    if (konsistensiHafalan != null) body['konsistensi_hafalan'] = konsistensiHafalan;
    if (catatanBidang1 != null) body['catatan_bidang1'] = catatanBidang1;
    // Bidang 2
    if (makhorijulHuruf != null) body['makhorijul_huruf'] = makhorijulHuruf;
    if (sifatulHuruf != null) body['sifatul_huruf'] = sifatulHuruf;
    if (ahkamulHuruf != null) body['ahkamul_huruf'] = ahkamulHuruf;
    if (ahkamulMadd != null) body['ahkamul_madd'] = ahkamulMadd;
    if (catatanBidang2 != null) body['catatan_bidang2'] = catatanBidang2;
    // Bidang 3
    if (ahkamulWaqfi != null) body['ahkamul_waqfi'] = ahkamulWaqfi;
    if (adabutTilawah != null) body['adabut_tilawah'] = adabutTilawah;
    if (kerapihanBacaan != null) body['kerapihan_bacaan'] = kerapihanBacaan;
    if (ketepatanTempo != null) body['ketepatan_tempo'] = ketepatanTempo;
    if (catatanBidang3 != null) body['catatan_bidang3'] = catatanBidang3;
    // Catatan
    if (catatanUmum != null) body['catatan_umum'] = catatanUmum;
    if (rencanaTindakLanjut != null) body['rencana_tindak_lanjut'] = rencanaTindakLanjut;
    final res = await ApiClient.post('/musyrifah/nilai', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateNilai({
    required int id,
    int? suratNomor,
    String? statusHafalan,
    int? jadwalId,
    int? dariAyat,
    int? sampaiAyat,
    int? kelancaran,
    int? ketepatanAyat,
    int? murojaahSambung,
    int? konsistensiHafalan,
    String? catatanBidang1,
    int? makhorijulHuruf,
    int? sifatulHuruf,
    int? ahkamulHuruf,
    int? ahkamulMadd,
    String? catatanBidang2,
    int? ahkamulWaqfi,
    int? adabutTilawah,
    int? kerapihanBacaan,
    int? ketepatanTempo,
    String? catatanBidang3,
    String? catatanUmum,
    String? rencanaTindakLanjut,
  }) async {
    final body = <String, dynamic>{};
    if (jadwalId != null) body['jadwal_id'] = jadwalId;
    if (suratNomor != null) body['surat_nomor'] = suratNomor;
    if (dariAyat != null) body['dari_ayat'] = dariAyat;
    if (sampaiAyat != null) body['sampai_ayat'] = sampaiAyat;
    if (statusHafalan != null) body['status_hafalan'] = statusHafalan;
    if (kelancaran != null) body['kelancaran'] = kelancaran;
    if (ketepatanAyat != null) body['ketepatan_ayat'] = ketepatanAyat;
    if (murojaahSambung != null) body['murojaah_sambung'] = murojaahSambung;
    if (konsistensiHafalan != null) body['konsistensi_hafalan'] = konsistensiHafalan;
    if (catatanBidang1 != null) body['catatan_bidang1'] = catatanBidang1;
    if (makhorijulHuruf != null) body['makhorijul_huruf'] = makhorijulHuruf;
    if (sifatulHuruf != null) body['sifatul_huruf'] = sifatulHuruf;
    if (ahkamulHuruf != null) body['ahkamul_huruf'] = ahkamulHuruf;
    if (ahkamulMadd != null) body['ahkamul_madd'] = ahkamulMadd;
    if (catatanBidang2 != null) body['catatan_bidang2'] = catatanBidang2;
    if (ahkamulWaqfi != null) body['ahkamul_waqfi'] = ahkamulWaqfi;
    if (adabutTilawah != null) body['adabut_tilawah'] = adabutTilawah;
    if (kerapihanBacaan != null) body['kerapihan_bacaan'] = kerapihanBacaan;
    if (ketepatanTempo != null) body['ketepatan_tempo'] = ketepatanTempo;
    if (catatanBidang3 != null) body['catatan_bidang3'] = catatanBidang3;
    if (catatanUmum != null) body['catatan_umum'] = catatanUmum;
    if (rencanaTindakLanjut != null) body['rencana_tindak_lanjut'] = rencanaTindakLanjut;
    final res = await ApiClient.put('/musyrifah/nilai/$id', body: body);
    return res['data'] as Map<String, dynamic>;
  }
}
