// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/view_models/home_view_model.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late EditorDeCroqui editor;
  late DatasetRepository repositorio;
  late SyncService servicoSync;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_home_vm_test_');
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HomeViewModel Tests', () {
    test('inicia em estado de carregamento quando dataset é nulo', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      expect(vm.carregando, isTrue);
      expect(vm.picosProximos, isEmpty);
      vm.dispose();
    });

    test('reage a atualizações no activeDataset e calcula picos mais próximos ordenados por distância', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          caminhoRelativo: 'sp/bau',
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
          id: 'cuscuzeiro',
          nome: 'Cuscuzeiro',
          caminhoRelativo: 'sp/cuscuzeiro',
          localizacao: Coordenada(
            latitude: -221000000,
            longitude: -477000000,
          ),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 2,
            totalEscaladas: 20,
          ),
        ),
      ];

      repositorio.indiceData.value = Indice(croquis: picosIndice);
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      // Usuário próximo a São Bento do Sapucaí (perto da Pedra do Baú)
