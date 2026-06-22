import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/network_constants.dart';

void main() {
  group('NetworkConstants', () {
    test('NetworkConstants kDataVersion must be correctly defined', () {
      expect(NetworkConstants.kDataVersion, isA<int>());
      expect(NetworkConstants.kDataVersion, greaterThan(0));
    });

    test('kBaseUrl must be correctly defined', () {
      expect(NetworkConstants.kBaseUrl, isNotEmpty);
      expect(NetworkConstants.kBaseUrl, 'https://serving.arestaclimb.com');
    });

    test('officialServerUrl returns combined URL', () {
      expect(
        NetworkConstants.officialServerUrl,
        'https://serving.arestaclimb.com/v${NetworkConstants.kDataVersion}',
      );
    });
  });
}
