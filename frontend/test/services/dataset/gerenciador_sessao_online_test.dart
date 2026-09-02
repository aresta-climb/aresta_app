// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/sessao_online/gerenciador_sessao_online.dart';

void main() {
  late GerenciadorSessaoOnline gerenciador;

  setUp(() {
    gerenciador = GerenciadorSessaoOnline();
  });

  group('GerenciadorSessaoOnline', () {
    test('armazena e recupera croqui online em memória', () {
      expect(gerenciador.obterCroquiOnline('pico_1'), isNull);

      final croqui = Croqui(id: 'pico_1', nome: 'Falésia dos Olhos');
      gerenciador.registrarCroquiOnline('pico_1', croqui, etag: 'etag_123');

      expect(gerenciador.obterCroquiOnline('pico_1'), equals(croqui));
      expect(gerenciador.obterEtag('pico_1'), equals('etag_123'));
    });

    test('gerencia atualizações pendentes via ValueNotifier', () {
      expect(gerenciador.atualizacoesPendentes.value.containsKey('pico_1'), isFalse);

      gerenciador.registrarAtualizacaoPendente('pico_1', 'etag_novo');
      expect(gerenciador.atualizacoesPendentes.value['pico_1'], equals('etag_novo'));

      gerenciador.limparAtualizacaoPendente('pico_1');
      expect(gerenciador.atualizacoesPendentes.value.containsKey('pico_1'), isFalse);
    });

    test('removerSessao limpa o croqui e o ETag daquele pico', () {
      final croqui = Croqui(id: 'pico_1', nome: 'Pico 1');
      gerenciador.registrarCroquiOnline('pico_1', croqui, etag: 'etag_1');
      gerenciador.registrarAtualizacaoPendente('pico_1', 'etag_novo');

      gerenciador.removerSessao('pico_1');

      expect(gerenciador.obterCroquiOnline('pico_1'), isNull);
      expect(gerenciador.obterEtag('pico_1'), isNull);
      expect(gerenciador.atualizacoesPendentes.value.containsKey('pico_1'), isFalse);
    });

    test('limparTudo esvazia todos os registros da sessão', () {
      gerenciador.registrarCroquiOnline('pico_1', Croqui(id: 'pico_1'));
      gerenciador.registrarCroquiOnline('pico_2', Croqui(id: 'pico_2'));

      gerenciador.limparTudo();

      expect(gerenciador.obterCroquiOnline('pico_1'), isNull);
      expect(gerenciador.obterCroquiOnline('pico_2'), isNull);
    });
  });
}
