// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Testes unitários para [ExtratorAssetsPreload], validando a extração de
/// `indice.binarypb`, `catalogo.db` e thumbnails pré-embutidas em `$docsPath/downloads/thumbnails/`
/// e a limpeza do diretório legado `$docsPath/thumbnails/`.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:frontend/services/dataset/armazenamento/extrator_assets_preload.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../../mocks/mock_app_logger.dart';

/// Implementação determinística em memória de [AssetBundle] para testes sem mocks.
class _BundlePreloadFake extends CachingAssetBundle {
  final Map<String, Uint8List> _arquivos = {};

  void registrarAsset(String chave, List<int> bytes) {
    _arquivos[chave] = Uint8List.fromList(bytes);
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = _arquivos[key];
    if (bytes == null) {
      throw FlutterError('Asset não encontrado no bundle fake: $key');
    }
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late Directory tempDir;
  late _BundlePreloadFake bundleFake;
  late MockAppLogger mockLogger;
  late ExtratorAssetsPreload extrator;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('extrator_preload_test');
    bundleFake = _BundlePreloadFake();
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
    SharedPreferences.setMockInitialValues({});
    extrator = ExtratorAssetsPreload();
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ExtratorAssetsPreload', () {
    test(
      'deve extrair indice.binarypb, catalogo.db e thumbnails do preload e remover diretorio legado',
      () async {
        final fakeIndice = Indice(
          versaoCatalogo: 'a1b2c3d4e5f60718',
          croquis: [
            ResumoCroqui(
              id: 'pico_preload_1',
              caminhoRelativo: 'br/mg/pico_preload_1/compilado.binarypb',
            ),
            ResumoCroqui(
              id: '',
              caminhoRelativo: 'br/rj/urca/compilado.binarypb',
            ),
          ],
        );
        final indiceBytes = fakeIndice.writeToBuffer();

        // Cria diretório legado para validar remoção automática
        final dirLegado = Directory('${tempDir.path}/thumbnails')
          ..createSync(recursive: true);
        final arquivoLegado = File('${dirLegado.path}/antigo.webp')
          ..writeAsBytesSync([9, 9, 9]);
        expect(arquivoLegado.existsSync(), isTrue);

        bundleFake.registrarAsset('assets/preload/indice.binarypb', indiceBytes);
        bundleFake.registrarAsset('assets/preload/catalogo.db', [83, 81, 76, 51]);
        bundleFake.registrarAsset(
          'assets/preload/thumbnails/pico_preload_1.webp',
          [10, 20, 30],
        );
        bundleFake.registrarAsset(
          'assets/preload/thumbnails/br_rj_urca.webp',
          [40, 50],
        );

        final indicePath = '${tempDir.path}/indice.binarypb';
        final catalogoPath = '${tempDir.path}/db_sub/catalogo.db';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          catalogoPath: catalogoPath,
          bundle: bundleFake,
        );

        expect(File(indicePath).existsSync(), isTrue);
        expect(File(catalogoPath).existsSync(), isTrue);
        expect(File(catalogoPath).readAsBytesSync(), equals([83, 81, 76, 51]));

        // Deve ter salvo em $docsPath/downloads/thumbnails/
        final thumb1 = File(
          '${tempDir.path}/downloads/thumbnails/pico_preload_1.webp',
        );
        final thumb2 = File(
          '${tempDir.path}/downloads/thumbnails/br_rj_urca.webp',
        );
        expect(thumb1.existsSync(), isTrue);
        expect(thumb1.readAsBytesSync(), equals([10, 20, 30]));
        expect(thumb2.existsSync(), isTrue);
        expect(thumb2.readAsBytesSync(), equals([40, 50]));

        // Diretório legado $docsPath/thumbnails deve ter sido removido
        expect(dirLegado.existsSync(), isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt('cached_data_version'),
          equals(NetworkConstants.kDataVersion),
        );
      },
    );

    test(
      'deve registrar erro e retornar silenciosamente quando indice.binarypb nao existir no preload',
      () async {
        final indicePath = '${tempDir.path}/indice.binarypb';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          bundle: bundleFake,
        );

        expect(File(indicePath).existsSync(), isFalse);
        expect(mockLogger.recordedErrors, isNotEmpty);
      },
    );

    test(
      'deve continuar extracao mesmo se catalogo.db ou uma thumbnail especifica falhar ao carregar do bundle',
      () async {
        final fakeIndice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_sem_asset',
              caminhoRelativo: 'picos/pico_sem_asset/compilado.binarypb',
            ),
          ],
        );
        final indiceBytes = fakeIndice.writeToBuffer();

        bundleFake.registrarAsset('assets/preload/indice.binarypb', indiceBytes);

        final indicePath = '${tempDir.path}/indice.binarypb';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          bundle: bundleFake,
        );

        expect(File(indicePath).existsSync(), isTrue);
        expect(mockLogger.recordedErrors, isNotEmpty);
      },
    );

    test(
      'deve registrar erro geral quando escrita de indicePath falhar ou ao usar rootBundle padrao',
      () async {
        bundleFake.registrarAsset('assets/preload/indice.binarypb', [1, 2]);

        // Passa o próprio diretório como caminho de arquivo para causar falha de escrita
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: tempDir.path,
          bundle: bundleFake,
        );

        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage']
                .toString()
                .contains('Erro geral ao descompactar assets'),
          ),
          isTrue,
        );

        // Exercita fallback para rootBundle quando bundle não é informado
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async => null);
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: '${tempDir.path}/indice_padrao.binarypb',
        );
      },
    );

    test(
      'extrairCatalogoPreload deve extrair catalogo.db quando ausente no disco e preservar quando ja existir',
      () async {
        bundleFake.registrarAsset('assets/preload/catalogo.db', [1, 2, 3, 4]);
        final catalogoPath = '${tempDir.path}/instalacao_existente/catalogo.db';

        // 1. Extrai porque ainda não existe no disco
        await extrator.extrairCatalogoPreload(
          docsPath: tempDir.path,
          catalogoPath: catalogoPath,
          bundle: bundleFake,
        );
        expect(File(catalogoPath).existsSync(), isTrue);
        expect(File(catalogoPath).readAsBytesSync(), equals([1, 2, 3, 4]));

        // 2. Se já existir no disco e sobrescrever=false, não sobrescreve
        bundleFake.registrarAsset('assets/preload/catalogo.db', [9, 9, 9, 9]);
        await extrator.extrairCatalogoPreload(
          docsPath: tempDir.path,
          catalogoPath: catalogoPath,
          bundle: bundleFake,
        );
        expect(File(catalogoPath).readAsBytesSync(), equals([1, 2, 3, 4]));

        // 3. Fallback para rootBundle quando bundle é omitido
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async => null);
        await extrator.extrairCatalogoPreload(
          docsPath: '${tempDir.path}/sem_bundle',
        );
      },
    );
  });
}



