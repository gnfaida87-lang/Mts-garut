import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/shared/models/api_response.dart';
import 'package:mts_garut/shared/models/paginated_response.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson should parse correctly', () {
      final json = {
        'data': {'id': 1, 'name': 'Test'},
        'message': 'Success',
        'pagination': {
          'current_page': 1,
          'total_pages': 5,
          'total_items': 100,
        },
      };

      final response = ApiResponse.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.data['id'], 1);
      expect(response.data['name'], 'Test');
      expect(response.message, 'Success');
      expect(response.currentPage, 1);
      expect(response.totalPages, 5);
      expect(response.totalItems, 100);
    });

    test('fromJson should handle missing pagination', () {
      final json = {
        'data': 'test',
        'message': 'OK',
      };

      final response = ApiResponse.fromJson(json, (data) => data as String);

      expect(response.data, 'test');
      expect(response.currentPage, isNull);
      expect(response.totalPages, isNull);
    });

    test('hasMore should return true when currentPage < totalPages', () {
      const response = ApiResponse(
        data: 'test',
        currentPage: 1,
        totalPages: 5,
      );
      expect(response.hasMore, isTrue);
    });

    test('hasMore should return false when currentPage >= totalPages', () {
      const response = ApiResponse(
        data: 'test',
        currentPage: 5,
        totalPages: 5,
      );
      expect(response.hasMore, isFalse);
    });

    test('fromPaginated should parse list correctly', () {
      final json = {
        'data': [
          {'id': 1},
          {'id': 2},
        ],
        'pagination': {
          'current_page': 1,
          'total_pages': 3,
        },
      };

      final response = ApiResponse<dynamic>.fromPaginated(
        json,
        (item) => item,
      );

      expect(response.data, isA<List>());
      expect((response.data as List).length, 2);
      expect(response.currentPage, 1);
      expect(response.totalPages, 3);
    });
  });

  group('PaginatedResponse', () {
    test('fromJson should parse correctly', () {
      final json = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'pagination': {
          'current_page': 1,
          'total_pages': 5,
          'total_items': 100,
        },
      };

      final response = PaginatedResponse.fromJson(
        json,
        (item) => item as Map<String, dynamic>,
      );

      expect(response.items.length, 2);
      expect(response.items[0]['id'], 1);
      expect(response.currentPage, 1);
      expect(response.totalPages, 5);
      expect(response.totalItems, 100);
    });

    test('hasMore should return true when currentPage < totalPages', () {
      const response = PaginatedResponse(
        items: [],
        currentPage: 1,
        totalPages: 5,
      );
      expect(response.hasMore, isTrue);
    });

    test('hasMore should return false when currentPage >= totalPages', () {
      const response = PaginatedResponse(
        items: [],
        currentPage: 5,
        totalPages: 5,
      );
      expect(response.hasMore, isFalse);
    });

    test('fromJson should handle empty data', () {
      final json = <String, dynamic>{};
      final response = PaginatedResponse.fromJson(
        json,
        (item) => item,
      );

      expect(response.items, isEmpty);
      expect(response.currentPage, 1);
      expect(response.totalPages, 1);
    });
  });
}
