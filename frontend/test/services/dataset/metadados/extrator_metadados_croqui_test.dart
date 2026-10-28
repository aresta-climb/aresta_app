// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => '$tempPath/temp_cache';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory diretorioTemp;
  late EditorDeCroqui editor;
  late DatasetRepository repositorio;
  late ExtratorMetadadosCroqui extrator;

  setUp(() async {
    diretorioTemp = await Directory.systemTemp.createTemp('metadados_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(diretorioTemp.path);
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    extrator = ExtratorMetadadosCroqui(repository: repositorio);
  });

  tearDown(() async {
    if (await diretorioTemp.exists()) {
      await diretorioTemp.delete(recursive: true);
    }
  });

  group('ExtratorMetadadosCroqui', () {
    test(
      'carregarMetadadosLocais vincula croqui e pico ao ResumoPico sem resolver capaPath antecipadamente em disco',
      () async {
        final downloadsPath = editor.downloadsPath(diretorioTemp.path);
        final picoDir = Directory('$downloadsPath/pico_tipado');
        await picoDir.create(recursive: true);

        final imgCapa = File('${picoDir.path}/capa.webp');
        await imgCapa.writeAsBytes([1, 2, 3]);

        final croqui = Croqui(
          id: 'pico_tipado',
          caminhoThumbnail: 'capa.webp',
        )..picos.add(Pico(nome: 'Pico Forte'));

        const picoOriginal = ResumoPico(
          id: 'pico_tipado',
          nome: 'Pico Forte',
          local: 'Minas Gerais',
        );

        final picoCarregado = await extrator.carregarMetadadosLocais(
          pico: picoOriginal,
          downloadsPath: downloadsPath,
          baseUrl: 'https://exemplo.com',
          parsedCroqui: croqui,
        );

        expect(picoCarregado.croqui, equals(croqui));
        expect(picoCarregado.pico?.nome, equals('Pico Forte'));
        expect(
          picoCarregado.capaPath,
          isNull,
          reason: 'Não deve resolver nem preencher capaPath antecipadamente em disco',
        );
      },
    );

    test(
      'carregarMetadadosLocais resolve croqui via DatasetRepository real a partir de compilado.binarypb quando parsedCroqui é nulo',
      () async {
        final downloadsPath = editor.downloadsPath(diretorioTemp.path);
        final picoDir = Directory('$downloadsPath/pico_disco');
        await picoDir.create(recursive: true);

        final croquiEsperado = Croqui(
          id: 'pico_disco',
          nome: 'Pico do Disco',
        )..picos.add(Pico(nome: 'Pico do Disco Principal'));

        final arquivoCompilado = File('${picoDir.path}/compilado.binarypb');
        await arquivoCompilado.writeAsBytes(croquiEsperado.writeToBuffer());

        const picoOriginal = ResumoPico(
          id: 'pico_disco',
          nome: 'Pico do Disco',
          local: 'Minas Gerais',
        );

        final extratorSemInjecao = ExtratorMetadadosCroqui();
        final picoCarregado = await extratorSemInjecao.carregarMetadadosLocais(
          pico: picoOriginal,
          downloadsPath: downloadsPath,
          baseUrl: 'https://exemplo.com',
          repositoryOverride: repositorio,
        );

        expect(picoCarregado.croqui?.id, equals('pico_disco'));
        expect(picoCarregado.pico?.nome, equals('Pico do Disco Principal'));
      },
    );

    test(
      'carregarMetadadosLocais retorna ResumoPico inalterado quando o croqui não é encontrado no repositório',
      () async {
        final downloadsPath = editor.downloadsPath(diretorioTemp.path);
        const picoOriginal = ResumoPico(
          id: 'pico_inexistente',
          nome: 'Pico Inexistente',
          local: 'São Paulo',
        );

        final picoCarregado = await extrator.carregarMetadadosLocais(
          pico: picoOriginal,
          downloadsPath: downloadsPath,
          baseUrl: 'https://exemplo.com',
        );

        expect(picoCarregado.croqui, isNull);
        expect(picoCarregado.pico, isNull);
      },
    );

    test(
      'extrairCapaPathFromMarkdown extrai e normaliza caminho relativo de imagem em botão de capa',
      () {
        final croqui = Croqui(
          botoes: [
            Botao(
              texto: 'Capa Principal',
              destino: DestinoBotao(
                secaoTextual: ArquivoMarkdown(
                  conteudo: '# Bem-vindo\n![Foto da Capa](./imagens/capa.jpg)\nMais texto',
                ),
              ),
            ),
          ],
        );

        expect(
          extrator.extrairCapaPathFromMarkdown(croqui, 'mg_bau'),
          equals('mg_bau/imagens/capa.jpg'),
        );
        expect(
          extrator.extrairCapaPathFromMarkdown(croqui, ''),
          equals('imagens/capa.jpg'),
        );

        final croquiComBarra = Croqui(
          botoes: [
            Botao(
              texto: 'Capa',
              destino: DestinoBotao(
                secaoTextual: ArquivoMarkdown(
                  conteudo: '![Capa](/mg_bau/imagens/capa.jpg)',
                ),
              ),
            ),
          ],
        );
        expect(
          extrator.extrairCapaPathFromMarkdown(croquiComBarra, 'mg_bau'),
          equals('mg_bau/imagens/capa.jpg'),
        );
      },
    );

    test(
      'extrairCapaPathFromMarkdown retorna null quando botão capa contém URL http ou não existe',
      () {
        final croquiHttp = Croqui(
          botoes: [
            Botao(
              texto: 'Capa Remota',
              destino: DestinoBotao(
                secaoTextual: ArquivoMarkdown(
                  conteudo: '![Capa](https://exemplo.com/capa.jpg)',
                ),
              ),
            ),
          ],
        );

        expect(extrator.extrairCapaPathFromMarkdown(croquiHttp, 'mg_bau'), isNull);
        expect(extrator.extrairCapaPathFromMarkdown(Croqui(), 'mg_bau'), isNull);
      },
    );
  });
}
