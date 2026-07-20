import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return 'fake_path';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;
  late SyncService mockSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = FakePathProviderPlatform();
    
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    
    PackageInfo.setMockInitialValues(
      appName: 'Aresta Climb',
      packageName: 'com.aresta.app',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: 'buildSignature',
    );
  });

}
