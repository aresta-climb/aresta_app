// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/pico_subpages/explorar_local_page.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/utils/pico_categorization.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempDir;
  final String docDir;

  _MockPathProviderPlatform({required this.tempDir, required this.docDir});

  @override
  Future<String?> getApplicationDocumentsPath() async => docDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late HttpServer servidorHttp;
  late Directory pastaTemp;
  late Directory pastaDocs;
  late DatasetRepository repositorioDataset;
  late EditorDeCroqui editorDeCroqui;

  int contagemRequisicoesCapa = 0;

  // Imagem PNG 1x1 válida
  final bytesPngValidos = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );
  final hashSha256Capa = sha256.convert(bytesPngValidos).toString();

  setUpAll(() async {
    servidorHttp = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidorHttp.listen((HttpRequest requisicao) {
      final caminhoUri = requisicao.uri.path;
      if (caminhoUri.contains('capa.png')) {
        contagemRequisicoesCapa++;
        requisicao.response.headers.contentType = ContentType('image', 'png');
        requisicao.response.statusCode = HttpStatus.ok;
        requisicao.response.add(bytesPngValidos);
        requisicao.response.close();
        return;
      }
      requisicao.response.statusCode = HttpStatus.notFound;
      requisicao.response.close();
    });
  });

  tearDownAll(() async {
    await servidorHttp.close(force: true);
  });

  setUp(() async {
    HttpOverrides.global = null;
    contagemRequisicoesCapa = 0;
    pastaTemp = await Directory.systemTemp.createTemp('teste_cache_temp_');
    pastaDocs = await Directory.systemTemp.createTemp('teste_cache_docs_');

    PathProviderPlatform.instance = _MockPathProviderPlatform(
      tempDir: pastaTemp.path,
      docDir: pastaDocs.path,
    );

    editorDeCroqui = EditorDeCroqui();
    editorDeCroqui.isExperimentalMode.value = true;
    editorDeCroqui.editorUrl.value = 'http://127.0.0.1:${servidorHttp.port}';

    repositorioDataset = DatasetRepository(editorDeCroqui: editorDeCroqui);
  });

  tearDown(() async {
    try {
      if (await pastaTemp.exists()) {
        await pastaTemp.delete(recursive: true);
      }
      if (await pastaDocs.exists()) {
        await pastaDocs.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets(
    'Fluxo de navegação em croqui online reutiliza imagem em disco e dispara exatamente 1 requisição de rede',
    (WidgetTester tester) async {
      HttpOverrides.global = null;
      const idPico = 'pico_online_integracao';
      final pico = Pico()..nome = 'Pico de Teste Online';

      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'capa.png'
            ..checksumSha256 = hashSha256Capa,
        )
        ..botoes.add(
          Botao()
            ..texto = 'Capa'
            ..destino = (DestinoBotao()
              ..secaoTextual = (ArquivoMarkdown()
                ..conteudo = '![Capa do Local](capa.png)')),
        );

      // Indexa o checksum SHA-256 no DatasetRepository para resolução automática
      repositorioDataset.indexarMidiasDoCroqui(idPico, croqui);
      repositorioDataset.gerenciadorSessaoOnline.registrarCroquiOnline(idPico, croqui);

      final categorias = PicoCategorizedData(croqui);

      // 1. Abre a página ExplorarLocalPage pela primeira vez dentro do contexto assíncrono real
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => ExplorarLocalPage(
                    pico: pico,
                    cragId: idPico,
                    categories: categorias,
                  ),
                );
              },
            ),
          ),
        );

        final limite = DateTime.now().add(const Duration(seconds: 3));
        while (contagemRequisicoesCapa == 0 && DateTime.now().isBefore(limite)) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      // Reconstrói a árvore após resolução do FutureBuilder
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        contagemRequisicoesCapa,
        equals(1),
        reason: 'A primeira abertura deve baixar a imagem da CDN',
      );

      // 2. Simula o usuário saindo da página e reabrindo (pop e push de nova rota)
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExplorarLocalPage(
                          pico: pico,
                          cragId: idPico,
                          categories: categorias,
                        ),
                      ),
                    );
                  },
                  child: const Text('Reabrir'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Clica para reabrir
      await tester.tap(find.text('Reabrir'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // 3. Validação do Princípio V: A reabertura DEVE ler do temp_cache e NÃO disparar uma 2ª requisição
      expect(
        contagemRequisicoesCapa,
        equals(1),
        reason:
            'A reabertura não pode disparar nova requisição HTTP; deve usar o cache volátil em disco',
      );
    },
  );
}
