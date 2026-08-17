import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Manifest Configuration', () {
    test('predictive back should be disabled globally to fix BetterFeedback', () {
      // Get the path to the AndroidManifest.xml
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      
      // Ensure the file exists
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml not found');
      
      final manifestContent = manifestFile.readAsStringSync();
      
      // Ensure the fix is present
      expect(
        manifestContent.contains('android:enableOnBackInvokedCallback="false"'),
        isTrue,
        reason: 'The android:enableOnBackInvokedCallback="false" flag is missing from AndroidManifest.xml. '
                'This flag is crucial to prevent the BetterFeedback package from forcefully closing the app '
                'during the drawing phase on Android 14+ devices.',
      );
    });
  });
}
