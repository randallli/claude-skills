import 'package:flutter_test/flutter_test.dart';
import 'package:counter_app/counter.dart';

void main() {
  test('starts at zero', () {
    expect(Counter().value, 0);
  });
}
