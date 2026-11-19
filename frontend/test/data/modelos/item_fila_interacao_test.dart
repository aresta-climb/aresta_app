// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';

void main() {
  group('ItemFilaInteracao', () {
    test('serializa e desserializa todos os quatro tipos de interação com validação Fail-Fast', () {
      final instante = DateTime.utc(2026, 11, 19, 18, 0);

      final voto = ItemFilaInteracao.votoGrau(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana Silva',
        escaladaUid: 'x8siJek3FiG3aB',
        deltaGrau: 1,
        grauSugerido: GrauVia_GrauVia.BR_7B.value,
        tipoAscensao: TipoAscensao.flash,
        criadoEm: instante,
      );
      final votoRestaurado = ItemFilaInteracao.fromJson(voto.toJson());
      expect(votoRestaurado.tipo, TipoFilaInteracao.votoGrau);
      expect(votoRestaurado.deltaGrau, 1);
      expect(votoRestaurado.grauSugerido, GrauVia_GrauVia.BR_7B.value);
      expect(votoRestaurado.tipoAscensao, TipoAscensao.flash);

      final comentario = ItemFilaInteracao.comentario(
        id: 'm8Kq2L1x9Y7zWq',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana Silva',
        escaladaUid: 'x8siJek3FiG3aB',
        textoComentario: '  Chapeleta 3 bamba, levar chave 13.  ',
        tipoAscensao: TipoAscensao.aVista,
        criadoEm: instante,
      );
      final comentarioRestaurado = ItemFilaInteracao.fromJson(comentario.toJson());
      expect(comentarioRestaurado.tipo, TipoFilaInteracao.comentario);
      expect(comentarioRestaurado.textoComentario, 'Chapeleta 3 bamba, levar chave 13.');
      expect(comentarioRestaurado.tipoAscensao, TipoAscensao.aVista);

      final alerta = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Carlos',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'a1B2c3D4e5F6g7',
        categoriaAlerta: CategoriaAlertaSeguranca.abelhasInsetos,
        detalhe: 'Colmeia na fenda',
        criadoEm: instante,
      );
      final alertaRestaurado = ItemFilaInteracao.fromJson(alerta.toJson());
      expect(alertaRestaurado.categoriaAlerta, CategoriaAlertaSeguranca.abelhasInsetos);
      expect(alertaRestaurado.alertaAlvoUid, 'a1B2c3D4e5F6g7');

      final confirmacao = ItemFilaInteracao.confirmacaoAlerta(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Ana',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'a1B2c3D4e5F6g7',
        alertaAtivo: false,
        criadoEm: instante,
      );
      final confirmacaoRestaurada = ItemFilaInteracao.fromJson(confirmacao.toJson());
      expect(confirmacaoRestaurada.tipo, TipoFilaInteracao.confirmacaoAlerta);
      expect(confirmacaoRestaurada.alertaAtivo, isFalse);

      expect(() => TipoFilaInteracao.deCodigoBanco('INVALIDO'), throwsArgumentError);
      expect(
        () => ItemFilaInteracao.votoGrau(
          autorIdPublico: 'curto',
          autorNomePublico: 'Ana',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => ItemFilaInteracao.votoGrau(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Ana',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => ItemFilaInteracao.comentario(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: '   ',
          escaladaUid: 'x8siJek3FiG3aB',
          textoComentario: '   ',
        ),
        throwsArgumentError,
      );
      expect(
        () => ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Ana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'a1B2c3D4e5F6g7',
          categoriaAlerta: CategoriaAlertaSeguranca.viaMolhada,
          detalhe: 'x' * 101,
        ),
        throwsArgumentError,
      );

      final semCriadoEm = ItemFilaInteracao.fromJson({
        'autor_id_publico': 'c3Lk9P1x4Vw8Mn',
        'autor_nome_publico': '',
        'escalada_uid': 'x8siJek3FiG3aB',
        'tipo': 'VOTO_GRAU',
        'delta_grau': 0,
      });
      expect(semCriadoEm.autorNomePublico, 'Escalador Aresta');
    });
  });
}
