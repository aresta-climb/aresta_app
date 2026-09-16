// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/widgets/global_search.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../mocks/mock_telemetry_service.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

void main() {
  group('Teste do Widget GlobalSearch', () {
    late DatasetRepository repo;
    late EditorDeCroqui editor;
    late Directory tempDir;

    setUpAll(() {
      TelemetryService.instance = MockTelemetryService();
      tempDir = Directory.systemTemp.createTempSync('global_search_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    });

    tearDownAll(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    setUp(() async {
      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
    });

    testWidgets('Renderiza a barra de pesquisa e expande ao clicar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalSearch(datasetRepo: repo, downloadedPicos: const []),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifica o estado inicial com texto de dica atualizado
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);

      // Verifica a expansão procurando pelo dropdown de filtro
      expect(find.text('Filtro: Todos'), findsOneWidget);
      expect(
        find.textContaining('Dica: pesquise por picos'),
        findsOneWidget,
      );

      // Digita algo sem correspondência
      await tester.enterText(find.byType(TextField), '7a_inexistente');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Os resultados devem ser "Nenhum resultado"
      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
    });

    testWidgets('Busca encontra picos do catálogo e picos baixados por relevância fuzzy', (
      WidgetTester tester,
    ) async {
      repo.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': 'pico_remoto', 'nome': 'Serra do Cipo', 'local': 'Santana do Riacho, MG'},
          {'id': 'pico_baixado', 'nome': 'Pedra Grande', 'local': 'Igarape, MG'},
        ],
        downloadedPicos: [
          {'id': 'pico_baixado', 'nome': 'Pedra Grande', 'local': 'Igarape, MG'},
        ],
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: repo.activeDataset.value!.downloadedPicos,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Digita para buscar
      await tester.enterText(find.byType(TextField), 'Pedra');
      await tester.pump();

      // Deve encontrar Pedra Grande como salvo offline
      expect(find.text('Pedra Grande'), findsOneWidget);
      expect(find.textContaining('Salvo offline'), findsOneWidget);

      // Digita para buscar o pico do catálogo não baixado
      await tester.enterText(find.byType(TextField), 'Cipo');
      await tester.pump();

      expect(find.text('Serra do Cipo'), findsOneWidget);
      expect(find.textContaining('Catálogo'), findsOneWidget);
    });

    testWidgets('Busca de vias exibe modalidade correta (incluindo Mista para via móvel com fixas)', (
      WidgetTester tester,
    ) async {
      final croqui = Croqui();
      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Sol';
      setor.escaladas.addAll([
        Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Esportiva da Tarde',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        ),
        Escalada(
          viaMovel: ViaMovel(
            nome: 'Fenda da Manhã',
            dificuldade: GrauVia_GrauVia.BR_6SUP,
            quantidadeProtecoesIntermediarias: 3,
          ),
        ),
      ]);
      pico.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
      );
      croqui.picos.add(pico);

      repo.gerenciadorSessaoOnline.registrarCroquiOnline('crag_teste', croqui);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlobalSearch(
                datasetRepo: repo,
                downloadedPicos: const [],
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Busca via esportiva
      await tester.enterText(find.byType(TextField), 'Esportiva');
      await tester.pump();
      expect(find.text('Esportiva da Tarde'), findsOneWidget);
      expect(find.textContaining('Esportiva | 5º • Setor Sol • Pico Teste'), findsOneWidget);

      // Busca via mista (via móvel com fixas)
      await tester.enterText(find.byType(TextField), 'Fenda');
      await tester.pump();
      expect(find.text('Fenda da Manhã'), findsOneWidget);
      expect(find.textContaining('Mista | 6ºsup • Setor Sol • Pico Teste'), findsOneWidget);
    });
  });
}
