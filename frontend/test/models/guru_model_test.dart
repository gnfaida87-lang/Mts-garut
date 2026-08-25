import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/guru_model.dart';

void main() {
  group('Guru', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'nip': '12345',
        'nama': 'Ustadz Ahmad',
        'jenis_kelamin': 'L',
        'jabatan': 'guru_mapel,wali_kelas',
        'status_aktif': 1,
        'username': 'ahmad',
      };

      final guru = Guru.fromJson(json);

      expect(guru.id, 1);
      expect(guru.nip, '12345');
      expect(guru.nama, 'Ustadz Ahmad');
      expect(guru.jenisKelamin, 'L');
      expect(guru.jabatan, 'guru_mapel,wali_kelas');
      expect(guru.statusAktif, 1);
      expect(guru.username, 'ahmad');
    });

    test('fromJson should handle null fields', () {
      final json = {
        'id': 1,
        'nip': '12345',
        'nama': 'Test',
      };

      final guru = Guru.fromJson(json);

      expect(guru.jenisKelamin, isNull);
      expect(guru.jabatan, isNull);
      expect(guru.statusAktif, isNull);
      expect(guru.username, isNull);
    });

    test('toJson should serialize correctly', () {
      const guru = Guru(
        id: 1,
        nip: '12345',
        nama: 'Ustadz Ahmad',
        jenisKelamin: 'L',
        jabatan: 'guru_mapel',
        statusAktif: 1,
        username: 'ahmad',
      );

      final json = guru.toJson();

      expect(json['id'], 1);
      expect(json['nip'], '12345');
      expect(json['nama'], 'Ustadz Ahmad');
      expect(json['jenis_kelamin'], 'L');
      expect(json['jabatan'], 'guru_mapel');
      expect(json['status_aktif'], 1);
      expect(json['username'], 'ahmad');
    });

    test('isAktif should return true when statusAktif is 1', () {
      const guru = Guru(id: 1, nip: '1', nama: 'Test', statusAktif: 1);
      expect(guru.isAktif, isTrue);
    });

    test('isAktif should return false when statusAktif is 0', () {
      const guru = Guru(id: 1, nip: '1', nama: 'Test', statusAktif: 0);
      expect(guru.isAktif, isFalse);
    });

    test('displayName should return nama when not empty', () {
      const guru = Guru(id: 1, nip: '12345', nama: 'Ustadz Ahmad');
      expect(guru.displayName, 'Ustadz Ahmad');
    });

    test('displayName should return nip when nama is empty', () {
      const guru = Guru(id: 1, nip: '12345', nama: '');
      expect(guru.displayName, '12345');
    });
  });
}
