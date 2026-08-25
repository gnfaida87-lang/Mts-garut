import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/absensi_model.dart';

void main() {
  group('AbsensiGuru', () {
    test('fromJson should parse correctly', () {
      final json = {
        'guru_nip': '12345',
        'guru_nama': 'Ustadz Ahmad',
        'tanggal': '2024-01-15',
        'status': 'hadir',
        'jam_masuk': '07:00',
        'jam_keluar': '15:00',
        'keterangan': '',
      };

      final absensi = AbsensiGuru.fromJson(json);

      expect(absensi.guruNip, '12345');
      expect(absensi.guruNama, 'Ustadz Ahmad');
      expect(absensi.tanggal, '2024-01-15');
      expect(absensi.status, 'hadir');
      expect(absensi.jamMasuk, '07:00');
      expect(absensi.jamKeluar, '15:00');
    });

    test('fromJson should default status to alpa', () {
      final json = <String, dynamic>{};
      final absensi = AbsensiGuru.fromJson(json);
      expect(absensi.status, 'alpa');
    });

    test('displayName should return guruNama', () {
      const absensi = AbsensiGuru(guruNama: 'Ustadz Ahmad', status: 'hadir');
      expect(absensi.displayName, 'Ustadz Ahmad');
    });

    test('displayName should fallback to guruNip', () {
      const absensi = AbsensiGuru(guruNip: '12345', status: 'hadir');
      expect(absensi.displayName, '12345');
    });

    test('displayName should return - when both null', () {
      const absensi = AbsensiGuru(status: 'hadir');
      expect(absensi.displayName, '-');
    });
  });

  group('AbsensiSiswa', () {
    test('fromJson should parse correctly', () {
      final json = {
        'siswa_nis': 'S001',
        'siswa_nama': 'Budi',
        'kelas_nama': 'X-A',
        'mapel_nama': 'Matematika',
        'tanggal': '2024-01-15',
        'status': 'izin',
        'keterangan': 'Sakit',
      };

      final absensi = AbsensiSiswa.fromJson(json);

      expect(absensi.siswaNis, 'S001');
      expect(absensi.siswaNama, 'Budi');
      expect(absensi.kelasNama, 'X-A');
      expect(absensi.mapelNama, 'Matematika');
      expect(absensi.tanggal, '2024-01-15');
      expect(absensi.status, 'izin');
      expect(absensi.keterangan, 'Sakit');
    });

    test('displayName should return siswaNama', () {
      const absensi = AbsensiSiswa(siswaNama: 'Budi', status: 'hadir');
      expect(absensi.displayName, 'Budi');
    });

    test('displayName should fallback to siswaNis', () {
      const absensi = AbsensiSiswa(siswaNis: 'S001', status: 'hadir');
      expect(absensi.displayName, 'S001');
    });
  });
}
