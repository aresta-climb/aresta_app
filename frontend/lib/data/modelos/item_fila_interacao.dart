// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
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
}
