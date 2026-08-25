import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/master_data_models.dart';

void main() {
  group('Kelas', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'X-A', 'tingkat_id': 1, 'jurusan_id': 2, 'tahun_ajaran_id': 3};
      final kelas = Kelas.fromJson(json);
      expect(kelas.id, 1);
      expect(kelas.nama, 'X-A');
      expect(kelas.tingkatId, 1);
      expect(kelas.jurusanId, 2);
      expect(kelas.tahunAjaranId, 3);
    });

    test('toJson should serialize correctly', () {
      const kelas = Kelas(id: 1, nama: 'X-A', tingkatId: 1);
      final json = kelas.toJson();
      expect(json['id'], 1);
      expect(json['nama'], 'X-A');
      expect(json['tingkat_id'], 1);
    });
  });

  group('MataPelajaran', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'Matematika', 'kode': 'MTK'};
      final mapel = MataPelajaran.fromJson(json);
      expect(mapel.id, 1);
      expect(mapel.nama, 'Matematika');
      expect(mapel.kode, 'MTK');
    });

    test('toJson should serialize correctly', () {
      const mapel = MataPelajaran(id: 1, nama: 'Matematika', kode: 'MTK');
      final json = mapel.toJson();
      expect(json['id'], 1);
      expect(json['nama'], 'Matematika');
      expect(json['kode'], 'MTK');
    });
  });

  group('TahunAjaran', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': '2024/2025', 'tanggal_mulai': '2024-07-01', 'tanggal_selesai': '2025-06-30', 'is_aktif': 1};
      final ta = TahunAjaran.fromJson(json);
      expect(ta.id, 1);
      expect(ta.nama, '2024/2025');
      expect(ta.tanggalMulai, '2024-07-01');
      expect(ta.tanggalSelesai, '2025-06-30');
      expect(ta.isAktif, 1);
    });

    test('isActive should return true when isAktif is 1', () {
      const ta = TahunAjaran(id: 1, nama: '2024/2025', isAktif: 1);
      expect(ta.isActive, isTrue);
    });

    test('isActive should return false when isAktif is 0', () {
      const ta = TahunAjaran(id: 1, nama: '2024/2025', isAktif: 0);
      expect(ta.isActive, isFalse);
    });
  });

  group('Semester', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'Ganjil', 'tahun_ajaran_id': 1, 'is_aktif': 1};
      final sem = Semester.fromJson(json);
      expect(sem.id, 1);
      expect(sem.nama, 'Ganjil');
      expect(sem.tahunAjaranId, 1);
      expect(sem.isAktif, 1);
    });

    test('isActive should work correctly', () {
      const sem = Semester(id: 1, nama: 'Ganjil', tahunAjaranId: 1, isAktif: 1);
      expect(sem.isActive, isTrue);
    });
  });

  group('Jurusan', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'IPA', 'kode': 'IPA'};
      final jur = Jurusan.fromJson(json);
      expect(jur.id, 1);
      expect(jur.nama, 'IPA');
      expect(jur.kode, 'IPA');
    });
  });

  group('Tingkat', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'X', 'jenjang': 'SMA'};
      final t = Tingkat.fromJson(json);
      expect(t.id, 1);
      expect(t.nama, 'X');
      expect(t.jenjang, 'SMA');
    });
  });

  group('Ruangan', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'nama': 'Ruang 1', 'kapasitas': '40'};
      final r = Ruangan.fromJson(json);
      expect(r.id, 1);
      expect(r.nama, 'Ruang 1');
      expect(r.kapasitas, '40');
    });
  });
}
