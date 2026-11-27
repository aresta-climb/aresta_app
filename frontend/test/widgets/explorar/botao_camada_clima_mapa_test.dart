// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_en.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/explorar/botao_camada_clima_mapa.dart';
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
    tempDir = await Directory.systemTemp.createTemp('botao_clima_nav_test_');
    repo = DatasetRepository(
      editorDeCroqui: EditorDeCroqui(),
      repositorioCatalogo: RepositorioCatalogo(
        provedorCaminhoBanco: () async => '${tempDir.path}/catalogo.db',
        fabricaBanco: databaseFactoryFfi,
      ),
    );
    syncService = SyncService(datasetRepository: repo);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BotaoCamadaClimaMapa e DialogoAvisoPrecisaoClima', () {
    testWidgets(
      'inicia desligado, navega pela árvore de nós ao tocar em Ver estatísticas e exige confirmação (~85%) para ativar',
      (tester) async {
        var ativo = false;
        final treeController = TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: BrowseNode(HomeNode()),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: treeController,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    body: Center(
                      child: BotaoCamadaClimaMapa(
                        ativo: ativo,
                        aoAlterarAtivo: (novo) => setState(() => ativo = novo),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('botao_camada_clima_mapa')), findsOneWidget);
        expect(find.byIcon(Icons.thunderstorm_outlined), findsOneWidget);
        expect(ativo, isFalse);

        // 1. Primeiro clique abre o aviso de ~85% com as 6 fontes específicas
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dialogo_aviso_precisao_clima')), findsOneWidget);
        expect(find.text('~85%'), findsOneWidget);
        expect(find.textContaining('Open-Meteo'), findsOneWidget);
        expect(find.textContaining('RainViewer'), findsOneWidget);
        expect(find.textContaining('INPE BDQueimadas'), findsOneWidget);
        expect(find.textContaining('FIRMS'), findsOneWidget);
        expect(find.textContaining('SRTM'), findsOneWidget);
        expect(find.textContaining('Blue Marble'), findsOneWidget);
        expect(
          dicionarioIngles[ChaveTexto.explorarAvisoClimaCorpo],
          allOf(
            contains('~85%'),
            contains('Open-Meteo'),
            contains('RainViewer'),
            contains('INPE BDQueimadas'),
            contains('public NASA mission resources'),
            contains('reference tool instead of absolute truth'),
          ),
        );

        // 1b. Tocar em "Ver estatísticas" fecha o diálogo sem ativar a camada e empilha EstatisticasClimaNode na árvore
        await tester.tap(find.byKey(const Key('botao_ver_estatisticas_clima')));
        await tester.pumpAndSettle();
        expect(ativo, isFalse);
        expect(treeController.currentNode, isA<EstatisticasClimaNode>());
        expect(treeController.currentNode.parent, isA<BrowseNode>());
        treeController.goBack();
        await tester.pumpAndSettle();
        expect(treeController.currentNode, isA<BrowseNode>());

        // 2. Cancelar mantém o botão desligado
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('botao_cancelar_aviso_clima')));
        await tester.pumpAndSettle();
        expect(ativo, isFalse);
        expect(find.byIcon(Icons.thunderstorm_outlined), findsOneWidget);

        // 3. Tocar novamente e pressionar OK ativa a camada
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('botao_confirmar_aviso_clima')));
        await tester.pumpAndSettle();

        expect(ativo, isTrue);
        expect(find.byIcon(Icons.thunderstorm_rounded), findsOneWidget);
        expect(find.byType(BotaoVoltarComRetornoInicio), findsNothing);

        // 4. Tocar no botão já ligado desliga imediatamente sem abrir diálogo
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dialogo_aviso_precisao_clima')), findsNothing);
        expect(ativo, isFalse);
      },
    );
  });
}
