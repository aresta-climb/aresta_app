// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/gerenciador_filtros_croqui.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';

void main() {
  group('GerenciadorFiltrosCroqui Unit Tests', () {
    late GerenciadorFiltrosCroqui gerenciador;

    setUp(() {
      gerenciador = GerenciadorFiltrosCroqui.instance;
      gerenciador.redefinir();
    });

    test('retorna EstadoFiltrosUnificado padrão para croqui sem filtros prévios', () {
      final estado = gerenciador.obterFiltros('croqui-1');
      expect(estado.temFiltrosAtivos, isFalse);
      expect(estado.tipoOrdenacao, TipoOrdenacaoExploracao.padrao);
    });

    test('preserva e atualiza filtros configurados para um croqui específico', () {
      const novoEstado = EstadoFiltrosUnificado(
        apenasClassicas: true,
        tipoOrdenacao: TipoOrdenacaoExploracao.grau,
      );

      gerenciador.atualizarFiltros('croqui-1', novoEstado);

      final recuperado = gerenciador.obterFiltros('croqui-1');
      expect(recuperado.apenasClassicas, isTrue);
      expect(recuperado.tipoOrdenacao, TipoOrdenacaoExploracao.grau);
    });

    test('segrega filtros entre croquis distintos', () {
      const estado1 = EstadoFiltrosUnificado(apenasClassicas: true);
      const estado2 = EstadoFiltrosUnificado(
        tipoOrdenacao: TipoOrdenacaoExploracao.alfabetico,
      );

      gerenciador.atualizarFiltros('croqui-1', estado1);
      gerenciador.atualizarFiltros('croqui-2', estado2);

      expect(gerenciador.obterFiltros('croqui-1').apenasClassicas, isTrue);
      expect(gerenciador.obterFiltros('croqui-1').tipoOrdenacao, TipoOrdenacaoExploracao.padrao);

      expect(gerenciador.obterFiltros('croqui-2').apenasClassicas, isFalse);
      expect(gerenciador.obterFiltros('croqui-2').tipoOrdenacao, TipoOrdenacaoExploracao.alfabetico);
    });

    test('limparFiltros reseta os filtros do croqui para o estado padrão', () {
      const estado = EstadoFiltrosUnificado(apenasClassicas: true);
      gerenciador.atualizarFiltros('croqui-1', estado);
      expect(gerenciador.obterFiltros('croqui-1').apenasClassicas, isTrue);

      gerenciador.limparFiltros('croqui-1');
      expect(gerenciador.obterFiltros('croqui-1').temFiltrosAtivos, isFalse);
    });

    test('notifica ouvintes ao atualizar ou limpar filtros', () {
      int notificacoes = 0;
      gerenciador.addListener(() => notificacoes++);

      gerenciador.atualizarFiltros(
        'croqui-1',
        const EstadoFiltrosUnificado(apenasClassicas: true),
      );
      expect(notificacoes, 1);

      gerenciador.limparFiltros('croqui-1');
      expect(notificacoes, 2);
    });
  });
}
