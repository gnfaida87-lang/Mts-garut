import '../../../../core/network/api_client.dart';

/// Service untuk Modul Dauroh
/// Endpoint: /api/admin/dauroh/*, /api/musyrifah/*, /api/siswa/dauroh/*
class DaurohService {
  // ═══════════════════════════════════════════════════════════════
  //  PROGRAM KEGIATAN
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> listProgram({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/admin/dauroh/program', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProgram(int id) async {
    final res = await ApiClient.get('/admin/dauroh/program/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProgram(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/dauroh/program', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateProgram(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/dauroh/program/$id', body: body);
  }

  static Future<void> deleteProgram(int id) async {
    await ApiClient.delete('/admin/dauroh/program/$id');
  }

  // ═══════════════════════════════════════════════════════════════
  //  MUSYRIFAH
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> listMusyrifah({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/admin/dauroh/musyrifah', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMusyrifah(int id) async {
    final res = await ApiClient.get('/admin/dauroh/musyrifah/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createMusyrifah(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/dauroh/musyrifah', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateMusyrifah(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/dauroh/musyrifah/$id', body: body);
  }

  static Future<void> deleteMusyrifah(int id) async {
    await ApiClient.delete('/admin/dauroh/musyrifah/$id');
  }

  // ═══════════════════════════════════════════════════════════════
  //  JADWAL
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> listJadwal({
    int page = 1,
    int perPage = 20,
    String? search,
    String? programId,
    String? hari,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    if (hari != null && hari.isNotEmpty) params['hari'] = hari;
    final res = await ApiClient.get('/admin/dauroh/jadwal', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getJadwal(int id) async {
    final res = await ApiClient.get('/admin/dauroh/jadwal/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createJadwal(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/dauroh/jadwal', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateJadwal(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/dauroh/jadwal/$id', body: body);
  }

  static Future<void> deleteJadwal(int id) async {
    await ApiClient.delete('/admin/dauroh/jadwal/$id');
  }

  // ═══════════════════════════════════════════════════════════════
  //  QR CODE
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getQRInfo() async {
    final res = await ApiClient.get('/admin/dauroh/qr');
    return res['data'] as Map<String, dynamic>;
  }

  // ── Pengaturan Waktu Absensi Musyrifah ──
  static Future<Map<String, dynamic>> getPengaturanWaktuAbsensi() async {
    final res = await ApiClient.get('/admin/dauroh/pengaturan-waktu');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updatePengaturanWaktuAbsensi(Map<String, dynamic> body) async {
    await ApiClient.put('/admin/dauroh/pengaturan-waktu', body: body);
  }

  // ═══════════════════════════════════════════════════════════════
  //  MONITORING
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> monitoringAbsensi({
    String? tanggal,
    String? programId,
  }) async {
    final params = <String, String>{};
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    final res = await ApiClient.get('/admin/dauroh/monitoring/absensi', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateAbsensiMusyrifah(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/dauroh/monitoring/absensi/$id', body: body);
  }

  static Future<List<Map<String, dynamic>>> monitoringNilai({
    String? jenjang,
    String? kelasId,
    String? programId,
    String? status,
  }) async {
    final params = <String, String>{};
    if (jenjang != null && jenjang.isNotEmpty) params['jenjang'] = jenjang;
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/dauroh/monitoring/nilai', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════════════
  //  MUSYRIFAH ROUTES (dari frontend musyrifah)
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMusyrifahDashboard() async {
    final res = await ApiClient.get('/musyrifah/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMusyrifahProfil() async {
    final res = await ApiClient.get('/musyrifah/profil');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getMusyrifahJadwal({
    String? hari,
    String? programId,
  }) async {
    final params = <String, String>{};
    if (hari != null && hari.isNotEmpty) params['hari'] = hari;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    final res = await ApiClient.get('/musyrifah/jadwal', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getMusyrifahJadwalDetail(int id) async {
    final res = await ApiClient.get('/musyrifah/jadwal/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> scanAbsensiMusyrifah({
    required String token,
    int? jadwalId,
  }) async {
    final body = <String, dynamic>{'token': token};
    if (jadwalId != null) body['jadwal_id'] = jadwalId;
    final res = await ApiClient.post('/musyrifah/absensi/scan', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> listAbsensiMusyrifah({
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

  static Future<List<Map<String, dynamic>>> listNilaiMusyrifah({
    String? programId,
    String? kelasId,
    String? search,
  }) async {
    final params = <String, String>{};
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/musyrifah/nilai', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SANTRI DAUROH ROUTES
  // ═══════════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getSantriProgram() async {
    final res = await ApiClient.get('/siswa/dauroh/program');
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSantriNilai() async {
    final res = await ApiClient.get('/siswa/dauroh/nilai');
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════════════
  //  REFERENSI (untuk dropdown)
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getReferensi() async {
    final res = await ApiClient.get('/referensi');
    return res['data'] as Map<String, dynamic>;
  }
}
