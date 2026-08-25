import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    final sampleJson = {
      'id': 1,
      'username': 'admin',
      'role': 'admin',
      'guru_id': null,
    };

    test('fromJson should parse valid JSON', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.id, 1);
      expect(user.username, 'admin');
      expect(user.role, 'admin');
      expect(user.guruId, isNull);
    });

    test('fromJson should parse with guru_id', () {
      final user = UserModel.fromJson({
        'id': 2,
        'username': 'guru1',
        'role': 'guru_mapel_wali_kelas',
        'guru_id': 5,
      });
      expect(user.guruId, 5);
    });

    test('toJson should return correct map', () {
      final user = UserModel.fromJson(sampleJson);
      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['username'], 'admin');
      expect(json['role'], 'admin');
      expect(json['guru_id'], isNull);
    });

    test('isAdmin should return true for admin role', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.isAdmin, isTrue);
      expect(user.isKepalaSekolah, isFalse);
      expect(user.isWakilKurikulum, isFalse);
      expect(user.isGuru, isFalse);
      expect(user.isGuruBk, isFalse);
    });

    test('isGuru should return true for guru_mapel_wali_kelas role', () {
      final user = UserModel.fromJson({
        'id': 3,
        'username': 'guru',
        'role': 'guru_mapel_wali_kelas',
      });
      expect(user.isAdmin, isFalse);
      expect(user.isGuru, isTrue);
    });

    test('isGuruBk should return true for guru_bk role', () {
      final user = UserModel.fromJson({
        'id': 4,
        'username': 'bk',
        'role': 'guru_bk',
      });
      expect(user.isGuruBk, isTrue);
    });

    test('isKepalaSekolah should return true for kepala_sekolah role', () {
      final user = UserModel.fromJson({
        'id': 5,
        'username': 'ks',
        'role': 'kepala_sekolah',
      });
      expect(user.isKepalaSekolah, isTrue);
    });

    test('isWakilKurikulum should return true for wakil_kurikulum role', () {
      final user = UserModel.fromJson({
        'id': 6,
        'username': 'wk',
        'role': 'wakil_kurikulum',
      });
      expect(user.isWakilKurikulum, isTrue);
    });
  });
}
