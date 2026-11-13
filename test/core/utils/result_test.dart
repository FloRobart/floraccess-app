import 'package:floraccess_app/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.when', () {
    test('calls the success branch with the data of a Success', () {
      const Result<int> result = Success(42);

      final description = result.when(
        success: (data) => 'success: $data',
        error: (message) => 'error: $message',
      );

      expect(description, 'success: 42');
    });

    test('calls the error branch with the message of a Failure', () {
      const Result<int> result = Failure('Network unavailable');

      final description = result.when(
        success: (data) => 'success: $data',
        error: (message) => 'error: $message',
      );

      expect(description, 'error: Network unavailable');
    });
  });
}
