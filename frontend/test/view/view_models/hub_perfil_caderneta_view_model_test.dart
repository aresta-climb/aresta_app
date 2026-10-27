// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/hub_perfil_caderneta_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  group('HubPerfilCadernetaViewModel', () {
    test('expõe dados padrão do perfil e métricas zeradas quando não há cadenas', () {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      expect(vm.nomeAtleta, 'Escalador Aresta');
      expect(vm.autorIdPublico.length, 14);
      expect(vm.funcaoAtleta, 'Escalador');
      expect(vm.totalCadenas, 0);
      expect(vm.totalTentativas, 0);
      expect(vm.totalPicos, 0);
      expect(vm.totalVias, 0);

      vm.dispose();
    });

  });
}
