// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';

class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackMetadataCollector', () {
    test('coleta todos os metadados com sucesso', () async {
      final mockVersion = MockAndroidBuildVersion();
      when(() => mockVersion.release).thenReturn('13');

      final mockDevice = MockAndroidDeviceInfo();
      when(() => mockDevice.brand).thenReturn('Samsung');
      when(() => mockDevice.model).thenReturn('SM-G991B');
      when(() => mockDevice.version).thenReturn(mockVersion);

      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => 'test_instance_id',
        getPackageInfoOverride: () async => PackageInfo(
          appName: 'Test App',
          packageName: 'com.test',
          version: '1.2.3',
          buildNumber: '10',
        ),
        getOSOverride: () => 'android',
        getNavigationTreeOverride: () => 'HomeNode -> SettingsNode',
        getDeviceInfoOverride: () async => mockDevice,
        getConnectivityOverride: () async => [ConnectivityResult.wifi],
        getTimestampOverride: () => DateTime.utc(2026, 6, 16, 12, 0, 0),
      );

      final metadata = await collector.collect();

      expect(metadata.appInstanceId, 'test_instance_id');
      expect(metadata.os, 'android');
      expect(metadata.osVersion, '13');
      expect(metadata.deviceModel, 'Samsung SM-G991B');
      expect(metadata.appVersion, '1.2.3');
      expect(metadata.navigationTree, 'HomeNode -> SettingsNode');
      expect(metadata.screenSize, 'unknown'); // O teste não passa context
      expect(
        metadata.deviceOrientation,
        'unknown',
      ); // O teste não passa context
      expect(metadata.isDarkMode, 'unknown'); // O teste não passa context
      expect(metadata.connectivity, 'wifi');
      expect(
        metadata.submittedAt,
        '16 de junho de 2026 às 09:00:00 (GMT-3)',
      );
      expect(metadata.submittedAtTimestamp, '2026-06-16T09:00:00.000-03:00');
    });

    test('usa valores padrão caso haja falha ou nulos na coleta', () async {
      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => null,
        getPackageInfoOverride: () async => throw Exception('error'),
        getOSOverride: () => throw Exception('error'),
        getNavigationTreeOverride: () => '',
        getDeviceInfoOverride: () async => throw Exception('error'),
        getConnectivityOverride: () async => throw Exception('error'),
        getTimestampOverride: () => throw Exception('error'),
      );

      final metadata = await collector.collect();

      expect(metadata.appInstanceId, 'unknown');
      expect(metadata.os, '');
      expect(metadata.osVersion, 'unknown');
      expect(metadata.deviceModel, 'unknown');
      expect(metadata.appVersion, 'unknown');
      expect(metadata.navigationTree, 'unknown');
      expect(metadata.screenSize, 'unknown');
      expect(metadata.deviceOrientation, 'unknown');
      expect(metadata.isDarkMode, 'unknown');
      expect(metadata.connectivity, 'unknown');
      expect(metadata.submittedAt, 'unknown');
      expect(metadata.submittedAtTimestamp, 'unknown');
    });

    test('aplica globalActiveNodeOverride corretamente', () async {
      FeedbackMetadataCollector.globalActiveNodeOverride = 'NodeSubstituto';

      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => '123',
        getNavigationTreeOverride: () => 'HomeNode -> OriginalNode',
      );

      final metadata = await collector.collect();
      expect(
        metadata.navigationTree,
        'HomeNode -> NodeSubstituto',
      ); // Como o node tree é uma string fixa, o nosso mock é simples

      FeedbackMetadataCollector.globalActiveNodeOverride = null;
    });

    test('gera caminho canônico mais curto para nós profundos de navegação', () {
      final viaNode = ViaNode(
        cragId: 'bau',
        setorNome: 'Falésia Central',
        grupoNome: 'Bloco A',
        escaladaNome: 'Via Láctea',
        parent: HomeNode(),
      );

      expect(
        viaNode.obterCaminhoCurto(),
        'Início -> Pico (bau) -> Grupo (Bloco A) -> Setor (Falésia Central) -> Via (Via Láctea)',
      );

      final setorSemGrupo = SetorNode(
        cragId: 'bau',
        setorNome: 'Falésia Sul',
        parent: HomeNode(),
      );

      expect(
        setorSemGrupo.obterCaminhoCurto(),
        'Início -> Pico (bau) -> Setor (Falésia Sul)',
      );
    });
  });

  group('Auditoria Criptográfica de Hashes', () {
    late Directory tempDocsDir;
    late Directory tempCacheDir;

    setUp(() async {
      tempDocsDir = await Directory.systemTemp.createTemp('feedback_docs_');
      tempCacheDir = await Directory.systemTemp.createTemp('feedback_cache_');
    });

    tearDown(() async {
      if (await tempDocsDir.exists()) {
        await tempDocsDir.delete(recursive: true);
      }
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }
    });

    test('coleta hashes de auditoria com status INTEGRO quando arquivos coincidem com o índice', () async {
      final croquiBytes = [10, 20, 30, 40];
      final croquiHash = sha256.convert(croquiBytes).toString();

      final thumbBytes = [50, 60, 70];
      final thumbHash = sha256.convert(thumbBytes).toString();

      final indice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'pico_integro',
            checksumSha256Croqui: croquiHash,
            checksumSha256Thumbnail: thumbHash,
          ),
        ],
      );
      final indiceBytes = indice.writeToBuffer();
      final indiceHash = sha256.convert(indiceBytes).toString();

      final indiceFile = File('${tempDocsDir.path}/indice.binarypb');
      await indiceFile.writeAsBytes(indiceBytes);

      final croquiDir = Directory('${tempDocsDir.path}/downloads/pico_integro')..createSync(recursive: true);
      await File('${croquiDir.path}/compilado.binarypb').writeAsBytes(croquiBytes);

      final thumbDir = Directory('${tempDocsDir.path}/thumbnails')..createSync(recursive: true);
      await File('${thumbDir.path}/pico_integro.webp').writeAsBytes(thumbBytes);

      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => 'inst_1',
        getDocsPathOverride: () async => tempDocsDir.path,
        getTempCachePathOverride: () async => tempCacheDir.path,
        getCragIdOverride: () => 'pico_integro',
      );

      final metadata = await collector.collect();

      expect(metadata.indiceSha256, equals(indiceHash));
      expect(metadata.croquiId, equals('pico_integro'));
      expect(metadata.croquiSha256Esperado, equals(croquiHash));
      expect(metadata.croquiSha256Real, equals(croquiHash));
      expect(metadata.croquiStatus, equals('INTEGRO'));
      expect(metadata.thumbnailSha256Esperado, equals(thumbHash));
      expect(metadata.thumbnailSha256Real, equals(thumbHash));
      expect(metadata.thumbnailStatus, equals('INTEGRO'));
    });

    test('identifica status DIVERGENTE quando os arquivos locais divergem dos hashes do índice', () async {
      final indice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'pico_divergente',
            checksumSha256Croqui: 'hash_esperado_croqui',
            checksumSha256Thumbnail: 'hash_esperado_thumb',
          ),
        ],
      );
      await File('${tempDocsDir.path}/indice.binarypb').writeAsBytes(indice.writeToBuffer());

      final croquiDir = Directory('${tempDocsDir.path}/downloads/pico_divergente')..createSync(recursive: true);
      await File('${croquiDir.path}/compilado.binarypb').writeAsBytes([9, 9, 9]);

      final thumbDir = Directory('${tempDocsDir.path}/thumbnails')..createSync(recursive: true);
      await File('${thumbDir.path}/pico_divergente.webp').writeAsBytes([8, 8, 8]);

      final collector = FeedbackMetadataCollector(
        getDocsPathOverride: () async => tempDocsDir.path,
        getTempCachePathOverride: () async => tempCacheDir.path,
        getCragIdOverride: () => 'pico_divergente',
      );

      final metadata = await collector.collect();

      expect(metadata.croquiStatus, equals('DIVERGENTE'));
      expect(metadata.croquiSha256Esperado, equals('hash_esperado_croqui'));
      expect(metadata.croquiSha256Real, equals(sha256.convert([9, 9, 9]).toString()));
      expect(metadata.thumbnailStatus, equals('DIVERGENTE'));
      expect(metadata.thumbnailSha256Esperado, equals('hash_esperado_thumb'));
      expect(metadata.thumbnailSha256Real, equals(sha256.convert([8, 8, 8]).toString()));
    });

    test('identifica status NAO_BAIXADO quando os arquivos não existem localmente', () async {
      final indice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'pico_nao_baixado',
            checksumSha256Croqui: 'hash_croqui_esperado',
            checksumSha256Thumbnail: 'hash_thumb_esperado',
          ),
        ],
      );
      await File('${tempDocsDir.path}/indice.binarypb').writeAsBytes(indice.writeToBuffer());

      final collector = FeedbackMetadataCollector(
        getDocsPathOverride: () async => tempDocsDir.path,
        getTempCachePathOverride: () async => tempCacheDir.path,
        getCragIdOverride: () => 'pico_nao_baixado',
      );

      final metadata = await collector.collect();

      expect(metadata.croquiStatus, equals('NAO_BAIXADO'));
      expect(metadata.croquiSha256Real, isNull);
      expect(metadata.thumbnailStatus, equals('NAO_BAIXADO'));
      expect(metadata.thumbnailSha256Real, isNull);
    });

    test('coleta apenas indiceSha256 quando nenhum croqui ativo está em visualização', () async {
      final indiceBytes = [1, 2, 3];
      await File('${tempDocsDir.path}/indice.binarypb').writeAsBytes(indiceBytes);

      final collector = FeedbackMetadataCollector(
        getDocsPathOverride: () async => tempDocsDir.path,
        getTempCachePathOverride: () async => tempCacheDir.path,
        getCragIdOverride: () => null,
      );

      final metadata = await collector.collect();

      expect(metadata.indiceSha256, equals(sha256.convert(indiceBytes).toString()));
      expect(metadata.croquiId, isNull);
      expect(metadata.croquiStatus, isNull);
      expect(metadata.thumbnailStatus, isNull);
    });

    test('reconhece croqui ativo a partir de temp_cache indexado por hash', () async {
      final croquiBytes = [7, 7, 7];
      final croquiHash = sha256.convert(croquiBytes).toString();

      final indice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'pico_cache',
            checksumSha256Croqui: croquiHash,
          ),
        ],
      );
      await File('${tempDocsDir.path}/indice.binarypb').writeAsBytes(indice.writeToBuffer());

      final cacheDir = Directory('${tempCacheDir.path}/pico_cache')..createSync(recursive: true);
      await File('${cacheDir.path}/compilado.binarypb.$croquiHash').writeAsBytes(croquiBytes);

      final collector = FeedbackMetadataCollector(
        getDocsPathOverride: () async => tempDocsDir.path,
        getTempCachePathOverride: () async => tempCacheDir.path,
        getCragIdOverride: () => 'pico_cache',
      );

      final metadata = await collector.collect();

      expect(metadata.croquiSha256Real, equals(croquiHash));
      expect(metadata.croquiStatus, equals('INTEGRO'));
    });
  });
}
