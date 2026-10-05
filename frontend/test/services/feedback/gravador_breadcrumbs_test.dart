// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/gravador_breadcrumbs.dart';

void main() {
  group('GravadorBreadcrumbs', () {
    late GravadorBreadcrumbs gravador;

    setUp(() {
      gravador = GravadorBreadcrumbs(capacidadeMaxima: 5);
      GravadorBreadcrumbs.resetForTesting();
    });

    test('inicializa com lista vazia de breadcrumbs', () {
      expect(gravador.obterBreadcrumbs(), isEmpty);
      expect(gravador.total, 0);
    });

    test('registra evento com timestamp e parâmetros estruturados', () {
      final dataFixa = DateTime(2026, 10, 5, 12, 0, 0);
      gravador.registrar(
        evento: 'acao_croqui',
        parametros: {'id_croqui': 'pico_1', 'acao': 'abrir_croqui'},
        timestamp: dataFixa,
      );

      final breadcrumbs = gravador.obterBreadcrumbs();
      expect(breadcrumbs.length, 1);
      expect(breadcrumbs.first['evento'], 'acao_croqui');
      expect(breadcrumbs.first['timestamp'], dataFixa.toIso8601String());
      expect(breadcrumbs.first['parametros'], {
        'id_croqui': 'pico_1',
        'acao': 'abrir_croqui',
      });
    });

    test('preserva parâmetros vazios caso nenhum seja informado', () {
      gravador.registrar(evento: 'abrir_modal');

      final breadcrumbs = gravador.obterBreadcrumbs();
      expect(breadcrumbs.length, 1);
      expect(breadcrumbs.first['evento'], 'abrir_modal');
      expect(breadcrumbs.first['parametros'], isEmpty);
      expect(breadcrumbs.first['timestamp'], isNotEmpty);
    });

    test('descarta os eventos mais antigos ao atingir a capacidade máxima (FIFO)', () {
      for (int i = 1; i <= 7; i++) {
        gravador.registrar(
          evento: 'evento_$i',
          parametros: {'indice': i},
        );
      }

      final breadcrumbs = gravador.obterBreadcrumbs();
      expect(breadcrumbs.length, 5);
      expect(gravador.total, 5);

      // Como a capacidade máxima é 5, os eventos 1 e 2 foram descartados.
      expect(breadcrumbs[0]['evento'], 'evento_3');
      expect(breadcrumbs[1]['evento'], 'evento_4');
      expect(breadcrumbs[2]['evento'], 'evento_5');
      expect(breadcrumbs[3]['evento'], 'evento_6');
      expect(breadcrumbs[4]['evento'], 'evento_7');
    });

    test('limpa todos os breadcrumbs acumulados', () {
      gravador.registrar(evento: 'evento_1');
      gravador.registrar(evento: 'evento_2');
      expect(gravador.total, 2);

      gravador.limpar();
      expect(gravador.obterBreadcrumbs(), isEmpty);
      expect(gravador.total, 0);
    });

    test('singleton GravadorBreadcrumbs.instance possui capacidade padrão de 50', () {
      final instancia = GravadorBreadcrumbs.instance;
      expect(instancia.capacidadeMaxima, 50);

      GravadorBreadcrumbs.instance.registrar(evento: 'teste_singleton');
      expect(GravadorBreadcrumbs.instance.total, 1);

      GravadorBreadcrumbs.resetForTesting();
      expect(GravadorBreadcrumbs.instance.total, 0);
    });
  });
}
