// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/navegacao/botao_voltar_com_retorno_inicio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late DatasetRepository repo;
  late SyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('estatisticas_clima_page_test_');
    repo = DatasetRepository(
      editorDeCroqui: EditorDeCroqui(),
      repositorioCatalogo: RepositorioCatalogo(
        provedorCaminhoBanco: () async => '${tempDir.path}/catalogo.db',
        fabricaBanco: databaseFactoryFfi,
      ),
    );
    syncService = SyncService(datasetRepository: repo);
  });

  tearDown(() async {
    await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.portugues);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PaginaEstatisticasClima', () {
    testWidgets(
      'renderiza sem overflow ou clipping em tela estreita (320x640) nos 5 idiomas e retrocede pela árvore de nós',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final treeController = TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: EstatisticasClimaNode(BrowseNode(HomeNode())),
          ),
        );

        await tester.pumpWidget(
          EscopoIdiomaApp(
            notificador: ControladorIdiomaApp.instancia.notificadorIdioma,
            child: MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
              home: TreeNavigationWrapper(
                key: TreeNavigationWrapper.navKey,
                datasetRepo: repo,
                syncService: syncService,
                treeController: treeController,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const Key('pagina_estatisticas_clima')), findsOneWidget);
        expect(find.textContaining('85%'), findsWidgets);
        expect(find.textContaining('2024'), findsWidgets);
        expect(find.textContaining('5.133'), findsWidgets);

        // Rola até a seção da Hipótese Nula e confere os cálculos explícitos (+27.73σ)
        await tester.scrollUntilVisible(
          find.text('+27.73σ'),
          200.0,
          scrollable: find.descendant(
            of: find.byKey(const Key('pagina_estatisticas_clima')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('+27.73σ'), findsOneWidget);

        // Rola até a Tabela Z e verifica faixa 83.7% – 87.2% + entradas canônicas (1.96 -> 0.9750, 2.57 -> 0.9949)
        await tester.scrollUntilVisible(
          find.text('+2.57'),
          220.0,
          scrollable: find.descendant(
            of: find.byKey(const Key('pagina_estatisticas_clima')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('83.7% – 87.2%'), findsOneWidget);
        expect(find.text('+1.96'), findsOneWidget);
        expect(find.text('0.9750'), findsOneWidget);
        expect(find.text('+2.57'), findsOneWidget);
        expect(find.text('0.9949'), findsOneWidget);

        // Rola até a seção das 6 fontes específicas (3 meteorológicas + 3 NASA)
        await tester.scrollUntilVisible(
          find.text('NASA Blue Marble'),
          220.0,
          scrollable: find.descendant(
            of: find.byKey(const Key('pagina_estatisticas_clima')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Open-Meteo'), findsOneWidget);
        expect(find.text('RainViewer'), findsOneWidget);
        expect(find.text('INPE BDQueimadas'), findsOneWidget);
        expect(find.text('NASA FIRMS (VIIRS 375m / MODIS)'), findsOneWidget);
        expect(find.text('NASA SRTM (30m)'), findsOneWidget);
        expect(find.text('NASA Blue Marble'), findsOneWidget);

        // Verifica ausência total de overflow/clipping nos 5 idiomas suportados em 320px de largura
        for (final idioma in IdiomaApp.values) {
          await ControladorIdiomaApp.instancia.definirIdioma(idioma);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        // Botão voltar da AppBar padrão retorna pela árvore de nós para BrowseNode
        await tester.tap(find.byType(BotaoVoltarComRetornoInicio));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        expect(treeController.currentNode, isA<BrowseNode>());
        expect(find.byKey(const Key('pagina_estatisticas_clima')), findsNothing);
      },
    );
  });
}
