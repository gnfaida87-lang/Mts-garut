import '../../../core/network/api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/admin/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> list(String resource, {int page = 1, int perPage = 20, String? search, Map<String, String>? filters}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (filters != null) params.addAll(filters);
    final res = await ApiClient.get('/admin/$resource', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getById(String resource, int id) async {
    final res = await ApiClient.get('/admin/$resource/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create(String resource, Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/$resource', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> update(String resource, int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/$resource/$id', body: body);
  }

  static Future<void> delete(String resource, int id) async {
    await ApiClient.delete('/admin/$resource/$id');
  }

  static Future<List<dynamic>> getHakAkses() async {
    final res = await ApiClient.get('/admin/hak-akses');
    return res['data'] as List<dynamic>;
  }

  static Future<void> addHakAkses(Map<String, dynamic> body) async {
    await ApiClient.post('/admin/hak-akses', body: body);
  }

  static Future<void> deleteHakAkses(int id) async {
    await ApiClient.delete('/admin/hak-akses/$id');
  }

  static Future<void> backup() async {
    await ApiClient.post('/admin/backup');
  }

  static Future<void> restore(Map<String, dynamic> body) async {
    await ApiClient.post('/admin/restore', body: body);
  }

  static Future<Map<String, dynamic>> getLogAktivitas({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/log-aktivitas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Absensi ──
  static Future<Map<String, dynamic>> getAbsensiGuru({int page = 1, int perPage = 20, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/absensi/guru', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateAbsensiGuru(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/absensi/guru/$id', body: body);
  }

  static Future<Map<String, dynamic>> getAbsensiSiswa({int page = 1, int perPage = 20, String? kelasId, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/absensi/siswa', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAnalisisAbsensi({String? tanggalMulai, String? tanggalSelesai, String? kelasId}) async {
    final params = <String, String>{};
    if (tanggalMulai != null) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalSelesai != null) params['tanggal_selesai'] = tanggalSelesai;
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/admin/absensi/analisis', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAuditAbsensi({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/absensi/audit', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRekapAbsensi({String? tanggalMulai, String? tanggalSelesai, String? kelasId}) async {
    final params = <String, String>{};
    if (tanggalMulai != null) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalSelesai != null) params['tanggal_selesai'] = tanggalSelesai;
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/admin/absensi/rekap', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Nilai ──
  static Future<Map<String, dynamic>> getNilai({int page = 1, int perPage = 20, String? kelasId, String? mapelId, String? jenis, String? statusValidasi, String? semesterId}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (mapelId != null) params['mata_pelajaran_id'] = mapelId;
    if (jenis != null) params['jenis'] = jenis;
    if (statusValidasi != null) params['status_validasi'] = statusValidasi;
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/admin/nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> validasiNilai(int id) async {
    await ApiClient.put('/admin/nilai/$id/validasi');
  }

  static Future<Map<String, dynamic>> getAnalisisNilai({required String semesterId, String? kelasId, String? jenis}) async {
    final params = <String, String>{'semester_id': semesterId};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (jenis != null) params['jenis'] = jenis;
    final res = await ApiClient.get('/admin/nilai/analisis', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAuditNilai({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/nilai/audit', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Rapor ──
  static Future<Map<String, dynamic>> getRapor({int page = 1, int perPage = 20, String? kelasId, String? semesterId, String? statusKirim}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (semesterId != null) params['semester_id'] = semesterId;
    if (statusKirim != null) params['status_kirim'] = statusKirim;
    final res = await ApiClient.get('/admin/rapor', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> cetakRapor(int id) async {
    await ApiClient.post('/admin/rapor/$id/cetak');
  }

  static Future<Map<String, dynamic>> getArsipRapor({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/rapor/arsip', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAnalisisRapor({required String semesterId, String? kelasId}) async {
    final params = <String, String>{'semester_id': semesterId};
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/admin/rapor/analisis', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getReferensi() async {
    final res = await ApiClient.get('/referensi');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAuditRapor({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/rapor/audit', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Publikasi Nilai ──
  static Future<Map<String, dynamic>> getPublikasiStatus(int? semesterId) async {
    final params = <String, String>{};
    if (semesterId != null) params['semester_id'] = '$semesterId';
    final res = await ApiClient.get('/admin/rapor/status-publikasi', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> togglePublikasiNilai(int semesterId, bool published) async {
    await ApiClient.put('/admin/rapor/$semesterId/publikasi-nilai', body: {'nilai_published': published});
  }

  // ── Publikasi per Jenis Ujian ──
  static Future<Map<String, dynamic>> getPublikasiJenis(int? semesterId) async {
    final params = <String, String>{};
    if (semesterId != null) params['semester_id'] = '$semesterId';
    final res = await ApiClient.get('/admin/rapor/status-publikasi-jenis', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> togglePublikasiJenis(int semesterId, String jenis, bool published) async {
    await ApiClient.put('/admin/rapor/publikasi-jenis', body: {
      'semester_id': semesterId,
      'jenis': jenis,
      'is_published': published,
    });
  }

  // ── Publikasi per Kelas ──
  static Future<Map<String, dynamic>> getPublikasiKelas(int? semesterId) async {
    final params = <String, String>{};
    if (semesterId != null) params['semester_id'] = '$semesterId';
    final res = await ApiClient.get('/admin/rapor/status-publikasi-kelas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> togglePublikasiKelas(int semesterId, int kelasId, bool published) async {
    await ApiClient.put('/admin/rapor/publikasi-kelas', body: {
      'semester_id': semesterId,
      'kelas_id': kelasId,
      'is_published': published,
    });
  }

  // ── Profil Sekolah ──
  static Future<Map<String, dynamic>> getProfil() async {
    final res = await ApiClient.get('/admin/profil');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateProfil(Map<String, String> body) async {
    await ApiClient.put('/admin/profil', body: body);
  }

  // ── Pengaturan Tampilan Login ──
  static Future<List<dynamic>> getPengaturanTampilan() async {
    final res = await ApiClient.get('/admin/pengaturan-tampilan');
    return res['data'] as List<dynamic>;
  }

  static Future<void> updatePengaturanTampilan(Map<String, String> body) async {
    await ApiClient.put('/admin/pengaturan-tampilan', body: body);
  }

  // ── Guru Mapel Kelas (Gabungan Spesifik) ──
  static Future<List<dynamic>> getGuruMapelKelas(int guruId) async {
    final res = await ApiClient.get('/admin/guru-mapel-kelas/$guruId');
    return res['data'] as List<dynamic>;
  }

  static Future<void> saveGuruMapelKelas(int guruId, List<Map<String, dynamic>> assignments) async {
    await ApiClient.post('/admin/guru-mapel-kelas/$guruId', body: {
      'assignments': assignments,
    });
  }

  static Future<Map<String, dynamic>> getGuruMapelKelasAll({int page = 1, int perPage = 100, String? search}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/admin/guru-mapel-kelas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> createGuruMapelKelas(Map<String, dynamic> body) async {
    await ApiClient.post('/admin/guru-mapel-kelas', body: body);
  }

  static Future<void> updateGuruMapelKelas(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/guru-mapel-kelas/$id', body: body);
  }

  static Future<void> deleteGuruMapelKelas(int id) async {
    await ApiClient.delete('/admin/guru-mapel-kelas/$id');
  }

  // ── API Keys ──
  static Future<Map<String, dynamic>> getApiKeys({int page = 1, int perPage = 20, String? search, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/api-keys', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getApiKey(int id) async {
    final res = await ApiClient.get('/admin/api-keys/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/api-keys', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateApiKey(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/api-keys/$id', body: body);
  }

  static Future<void> deleteApiKey(int id) async {
    await ApiClient.delete('/admin/api-keys/$id');
  }
}
