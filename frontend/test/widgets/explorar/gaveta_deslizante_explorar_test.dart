// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/widgets/explorar/gaveta_deslizante_explorar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../fakes/cliente_clima_altimetria_fake.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  sqfliteFfiInit();
  late Directory dirTemp;
  late RepositorioCatalogo catalogo;
  late DatasetRepository repo;
  late SyncService sync;
  late ServicoClimaAltimetria servicoClima;
  late BrowseViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TelemetryService.instance = MockTelemetryService();
    dirTemp = await Directory.systemTemp.createTemp('gaveta_explorar_');

    catalogo = RepositorioCatalogo(
      fabricaBanco: databaseFactoryFfi,
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
    );

    repo = DatasetRepository(
      editorDeCroqui: EditorDeCroqui(),
      repositorioCatalogo: catalogo,
    );

    final listaPicos = List.generate(8, (i) {
      return ResumoCroqui(
        id: 'pico_$i',
        nome: 'Pico Gaveta $i',
        localizacao: Coordenada(
          latitude: ((-20.0 - i * 0.12) * 1e7).round(),
          longitude: (-44.0 * 1e7).round(),
        ),
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 2,
          totalEscaladas: 20 + i,
          totalEsportivas: 15,
          totalMultiplasEnfiadas: i.isEven ? 5 : 0,
        ),
      );
    });

    repo.activeDataset.value = ConjuntoDadosCroqui(
      metadadosDisponiveis: listaPicos,
      croquisBaixados: [Croqui(id: 'pico_0', nome: 'Pico Gaveta 0')],
    );

    final agora = DateTime.utc(2026, 11, 25, 12);
    final fakeRemoto = ClienteClimaAltimetriaFake(
      snapshotInicial: SnapshotClimaAltimetria(
        geradoEm: agora,
        bolhasChuva: const [],
        chuvaPorPico: {
          'pico_1': [
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 25),
              milimetros: 9.0,
            ),
          ],
          'pico_2': [
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 23),
              milimetros: 9.0,
            ),
          ],
          'pico_5': [
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 24),
              milimetros: 18.0,
            ),
          ],
        },
        altimetriaPorPico: const {
          'pico_0': CotaAltimetricaPico(
            altitudeBaseMetros: 800,
            altitudePicoMetros: 1180,
          ),
          'pico_5': CotaAltimetricaPico(
            altitudeBaseMetros: 960,
            altitudePicoMetros: 1450,
          ),
        },
      ),
    );

    sync = SyncService(datasetRepository: repo);
    servicoClima = ServicoClimaAltimetria(
      armazenamento: ArmazenamentoClimaLocal(
        provedorDiretorioBase: () async => dirTemp.path,
      ),
      fonteRemota: fakeRemoto,
      relogioUtc: () => agora,
    );
    await servicoClima.inicializar();
    await servicoClima.sincronizarSeNecessario(forcar: true);

    viewModel = BrowseViewModel(
      datasetRepo: repo,
      syncService: sync,
      servicoClima: servicoClima,
    )..atualizarLocalizacaoUsuario(-20.0, -44.0);
  });

  tearDown(() async {
    viewModel.dispose();
    servicoClima.dispose();
    await catalogo.fechar();
    if (await dirTemp.exists()) {
      try {
        await dirTemp.delete(recursive: true);
      } catch (_) {}
    }
  });

  group('GavetaDeslizanteExplorar', () {
    testWidgets(
      'alterna entre os 3 encaixes (Mapa, Dividir, Lista), exibe altitude e alerta contextual de chuva apenas em picos umidos, e faz auto-scroll ao selecionar no mapa',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final alturaPx = ValueNotifier<double>(0);
        addTearDown(alturaPx.dispose);
        String? focadoNoGlobo;
        final abertosIds = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GavetaDeslizanteExplorar(
                    viewModel: viewModel,
                    alturaGavetaPx: alturaPx,
                    posicaoInicial: PosicaoEncaixeGaveta.mapa,
                    aoAbrirPico: (card) => abertosIds.add(card.id),
                    aoFocarPicoNaLista: (id) => focadoNoGlobo = id,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final alturaMapa = alturaPx.value;
        // No modo Mapa, exibe apenas a borda fina da alca arrastavel (< 40px)
        expect(alturaMapa, lessThan(40.0));

        // Tocar na borda recolhida restaura Dividir; recolhe de volta para Mapa para testar auto-scroll
        await tester.tap(find.byKey(const Key('alca_gaveta_explorar')));
        await tester.pumpAndSettle();
        expect(alturaPx.value, greaterThan(350.0));
        await tester.tap(find.byKey(const Key('encaixe_gaveta_mapa')));
        await tester.pumpAndSettle();
        expect(alturaPx.value, lessThan(40.0));

