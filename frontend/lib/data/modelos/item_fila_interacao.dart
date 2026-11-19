// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../utils/gerador_uid.dart';
import 'interacao_via.dart';
import 'perfil_escalador.dart';
import 'tipo_ascensao.dart';

/// Tipos canônicos de eventos na tabela `public.fila_interacoes` do Supabase.
enum TipoFilaInteracao {
  /// Sugestão democrática de grau (`delta_grau` `-2..+2` e/ou `grau_sugerido`).
  votoGrau('VOTO_GRAU'),

  /// Comentário público de beta ou dica de equipamento (`<= 280` caracteres).
  comentario('COMENTARIO'),

  /// Novo alerta rápido de segurança estilo Waze (`<= 100` caracteres opcionais).
  alertaSeguranca('ALERTA_SEGURANCA'),

  /// Confirmação *"Ainda está lá?"* (`alerta_ativo = true` ou `false`).
  confirmacaoAlerta('CONFIRMACAO_ALERTA');

  /// Valor textual persistido na coluna `tipo` de `public.fila_interacoes`.
  final String codigoBanco;

  const TipoFilaInteracao(this.codigoBanco);

  /// Resolve [codigo] proveniente do PostgREST/JSON para [TipoFilaInteracao].
  static TipoFilaInteracao deCodigoBanco(String codigo) {
    for (final item in TipoFilaInteracao.values) {
      if (item.codigoBanco == codigo) {
        return item;
      }
    }
    throw ArgumentError.value(
      codigo,
      'codigo',
      'Tipo de interação na fila desconhecido.',
    );
  }
}

/// Representação imutável e validada de uma linha em `public.fila_interacoes`.
///
/// Projetada tanto para o tráfego PostgREST (`SELECT`/`INSERT`) quanto para a fila
/// persistente local (*offline outbox*) quando o escalador está sem sinal na rocha.
@immutable
class ItemFilaInteracao {
  /// Identificador local ou remoto do registro.
  final String id;

  /// NanoID 14c público do autor (sem expor `user_id` privado).
  final String autorIdPublico;

  /// Apelido público exibido junto à contribuição.
  final String autorNomePublico;

  /// NanoID 14c da escalada alvo.
  final String escaladaUid;

  /// Discriminador semântico da interação.
  final TipoFilaInteracao tipo;

  /// Categoria de risco quando [tipo] é [TipoFilaInteracao.alertaSeguranca].
  final CategoriaAlertaSeguranca? categoriaAlerta;

  /// NanoID 14c do alerta criado ou confirmado (*"Ainda está lá?"*).
  final String? alertaAlvoUid;

  /// Resposta de confirmação (`true` = ainda está lá, `false` = resolvido).
  final bool? alertaAtivo;

  /// Código numérico Protobuf do grau sugerido.
  final int? grauSugerido;

  /// Deslocamento relativo ao grau oficial (`-2` a `+2`).
  final int? deltaGrau;

  /// Estilo esportivo da ascensão associada ao voto ou comentário.
  final TipoAscensao? tipoAscensao;

  /// Comentário público de beta (`<= 280` chars) ou detalhe do alerta (`<= 100` chars).
  final String? textoComentario;

  /// Instante UTC de criação do registro.
  final DateTime criadoEm;

  const ItemFilaInteracao._({
    required this.id,
    required this.autorIdPublico,
    required this.autorNomePublico,
    required this.escaladaUid,
    required this.tipo,
    this.categoriaAlerta,
    this.alertaAlvoUid,
    this.alertaAtivo,
    this.grauSugerido,
    this.deltaGrau,
    this.tipoAscensao,
    this.textoComentario,
    required this.criadoEm,
  });

  /// Constrói um evento validado de `VOTO_GRAU`.
  factory ItemFilaInteracao.votoGrau({
    String? id,
    required String autorIdPublico,
    required String autorNomePublico,
    required String escaladaUid,
    required int deltaGrau,
    int? grauSugerido,
    TipoAscensao? tipoAscensao,
    DateTime? criadoEm,
  }) {
    _exigirUidValido(autorIdPublico, 'autorIdPublico');
    _exigirUidValido(escaladaUid, 'escaladaUid');
    if (deltaGrau < -2 || deltaGrau > 2) {
      throw ArgumentError.value(
        deltaGrau,
        'deltaGrau',
        'O delta de grau deve estar entre -2 e +2.',
      );
    }
    return ItemFilaInteracao._(
      id: id ?? gerarUid(),
      autorIdPublico: autorIdPublico,
      autorNomePublico: _normalizarNome(autorNomePublico),
      escaladaUid: escaladaUid,
      tipo: TipoFilaInteracao.votoGrau,
      deltaGrau: deltaGrau,
      grauSugerido: grauSugerido,
      tipoAscensao: tipoAscensao,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Constrói um evento validado de `COMENTARIO` público (`1..280` caracteres).
  factory ItemFilaInteracao.comentario({
    String? id,
    required String autorIdPublico,
    required String autorNomePublico,
    required String escaladaUid,
    required String textoComentario,
    TipoAscensao? tipoAscensao,
    DateTime? criadoEm,
  }) {
    _exigirUidValido(autorIdPublico, 'autorIdPublico');
    _exigirUidValido(escaladaUid, 'escaladaUid');
    final limpo = textoComentario.trim();
    if (limpo.isEmpty || limpo.length > ComentarioComunidadeVia.limiteCaracteres) {
      throw ArgumentError.value(
        textoComentario,
        'textoComentario',
        'O comentário deve ter entre 1 e ${ComentarioComunidadeVia.limiteCaracteres} caracteres.',
      );
    }
    return ItemFilaInteracao._(
      id: id ?? gerarUid(),
      autorIdPublico: autorIdPublico,
      autorNomePublico: _normalizarNome(autorNomePublico),
      escaladaUid: escaladaUid,
      tipo: TipoFilaInteracao.comentario,
      textoComentario: limpo,
      tipoAscensao: tipoAscensao,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }


  static void _exigirUidValido(String valor, String campo) {
    if (!validarUid(valor)) {
      throw ArgumentError.value(
        valor,
        campo,
        'Identificador deve seguir o padrão NanoID 14c Base62.',
      );
    }
  }

  static String _normalizarNome(String? bruto) {
    final limpo = bruto?.trim();
    if (limpo == null || limpo.isEmpty) {
      return PerfilEscalador.apelidoPadrao;
    }
    return limpo.length > 50 ? limpo.substring(0, 50) : limpo;
  }
}
