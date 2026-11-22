// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/beta.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/utils/extrator_detalhes_tecnicos_via.dart';

void main() {
  test(
    'extrai especificações, textos, enfiadas, mídias e histórico para todas as modalidades Protobuf',
    () {
      final esportiva = Escalada(
        betas: [
          MidiaBeta(
            url: 'https://youtube.com/watch?v=1',
            titulo: 'Beta Oficial',
            fonte: FonteMidia_Enum.YOUTUBE,
          ),
          MidiaBeta(
            url: 'https://instagram.com/p/1',
            titulo: '',
            fonte: FonteMidia_Enum.INSTAGRAM,
          ),
        ],
        viaEsportiva: ViaEsportiva(
          nome: 'Via Deslize',
          destaque: true,
          dificuldade: GrauVia_GrauVia.BR_7A,
          dificuldadeArtificial: GrauArtificial_GrauArtificial.A1_MAIS,
          exposicao: GrauExposicao_GrauExposicao.E2,
          tipoParede: TipoParede_TipoParede.NEGATIVO,
          extensao: 28,
          quantidadeProtecoesIntermediarias: 11,
          quantidadeProtecoesParada: 2,
          tipoAncoragem: 'Dupla inox',
          conquistadores: ['João', 'Maria'],
          dataAbertura: '2012',
          dataManutencao: '2024',
          descricao: 'Crux técnico.',
          urlVideoBeta: 'https://vimeo.com/1',
          chavePixManutencao: 'pix@aresta.cc',
        ),
      );

      expect(ExtratorDetalhesTecnicosVia.extrairModalidade(esportiva), 'Esportiva');
      expect(ExtratorDetalhesTecnicosVia.extrairDestaque(esportiva), isTrue);
      expect(
        ExtratorDetalhesTecnicosVia.extrairGrauOficialExibicao(esportiva),
        '7a',
      );
      expect(
        ExtratorDetalhesTecnicosVia.extrairComplementoGrauOficial(esportiva),
        contains('Artificial A1+'),
      );
      expect(
        ExtratorDetalhesTecnicosVia.extrairTipoAncoragem(esportiva),
        'Dupla inox',
      );
      expect(
        ExtratorDetalhesTecnicosVia.extrairAtributosTecnicos(esportiva)
            .map((a) => a.rotulo),
        equals(['EXTENSÃO', 'PROTEÇÕES', 'PAREDE', 'EXPOSIÇÃO']),
      );
      expect(ExtratorDetalhesTecnicosVia.extrairSecoesTexto(esportiva), hasLength(1));
      expect(ExtratorDetalhesTecnicosVia.extrairMidiasBeta(esportiva), hasLength(3));
      expect(
        ExtratorDetalhesTecnicosVia.extrairConquistadores(esportiva),
        'João, Maria',
      );
      expect(ExtratorDetalhesTecnicosVia.extrairDataAbertura(esportiva), '2012');
      expect(ExtratorDetalhesTecnicosVia.extrairDataManutencao(esportiva), '2024');
      expect(
        ExtratorDetalhesTecnicosVia.extrairChavePix(esportiva),
        'pix@aresta.cc',
      );

      final multi = Escalada(
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
          nome: 'Parede Sul',
          dificuldadeMaxima: GrauVia_GrauVia.PROJETO,
          dificuldadeMedia: GrauVia_GrauVia.BR_6,
          dificuldadeArtificial: GrauArtificial_GrauArtificial.A2,
          dificuldadeArtificialEmLivre: GrauVia_GrauVia.BR_7C,
          numeroEnfiadas: 2,
          comprimentoTotal: 80,
          enfiadas: [
            Escalada(
              viaMovel: ViaMovel(
                nome: 'Fenda',
                extensao: 40,
                protecoesMoveis: 'Friends #1-#3',
              ),
            ),
          ],
        ),
      );
      expect(
        ExtratorDetalhesTecnicosVia.extrairGrauOficialExibicao(multi),
        'Projeto',
      );
      expect(
        ExtratorDetalhesTecnicosVia.extrairComplementoGrauOficial(multi),
        contains('7c em livre'),
      );
      expect(ExtratorDetalhesTecnicosVia.extrairEnfiadas(multi), hasLength(1));
    },
  );

  test(
    'constrói ApresentacaoConsensoGrauVia e NotaComunidadeApresentacao prontos para Dumb UI',
    () {
      final semVotos = ExtratorDetalhesTecnicosVia.construirApresentacaoConsenso(
        const ConsensoGrauVia.vazio(),
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
      );
      expect(semVotos.possuiVotos, isFalse);
      expect(semVotos.faixasDistribuicao, isEmpty);
      expect(semVotos.subtituloTendencia, 'Registre sua ascensão para avaliar');

      final comVotos = ExtratorDetalhesTecnicosVia.construirApresentacaoConsenso(
        const ConsensoGrauVia(
          grauSugerido: '7b',
          totalVotos: 10,
          distribuicaoDeltas: {-1: 1, 0: 2, 1: 7},
        ),
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
      );
      expect(comVotos.possuiVotos, isTrue);
      expect(comVotos.votosSuaves, 1);
      expect(comVotos.votosJustos, 2);
      expect(comVotos.votosDuros, 7);
      expect(comVotos.tituloDistribuicao, 'DISTRIBUIÇÃO DE VOTOS (10)');
      expect(comVotos.faixasDistribuicao, hasLength(5));
      final moda = comVotos.faixasDistribuicao.firstWhere((f) => f.delta == 1);
      expect(moda.rotulo, '7b (+1)');
      expect(moda.ehModa, isTrue);
      expect(moda.fatorLargura, 1.0);

      final semGrauOficial =
          ExtratorDetalhesTecnicosVia.construirApresentacaoConsenso(
            const ConsensoGrauVia(
              grauSugerido: 'v3',
              totalVotos: 2,
              distribuicaoDeltas: {0: 2},
            ),
            codigoGrauOficial: null,
            ehBoulder: true,
          );
      expect(
        semGrauOficial.faixasDistribuicao.firstWhere((f) => f.delta == 0).rotulo,
        'Justo (0)',
      );

      final notas = ExtratorDetalhesTecnicosVia.formatarNotasComunidade([
        ComentarioComunidadeVia(
          uid: 'c1Kq2L1x9Y7zWq',
          autorIdPublico: 'a1Lk9P1x4Vw8Mn',
          autorNomePublico: 'Carlos',
          criadoEm: DateTime.utc(2026, 9, 5),
          estiloAscensao: TipoAscensao.flash,
          texto: 'Ótima linha!',
        ),
      ]);
      expect(notas.single.cabecalhoAutorData, 'Carlos • 05/09/2026');
      expect(notas.single.rotuloEstilo, 'FLASH ★');

      // Resolução de EstadoCroquiVia por nome (sem uid) com mapa próprio e pico
      final viaSemUidComMapa = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Via Local'),
        mapas: [
          Mapa(
            caminhoImagemMapa: 'mapas/local.webp',
            larguraMapa: 600,
            alturaMapa: 600,
          ),
        ],
      );
      final picoComVia = Pico(
        nome: 'Pico Local',
        setoresOuGrupos: [
          SetorOuGrupo(
            setor: ArquivoSetor(
              conteudo: Setor(
                nome: 'Setor Local',
                escaladas: [viaSemUidComMapa],
              ),
            ),
          ),
        ],
      );
      final estadoComPico = ExtratorDetalhesTecnicosVia.resolverEstadoCroqui(
        escalada: viaSemUidComMapa,
        pico: picoComVia,
        setor: Setor(nome: 'Setor Local'),
      );
      expect(estadoComPico.mapasMiniatura, hasLength(1));
      expect(estadoComPico.aspectRatioMiniatura, 1.0);
    },
  );
}
