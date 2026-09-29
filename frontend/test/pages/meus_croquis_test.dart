// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/meus_croquis_functions.dart';
import 'package:frontend/view/view_models/meus_croquis_view_model.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../mocks/mock_geolocator_platform.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _PlataformaCaminhosMock extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String caminhoTemp;
  _PlataformaCaminhosMock(this.caminhoTemp);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoTemp;
  @override
  Future<String?> getTemporaryPath() async => caminhoTemp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late DatasetRepository repositorio;
  late SyncService servicoSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RegistroPrimeiraVisita.resetForTesting();
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    tempDir = await Directory.systemTemp.createTemp('meus_croquis_page_test_');
    PathProviderPlatform.instance = _PlataformaCaminhosMock(tempDir.path);

    final editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestWidget({MeusCroquisViewModel? viewModel}) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(extensions: [AppColors.dark]),
        child: MeusCroquisPage(
          viewModel: viewModel ??
              MeusCroquisViewModel(
                datasetRepo: repositorio,
                syncService: servicoSync,
              ),
        ),
      ),
    );
  }

  group('MeusCroquisPage - Testes de Widget e ViewModel', () {
    testWidgets('exibe mensagem quando não houver croquis baixados offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MEUS CROQUIS'), findsOneWidget);
      expect(find.text('ARMAZENAMENTO OFFLINE'), findsOneWidget);
      expect(find.text('Nenhum croqui salvo offline ainda.'), findsOneWidget);
      expect(find.byType(OfflineCragCard), findsNothing);
    });

    testWidgets('renderiza OfflineCragCard quando há croquis salvos offline', (
      WidgetTester tester,
    ) async {
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        availablePicos: [],
        croquisBaixados: [
          Croqui(
            id: 'croqui_1',
            nome: 'Pico da Neblina',
            picos: [
              Pico(
                estado: 'Amazonas',
                precomputados: PrecomputadosPico(totalSetores: 2, totalEscaladas: 10),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nenhum croqui salvo offline ainda.'), findsNothing);
      expect(find.byType(OfflineCragCard), findsOneWidget);
      expect(find.text('PICO DA NEBLINA'), findsOneWidget);
      expect(find.text('AMAZONAS'), findsOneWidget);
    });

    testWidgets('renderiza com ViewModel customizado injetado', (
      WidgetTester tester,
    ) async {
      final vmCustomizado = MeusCroquisViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      await tester.pumpWidget(buildTestWidget(viewModel: vmCustomizado));
      await tester.pumpAndSettle();

      expect(find.text('MEUS CROQUIS'), findsOneWidget);
      expect(find.text('Nenhum croqui salvo offline ainda.'), findsOneWidget);
    });

    testWidgets('exibe lista de cards e abre croqui salvo em compilado.binarypb com sucesso', (
      WidgetTester tester,
    ) async {
      final picoDir = Directory('${tempDir.path}/downloads/pedra_do_bau')
        ..createSync(recursive: true);
      final croqui = Croqui(
        id: 'pedra_do_bau',
        nome: 'Pedra do Baú',
        picos: [
          Pico(
            nome: 'Baú',
            estado: 'São Paulo',
          ),
        ],
      );
      File('${picoDir.path}/compilado.binarypb')
          .writeAsBytesSync(croqui.writeToBuffer());

      final crag = croqui.paraResumoPico();
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        croquisBaixados: [croqui],
        picosBaixados: [crag],
        picosDisponiveis: [crag],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repositorio,
            syncService: servicoSync,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final treeController = TreeNavigationWrapper.currentTreeController!;
      treeController.navigateTo(MeusCroquisNode(const HomeNode()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PEDRA DO BAÚ'), findsOneWidget);
      expect(find.text('ABRIR OFFLINE'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('ABRIR OFFLINE'));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(treeController.currentNode, isA<PicoNode>());
      expect(find.text('BAÚ'), findsOneWidget);
    });
  });
}
