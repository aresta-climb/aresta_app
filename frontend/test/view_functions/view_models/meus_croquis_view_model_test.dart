// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view_functions/view_models/meus_croquis_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repositorio;
  late SyncService servicoSync;
  late MeusCroquisViewModel viewModel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_meus_croquis_vm_test_');
    final editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
    viewModel = MeusCroquisViewModel(
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

  group('MeusCroquisViewModel', () {
    test('inicialmente sem croquis baixados retorna lista vazia e estaVazio true', () {
      expect(viewModel.croquisSalvos, isEmpty);
      expect(viewModel.estaVazio, isTrue);
    });

    test('ao atualizar dataset notifica ouvintes e mapeia para CardCroquiDTO', () {
      bool notificado = false;
      viewModel.addListener(() {
        notificado = true;
      });

      final croqui = Croqui(
        id: 'pico_offline_teste',
        nome: 'Falésia Paraíso',
        picos: [
          Pico(
            estado: 'Minas Gerais',
            precomputados: PrecomputadosPico(totalSetores: 4, totalEscaladas: 28),
          ),
        ],
      );

      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        croquisBaixados: [croqui],
      );

      expect(notificado, isTrue);
      expect(viewModel.estaVazio, isFalse);
      expect(viewModel.croquisSalvos.length, equals(1));

      final card = viewModel.croquisSalvos.first;
      expect(card.id, equals('pico_offline_teste'));
      expect(card.titulo, equals('FALÉSIA PARAÍSO'));
      expect(card.localizacao, equals('MINAS GERAIS'));
      expect(card.textoEstatisticas, equals('4 setores • 28 escaladas'));
      expect(card.caminhoMiniatura, equals('thumbnails/pico_offline_teste.webp'));
    });

    testWidgets('excluirCroqui exibe diálogo e remove o croqui com sucesso', (tester) async {
      final croqui = Croqui(
        id: 'pico_para_excluir',
        nome: 'Pico Deletável',
        picos: [Pico(nome: 'Pico Deletável')],
      );
      repositorio.activeDataset.value = TopoDataset(
        croquisBaixados: [croqui],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => viewModel.excluirCroqui(context, 'pico_para_excluir', 'Pico Deletável'),
                child: const Text('EXCLUIR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(find.text('Deseja excluir o guia de Pico Deletável?'), findsOneWidget);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.text('Deseja excluir o guia de Pico Deletável?'), findsNothing);
    });
  });
}
