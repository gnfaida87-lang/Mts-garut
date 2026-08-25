import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/rapor_model.dart';

void main() {
  group('Rapor', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'siswa_nama': 'Budi',
        'siswa_nis': 'S001',
        'mapel_nama': 'Matematika',
        'kelas_nama': 'X-A',
        'semester_nama': 'Ganjil',
        'predikat': 'A',
        'nilai_akhir': 90,
        'status_kirim': 'draft',
        'catatan_wali_kelas': 'Sangat baik',
      };

      final rapor = Rapor.fromJson(json);

      expect(rapor.id, 1);
      expect(rapor.siswaNama, 'Budi');
      expect(rapor.siswaNis, 'S001');
      expect(rapor.mapelNama, 'Matematika');
      expect(rapor.kelasNama, 'X-A');
      expect(rapor.semesterNama, 'Ganjil');
      expect(rapor.predikat, 'A');
      expect(rapor.nilaiAkhir, 90);
      expect(rapor.statusKirim, 'draft');
      expect(rapor.catatanWaliKelas, 'Sangat baik');
    });

    test('nilaiAkhirNum should return num when nilaiAkhir is num', () {
      const rapor = Rapor(nilaiAkhir: 90);
      expect(rapor.nilaiAkhirNum, 90);
    });

    test('nilaiAkhirNum should parse string nilaiAkhir', () {
      const rapor = Rapor(nilaiAkhir: '85.5');
      expect(rapor.nilaiAkhirNum, 85.5);
    });

    test('isDraft should return true when statusKirim is draft', () {
      const rapor = Rapor(statusKirim: 'draft');
      expect(rapor.isDraft, isTrue);
    });

    test('isSent should return true when statusKirim is terkirim', () {
      const rapor = Rapor(statusKirim: 'terkirim');
      expect(rapor.isSent, isTrue);
    });

    test('isValidated should return true when statusKirim is divalidasi', () {
      const rapor = Rapor(statusKirim: 'divalidasi');
      expect(rapor.isValidated, isTrue);
    });
  });
}
