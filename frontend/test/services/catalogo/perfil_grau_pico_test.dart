// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/services/catalogo/repositorio_catalogo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory dirTemp;
  late RepositorioCatalogo repositorio;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp('perfil_grau_cat_test_');
    repositorio = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repositorio.fechar();
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('PerfilGrauPico e RepositorioCatalogo.carregarPerfisGrauPorCroqui', () {
    test(
      'deve retornar mapa vazio quando catalogo.db ainda nao existir no disco',
      () async {
        final perfis = await repositorio.carregarPerfisGrauPorCroqui();
        expect(perfis, isEmpty);
      },
    );

    test(
      'deve converter graus brasileiros de via (1º a 12a, romanos, barras) e escala V de boulder com exatidao',
      () {
        expect(PerfilGrauPico.converterGrauViaParaPeso('3º'), equals(400));
        expect(PerfilGrauPico.converterGrauViaParaPeso('IVsup'), equals(505));
        expect(PerfilGrauPico.converterGrauViaParaPeso('5sup'), equals(605));
        expect(PerfilGrauPico.converterGrauViaParaPeso('6º'), equals(700));
        expect(PerfilGrauPico.converterGrauViaParaPeso('6sup/7a'), equals(705));
        expect(PerfilGrauPico.converterGrauViaParaPeso('7b'), equals(820));
        expect(PerfilGrauPico.converterGrauViaParaPeso('8c'), equals(930));
        expect(PerfilGrauPico.converterGrauViaParaPeso('9a'), equals(1010));
        expect(PerfilGrauPico.converterGrauViaParaPeso('10b'), equals(1120));
        expect(PerfilGrauPico.converterGrauViaParaPeso('11c'), equals(1230));
        expect(PerfilGrauPico.converterGrauViaParaPeso('12a'), equals(1310));
        expect(PerfilGrauPico.converterGrauViaParaPeso('projeto'), isNull);
        expect(PerfilGrauPico.converterGrauViaParaPeso(''), isNull);

        expect(PerfilGrauPico.converterGrauBoulderParaPeso('VB'), equals(100));
        expect(PerfilGrauPico.converterGrauBoulderParaPeso('V0'), equals(100));
        expect(PerfilGrauPico.converterGrauBoulderParaPeso('V4/V5'), equals(500));
        expect(PerfilGrauPico.converterGrauBoulderParaPeso('V12'), equals(1300));
        expect(PerfilGrauPico.converterGrauBoulderParaPeso('V16'), equals(1600));
        expect(PerfilGrauPico.converterGrauBoulderParaPeso('45m'), isNull);
      },
    );

