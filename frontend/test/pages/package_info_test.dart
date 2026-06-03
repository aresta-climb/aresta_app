import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.app',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: 'buildSignature',
    );
  });

  testWidgets('PackageInfo test', (WidgetTester tester) async {
    final info = await PackageInfo.fromPlatform();
    expect(info.version, '1.2.3');
  });
}
