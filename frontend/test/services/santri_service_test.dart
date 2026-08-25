import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/features/santri/services/santri_service.dart';

void main() {
  group('SantriService', () {
    test('should instantiate without error', () {
      final service = SantriService();
      expect(service, isNotNull);
    });
  });
}
