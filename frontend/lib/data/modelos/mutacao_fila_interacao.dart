// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../utils/gerador_uid.dart';
import 'interacao_via.dart';
import 'item_fila_interacao.dart';

/// Operações autenticadas de edição ou exclusão sobre comentários e alertas do próprio autor.
enum TipoMutacaoFilaInteracao {
  /// Atualiza o texto (`1..280` caracteres) de um comentário público pendente do autor.
  editarComentario('EDITAR_COMENTARIO'),

  /// Exclui permanentemente um comentário público pendente do autor.
  excluirComentario('EXCLUIR_COMENTARIO'),

  /// Atualiza a categoria e/ou o detalhe (`<= 100` caracteres) de um alerta pendente do autor.
  editarAlerta('EDITAR_ALERTA'),

  /// Exclui permanentemente um alerta de segurança pendente do autor.
  excluirAlerta('EXCLUIR_ALERTA');

  /// Código persistido em JSON na fila offline local.
  final String codigo;

  const TipoMutacaoFilaInteracao(this.codigo);

  /// Converte [codigo] serializado no [TipoMutacaoFilaInteracao] correspondente.
  static TipoMutacaoFilaInteracao deCodigo(String codigo) {
    for (final item in TipoMutacaoFilaInteracao.values) {
      if (item.codigo == codigo) return item;
    }
    throw ArgumentError.value(
      codigo,
      'codigo',
      'Tipo de mutação na fila de interações desconhecido.',
    );
  }
}

/// Representação imutável de uma mutação pendente (edição ou exclusão) de autoria do usuário
/// na fila offline (*outbox*) de `public.fila_interacoes`.
@immutable
class MutacaoFilaInteracao {
  /// Operação a executar no PostgREST.
  final TipoMutacaoFilaInteracao tipo;

  /// Identificador do comentário (`id`) ou do alerta (`alerta_alvo_uid`) alvo.
  final String alvoUid;

  /// NanoID 14c da escalada associada.
  final String escaladaUid;

  /// NanoID 14c público do autor titular da interação.
  final String autorIdPublico;

  /// Novo texto em edições de comentário ou detalhe opcional em edições de alerta.
  final String? novoTexto;

  /// Nova categoria em edições de alerta de segurança.
  final CategoriaAlertaSeguranca? novaCategoria;

  /// Instante UTC de registro da mutação.
  final DateTime criadoEm;

  const MutacaoFilaInteracao._({
    required this.tipo,
    required this.alvoUid,
    required this.escaladaUid,
    required this.autorIdPublico,
    this.novoTexto,
    this.novaCategoria,
    required this.criadoEm,
  });

  /// Constrói uma mutação validada de edição de comentário (`1..280` caracteres).
  factory MutacaoFilaInteracao.editarComentario({
    required String alvoUid,
    required String escaladaUid,
    required String autorIdPublico,
    required String novoTexto,
    DateTime? criadoEm,
  }) {
    final alvoLimpo = _exigirNaoVazio(alvoUid, 'alvoUid');
    _exigirUid(escaladaUid, 'escaladaUid');
    _exigirUid(autorIdPublico, 'autorIdPublico');
    final textoLimpo = novoTexto.trim();
    if (textoLimpo.isEmpty ||
        textoLimpo.length > ComentarioComunidadeVia.limiteCaracteres) {
      throw ArgumentError.value(
        novoTexto,
        'novoTexto',
        'O comentário deve ter entre 1 e ${ComentarioComunidadeVia.limiteCaracteres} caracteres.',
      );
    }
    return MutacaoFilaInteracao._(
      tipo: TipoMutacaoFilaInteracao.editarComentario,
      alvoUid: alvoLimpo,
      escaladaUid: escaladaUid,
      autorIdPublico: autorIdPublico,
      novoTexto: textoLimpo,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Constrói uma mutação validada de exclusão de comentário.
  factory MutacaoFilaInteracao.excluirComentario({
    required String alvoUid,
    required String escaladaUid,
    required String autorIdPublico,
    DateTime? criadoEm,
  }) {
    final alvoLimpo = _exigirNaoVazio(alvoUid, 'alvoUid');
    _exigirUid(escaladaUid, 'escaladaUid');
    _exigirUid(autorIdPublico, 'autorIdPublico');
    return MutacaoFilaInteracao._(
      tipo: TipoMutacaoFilaInteracao.excluirComentario,
      alvoUid: alvoLimpo,
      escaladaUid: escaladaUid,
      autorIdPublico: autorIdPublico,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Constrói uma mutação validada de edição de alerta de segurança (`<= 100` caracteres).
  factory MutacaoFilaInteracao.editarAlerta({
    required String alvoUid,
    required String escaladaUid,
    required String autorIdPublico,
    required CategoriaAlertaSeguranca novaCategoria,
    String? detalhe,
    DateTime? criadoEm,
  }) {
    _exigirUid(alvoUid, 'alvoUid');
    _exigirUid(escaladaUid, 'escaladaUid');
    _exigirUid(autorIdPublico, 'autorIdPublico');
    final detalheLimpo = detalhe?.trim();
    if (detalheLimpo != null &&
        detalheLimpo.length > AlertaSegurancaVia.limiteCaracteresDetalhe) {
      throw ArgumentError.value(
        detalheLimpo.length,
        'detalhe',
        'O detalhe do alerta deve ter no máximo ${AlertaSegurancaVia.limiteCaracteresDetalhe} caracteres.',
      );
    }
    return MutacaoFilaInteracao._(
      tipo: TipoMutacaoFilaInteracao.editarAlerta,
      alvoUid: alvoUid,
      escaladaUid: escaladaUid,
      autorIdPublico: autorIdPublico,
      novaCategoria: novaCategoria,
      novoTexto: (detalheLimpo != null && detalheLimpo.isNotEmpty)
          ? detalheLimpo
          : null,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Constrói uma mutação validada de exclusão de alerta de segurança.
  factory MutacaoFilaInteracao.excluirAlerta({
    required String alvoUid,
    required String escaladaUid,
    required String autorIdPublico,
    DateTime? criadoEm,
  }) {
    _exigirUid(alvoUid, 'alvoUid');
    _exigirUid(escaladaUid, 'escaladaUid');
    _exigirUid(autorIdPublico, 'autorIdPublico');
    return MutacaoFilaInteracao._(
      tipo: TipoMutacaoFilaInteracao.excluirAlerta,
      alvoUid: alvoUid,
      escaladaUid: escaladaUid,
      autorIdPublico: autorIdPublico,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

