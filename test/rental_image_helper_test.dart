import 'package:bluebug/screens/rent/rent_rentout_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes rental image values from stored DB arrays and data URIs',
      () {
    expect(
      normalizeRentalImageValue(['data:image/jpeg;base64,AAAA', 'ignored']),
      'data:image/jpeg;base64,AAAA',
    );

    expect(
      normalizeRentalImageValue('{"data:image/png;base64,BBBB"}'),
      'data:image/png;base64,BBBB',
    );

    expect(
      normalizeRentalImageValue('https://example.com/house.jpg'),
      'https://example.com/house.jpg',
    );
  });
}
