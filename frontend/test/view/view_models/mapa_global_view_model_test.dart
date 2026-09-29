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
  });
}
