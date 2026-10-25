// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import '../../mocks/mock_telemetria.dart';

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

    test('picosFiltrados usa fallback alfabético (A-Z) quando sem localização na ordem proximidade padrão', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '2', 'nome': 'Serra do Cipó'},
          {'id': '1', 'nome': 'Pedra do Baú'},
        ],
        downloadedPicos: [],
      );

      expect(viewModel.carregando, isFalse);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.proximidade));
      expect(viewModel.picosFiltrados.length, equals(2));
      expect(viewModel.picosFiltrados.first.nome, equals('Pedra do Baú'));
      expect(viewModel.picosFiltrados.last.nome, equals('Serra do Cipó'));
      expect(viewModel.picosCards.first.textoDistancia, isNull);
    });

    test('ordenação por proximidade produz exatamente a mesma ordem e distância da HomeViewModel e preserva badges em todas as ordenações', () {
      final picos = List.generate(
        8,
        (i) => {
          'id': 'pico_$i',
          'nome': 'Pico ${8 - i}',
          'latitude': -22.0 - (i * 0.2),
          'longitude': -45.0,
          'estatisticas': {'totalVias': (i + 1) * 10},
        },
      );

      repositorio.activeDataset.value = TopoDataset(
        availablePicos: picos.reversed.toList(),
        downloadedPicos: [],
      );

      final homeVm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      homeVm.atualizarLocalizacaoUsuario(-22.0, -45.0);
      viewModel.atualizarLocalizacaoUsuario(-22.0, -45.0);

      expect(viewModel.latitudeUsuario, equals(-22.0));
      expect(viewModel.longitudeUsuario, equals(-45.0));

      // Os 6 primeiros picos de BrowseViewModel devem ser idênticos aos 6 de HomeViewModel
      final idsHome = homeVm.picosProximos.map((p) => p.id).toList();
      final idsExplorarTop6 = viewModel.picosFiltrados.take(6).map((p) => p.id).toList();
      expect(idsExplorarTop6, equals(idsHome));
      expect(viewModel.picosFiltrados.length, equals(8));
      expect(viewModel.picosFiltrados[6].id, equals('pico_6'));

      // As badges de distância nos 6 primeiros cards devem ser idênticas às da Home
      final distHome = homeVm.picosProximos.map((p) => p.paraCardCroquiViewModel().textoDistancia).toList();
      final distExplorarTop6 = viewModel.picosCards.take(6).map((c) => c.textoDistancia).toList();
      expect(distExplorarTop6, equals(distHome));
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      // Ao mudar para Alfabético ou Mais escaladas, todos os cards continuam exibindo textoDistancia
      viewModel.alterarOrdem(OrdemOrdenacaoPico.alfabetico);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.picosCards.every((c) => c.textoDistancia != null), isTrue);

      homeVm.dispose();
    });

    test('focarSetimoPicoProximo limpa busca, restaura ordem proximidade e incrementa solicitacaoScrollSetimoPico', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': '1', 'nome': 'Pedra do Baú', 'latitude': -22.68, 'longitude': -45.66},
        ],
        downloadedPicos: [],
      );

      viewModel.alterarTermoBusca('Baú');
      viewModel.alterarOrdem(OrdemOrdenacaoPico.escaladas);
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(0));

      viewModel.focarSetimoPicoProximo();

      expect(viewModel.termoBusca, isEmpty);
      expect(viewModel.ordem, equals(OrdemOrdenacaoPico.proximidade));
      expect(viewModel.solicitacaoScrollSetimoPico.value, equals(1));
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
