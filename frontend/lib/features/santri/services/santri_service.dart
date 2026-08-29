import '../../../core/network/api_client.dart';

class SantriService {
  Future<Map<String, dynamic>> getProfil() async {
    final response = await ApiClient.get('/siswa/profil');
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getJadwal({String? hari}) async {
    final queryParams = <String, String>{};
    if (hari != null) queryParams['hari'] = hari;
    final response = await ApiClient.get('/siswa/jadwal', queryParams: queryParams);
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAbsensi({
    String? bulan,
    String? tahun,
    String? tanggal,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (tanggal != null && tanggal.isNotEmpty) queryParams['tanggal'] = tanggal;
    if (bulan != null) queryParams['bulan'] = bulan;
    if (tahun != null) queryParams['tahun'] = tahun;
    final response = await ApiClient.get('/siswa/absensi', queryParams: queryParams);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNilai({String? semesterId}) async {
    final queryParams = <String, String>{};
    if (semesterId != null) queryParams['semester_id'] = semesterId;
    final response = await ApiClient.get('/siswa/nilai', queryParams: queryParams);
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMateri({String? mapelId}) async {
    final queryParams = <String, String>{};
    if (mapelId != null) queryParams['mapel_id'] = mapelId;
    final response = await ApiClient.get('/siswa/materi', queryParams: queryParams);
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMateriGrouped({String? mapelId}) async {
    final queryParams = <String, String>{};
    if (mapelId != null) queryParams['mapel_id'] = mapelId;
    final response = await ApiClient.get('/siswa/materi', queryParams: queryParams);
    return (response['data']['grouped'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPembayaran({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    final response = await ApiClient.get('/siswa/pembayaran', queryParams: queryParams);
    return response['data'] as Map<String, dynamic>;
  }
}
