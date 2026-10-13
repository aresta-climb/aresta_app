// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view/view_models/mapa_global_view_model.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repositorio;
  late SyncService servicoSync;
  late MapaGlobalViewModel viewModel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_mapa_vm_test_');
    final editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
    viewModel = MapaGlobalViewModel(
      datasetRepo: repositorio,
      syncService: servicoSync,
    );
  });

  tearDown(() {
    viewModel.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MapaGlobalViewModel Tests', () {
    test('picosNoMapa filtra picos sem coordenadas e retorna MapaPicoViewModel válidos', () {
      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          localizacao: Coordenada(
            latitude: -226844440,
            longitude: -456633330,
          ),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 4,
            totalEscaladas: 40,
          ),
        ),
        ResumoCroqui(
          id: 'sem_coord',
          nome: 'Pico Sem Coordenadas',
        ),
      ];

      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      final picos = viewModel.picosNoMapa;
      expect(picos.length, equals(1));
      expect(picos.first.id, equals('bau'));
      expect(picos.first.temCoordenadasValidas, isTrue);
      expect(picos.first.latitude, closeTo(-22.684444, 0.0001));
    });

    test('estaBaixado verifica presença de croqui salvo offline', () {
      final croqui = Croqui(id: 'bau', nome: 'Pedra do Baú');
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        croquisBaixados: [croqui],
      );

      expect(viewModel.estaBaixado('bau'), isTrue);
      expect(viewModel.estaBaixado('inexistente'), isFalse);
    });

    test('picosNoMapa resolve CardCroquiViewModel cruzando com metadados do dataset', () {
      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          localizacao: Coordenada(
            latitude: -226844440,
            longitude: -456633330,
          ),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 4,
            totalEscaladas: 40,
          ),
        ),
      ];

      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      final card = CardCroquiViewModel.deValores(
        id: 'bau',
        titulo: 'PEDRA DO BAÚ',
        textoEstatisticas: '4 setores • 40 escaladas',
        caminhoMiniatura: 'thumbnails/bau.webp',
      );

      final vmComCards = MapaGlobalViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
        picosIniciais: [card],
      );

      final picos = vmComCards.picosNoMapa;
      expect(picos.length, equals(1));
      expect(picos.first.id, equals('bau'));
      expect(picos.first.temCoordenadasValidas, isTrue);
      expect(picos.first.latitude, closeTo(-22.684444, 0.0001));

      vmComCards.dispose();
    });

    test('picosNoMapa resolve identificadores String de picos cruzando com dataset', () {
      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          localizacao: Coordenada(
            latitude: -226844440,
            longitude: -456633330,
          ),
        ),
      ];

      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      final vmComIds = MapaGlobalViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
        picosIniciais: const ['bau'],
      );

      final picos = vmComIds.picosNoMapa;
      expect(picos.length, equals(1));
      expect(picos.first.id, equals('bau'));
      expect(picos.first.temCoordenadasValidas, isTrue);

      vmComIds.dispose();
    });

    test('picosNoMapa faz fallback para catálogo completo quando picosIniciais não gera marcadores válidos', () {
      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          localizacao: Coordenada(
            latitude: -226844440,
            longitude: -456633330,
          ),
        ),
      ];

      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      // Card com id inexistente ou sem coordenadas
      final cardInvalido = CardCroquiViewModel.deValores(
        id: 'desconhecido',
        titulo: 'DESCONHECIDO',
        textoEstatisticas: '',
        caminhoMiniatura: '',
      );

      final vmComInvalido = MapaGlobalViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
        picosIniciais: [cardInvalido],
      );

      // Deve acionar o fallback para todos os picos disponíveis com coordenadas válidas
      final picos = vmComInvalido.picosNoMapa;
      expect(picos.length, equals(1));
      expect(picos.first.id, equals('bau'));

      vmComInvalido.dispose();
    });
  });
}
