import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/bk_models.dart';

void main() {
  group('Pengaduan', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'siswa_id': 10,
        'siswa_nama': 'Budi',
        'kategori': 'perilaku',
        'deskripsi': 'Terlambat masuk kelas',
        'status': 'diproses',
        'tindak_lanjut': 'Peringatan lisan',
        'created_at': '2024-01-15',
      };

      final pengaduan = Pengaduan.fromJson(json);

      expect(pengaduan.id, 1);
      expect(pengaduan.siswaId, 10);
      expect(pengaduan.siswaNama, 'Budi');
      expect(pengaduan.kategori, 'perilaku');
      expect(pengaduan.deskripsi, 'Terlambat masuk kelas');
      expect(pengaduan.status, 'diproses');
      expect(pengaduan.tindakLanjut, 'Peringatan lisan');
      expect(pengaduan.createdAt, '2024-01-15');
    });

    test('isPending should return true when status is diproses', () {
      const pengaduan = Pengaduan(siswaId: 1, status: 'diproses');
      expect(pengaduan.isPending, isTrue);
    });

    test('isResolved should return true when status is selesai', () {
      const pengaduan = Pengaduan(siswaId: 1, status: 'selesai');
      expect(pengaduan.isResolved, isTrue);
    });

    test('toJson should serialize correctly', () {
      const pengaduan = Pengaduan(siswaId: 10, kategori: 'perilaku', deskripsi: 'Test');
      final json = pengaduan.toJson();
      expect(json['siswa_id'], 10);
      expect(json['kategori'], 'perilaku');
      expect(json['deskripsi'], 'Test');
    });
  });

  group('Konseling', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'siswa_id': 10,
        'siswa_nama': 'Budi',
        'tanggal': '2024-01-15',
        'jam': '10:00',
        'jenis': 'individu',
        'catatan': 'Diskusi prestasi',
      };

      final konseling = Konseling.fromJson(json);

      expect(konseling.id, 1);
      expect(konseling.siswaId, 10);
      expect(konseling.siswaNama, 'Budi');
      expect(konseling.tanggal, '2024-01-15');
      expect(konseling.jam, '10:00');
      expect(konseling.jenis, 'individu');
      expect(konseling.catatan, 'Diskusi prestasi');
    });

    test('toJson should serialize correctly', () {
      const konseling = Konseling(siswaId: 10, tanggal: '2024-01-15', jenis: 'individu');
      final json = konseling.toJson();
      expect(json['siswa_id'], 10);
      expect(json['tanggal'], '2024-01-15');
      expect(json['jenis'], 'individu');
    });
  });

  group('BakatMinat', () {
    test('fromJson should parse correctly', () {
      final json = {
        'bm_id': 1,
        'siswa_id': 10,
        'siswa_nama': 'Budi',
        'nis': 'S001',
        'kelas_nama': 'X-A',
        'jenis': 'bakat',
        'deskripsi': 'Olahraga',
      };

      final bm = BakatMinat.fromJson(json);

      expect(bm.id, 1);
      expect(bm.siswaId, 10);
      expect(bm.siswaNama, 'Budi');
      expect(bm.nis, 'S001');
      expect(bm.kelasNama, 'X-A');
      expect(bm.jenis, 'bakat');
      expect(bm.deskripsi, 'Olahraga');
    });

    test('fromJson should fallback to id when bm_id is null', () {
      final json = {'id': 5, 'siswa_id': 10, 'jenis': 'minat'};
      final bm = BakatMinat.fromJson(json);
      expect(bm.id, 5);
    });

    test('isBakat should return true when jenis is bakat', () {
      const bm = BakatMinat(jenis: 'bakat');
      expect(bm.isBakat, isTrue);
      expect(bm.isMinat, isFalse);
    });

    test('isMinat should return true when jenis is minat', () {
      const bm = BakatMinat(jenis: 'minat');
      expect(bm.isMinat, isTrue);
      expect(bm.isBakat, isFalse);
    });
  });
}
