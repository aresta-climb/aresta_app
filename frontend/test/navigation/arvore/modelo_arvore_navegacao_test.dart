// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/modelo_arvore_navegacao.dart';
import 'package:frontend/navigation/arvore/nos_globais.dart';
import 'package:frontend/navigation/arvore/nos_pico.dart';

void main() {
  group('ArvoreNavegacao (Modelo de Domínio Puro)', () {
    test('inicia na raiz com HomeNode por padrão', () {
      const arvore = ArvoreNavegacao();

      expect(arvore.noAtual, isA<HomeNode>());
      expect(arvore.currentNode, isA<HomeNode>());
      expect(arvore.profundidade, 1);
      expect(arvore.estaNaRaiz, isTrue);
      expect(arvore.caminho.length, 1);
      expect(arvore.path.length, 1);
      expect(arvore.hashCode, equals(const ArvoreNavegacao().hashCode));
      expect(arvore.toString(), contains('ArvoreNavegacao('));
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

    test(
      'podarNosPerfilECaderneta mantém árvore intacta quando não há PerfilNode nem CadernetaNode',
      () {
        const home = HomeNode();
        final arvore = ArvoreNavegacao(noAtual: SettingsNode(home));

        final podada = arvore.podarNosPerfilECaderneta();
        expect(identical(podada, arvore), isTrue);
      },
    );

    test(
      'podarNosPerfilECaderneta retorna ao ancestral sobrevivente quando noAtual é PerfilNode ou CadernetaNode',
      () {
        const home = HomeNode();
        const perfil = PerfilNode(home);
        const caderneta = CadernetaNode(perfil);

        final arvorePerfil = const ArvoreNavegacao(
          noAtual: perfil,
        ).podarNosPerfilECaderneta();
        expect(arvorePerfil.noAtual, isA<HomeNode>());
        expect(arvorePerfil.profundidade, equals(1));

        final arvoreCaderneta = const ArvoreNavegacao(
          noAtual: caderneta,
        ).podarNosPerfilECaderneta();
        expect(arvoreCaderneta.noAtual, isA<HomeNode>());
        expect(arvoreCaderneta.profundidade, equals(1));
      },
    );

    test(
      'podarNosPerfilECaderneta reancora SettingsNode e SobreTimeNode ao remover PerfilNode e CadernetaNode intermediários',
      () {
        const home = HomeNode();
        const perfil = PerfilNode(home);
        const caderneta = CadernetaNode(perfil);
        const settings = SettingsNode(caderneta);
        const sobreTime = SobreTimeNode(settings);

        final arvoreSettings = const ArvoreNavegacao(
          noAtual: settings,
        ).podarNosPerfilECaderneta();
        expect(arvoreSettings.profundidade, equals(2));
        expect(arvoreSettings.caminho[0], isA<HomeNode>());
        expect(arvoreSettings.noAtual, isA<SettingsNode>());
        expect(arvoreSettings.noAtual.parent, isA<HomeNode>());

        final arvoreSobreTime = const ArvoreNavegacao(
          noAtual: sobreTime,
        ).podarNosPerfilECaderneta();
        expect(arvoreSobreTime.profundidade, equals(3));
        expect(arvoreSobreTime.caminho[0], isA<HomeNode>());
        expect(arvoreSobreTime.caminho[1], isA<SettingsNode>());
        expect(arvoreSobreTime.noAtual, isA<SobreTimeNode>());

        const pico = PicoNode(cragId: 'bau', parent: home);
        const perfilAposPico = PerfilNode(pico);
        const settingsAposPico = SettingsNode(perfilAposPico);
        final arvorePicoSettings = const ArvoreNavegacao(
          noAtual: settingsAposPico,
        ).podarNosPerfilECaderneta();
        expect(arvorePicoSettings.profundidade, equals(3));
        expect(arvorePicoSettings.caminho[0], isA<HomeNode>());
        expect(arvorePicoSettings.caminho[1], isA<PicoNode>());
        expect(arvorePicoSettings.noAtual, isA<SettingsNode>());
        expect(arvorePicoSettings.noAtual.parent, isA<PicoNode>());
      },
    );
  });
}
