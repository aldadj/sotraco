import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sotraco_app/services/api_service.dart';

void main() {
  test('ApiService.withTimeout throws TimeoutException when future is too slow', () async {
    final future = () async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return 'done';
    }();

    expect(
      () => ApiService.withTimeout(future, timeout: const Duration(milliseconds: 50)),
      throwsA(isA<TimeoutException>()),
    );
  });
}
