// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/no_navegacao.dart';
import 'package:frontend/navigation/arvore/nos_globais.dart';
import 'package:frontend/navigation/arvore/nos_pico.dart';
import 'package:frontend/navigation/arvore/nos_modais.dart';

void main() {
  group('Nós de Navegação (Equivalência Polimórfica isSameNode)', () {
    test('Nós globais são equivalentes por tipo', () {
      const home1 = HomeNode();
      const home2 = HomeNode();
      const browse = BrowseNode(HomeNode());

      expect(home1.isSameNode(home2), isTrue);
      expect(home1.isSameNode(browse), isFalse);
    });

    test('PicoNode compara por cragId', () {
      const pico1 = PicoNode(cragId: 'bau', parent: HomeNode());
      const pico2 = PicoNode(cragId: 'bau', parent: null);
      const picoOutro = PicoNode(cragId: 'itaipava', parent: null);

      expect(pico1.isSameNode(pico2), isTrue);
      expect(pico1.isSameNode(picoOutro), isFalse);
    });

    test('SetorNode compara por cragId, setorNome e grupoNome', () {
      const setor1 = SetorNode(
        cragId: 'bau',
        setorNome: 'Central',
        grupoNome: 'G1',
        parent: HomeNode(),
      );
      const setorIgual = SetorNode(
        cragId: 'bau',
        setorNome: 'Central',
        grupoNome: 'G1',
        parent: null,
      );
      const setorOutroNome = SetorNode(
        cragId: 'bau',
        setorNome: 'Leste',
        grupoNome: 'G1',
        parent: null,
      );

      expect(setor1.isSameNode(setorIgual), isTrue);
      expect(setor1.isSameNode(setorOutroNome), isFalse);
    });

    test('ViaNode compara por cragId, escaladaNome, setorNome e grupoNome', () {
      const via1 = ViaNode(
        cragId: 'bau',
        escaladaNome: 'Via Láctea',
        setorNome: 'Central',
        grupoNome: 'G1',
        parent: HomeNode(),
      );
      const viaIgual = ViaNode(
        cragId: 'bau',
        escaladaNome: 'Via Láctea',
        setorNome: 'Central',
        grupoNome: 'G1',
        parent: null,
      );
      const viaOutra = ViaNode(
        cragId: 'bau',
        escaladaNome: 'Outra Via',
        setorNome: 'Central',
        grupoNome: 'G1',
        parent: null,
      );

      expect(via1.isSameNode(viaIgual), isTrue);
      expect(via1.isSameNode(viaOutra), isFalse);
    });

    test('TextNode compara por title', () {
      const text1 = TextNode(
        title: 'Regras',
        content: 'Conteudo',
        cragId: 'bau',
        parent: HomeNode(),
      );
      const text2 = TextNode(
        title: 'Regras',
        content: 'Outro',
        cragId: 'bau',
        parent: null,
      );
      const text3 = TextNode(
        title: 'História',
        content: 'Conteudo',
        cragId: 'bau',
        parent: null,
      );

      expect(text1.isSameNode(text2), isTrue);
      expect(text1.isSameNode(text3), isFalse);
    });
  });

  group('Nós de Navegação (Caminho Canônico Mais Curto)', () {
    test('retorna caminho conciso e canônico para nós profundos', () {
      const home = HomeNode();
      const browse = BrowseNode(home);
      const pico = PicoNode(cragId: 'pedra_grande', parent: browse);
      const setor = SetorNode(
        cragId: 'pedra_grande',
        setorNome: 'Falésia',
        parent: pico,
      );
      const via = ViaNode(
        cragId: 'pedra_grande',
        setorNome: 'Falésia',
        escaladaNome: 'Via Láctea',
        parent: setor,
      );
      const texto = TextNode(
        title: 'Beta da Via',
        content: 'Detalhes',
        cragId: 'pedra_grande',
        parent: via,
      );

      expect(home.obterCaminhoCurto(), 'Início');
      expect(browse.obterCaminhoCurto(), 'Início -> Buscar');
      expect(pico.obterCaminhoCurto(), 'Início -> Pico (pedra_grande)');
      expect(setor.obterCaminhoCurto(), 'Início -> Pico (pedra_grande) -> Setor (Falésia)');
      expect(via.obterCaminhoCurto(), 'Início -> Pico (pedra_grande) -> Setor (Falésia) -> Via (Via Láctea)');
      expect(texto.obterCaminhoCurto(), 'Início -> Pico (pedra_grande) -> Setor (Falésia) -> Via (Via Láctea) -> Texto (Beta da Via)');
    });
  });
}
