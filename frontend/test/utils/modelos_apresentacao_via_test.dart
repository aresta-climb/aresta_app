// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/utils/modelos_apresentacao_via.dart';

void main() {
  test(
    'ApresentacaoConsensoGrauVia.deConsenso computa proporções do anel, faixas e 5 pílulas de voto (-2..+2)',
    () {
      // ignore: prefer_const_constructors
      final semVotos = ApresentacaoConsensoGrauVia.semVotos();
      expect(semVotos.possuiVotos, isFalse);
      expect(semVotos.pilulasVoto, isEmpty);

      final vazio = ApresentacaoConsensoGrauVia.deConsenso(
        const ConsensoGrauVia.vazio(),
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
      );
      expect(vazio.possuiVotos, isFalse);
      expect(vazio.pilulasVoto, hasLength(5));
      expect(vazio.pilulasVoto[2].grauExibicao, '7a');
      expect(vazio.pilulasVoto[2].subtituloDelta, 'Justo');
      expect(vazio.pilulasVoto.any((p) => p.selecionada), isFalse);

      final apresentacao = ApresentacaoConsensoGrauVia.deConsenso(
        const ConsensoGrauVia(
          grauSugerido: '7b',
          totalVotos: 10,
          distribuicaoDeltas: {-1: 1, 0: 2, 1: 7},
        ),
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
        deltaVotoUsuario: 1,
      );

      expect(apresentacao.votosSuaves, 1);
      expect(apresentacao.votosJustos, 2);
      expect(apresentacao.votosDuros, 7);
      expect(apresentacao.deltaVotoUsuario, 1);
      expect(apresentacao.faixasDistribuicao, hasLength(5));
      expect(
        apresentacao.faixasDistribuicao.firstWhere((f) => f.delta == 1).ehModa,
        isTrue,
      );
      expect(
        apresentacao.pilulasVoto.firstWhere((p) => p.delta == 1).selecionada,
        isTrue,
      );
    },
  );

  test(
    'EstadoCroquiVia.resolver mapeia miniaturas próprias, mapas de setor referenciados e rótulo da linha',
    () {
      final viaPropria = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Via Própria'),
        mapas: [
          Mapa(
            caminhoImagemMapa: 'mapas/proprio.webp',
            larguraMapa: 1000,
            alturaMapa: 500,
          ),
        ],
      );

      final semPico = EstadoCroquiVia.resolver(
        escalada: viaPropria,
        setor: Setor(nome: 'Setor Sol'),
        grupo: Grupo(nome: 'Grupo Leste'),
      );
      expect(semPico.possuiCroqui, isTrue);
      expect(semPico.aspectRatioMiniatura, 2.0);
      expect(semPico.itensCarrosselMiniatura.single.setorContextNome, 'Setor Sol');
      expect(semPico.itensCarrosselMiniatura.single.grupoContextNome, 'Grupo Leste');

      final viaNoMapaSetor = Escalada(
        uid: 'viaSetorFoto01',
        viaEsportiva: ViaEsportiva(nome: 'Esticãozinho'),
      );
      final mapaDoSetor = Mapa(
        caminhoImagemMapa: 'mapas/setor_onca.webp',
        larguraMapa: 1200,
        alturaMapa: 800,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(uid: 'pt4', rotulo: '4'),
        ],
        referencias: [
          Mapa_Referencia(alvoUid: 'viaSetorFoto01', pontosUids: ['pt4']),
        ],
      );
      final setorOnca = Setor(
        uid: 'setorOncaUid01',
        nome: 'Setor Onça',
        escaladas: [viaNoMapaSetor],
        mapas: [mapaDoSetor],
      );
      final pico = Pico(
        nome: 'Serra do Cipó',
        setoresOuGrupos: [
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setorOnca)),
        ],
      );
      final resolvidoSetor = EstadoCroquiVia.resolver(
        escalada: viaNoMapaSetor,
        pico: pico,
        setor: setorOnca,
      );
      expect(resolvidoSetor.possuiCroqui, isTrue);
      expect(resolvidoSetor.mapasMiniatura, hasLength(1));
      expect(resolvidoSetor.aspectRatioMiniatura, 1.5);
      expect(resolvidoSetor.rotuloLinhaNoMapa, '4');

      // Referência em mapa sem dimensões positivas preserva navegação sem miniatura
      final mapaSemDimensao = Mapa(
        caminhoImagemMapa: 'mapas/sem_dim.webp',
        larguraMapa: 0,
        alturaMapa: 0,
        referencias: [Mapa_Referencia(alvoUid: 'viaSetorFoto01')],
      );
      final setorSemDim = Setor(
        nome: 'Setor Sem Dim',
        escaladas: [viaNoMapaSetor],
        mapas: [mapaSemDimensao],
      );
      final resolvidoSemDim = EstadoCroquiVia.resolver(
        escalada: viaNoMapaSetor,
        pico: Pico(
          nome: 'Pico',
          setoresOuGrupos: [
            SetorOuGrupo(setor: ArquivoSetor(conteudo: setorSemDim)),
          ],
        ),
        setor: setorSemDim,
      );
      expect(resolvidoSemDim.mapasMiniatura, isEmpty);
      expect(resolvidoSemDim.itensNavegacaoCroqui, hasLength(1));
    },
  );
}
