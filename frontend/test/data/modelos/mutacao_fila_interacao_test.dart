// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/mutacao_fila_interacao.dart';

void main() {
  group('MutacaoFilaInteracao', () {
    test('serializa, desserializa, reconcilia autor e valida pré-condições Fail-Fast', () {
      final instante = DateTime.utc(2026, 11, 25, 22, 0);

      final edicaoComentario = MutacaoFilaInteracao.editarComentario(
        alvoUid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        novoTexto: '  Crux atualizado: usar bico de pé esquerdo!  ',
        criadoEm: instante,
      );
      final restEdicaoCom = MutacaoFilaInteracao.fromJson(edicaoComentario.toJson());
      expect(restEdicaoCom.tipo, TipoMutacaoFilaInteracao.editarComentario);
      expect(restEdicaoCom.alvoUid, 'f47ac10b-58cc-4372-a567-0e02b2c3d479');
      expect(restEdicaoCom.novoTexto, 'Crux atualizado: usar bico de pé esquerdo!');
      expect(restEdicaoCom.criadoEm, instante);

      final exclusaoComentario = MutacaoFilaInteracao.excluirComentario(
        alvoUid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        criadoEm: instante,
      );
      final restExclusaoCom = MutacaoFilaInteracao.fromJson(exclusaoComentario.toJson());
      expect(restExclusaoCom.tipo, TipoMutacaoFilaInteracao.excluirComentario);

      final edicaoAlerta = MutacaoFilaInteracao.editarAlerta(
        alvoUid: 'alertaAbelha01',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        novaCategoria: CategoriaAlertaSeguranca.protecaoPrecaria,
        detalhe: '  Chapeleta 4 rodando  ',
        criadoEm: instante,
      );
      final restEdicaoAlerta = MutacaoFilaInteracao.fromJson(edicaoAlerta.toJson());
      expect(restEdicaoAlerta.tipo, TipoMutacaoFilaInteracao.editarAlerta);
      expect(
        restEdicaoAlerta.novaCategoria,
        CategoriaAlertaSeguranca.protecaoPrecaria,
      );
      expect(restEdicaoAlerta.novoTexto, 'Chapeleta 4 rodando');

      final edicaoAlertaSemDetalhe = MutacaoFilaInteracao.editarAlerta(
        alvoUid: 'alertaAbelha01',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        novaCategoria: CategoriaAlertaSeguranca.fauna,
        detalhe: '   ',
      );
      expect(edicaoAlertaSemDetalhe.novoTexto, isNull);

      final exclusaoAlerta = MutacaoFilaInteracao.excluirAlerta(
        alvoUid: 'alertaAbelha01',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      );
      final restExclusaoAlerta = MutacaoFilaInteracao.fromJson(exclusaoAlerta.toJson());
      expect(restExclusaoAlerta.tipo, TipoMutacaoFilaInteracao.excluirAlerta);

      final reconciliada = edicaoComentario.comAutor('z9Yx8Wv7Ut6Sr5');
      expect(reconciliada.autorIdPublico, 'z9Yx8Wv7Ut6Sr5');
      expect(() => edicaoComentario.comAutor('curto'), throwsArgumentError);

      final semDataJson = MutacaoFilaInteracao.fromJson({
        'tipo': 'EXCLUIR_COMENTARIO',
        'alvo_uid': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'escalada_uid': 'x8siJek3FiG3aB',
        'autor_id_publico': 'c3Lk9P1x4Vw8Mn',
      });
      expect(semDataJson.tipo, TipoMutacaoFilaInteracao.excluirComentario);

