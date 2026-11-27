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

