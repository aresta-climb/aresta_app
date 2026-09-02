// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/navigation_tree_model.dart';
import 'package:frontend/navigation/arvore/global_nodes.dart';
import 'package:frontend/navigation/arvore/pico_nodes.dart';

void main() {
  group('ArvoreNavegacao (Modelo de Domínio Puro)', () {
    test('inicia na raiz com HomeNode por padrão', () {
      const arvore = ArvoreNavegacao();

      expect(arvore.noAtual, isA<HomeNode>());
      expect(arvore.profundidade, 1);
      expect(arvore.estaNaRaiz, isTrue);
      expect(arvore.caminho.length, 1);
    });

    test('navega adicionando nós em profundidade', () {
      const arvoreInicial = ArvoreNavegacao();
      final picoNode = PicoNode(cragId: 'bau', parent: arvoreInicial.noAtual);
      final arvorePico = arvoreInicial.navegarPara(picoNode);

      expect(arvorePico.noAtual, equals(picoNode));
      expect(arvorePico.profundidade, 2);
      expect(arvorePico.estaNaRaiz, isFalse);
      expect(arvorePico.caminho[0], isA<HomeNode>());
      expect(arvorePico.caminho[1], isA<PicoNode>());

      final setorNode = SetorNode(
        cragId: 'bau',
        setorNome: 'Principal',
        parent: arvorePico.noAtual,
      );
      final arvoreSetor = arvorePico.navegarPara(setorNode);

      expect(arvoreSetor.noAtual, equals(setorNode));
      expect(arvoreSetor.profundidade, 3);
    });

    test('poda a árvore e mescla estado ao navegar para nó já existente no ancestral (prevenção de loop)', () {
      const arvore0 = ArvoreNavegacao();
      final picoNode = PicoNode(cragId: 'bau', parent: arvore0.noAtual);
      final arvore1 = arvore0.navegarPara(picoNode);

      final setorNode = SetorNode(
        cragId: 'bau',
        setorNome: 'Principal',
        parent: arvore1.noAtual,
      );
      final arvore2 = arvore1.navegarPara(setorNode);

      final viaNode = ViaNode(
        cragId: 'bau',
        setorNome: 'Principal',
        escaladaNome: 'Via 1',
        parent: arvore2.noAtual,
      );
      final arvore3 = arvore2.navegarPara(viaNode);
      expect(arvore3.profundidade, 4);

      // Agora o usuário no mapa da via clica para voltar ao setor (mesmo setor)
      final novoSetorNode = SetorNode(
        cragId: 'bau',
        setorNome: 'Principal',
        scrollToEscaladaNome: 'Via 1',
        parent: arvore3.noAtual,
      );

      final arvorePodada = arvore3.navegarPara(novoSetorNode);

      // Deve ter podado a árvore de volta para o nível do Setor (profundidade 3)
      expect(arvorePodada.profundidade, 3);
      expect(arvorePodada.noAtual, isA<SetorNode>());
      final setorFinal = arvorePodada.noAtual as SetorNode;
      expect(setorFinal.scrollToEscaladaNome, equals('Via 1'));
      expect(setorFinal.parent, isA<PicoNode>());
    });

    test('voltar retorna novo estado com nó pai ou null na raiz', () {
      const arvoreRaiz = ArvoreNavegacao();
      expect(arvoreRaiz.voltar(), isNull);

      final browseNode = BrowseNode(arvoreRaiz.noAtual);
      final arvoreBrowse = arvoreRaiz.navegarPara(browseNode);
      expect(arvoreBrowse.profundidade, 2);

      final arvoreVoltou = arvoreBrowse.voltar();
      expect(arvoreVoltou, isNotNull);
      expect(arvoreVoltou!.noAtual, isA<HomeNode>());
      expect(arvoreVoltou.profundidade, 1);
    });

    test('irParaRaiz retorna diretamente para o nó Home raiz', () {
      const arvore0 = ArvoreNavegacao();
      final picoNode = PicoNode(cragId: 'bau', parent: arvore0.noAtual);
      final arvore1 = arvore0.navegarPara(picoNode);
      final setorNode = SetorNode(cragId: 'bau', setorNome: 'S1', parent: arvore1.noAtual);
      final arvore2 = arvore1.navegarPara(setorNode);

      expect(arvore2.profundidade, 3);

      final arvoreHome = arvore2.irParaRaiz();
      expect(arvoreHome.profundidade, 1);
      expect(arvoreHome.estaNaRaiz, isTrue);
      expect(arvoreHome.noAtual, isA<HomeNode>());
    });

    test('encontrarAncestralCorrespondente localiza nós equivalentes na hierarquia', () {
      const arvore0 = ArvoreNavegacao();
      final picoNode = PicoNode(cragId: 'bau', parent: arvore0.noAtual);
      final arvore1 = arvore0.navegarPara(picoNode);

      final candidatoPico = PicoNode(cragId: 'bau', parent: null);
      final candidatoOutro = PicoNode(cragId: 'outro_pico', parent: null);

      expect(arvore1.encontrarAncestralCorrespondente(candidatoPico), isNotNull);
      expect(arvore1.encontrarAncestralCorrespondente(candidatoOutro), isNull);
    });
  });
}
