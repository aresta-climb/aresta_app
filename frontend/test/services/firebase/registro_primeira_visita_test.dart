// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RegistroPrimeiraVisita.resetForTesting();
  });

  group('RegistroPrimeiraVisita', () {
    test('retorna true na primeira visita a um croqui e false na subsequente', () async {
      final registro = RegistroPrimeiraVisita.instancia;

      final primeiraVez = await registro.registrarEVerificarPrimeiraVisita('br_mg_serra_do_cipo');
      expect(primeiraVez, isTrue);

      final segundaVez = await registro.registrarEVerificarPrimeiraVisita('br_mg_serra_do_cipo');
      expect(segundaVez, isFalse);
    });

    test('croquis diferentes sao rastreados de forma independente', () async {
      final registro = RegistroPrimeiraVisita.instancia;

      expect(await registro.registrarEVerificarPrimeiraVisita('pico_a'), isTrue);
      expect(await registro.registrarEVerificarPrimeiraVisita('pico_b'), isTrue);
      expect(await registro.registrarEVerificarPrimeiraVisita('pico_a'), isFalse);
      expect(await registro.registrarEVerificarPrimeiraVisita('pico_b'), isFalse);
    });

    test('jaVisitou consulta o historico sem alterar o estado', () async {
      final registro = RegistroPrimeiraVisita.instancia;

      expect(await registro.jaVisitou('pico_c'), isFalse);
      await registro.registrarEVerificarPrimeiraVisita('pico_c');
      expect(await registro.jaVisitou('pico_c'), isTrue);
    });

    test('recarrega historico pre-existente do SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'croquis_visitados_historico': <String>['pico_antigo'],
      });

      final registro = RegistroPrimeiraVisita.instancia;
      expect(await registro.jaVisitou('pico_antigo'), isTrue);
      expect(await registro.registrarEVerificarPrimeiraVisita('pico_antigo'), isFalse);
    });

    test('retorna false ao capturar erro em registrarEVerificarPrimeiraVisita', () async {
      final registro = RegistroPrimeiraVisita.instancia;
      registro.obterPrefsOverride = () => throw Exception('Falha ao acessar SharedPreferences');

      final resultado = await registro.registrarEVerificarPrimeiraVisita('pico_falha');
      expect(resultado, isFalse);
    });

    test('retorna false ao capturar erro em jaVisitou', () async {
      final registro = RegistroPrimeiraVisita.instancia;
      registro.obterPrefsOverride = () => throw Exception('Falha ao acessar SharedPreferences');

      final resultado = await registro.jaVisitou('pico_falha');
      expect(resultado, isFalse);
    });
  });
}
