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

    },
  );
}
