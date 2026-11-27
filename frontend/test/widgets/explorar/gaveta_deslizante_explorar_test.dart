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

        // Pico 0 e seco e baixado -> exibe altitude 1180m e globo alinhados no lado DIREITO do card, abre ao tocar e NAO exibe alerta Seco
        expect(find.byKey(const Key('badge_altitude_pico_0')), findsOneWidget);
        expect(find.textContaining('1180m'), findsOneWidget);
        expect(find.byKey(const Key('alerta_umidade_pico_0')), findsNothing);
        expect(find.text('Seco'), findsNothing);

        // Expande para Dividir para inspecionar geometria dos badges no topo direito do card
        await tester.tap(find.byKey(const Key('alca_gaveta_explorar')));
        await tester.pumpAndSettle();
        final centroTelaX = 200.0;
        final centroAltitude = tester.getCenter(
          find.byKey(const Key('badge_altitude_pico_0')),
        );
        final centroGlobo = tester.getCenter(
          find.byKey(const Key('botao_ver_no_globo_pico_0')),
        );
        expect(centroAltitude.dx, greaterThan(centroTelaX));
        expect(centroGlobo.dx, greaterThan(centroAltitude.dx));
        await tester.tap(find.byKey(const Key('encaixe_gaveta_mapa')));
        await tester.pumpAndSettle();

        // Selecionar pico_5 no mapa expande automaticamente de Mapa -> Dividir e faz auto-scroll ate pico_5
        viewModel.selecionarPico('pico_5', origemMapa: true);
        await tester.pumpAndSettle();

        expect(alturaPx.value, greaterThan(alturaMapa + 100.0));
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(GavetaDeslizanteExplorar),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        expect(scrollable.position.pixels, greaterThan(600.0));

        // Pico 5 esta muito molhado (chuva dia 24/11) -> alerta contextual visivel!
        expect(find.byKey(const Key('alerta_umidade_pico_5')), findsOneWidget);
        expect(find.textContaining('24/11'), findsOneWidget);
        expect(find.textContaining('1450m'), findsOneWidget);

        // Botao de focar no globo a partir do card dispara callback
        await tester.tap(find.byKey(const Key('botao_ver_no_globo_pico_5')));
        await tester.pump();
        expect(focadoNoGlobo, equals('pico_5'));

        // Toque no card nao baixado abre diretamente a pagina do pico (exploracao online, sem auto-download)
        await tester.tap(find.text('PICO GAVETA 5'));
        await tester.pump();
        expect(abertosIds, contains('pico_5'));

        // Alterna para Lista cobrindo praticamente toda a tela (> 740px em tela de 820px) e testa recolhimento ao tocar ver no globo
        await tester.tap(find.byKey(const Key('encaixe_gaveta_lista')));
        await tester.pumpAndSettle();
        expect(alturaPx.value, greaterThan(740.0));

        await tester.ensureVisible(
          find.byKey(const Key('botao_ver_no_globo_pico_5')),
        );
        await tester.tap(find.byKey(const Key('botao_ver_no_globo_pico_5')));
        await tester.pumpAndSettle();
        expect(alturaPx.value, lessThan(500.0));

        await tester.tap(find.byKey(const Key('encaixe_gaveta_lista')));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const Key('alca_gaveta_explorar')),
          const Offset(0, 360),
        );
        await tester.pumpAndSettle();
        expect(alturaPx.value, lessThan(500.0));

        // Volta ao topo e toca no pico_0 baixado -> tambem aciona aoAbrirPico
        await tester.drag(
          find.descendant(
            of: find.byType(GavetaDeslizanteExplorar),
            matching: find.byType(SingleChildScrollView),
          ),
          const Offset(0, 1500),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('PICO GAVETA 0'));
        await tester.pump();
        expect(abertosIds, contains('pico_0'));

        // Pilulas rapidas de modalidade no cabecalho (incluindo Paredao)
        await tester.ensureVisible(
          find.byKey(const Key('pilula_modalidade_paredao')),
        );
        await tester.tap(find.byKey(const Key('pilula_modalidade_paredao')));
        await tester.pumpAndSettle();
        expect(
          viewModel.modalidadesAtivas,
          contains(ModalidadeExploracaoPico.paredao),
        );

        // Suporta tambem solicitacaoScrollSetimoPico (focarSetimoPicoProximo)
        await tester.tap(find.byKey(const Key('encaixe_gaveta_mapa')));
        await tester.pumpAndSettle();
        viewModel.focarSetimoPicoProximo();
        await tester.pumpAndSettle();
        expect(find.text('PICO GAVETA 6'), findsOneWidget);

        // Estado vazio ao buscar termo inexistente
        viewModel.alterarTermoBusca('termo_inexistente_xyz');
        await tester.pumpAndSettle();
        expect(find.text('Nenhum pico encontrado.'), findsOneWidget);

        // Troca de ViewModel ja com solicitacaoScrollSetimoPico > 0 em didUpdateWidget + initState
        late BrowseViewModel vm2;
        await tester.runAsync(() async {
          vm2 = BrowseViewModel(
            datasetRepo: repo,
            syncService: sync,
            servicoClima: servicoClima,
          )
            ..atualizarLocalizacaoUsuario(-20.0, -44.0)
            ..focarSetimoPicoProximo();
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        addTearDown(vm2.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GavetaDeslizanteExplorar(
                    viewModel: vm2,
                    alturaGavetaPx: alturaPx,
                    aoAbrirPico: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                key: UniqueKey(),
                children: [
                  GavetaDeslizanteExplorar(
                    key: UniqueKey(),
                    viewModel: vm2,
                    alturaGavetaPx: alturaPx,
                    aoAbrirPico: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
    );
  });
}
