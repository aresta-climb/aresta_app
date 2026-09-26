// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset_repository.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

class FakeDatasetRepository extends Fake implements DatasetRepository {
  final Map<String, Croqui?> croquis = {};
  int chamadasGetCroqui = 0;

  @override
  Future<Croqui?> getCroqui(String id) async {
    chamadasGetCroqui++;
    return croquis[id];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ExtratorMetadadosCroqui extrator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('metadados_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    extrator = ExtratorMetadadosCroqui();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExtratorMetadadosCroqui', () {
    test('extrairCapaPathFromMarkdown extrai primeira imagem de markdown intitulado capa', () {
      final croqui = Croqui();
      final botaoCapa = Botao(
        texto: 'Capa Principal',
        destino: DestinoBotao(
          secaoTextual: ArquivoMarkdown(
            conteudo: '# Bem-vindo\n![Foto da Capa](imagens/capa.jpg)\nMais texto',
          ),
        ),
      );
      croqui.botoes.add(botaoCapa);

      final capa = extrator.extrairCapaPathFromMarkdown(croqui, 'mg_bau');
      expect(capa, equals('mg_bau/imagens/capa.jpg'));
    });

    test('atualizarMetadadosPico popula capaPath e dados do croqui', () async {
      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);

      final imgCapa = File('${picoDir.path}/capa.webp');
      await imgCapa.writeAsBytes([1, 2, 3]);

      final croqui = Croqui(
        id: 'pico_1',
        caminhoThumbnail: 'capa.webp',
      );
      croqui.picos.add(Pico(nome: 'Pico Alpha'));

      final picoData = <String, dynamic>{'id': 'pico_1'};

      await extrator.atualizarMetadadosPico(
        id: 'pico_1',
        picoData: picoData,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
        parsedCroqui: croqui,
      );

      expect(picoData['capaPath'], equals(imgCapa.path));
      expect(picoData['data'], isNotNull);
    });

    test('carregarMetadadosLocais retorna novo ResumoPico com capaPath e croqui tipados', () async {
      final picoDir = Directory('${tempDir.path}/pico_tipado');
      await picoDir.create(recursive: true);

      final imgCapa = File('${picoDir.path}/capa.webp');
      await imgCapa.writeAsBytes([1, 2, 3]);

      final croqui = Croqui(
        id: 'pico_tipado',
        caminhoThumbnail: 'capa.webp',
      );
      croqui.picos.add(Pico(nome: 'Pico Forte'));

      final picoOriginal = const ResumoPico(
        id: 'pico_tipado',
        nome: 'Pico Forte',
        local: 'Minas Gerais',
      );

      final picoCarregado = await extrator.carregarMetadadosLocais(
        pico: picoOriginal,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
        parsedCroqui: croqui,
      );

      expect(picoCarregado.capaPath, equals(imgCapa.path));
      expect(picoCarregado.croqui, equals(croqui));
      expect(picoCarregado.pico?.nome, equals('Pico Forte'));
    });

    test('carregarMetadadosLocais não lê disco manualmente e retorna pico inalterado quando não há repositório nem parsedCroqui', () async {
      final picoDir = Directory('${tempDir.path}/pico_compilado');
      await picoDir.create(recursive: true);

      final croqui = Croqui(
        id: 'pico_compilado',
        nome: 'Pico Compilado Local',
      );
      croqui.picos.add(Pico(nome: 'Pico Compilado Local'));

      final compiladoFile = File('${picoDir.path}/compilado.binarypb');
      await compiladoFile.writeAsBytes(croqui.writeToBuffer());

      final picoOriginal = const ResumoPico(
        id: 'pico_compilado',
        nome: 'Pico Compilado Local',
        local: 'São Paulo',
      );

      final picoCarregado = await extrator.carregarMetadadosLocais(
        pico: picoOriginal,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
      );

      // Como o extrator confia 100% no DatasetRepository e nenhum repositório foi fornecido,
      // ele não realiza leitura manual em disco e retorna o pico inalterado.
      expect(picoCarregado.croqui, isNull);
      expect(picoCarregado.capaPath, isNull);
    });

    test('carregarMetadadosLocais delega resolução ao DatasetRepository.getCroqui quando parsedCroqui for nulo', () async {
      final fakeRepo = FakeDatasetRepository();
      final croquiEsperado = Croqui(
        id: 'pico_remoto',
        nome: 'Pico Resolvido do Repo',
      )..picos.add(Pico(nome: 'Pico Resolvido do Repo'));
      fakeRepo.croquis['pico_remoto'] = croquiEsperado;

      final extratorComRepo = ExtratorMetadadosCroqui(repository: fakeRepo);
      const picoOriginal = ResumoPico(
        id: 'pico_remoto',
        nome: 'Pico Remoto',
        local: 'Minas Gerais',
      );

      final picoCarregado = await extratorComRepo.carregarMetadadosLocais(
        pico: picoOriginal,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
      );

      expect(fakeRepo.chamadasGetCroqui, equals(1));
      expect(picoCarregado.croqui, equals(croquiEsperado));
      expect(picoCarregado.pico?.nome, equals('Pico Resolvido do Repo'));
    });

    test('atualizarMetadadosPico delega resolução ao DatasetRepository.getCroqui quando parsedCroqui for nulo', () async {
      final fakeRepo = FakeDatasetRepository();
      final croquiEsperado = Croqui(
        id: 'pico_atualizar',
        caminhoThumbnail: 'capa.webp',
      )..picos.add(Pico(nome: 'Pico Atualizado'));
      fakeRepo.croquis['pico_atualizar'] = croquiEsperado;

      final extratorComRepo = ExtratorMetadadosCroqui(repository: fakeRepo);
      final picoData = <String, dynamic>{'id': 'pico_atualizar'};

      await extratorComRepo.atualizarMetadadosPico(
        id: 'pico_atualizar',
        picoData: picoData,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
      );

      expect(fakeRepo.chamadasGetCroqui, equals(1));
      expect(picoData['data']?['croqui'], equals(croquiEsperado));
    });
  });
}

