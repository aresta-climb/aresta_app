// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/widgets/explorar/barra_busca_filtros_explorar.dart';
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
    dirTemp = await Directory.systemTemp.createTemp('barra_busca_explorar_');

    catalogo = RepositorioCatalogo(
      fabricaBanco: databaseFactoryFfi,
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
    );
    await catalogo.aplicarDelta(
      const RespostaSyncCatalogo(
        acao: 'apply_delta',
        versaoAtual: 'v1',
        upserts: UpsertsSyncCatalogo(
          croquis: [
            CatalogoCroqui(
              croquiUid: 'uid_cipo',
              idSlug: 'serra_cipo',
              nome: 'Serra do Cipó',
            ),
            CatalogoCroqui(
              croquiUid: 'uid_ouro',
              idSlug: 'ouro_preto',
              nome: 'Ouro Preto',
            ),
          ],
          entidades: [
            CatalogoEntidade(
              uid: 'v1',
              tipo: 'escalada',
              croquiUid: 'uid_cipo',
              nome: 'Via 7b',
              escaladaGrau: '7b',
              escaladaTipo: 'esportiva',
            ),
            CatalogoEntidade(
              uid: 'b1',
              tipo: 'escalada',
              croquiUid: 'uid_ouro',
              nome: 'Bloco V6',
              escaladaGrau: 'V6',
              escaladaTipo: 'boulder',
            ),
          ],
        ),
      ),
    );

    repo = DatasetRepository(
      editorDeCroqui: EditorDeCroqui(),
      repositorioCatalogo: catalogo,
    );
    repo.activeDataset.value = ConjuntoDadosCroqui(
      metadadosDisponiveis: [
        ResumoCroqui(
          id: 'serra_cipo',
          croquiUid: 'uid_cipo',
          nome: 'Serra do Cipó',
          localizacao: Coordenada(latitude: -193400000, longitude: -436200000),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 4,
            totalEscaladas: 80,
            totalEsportivas: 70,
            totalMultiplasEnfiadas: 10,
          ),
        ),
        ResumoCroqui(
          id: 'ouro_preto',
          croquiUid: 'uid_ouro',
          nome: 'Ouro Preto',
          localizacao: Coordenada(latitude: -203800000, longitude: -435000000),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 3,
            totalEscaladas: 45,
            totalBoulders: 45,
          ),
        ),
      ],
      croquisBaixados: const [],
    );

    sync = SyncService(datasetRepository: repo);
    servicoClima = ServicoClimaAltimetria(
      armazenamento: ArmazenamentoClimaLocal(
        provedorDiretorioBase: () async => dirTemp.path,
      ),
      fonteRemota: ClienteClimaAltimetriaFake(),
    );
    await servicoClima.inicializar();
    await servicoClima.sincronizarSeNecessario();

    viewModel = BrowseViewModel(
      datasetRepo: repo,
      syncService: sync,
      servicoClima: servicoClima,
    )..atualizarLocalizacaoUsuario(-19.9, -43.9);
    await viewModel.recarregarPerfisGrauCatalogo();
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

  group('BarraBuscaFiltrosExplorar', () {
    testWidgets(
      'filtra por texto com botao limpar, sincroniza limpeza externa, remove botao redundante Grau e ajusta sliders no modal',
      (WidgetTester tester) async {
        var sincronizou = false;
        var trocouServing = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BarraBuscaFiltrosExplorar(
                viewModel: viewModel,
                aoSincronizar: () => sincronizou = true,
                aoTrocarServing: () => trocouServing = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Botao redundante "Grau" foi removido da barra superior (concentrado no botao de filtros)
        expect(
          find.byKey(const Key('botao_rapido_grau_explorar')),
          findsNothing,
        );

        // Busca textual + botao limpar
        await tester.enterText(find.byType(TextField), 'Cipó');
        await tester.pump();
        expect(viewModel.termoBusca, equals('Cipó'));
        expect(find.byKey(const Key('botao_limpar_busca_explorar')), findsOneWidget);

        await tester.tap(find.byKey(const Key('botao_limpar_busca_explorar')));
        await tester.pump();
        expect(viewModel.termoBusca, isEmpty);

        // Limpeza externa (ex.: focarSetimoPicoProximo) sincroniza o TextField
        await tester.enterText(find.byType(TextField), 'Ouro');
        await tester.pump();
        viewModel.focarSetimoPicoProximo();
        await tester.pump();
        expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

        // Abre modal de Filtros e ajusta RangeSliders de Via e Boulder (incluindo retorno aos extremos null)
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(RangeSlider), findsNWidgets(2));

        final sliders = tester.widgetList<RangeSlider>(find.byType(RangeSlider)).toList();
        sliders[0].onChanged!(const RangeValues(6, 12)); // 6º a 8b
        await tester.pump();
        expect(viewModel.temFiltroGrauVia, isTrue);

        final slidersAtualizados =
            tester.widgetList<RangeSlider>(find.byType(RangeSlider)).toList();
        slidersAtualizados[1].onChanged!(const RangeValues(4, 10)); // V4 a V10
        await tester.pump();
        expect(viewModel.temFiltroGrauBoulder, isTrue);

        // Retornar os sliders para a faixa completa (0..max) limpa o filtro para null
        final slidersReset =
            tester.widgetList<RangeSlider>(find.byType(RangeSlider)).toList();
        slidersReset[0].onChanged!(RangeValues(0, slidersReset[0].max));
        slidersReset[1].onChanged!(RangeValues(0, slidersReset[1].max));
        await tester.pump();
        expect(viewModel.temFiltroGrauVia, isFalse);
        expect(viewModel.temFiltroGrauBoulder, isFalse);

        await tester.tap(find.byKey(const Key('botao_aplicar_filtros_explorar')));
        await tester.pumpAndSettle();

        // Botoes auxiliares de sincronizar e trocar serving
        await tester.tap(find.byTooltip('Sincronizar com serving'));
        await tester.tap(find.byTooltip('Trocar serving'));
        await tester.pump();
        expect(sincronizou, isTrue);
        expect(trocouServing, isTrue);

        // Troca de instancia de BrowseViewModel em didUpdateWidget sincroniza o texto
        late BrowseViewModel vmAlternativo;
        await tester.runAsync(() async {
          vmAlternativo = BrowseViewModel(
            datasetRepo: repo,
            syncService: sync,
            servicoClima: servicoClima,
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        addTearDown(vmAlternativo.dispose);
        vmAlternativo.alterarTermoBusca('Novo Termo');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BarraBuscaFiltrosExplorar(viewModel: vmAlternativo),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          equals('Novo Termo'),
        );
      },
    );

    testWidgets(
      'abre modal completo Filtros e Ordenacao com Paredao, ordenacao, alcance 150 km, offline e chips removiveis',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BarraBuscaFiltrosExplorar(viewModel: viewModel),
            ),
          ),
        );
        await tester.pumpAndSettle();

