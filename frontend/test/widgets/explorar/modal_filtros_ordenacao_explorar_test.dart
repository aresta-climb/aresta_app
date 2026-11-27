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
