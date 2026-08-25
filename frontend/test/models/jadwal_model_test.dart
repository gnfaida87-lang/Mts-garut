import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/jadwal_model.dart';

void main() {
  group('Jadwal', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'hari': 'Senin',
        'jam_mulai': '07:00',
        'jam_selesai': '08:30',
        'mapel_nama': 'Matematika',
        'guru_nama': 'Ustadz Ahmad',
        'kelas_nama': 'X-A',
        'ruangan_nama': 'Ruang 1',
        'jp_ke': 1,
        'mata_pelajaran_id': 5,
        'guru_id': 10,
        'kelas_id': 3,
        'ruangan_id': 2,
        'semester_id': 1,
        'status': 'aktif',
      };

      final jadwal = Jadwal.fromJson(json);

      expect(jadwal.id, 1);
      expect(jadwal.hari, 'Senin');
      expect(jadwal.jamMulai, '07:00');
      expect(jadwal.jamSelesai, '08:30');
      expect(jadwal.mapelNama, 'Matematika');
      expect(jadwal.guruNama, 'Ustadz Ahmad');
      expect(jadwal.kelasNama, 'X-A');
      expect(jadwal.ruanganNama, 'Ruang 1');
      expect(jadwal.jpKe, 1);
      expect(jadwal.mataPelajaranId, 5);
      expect(jadwal.guruId, 10);
      expect(jadwal.kelasId, 3);
      expect(jadwal.ruanganId, 2);
      expect(jadwal.semesterId, 1);
      expect(jadwal.status, 'aktif');
    });

    test('fromJson should handle alternative field names', () {
      final json = {
        'id': 1,
        'hari': 'Senin',
        'mapel': 'Matematika',
        'guru': 'Ustadz Ahmad',
        'kelas': 'X-A',
        'ruangan': 'Ruang 1',
      };

      final jadwal = Jadwal.fromJson(json);

      expect(jadwal.mapelNama, 'Matematika');
      expect(jadwal.guruNama, 'Ustadz Ahmad');
      expect(jadwal.kelasNama, 'X-A');
      expect(jadwal.ruanganNama, 'Ruang 1');
    });

    test('fromJson should handle null optional fields', () {
      final json = {'id': 1, 'hari': 'Senin'};
      final jadwal = Jadwal.fromJson(json);

      expect(jadwal.id, 1);
      expect(jadwal.hari, 'Senin');
      expect(jadwal.jamMulai, isNull);
      expect(jadwal.jamSelesai, isNull);
      expect(jadwal.mapelNama, isNull);
      expect(jadwal.guruNama, isNull);
    });

    test('toJson should serialize correctly', () {
      const jadwal = Jadwal(
        id: 1,
        hari: 'Senin',
        jamMulai: '07:00',
        jamSelesai: '08:30',
        mataPelajaranId: 5,
        guruId: 10,
        kelasId: 3,
        ruanganId: 2,
        semesterId: 1,
        jpKe: 1,
      );

      final json = jadwal.toJson();

      expect(json['id'], 1);
      expect(json['hari'], 'Senin');
      expect(json['jam_mulai'], '07:00');
      expect(json['jam_selesai'], '08:30');
      expect(json['mata_pelajaran_id'], 5);
      expect(json['guru_id'], 10);
      expect(json['kelas_id'], 3);
      expect(json['ruangan_id'], 2);
      expect(json['semester_id'], 1);
      expect(json['jp_ke'], 1);
    });
  });
}
