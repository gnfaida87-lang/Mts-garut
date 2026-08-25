import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/siswa_model.dart';

void main() {
  group('Siswa', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'nis': 'S001',
        'nisn': '0012345678',
        'nama': 'Budi Santoso',
        'jenis_kelamin': 'L',
        'kelas_id': 5,
        'kelas_nama': 'X-A',
        'status': 'Aktif',
      };

      final siswa = Siswa.fromJson(json);

      expect(siswa.id, 1);
      expect(siswa.nis, 'S001');
      expect(siswa.nisn, '0012345678');
      expect(siswa.nama, 'Budi Santoso');
      expect(siswa.jenisKelamin, 'L');
      expect(siswa.kelasId, 5);
      expect(siswa.kelasNama, 'X-A');
      expect(siswa.status, 'Aktif');
    });

    test('fromJson should handle null fields', () {
      final json = {
        'id': 1,
        'nis': 'S001',
        'nama': 'Test',
      };

      final siswa = Siswa.fromJson(json);

      expect(siswa.nisn, isNull);
      expect(siswa.jenisKelamin, isNull);
      expect(siswa.kelasId, isNull);
      expect(siswa.kelasNama, isNull);
      expect(siswa.status, isNull);
    });

    test('toJson should serialize correctly', () {
      const siswa = Siswa(
        id: 1,
        nis: 'S001',
        nisn: '0012345678',
        nama: 'Budi Santoso',
        jenisKelamin: 'L',
        kelasId: 5,
        kelasNama: 'X-A',
        status: 'Aktif',
      );

      final json = siswa.toJson();

      expect(json['id'], 1);
      expect(json['nis'], 'S001');
      expect(json['nisn'], '0012345678');
      expect(json['nama'], 'Budi Santoso');
      expect(json['jenis_kelamin'], 'L');
      expect(json['kelas_id'], 5);
      expect(json['kelas_nama'], 'X-A');
      expect(json['status'], 'Aktif');
    });

    test('isAktif should return true when status is Aktif', () {
      const siswa = Siswa(id: 1, nis: '1', nama: 'Test', status: 'Aktif');
      expect(siswa.isAktif, isTrue);
    });

    test('isAktif should return false when status is not Aktif', () {
      const siswa = Siswa(id: 1, nis: '1', nama: 'Test', status: 'Tidak Aktif');
      expect(siswa.isAktif, isFalse);
    });
  });
}
