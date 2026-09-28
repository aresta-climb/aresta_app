// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/view/view_models/browse_view_model.dart';
import '../../mocks/mock_telemetry_service.dart';

import 'dart:io';
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
  late EditorDeCroqui editor;
  late MockTelemetryService mockTelemetria;
  late BrowseViewModel viewModel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('browse_vm_test_');
    PathProviderPlatform.instance = _PlataformaCaminhosMock(tempDir.path);
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;

    viewModel = BrowseViewModel(
      datasetRepo: repositorio,
      syncService: servicoSync,
      telemetria: mockTelemetria,
    );
  });

  tearDown(() {
    viewModel.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BrowseViewModel', () {
    test('carregando é true quando dataset é null', () {
      repositorio.activeDataset.value = null;
      expect(viewModel.carregando, isTrue);
      expect(viewModel.picosFiltrados, isEmpty);
    });

    test('picosFiltrados retorna lista padrão sem filtros', () {
      final pico1 = MetadadosIndice(id: '1', nome: 'Pedra do Baú');
      final pico2 = MetadadosIndice(id: '2', nome: 'Serra do Cipó');

      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú'},
          {'id': '2', 'nome': 'Serra do Cipó'},
        ],
        downloadedPicos: [],
      );

      expect(viewModel.carregando, isFalse);
      expect(viewModel.picosFiltrados.length, equals(2));
      expect(viewModel.picosFiltrados.first.nome, equals(pico1.nome));
      expect(viewModel.picosFiltrados.last.nome, equals(pico2.nome));
    });

    test('alterarTermoBusca filtra picos via busca fuzzy', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú'},
          {'id': '2', 'nome': 'Falésia Paraíso'},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      expect(viewModel.termoBusca, equals('Baú'));
      expect(viewModel.picosFiltrados.length, equals(1));
      expect(viewModel.picosFiltrados.first.nome, equals('Pedra do Baú'));
    });

    test('alterarOrdem ordena alfabeticamente e por número de vias', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'b',
            'nome': 'B Pico',
            'estatisticas': {'totalVias': 10},
          },
          {
            'id': 'a',
            'nome': 'A Pico',
            'estatisticas': {'totalVias': 30},
          },
        ],
        downloadedPicos: [],
      );

      // Alfabético
      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.alfabetico));
      expect(viewModel.picosFiltrados.first.nome, equals('A Pico'));
      expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));

      // Por escaladas (descendente)
      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.escaladas));
      expect(viewModel.picosFiltrados.first.nome, equals('A Pico')); // 30 vias > 10 vias
    });

    test('modoEditorAtivo reflete estado de experimentalMode e editorUrl', () {
      expect(viewModel.modoEditorAtivo, isFalse);

      editor.isExperimentalMode.value = true;
      expect(viewModel.modoEditorAtivo, isTrue);

      editor.isExperimentalMode.value = false;
      editor.editorUrl.value = 'http://localhost:8000';
      expect(viewModel.modoEditorAtivo, isTrue);
    });

    test('estaBaixado verifica presença no dataset local', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        croquisBaixados: [
          Croqui(id: 'pico_salvo', nome: 'Salvo'),
        ],
      );

      expect(viewModel.estaBaixado('pico_salvo'), isTrue);
      expect(viewModel.estaBaixado('pico_ausente'), isFalse);
    });
  });
}
