// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/widgets/explorar/modal_filtros_ordenacao_explorar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../fakes/cliente_clima_altimetria_fake.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  sqfliteFfiInit();

  group('ModalFiltrosOrdenacaoExplorar', () {
    test('resolve índices e resumos de faixas de graduação para valores explícitos e nulos', () {
      final grausVia = OpcoesGrau.grausVia;
      expect(
        indiceParaValorGrauExplorar(grausVia, null, padrao: 0),
        equals(0),
      );
      final indiceQuinto = indiceParaValorGrauExplorar(
        grausVia,
        grausVia[4].valor,
        padrao: 0,
      );
      expect(indiceQuinto, equals(4));

      final resumoTotal = formatarResumoGrauExplorar(grausVia, null, null);
      expect(resumoTotal, contains('–'));
    });

    testWidgets('abre modal completo, altera ordenação, modalidades, sliders de grau, alcance e limpa filtros', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      TelemetryService.instance = MockTelemetryService();
      late Directory dirTemp;
      late RepositorioCatalogo catalogo;
      late ServicoClimaAltimetria servicoClima;
      late BrowseViewModel vm;

      await tester.runAsync(() async {
        dirTemp = await Directory.systemTemp.createTemp('modal_filtros_test_');
        catalogo = RepositorioCatalogo(
          fabricaBanco: databaseFactoryFfi,
          provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
        );
        final repo = DatasetRepository(
          editorDeCroqui: EditorDeCroqui(),
          repositorioCatalogo: catalogo,
        );
        repo.activeDataset.value = ConjuntoDadosCroqui(
          metadadosDisponiveis: [
            ResumoCroqui(
              id: 'p1',
              nome: 'Pico Alfa',
              localizacao: Coordenada(
                latitude: (-20.0 * 1e7).round(),
                longitude: (-44.0 * 1e7).round(),
              ),
              precomputados: PrecomputadosResumoCroqui(
                totalEscaladas: 15,
                totalEsportivas: 15,
              ),
            ),
          ],
          croquisBaixados: [Croqui(id: 'p1', nome: 'Pico Alfa')],
        );
        final sync = SyncService(datasetRepository: repo);
        servicoClima = ServicoClimaAltimetria(
          armazenamento: ArmazenamentoClimaLocal(
            provedorDiretorioBase: () async => dirTemp.path,
          ),
          fonteRemota: ClienteClimaAltimetriaFake(
            snapshotInicial: SnapshotClimaAltimetria(
              geradoEm: DateTime.utc(2026, 11, 26),
              bolhasChuva: const [],
              chuvaPorPico: const {},
              altimetriaPorPico: const {},
            ),
          ),
        );
        await servicoClima.inicializar();
        vm = BrowseViewModel(
          datasetRepo: repo,
          syncService: sync,
          servicoClima: servicoClima,
        );
      });

      addTearDown(() async {
        vm.dispose();
        servicoClima.dispose();
        await tester.runAsync(() async {
          await catalogo.fechar();
          if (await dirTemp.exists()) {
            await dirTemp.delete(recursive: true);
          }
        });
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('abrir_modal'),
                onPressed: () => exibirModalFiltrosOrdenacaoExplorar(
                  context: ctx,
                  viewModel: vm,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('abrir_modal')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(tr(ChaveTexto.explorarAlfabeticoAZ)));
      await tester.pump();
      expect(vm.ordem, equals(OrdemOrdenacaoPico.alfabetico));

      await tester.tap(find.widgetWithText(FilterChip, tr(ChaveTexto.modBoulder)));
      await tester.pump();
      expect(vm.modalidadesAtivas, contains(ModalidadeExploracaoPico.boulder));

      final sliders = find.byType(RangeSlider);
      expect(sliders, findsNWidgets(2));
      final sliderVia = tester.widget<RangeSlider>(sliders.at(0));
      sliderVia.onChanged!(const RangeValues(2, 6));
      sliderVia.onChanged!(RangeValues(0, sliderVia.max));
      final sliderBld = tester.widget<RangeSlider>(sliders.at(1));
      sliderBld.onChanged!(const RangeValues(1, 5));
      sliderBld.onChanged!(RangeValues(0, sliderBld.max));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('filtro_raio_150km')));
      await tester.tap(find.byKey(const Key('filtro_raio_150km')));
      await tester.pump();
      expect(vm.raioMaximoKm, equals(150.0));
      await tester.tap(find.byKey(const Key('filtro_raio_150km')));
      await tester.pump();
      expect(vm.raioMaximoKm, isNull);

      await tester.tap(find.byKey(const Key('filtro_salvos_offline')));
      await tester.pump();
      expect(vm.apenasSalvosOffline, isTrue);

      await tester.tap(find.byKey(const Key('botao_limpar_todos_filtros')));
      await tester.pump();
      expect(vm.totalFiltrosAtivos, equals(0));

      await tester.tap(find.byKey(const Key('botao_aplicar_filtros_explorar')));
      await tester.pumpAndSettle();
      expect(find.byType(ModalFiltrosOrdenacaoExplorar), findsNothing);
    });
  });
}
