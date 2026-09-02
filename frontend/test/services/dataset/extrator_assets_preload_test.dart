// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/armazenamento/extrator_assets_preload.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAssetBundle extends Fake implements AssetBundle {
  final Map<String, ByteData> _assets = {};

  void addAsset(String key, List<int> bytes) {
    _assets[key] = ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<ByteData> load(String key) async {
    if (_assets.containsKey(key)) {
      return _assets[key]!;
    }
    throw FlutterError('Asset not found: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExtratorAssetsPreload', () {
    late Directory tempDir;
    late ExtratorAssetsPreload extrator;
    late MockAssetBundle mockBundle;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('preload_test_');
      extrator = ExtratorAssetsPreload();
      mockBundle = MockAssetBundle();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('desempacota indice.binarypb e thumbnails com sucesso', () async {
      final indice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'pico_demo'
            ..nome = 'Pico de Demonstração'
            ..caminhoRelativo = 'sao_paulo/pico_demo/pico_demo.binarypb',
        );

      final indiceBytes = indice.writeToBuffer();
      mockBundle.addAsset('assets/preload/indice.binarypb', indiceBytes);
      mockBundle.addAsset('assets/preload/thumbnails/pico_demo.webp', [1, 2, 3, 4]);

      final localIndicePath = '${tempDir.path}/indice.binarypb';

      await extrator.desempacotarAssetsPreload(
        docsPath: tempDir.path,
        indicePath: localIndicePath,
        bundle: mockBundle,
      );

      final localIndiceFile = File(localIndicePath);
      expect(await localIndiceFile.exists(), isTrue);

      final loadedIndice = Indice.fromBuffer(await localIndiceFile.readAsBytes());
      expect(loadedIndice.croquis.first.id, equals('pico_demo'));

      final thumbFile = File('${tempDir.path}/thumbnails/pico_demo.webp');
      expect(await thumbFile.exists(), isTrue);
      expect(await thumbFile.readAsBytes(), equals([1, 2, 3, 4]));
    });

    test('trata graciosamente quando indice não existe no bundle', () async {
      final localIndicePath = '${tempDir.path}/indice.binarypb';

      await extrator.desempacotarAssetsPreload(
        docsPath: tempDir.path,
        indicePath: localIndicePath,
        bundle: mockBundle,
      );

      final localIndiceFile = File(localIndicePath);
      expect(await localIndiceFile.exists(), isFalse);
    });
  });
}
