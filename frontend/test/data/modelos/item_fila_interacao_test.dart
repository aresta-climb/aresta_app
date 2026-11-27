// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
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
        autorAvatarUrl: '  https://cdn.aresta.cc/avatars/mariana.webp  ',
        escaladaUid: 'x8siJek3FiG3aB',
        textoComentario: '  Chapeleta 3 bamba, levar chave 13.  ',
        tipoAscensao: TipoAscensao.aVista,
        criadoEm: instante,
      );
      expect(comentario.toJson().containsKey('autor_avatar_url'), isFalse);
      final comentarioRestaurado = ItemFilaInteracao.fromJson(
        comentario.toJson(incluirAvatarLocal: true),
      );
      expect(comentarioRestaurado.tipo, TipoFilaInteracao.comentario);
      expect(comentarioRestaurado.textoComentario, 'Chapeleta 3 bamba, levar chave 13.');
      expect(comentarioRestaurado.autorAvatarUrl, 'https://cdn.aresta.cc/avatars/mariana.webp');
      expect(comentarioRestaurado.tipoAscensao, TipoAscensao.aVista);

      final alerta = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Carlos',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'a1B2c3D4e5F6g7',
        categoriaAlerta: CategoriaAlertaSeguranca.fauna,
        detalhe: 'Colmeia na fenda',
        criadoEm: instante,
      );
      final alertaRestaurado = ItemFilaInteracao.fromJson(alerta.toJson());
      expect(alertaRestaurado.categoriaAlerta, CategoriaAlertaSeguranca.fauna);
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

      expect(TipoFilaInteracao.votoGrau.exigeContaAutenticada, isTrue);
      expect(TipoFilaInteracao.comentario.exigeContaAutenticada, isTrue);
      expect(TipoFilaInteracao.alertaSeguranca.exigeContaAutenticada, isTrue);
      expect(TipoFilaInteracao.confirmacaoAlerta.exigeContaAutenticada, isTrue);

      final reconciliado = voto.comAutor(
        autorIdPublico: 'z9Yx8Wv7Ut6Sr5',
        autorNomePublico: '  Mariana Oficial  ',
      );
      expect(reconciliado.autorIdPublico, 'z9Yx8Wv7Ut6Sr5');
      expect(reconciliado.autorNomePublico, 'Mariana Oficial');
      expect(reconciliado.deltaGrau, voto.deltaGrau);
      expect(
        () => voto.comAutor(autorIdPublico: 'invalido', autorNomePublico: 'Ana'),
        throwsArgumentError,
      );

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
          categoriaAlerta: CategoriaAlertaSeguranca.exposicaoE4Mais,
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

    test('consolidarItensFilaEmDadosComunidade agrega votos, comentários reversos e ciclo de alertas Waze', () {
      final t1 = DateTime.utc(2026, 11, 19, 10, 0);
      final t2 = DateTime.utc(2026, 11, 19, 11, 0);
      final t3 = DateTime.utc(2026, 11, 19, 12, 0);

      final itens = [
        ItemFilaInteracao.votoGrau(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 1,
          grauSugerido: GrauVia_GrauVia.BR_7B.value,
          criadoEm: t1,
        ),
        ItemFilaInteracao.comentario(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          textoComentario: 'Primeiro comentário',
          tipoAscensao: TipoAscensao.trabalhado,
          criadoEm: t1,
        ),
        ItemFilaInteracao.comentario(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          textoComentario: 'Comentário mais recente',
          tipoAscensao: TipoAscensao.flash,
          criadoEm: t2,
        ),
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaAbelha01',
          categoriaAlerta: CategoriaAlertaSeguranca.fauna,
          detalhe: 'Enxame no diedro',
          criadoEm: t1,
        ),
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaAbelha02',
          categoriaAlerta: CategoriaAlertaSeguranca.fauna,
          detalhe: 'Continua ativo',
          criadoEm: t1,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaAbelha01',
          alertaAtivo: true,
          criadoEm: t2,
        ),
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaMolhada1',
          categoriaAlerta: CategoriaAlertaSeguranca.exposicaoE4Mais,
          criadoEm: t2,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaMolhada1',
          alertaAtivo: false,
          criadoEm: t3,
        ),
      ];

      final dados = consolidarItensFilaEmDadosComunidade(
        itens,
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
      );

      expect(dados.consensoGrau.grauSugerido, '7b');
      expect(dados.consensoGrau.totalVotos, 1);
      expect(dados.comentarios.map((c) => c.autorNomePublico), equals(['Pedro', 'Mariana']));
      expect(dados.comentarios.first.rotuloEstilo, 'FLASH ★');

      expect(dados.alertasAtivos, hasLength(1));
      expect(dados.alertasAtivos.single.uid, 'alertaAbelha01');
      // Pedro já reforçou via alertaSeguranca na mesma categoria, logo seu confirmacaoAlerta repetido NÃO soma de novo (Mariana + Pedro = 2)!
      expect(dados.alertasAtivos.single.confirmacoesAtivas, 2);
      expect(dados.alertasAtivos.single.detalhe, 'Continua ativo');
    });

    test('deduplica +1 repetido do mesmo autor, consolida alertas da Caderneta e valida SQL de deploy Supabase', () {
      final t1 = DateTime.utc(2026, 11, 20, 9, 0);
      final t2 = DateTime.utc(2026, 11, 20, 10, 0);
      final t3 = DateTime.utc(2026, 11, 20, 11, 0);
      const eu = 'c3Lk9P1x4Vw8Mn';
      const pedro = 'd4Ml0Q2y5Wx9No';

      final eventos = [
        // Eu crio alerta na via 1 e tento auto-confirmar +1 três vezes
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: eu,
          autorNomePublico: 'Mariana',
          escaladaUid: 'viaCriadaPorMi',
          alertaAlvoUid: 'alertaMeu00001',
          categoriaAlerta: CategoriaAlertaSeguranca.fauna,
          detalhe: 'Colmeia ativa',
          criadoEm: t1,
        ),
        // Duplicata de alertaSeguranca pela mesma autora na mesma categoria não soma novamente
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: eu,
          autorNomePublico: 'Mariana',
          escaladaUid: 'viaCriadaPorMi',
          alertaAlvoUid: 'alertaMeuDup01',
          categoriaAlerta: CategoriaAlertaSeguranca.fauna,
          detalhe: 'Colmeia ativa atualizada',
          criadoEm: t2,
        ),
        // Segundo alerta ativo criado por mim em outra via (testa ordenação por ultimaInteracaoEm entre ativos)
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: eu,
          autorNomePublico: 'Mariana',
          escaladaUid: 'viaCriadaRecen',
          alertaAlvoUid: 'alertaRecente3',
          categoriaAlerta: CategoriaAlertaSeguranca.exposicaoE4Mais,
          criadoEm: t3,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: eu,
          autorNomePublico: 'Mariana',
          escaladaUid: 'viaCriadaPorMi',
          alertaAlvoUid: 'alertaMeu00001',
          alertaAtivo: true,
          criadoEm: t2,
        ),
        // Pedro confirma duas vezes — só deve somar 1 vez (total = 2)
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: pedro,
          autorNomePublico: 'Pedro',
          escaladaUid: 'viaCriadaPorMi',
          alertaAlvoUid: 'alertaMeu00001',
          alertaAtivo: true,
          criadoEm: t2,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: pedro,
          autorNomePublico: 'Pedro',
          escaladaUid: 'viaCriadaPorMi',
          alertaAlvoUid: 'alertaMeu00001',
          alertaAtivo: true,
          criadoEm: t3,
        ),
        // Pedro cria alerta na via 2, eu confirmo (+1), e depois é resolvido
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: pedro,
          autorNomePublico: 'Pedro',
          escaladaUid: 'viaConfirmada1',
          alertaAlvoUid: 'alertaPedro002',
          categoriaAlerta: CategoriaAlertaSeguranca.rochaAgarraInstavel,
          detalhe: 'Bloco solto',
          criadoEm: t1,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: eu,
          autorNomePublico: 'Mariana',
          escaladaUid: 'viaConfirmada1',
          alertaAlvoUid: 'alertaPedro002',
          alertaAtivo: true,
          criadoEm: t2,
        ),
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: pedro,
          autorNomePublico: 'Pedro',
          escaladaUid: 'viaConfirmada1',
          alertaAlvoUid: 'alertaPedro002',
          alertaAtivo: false,
          criadoEm: t3,
        ),
      ];

      final dadosVia1 = consolidarItensFilaEmDadosComunidade(
        eventos.where((e) => e.escaladaUid == 'viaCriadaPorMi'),
        ehBoulder: false,
      );
      expect(dadosVia1.alertasAtivos.single.confirmacoesAtivas, 2);

      final meus = consolidarAlertasContribuidosPeloAutor(
        eventos,
        autorIdPublico: eu,
      );
      expect(meus, hasLength(3));
      // Ativos vêm primeiro, ordenados do mais recente para o mais antigo
      expect(meus[0].alerta.uid, 'alertaRecente3');
      expect(meus[1].alerta.uid, 'alertaMeu00001');
      expect(meus[1].papel, PapelContribuicaoAlerta.criadoPorMim);
      expect(meus[1].ativo, isTrue);
      expect(meus[1].alerta.confirmacoesAtivas, 2);

      expect(meus[2].alerta.uid, 'alertaPedro002');
      expect(meus[2].papel, PapelContribuicaoAlerta.confirmadoPorMim);
      expect(meus[2].ativo, isFalse);

      expect(
        consolidarAlertasContribuidosPeloAutor(eventos, autorIdPublico: '   '),
        isEmpty,
      );

      final sql = File(
        '../docs/arquitetura/sql/supabase_contas_cadenas_interacoes.sql',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(
        sql,
        contains('DROP POLICY IF EXISTS "fila_interacoes_seguranca_anonima"'),
      );
      expect(
        sql.contains('CREATE POLICY "fila_interacoes_seguranca_anonima"'),
        isFalse,
      );
      expect(
        sql,
        contains('REVOKE ALL ON public.fila_interacoes FROM anon;'),
      );
      expect(
        sql,
        contains('idx_fila_confirmacao_positiva_unica_por_autor'),
      );
      expect(sql, contains("'FAUNA'"));
      expect(sql, contains("'EXPOSICAO_E4_MAIS'"));
      expect(
        sql,
        contains("SET categoria_alerta = 'FAUNA'"),
      );
      expect(
        sql,
        contains("SET categoria_alerta = 'EXPOSICAO_E4_MAIS'"),
      );
      expect(
        sql,
        contains("DELETE FROM public.fila_interacoes\nWHERE categoria_alerta = 'VIA_MOLHADA';"),
      );
      expect(
        sql,
        contains('CREATE POLICY "fila_interacoes_atualizacao_proprio_autor"'),
      );
      expect(
        sql,
        contains('CREATE POLICY "fila_interacoes_exclusao_proprio_autor"'),
      );
      expect(
        sql,
        contains('proteger_campos_imutaveis_fila_interacoes'),
      );

      final comAuto = ItemFilaInteracao.comentario(
        autorIdPublico: eu,
        autorNomePublico: 'Mariana',
        escaladaUid: 'viaCriadaPorMi',
        textoComentario: 'Original',
      );
      expect(ItemFilaInteracao.ehUuidValido(comAuto.id), isTrue);
      expect(ItemFilaInteracao.ehUuidValido('nao-eh-uuid'), isFalse);
      final comEditado = comAuto.comTextoComentario('Editado');
      expect(comEditado.id, comAuto.id);
      expect(comEditado.textoComentario, 'Editado');
      final consolidadoCom = consolidarItensFilaEmDadosComunidade(
        [comEditado],
        ehBoulder: false,
      );
      expect(consolidadoCom.comentarios.single.uid, comAuto.id);

      expect(() => comAuto.comTextoComentario('   '), throwsArgumentError);
      expect(
        () => eventos.first.comEdicaoAlerta(
          categoria: CategoriaAlertaSeguranca.fauna,
          detalhe: 'x' * 101,
        ),
        throwsArgumentError,
      );
      final alertaEditado = eventos.first.comEdicaoAlerta(
        categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
        detalhe: '   ',
      );
      expect(alertaEditado.categoriaAlerta, CategoriaAlertaSeguranca.protecaoPrecaria);
      expect(alertaEditado.textoComentario, isNull);
    });
  });
}
