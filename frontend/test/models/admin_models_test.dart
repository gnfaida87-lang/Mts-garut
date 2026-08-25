import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/admin_models.dart';

void main() {
  group('LogAktivitas', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'aksi': 'create',
        'modul': 'guru',
        'detail': 'Menambah guru baru',
        'username': 'admin',
        'created_at': '2024-01-15 10:00:00',
      };

      final log = LogAktivitas.fromJson(json);

      expect(log.id, 1);
      expect(log.aksi, 'create');
      expect(log.modul, 'guru');
      expect(log.detail, 'Menambah guru baru');
      expect(log.username, 'admin');
      expect(log.createdAt, '2024-01-15 10:00:00');
    });

    test('fromJson should handle null fields', () {
      final json = <String, dynamic>{};
      final log = LogAktivitas.fromJson(json);
      expect(log.id, isNull);
      expect(log.aksi, isNull);
      expect(log.modul, isNull);
    });
  });

  group('HakAkses', () {
    test('fromJson should parse correctly', () {
      final json = {'id': 1, 'role': 'admin', 'modul': 'guru', 'aksi': 'view'};
      final ha = HakAkses.fromJson(json);
      expect(ha.id, 1);
      expect(ha.role, 'admin');
      expect(ha.modul, 'guru');
      expect(ha.aksi, 'view');
    });

    test('toJson should serialize correctly', () {
      const ha = HakAkses(id: 1, role: 'admin', modul: 'guru', aksi: 'create');
      final json = ha.toJson();
      expect(json['role'], 'admin');
      expect(json['modul'], 'guru');
      expect(json['aksi'], 'create');
    });
  });

  group('ProfilSekolah', () {
    test('fromJson should parse correctly', () {
      final json = {
        'nama': 'Madrasah MTs Garut',
        'alamat': 'Jl. Raya No. 1',
        'telepon': '021-1234567',
        'email': 'info@mtsgarut.id',
      };

      final profil = ProfilSekolah.fromJson(json);

      expect(profil.nama, 'Madrasah MTs Garut');
      expect(profil.alamat, 'Jl. Raya No. 1');
      expect(profil.telepon, '021-1234567');
      expect(profil.email, 'info@mtsgarut.id');
    });

    test('toJson should serialize correctly', () {
      const profil = ProfilSekolah(nama: 'MTs Garut', alamat: 'Jl. Raya');
      final json = profil.toJson();
      expect(json['nama'], 'MTs Garut');
      expect(json['alamat'], 'Jl. Raya');
    });
  });
}
