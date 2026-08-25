import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/nilai_model.dart';

void main() {
  group('Nilai', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'siswa_nama': 'Budi',
        'mapel_nama': 'Matematika',
        'kelas_nama': 'X-A',
        'semester_nama': 'Ganjil',
        'jenis': 'harian',
        'nilai': 85,
        'status_validasi': 'draft',
      };

      final nilai = Nilai.fromJson(json);

      expect(nilai.id, 1);
      expect(nilai.siswaNama, 'Budi');
      expect(nilai.mapelNama, 'Matematika');
      expect(nilai.kelasNama, 'X-A');
      expect(nilai.semesterNama, 'Ganjil');
      expect(nilai.jenis, 'harian');
      expect(nilai.nilai, 85);
      expect(nilai.statusValidasi, 'draft');
    });

    test('nilaiNum should return num when nilai is num', () {
      const nilai = Nilai(nilai: 85);
      expect(nilai.nilaiNum, 85);
    });

    test('nilaiNum should parse string nilai', () {
      const nilai = Nilai(nilai: '85.5');
      expect(nilai.nilaiNum, 85.5);
    });

    test('nilaiNum should return null for invalid string', () {
      const nilai = Nilai(nilai: 'abc');
      expect(nilai.nilaiNum, isNull);
    });

    test('isDraft should return true when status is draft', () {
      const nilai = Nilai(statusValidasi: 'draft');
      expect(nilai.isDraft, isTrue);
    });

    test('isValidated should return true when status is tervalidasi', () {
      const nilai = Nilai(statusValidasi: 'tervalidasi');
      expect(nilai.isValidated, isTrue);
    });

    test('isValidated should return true when status is divalidasi', () {
      const nilai = Nilai(statusValidasi: 'divalidasi');
      expect(nilai.isValidated, isTrue);
    });
  });

  group('BobotNilai', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'mapel_nama': 'Matematika',
        'mata_pelajaran_id': 5,
        'tahun_ajaran_id': 1,
        'harian_persen': 30,
        'tugas_persen': 20,
        'uts_persen': 25,
        'uas_persen': 25,
      };

      final bobot = BobotNilai.fromJson(json);

      expect(bobot.id, 1);
      expect(bobot.mapelNama, 'Matematika');
      expect(bobot.mataPelajaranId, 5);
      expect(bobot.tahunAjaranId, 1);
      expect(bobot.harianPersen, 30);
      expect(bobot.tugasPersen, 20);
      expect(bobot.utsPersen, 25);
      expect(bobot.uasPersen, 25);
    });

    test('isDefault should return true when mataPelajaranId is null', () {
      const bobot = BobotNilai(tahunAjaranId: 1, harianPersen: 30, tugasPersen: 20, utsPersen: 25, uasPersen: 25);
      expect(bobot.isDefault, isTrue);
    });

    test('isDefault should return false when mataPelajaranId is set', () {
      const bobot = BobotNilai(tahunAjaranId: 1, mataPelajaranId: 5, harianPersen: 30, tugasPersen: 20, utsPersen: 25, uasPersen: 25);
      expect(bobot.isDefault, isFalse);
    });

    test('displayName should return Default when isDefault', () {
      const bobot = BobotNilai(tahunAjaranId: 1, harianPersen: 30, tugasPersen: 20, utsPersen: 25, uasPersen: 25);
      expect(bobot.displayName, 'Default');
    });

    test('displayName should return mapelNama when not default', () {
      const bobot = BobotNilai(tahunAjaranId: 1, mataPelajaranId: 5, mapelNama: 'Matematika', harianPersen: 30, tugasPersen: 20, utsPersen: 25, uasPersen: 25);
      expect(bobot.displayName, 'Matematika');
    });
  });
}
