// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Testes unitários para [ExtratorAssetsPreload], validando a extração de
/// `indice.binarypb` e thumbnails pré-embutidas em `$docsPath/downloads/thumbnails/`
/// e a limpeza do diretório legado `$docsPath/thumbnails/`.
library;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:frontend/services/dataset/armazenamento/extrator_assets_preload.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../../mocks/mock_app_logger.dart';

class _MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  late Directory tempDir;
  late _MockAssetBundle mockBundle;
  late MockAppLogger mockLogger;
  late ExtratorAssetsPreload extrator;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('extrator_preload_test');
    mockBundle = _MockAssetBundle();
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
      'deve extrair thumbnails do preload em \$docsPath/downloads/thumbnails/ e remover diretorio legado \$docsPath/thumbnails/',
      () async {
        final fakeIndice = Indice(
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

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        when(
          () => mockBundle.load('assets/preload/thumbnails/pico_preload_1.webp'),
        ).thenAnswer(
          (_) async => ByteData.view(Uint8List.fromList([10, 20, 30]).buffer),
        );

        when(
          () => mockBundle.load('assets/preload/thumbnails/br_rj_urca.webp'),
        ).thenAnswer(
          (_) async => ByteData.view(Uint8List.fromList([40, 50]).buffer),
        );

        final indicePath = '${tempDir.path}/indice.binarypb';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          bundle: mockBundle,
        );

        expect(File(indicePath).existsSync(), isTrue);

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
        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenThrow(Exception('Asset nao encontrado'));

        final indicePath = '${tempDir.path}/indice.binarypb';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          bundle: mockBundle,
        );

        expect(File(indicePath).existsSync(), isFalse);
        expect(mockLogger.recordedErrors, isNotEmpty);
      },
    );

    test(
      'deve continuar extracao mesmo se uma thumbnail especifica falhar ao carregar do bundle',
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

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        when(
          () => mockBundle.load('assets/preload/thumbnails/pico_sem_asset.webp'),
        ).thenThrow(Exception('Thumbnail ausente no bundle'));

        final indicePath = '${tempDir.path}/indice.binarypb';
        await extrator.desempacotarAssetsPreload(
          docsPath: tempDir.path,
          indicePath: indicePath,
          bundle: mockBundle,
        );

        expect(File(indicePath).existsSync(), isTrue);
        expect(mockLogger.recordedErrors, isNotEmpty);
      },
    );
  });
}
