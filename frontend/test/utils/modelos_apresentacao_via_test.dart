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
    'EstadoCroquiVia.resolver mapeia miniaturas próprias (com e sem pico) e referências externas',
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
      expect(semPico.aspectRatioMiniatura, 2.0);
      expect(semPico.itensCarrosselMiniatura.single.setorContextNome, 'Setor Sol');
      expect(semPico.itensCarrosselMiniatura.single.grupoContextNome, 'Grupo Leste');

      final pico = Pico(
        nome: 'Pico Sol',
        setoresOuGrupos: [
          SetorOuGrupo(
            setor: ArquivoSetor(
              conteudo: Setor(nome: 'Setor Sol', escaladas: [viaPropria]),
            ),
          ),
        ],
      );
      final comPico = EstadoCroquiVia.resolver(
        escalada: viaPropria,
        pico: pico,
        setor: Setor(nome: 'Setor Sol'),
      );
      expect(comPico.mapasMiniatura, hasLength(1));
    },
  );
}
