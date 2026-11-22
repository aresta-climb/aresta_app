// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../utils/calculadora_delta_grau.dart';
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

  /// Indica se a política RLS (`fila_interacoes_insercao_autenticada`) exige JWT autenticado
  /// e vínculo válido em `public.perfis` (obrigatório para todos os tipos de escrita comunitária).
  bool get exigeContaAutenticada => true;

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

  /// Constrói um evento validado de `ALERTA_SEGURANCA` estilo Waze.
  factory ItemFilaInteracao.alertaSeguranca({
    String? id,
    required String autorIdPublico,
    required String autorNomePublico,
    required String escaladaUid,
    required String alertaAlvoUid,
    required CategoriaAlertaSeguranca categoriaAlerta,
    String? detalhe,
    DateTime? criadoEm,
  }) {
    _exigirUidValido(autorIdPublico, 'autorIdPublico');
    _exigirUidValido(escaladaUid, 'escaladaUid');
    _exigirUidValido(alertaAlvoUid, 'alertaAlvoUid');
    final detalheLimpo = detalhe?.trim();
    if (detalheLimpo != null &&
        detalheLimpo.length > AlertaSegurancaVia.limiteCaracteresDetalhe) {
      throw ArgumentError.value(
        detalheLimpo.length,
        'detalhe',
        'O detalhe do alerta deve ter no máximo ${AlertaSegurancaVia.limiteCaracteresDetalhe} caracteres.',
      );
    }
    return ItemFilaInteracao._(
      id: id ?? alertaAlvoUid,
      autorIdPublico: autorIdPublico,
      autorNomePublico: _normalizarNome(autorNomePublico),
      escaladaUid: escaladaUid,
      tipo: TipoFilaInteracao.alertaSeguranca,
      categoriaAlerta: categoriaAlerta,
      alertaAlvoUid: alertaAlvoUid,
      textoComentario: (detalheLimpo != null && detalheLimpo.isNotEmpty)
          ? detalheLimpo
          : null,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Constrói um evento validado de `CONFIRMACAO_ALERTA` (*"Ainda está lá?"*).
  factory ItemFilaInteracao.confirmacaoAlerta({
    String? id,
    required String autorIdPublico,
    required String autorNomePublico,
    required String escaladaUid,
    required String alertaAlvoUid,
    required bool alertaAtivo,
    DateTime? criadoEm,
  }) {
    _exigirUidValido(autorIdPublico, 'autorIdPublico');
    _exigirUidValido(escaladaUid, 'escaladaUid');
    _exigirUidValido(alertaAlvoUid, 'alertaAlvoUid');
    return ItemFilaInteracao._(
      id: id ?? gerarUid(),
      autorIdPublico: autorIdPublico,
      autorNomePublico: _normalizarNome(autorNomePublico),
      escaladaUid: escaladaUid,
      tipo: TipoFilaInteracao.confirmacaoAlerta,
      alertaAlvoUid: alertaAlvoUid,
      alertaAtivo: alertaAtivo,
      criadoEm: (criadoEm ?? DateTime.now()).toUtc(),
    );
  }

  /// Reconstrói [ItemFilaInteracao] a partir de JSON PostgREST ou cache local.
  factory ItemFilaInteracao.fromJson(Map<String, dynamic> json) {
    final tipo = TipoFilaInteracao.deCodigoBanco(json['tipo'] as String);
    final catTexto = json['categoria_alerta'] as String?;
    final codAscensao = json['tipo_ascensao'] as int?;
    final criadoTexto = json['criado_em'] as String?;
    final idBruto = json['id']?.toString();

    return ItemFilaInteracao._(
      id: (idBruto != null && idBruto.isNotEmpty) ? idBruto : gerarUid(),
      autorIdPublico: json['autor_id_publico'] as String,
      autorNomePublico: _normalizarNome(json['autor_nome_publico'] as String?),
      escaladaUid: json['escalada_uid'] as String,
      tipo: tipo,
      categoriaAlerta: catTexto != null
          ? CategoriaAlertaSeguranca.deCodigoBanco(catTexto)
          : null,
      alertaAlvoUid: json['alerta_alvo_uid'] as String?,
      alertaAtivo: json['alerta_ativo'] as bool?,
      grauSugerido: json['grau_sugerido'] as int?,
      deltaGrau: json['delta_grau'] as int?,
      tipoAscensao: codAscensao != null
          ? TipoAscensao.fromCodigo(codAscensao)
          : null,
      textoComentario: json['texto_comentario'] as String?,
      criadoEm: criadoTexto != null
          ? DateTime.parse(criadoTexto).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  /// Converte para o payload exato aceito por `INSERT INTO public.fila_interacoes`.
  Map<String, dynamic> toJson({bool incluirId = true}) {
    return <String, dynamic>{
      if (incluirId) 'id': id,
      'autor_id_publico': autorIdPublico,
      'autor_nome_publico': autorNomePublico,
      'escalada_uid': escaladaUid,
      'tipo': tipo.codigoBanco,
      if (categoriaAlerta != null)
        'categoria_alerta': categoriaAlerta!.codigoBanco,
      if (alertaAlvoUid != null) 'alerta_alvo_uid': alertaAlvoUid,
      if (alertaAtivo != null) 'alerta_ativo': alertaAtivo,
      if (grauSugerido != null) 'grau_sugerido': grauSugerido,
      if (deltaGrau != null) 'delta_grau': deltaGrau,
      if (tipoAscensao != null) 'tipo_ascensao': tipoAscensao!.codigo,
      if (textoComentario != null) 'texto_comentario': textoComentario,
      'status': 'PENDENTE',
      'criado_em': criadoEm.toUtc().toIso8601String(),
    };
  }

  /// Retorna uma cópia de [ItemFilaInteracao] reconciliando [autorIdPublico] e [autorNomePublico]
  /// com a identidade canônica registrada em `public.perfis`.
  ItemFilaInteracao comAutor({
    required String autorIdPublico,
    required String autorNomePublico,
  }) {
    _exigirUidValido(autorIdPublico, 'autorIdPublico');
    return ItemFilaInteracao._(
      id: id,
      autorIdPublico: autorIdPublico,
      autorNomePublico: _normalizarNome(autorNomePublico),
      escaladaUid: escaladaUid,
      tipo: tipo,
      categoriaAlerta: categoriaAlerta,
      alertaAlvoUid: alertaAlvoUid,
      alertaAtivo: alertaAtivo,
      grauSugerido: grauSugerido,
      deltaGrau: deltaGrau,
      tipoAscensao: tipoAscensao,
      textoComentario: textoComentario,
      criadoEm: criadoEm,
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

/// Redutor puro que projeta os eventos cronológicos de `fila_interacoes` em [DadosComunidadeVia].
DadosComunidadeVia consolidarItensFilaEmDadosComunidade(
  Iterable<ItemFilaInteracao> itens, {
  int? codigoGrauOficial,
  required bool ehBoulder,
}) {
  final ordenados = itens.toList()
    ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

  final votosPorAutor = <String, ({int? deltaGrau, int? grauSugerido})>{};
  final comentarios = <ComentarioComunidadeVia>[];
  final alertas = <AlertaSegurancaVia>[];

  for (final item in ordenados) {
    switch (item.tipo) {
      case TipoFilaInteracao.votoGrau:
        votosPorAutor[item.autorIdPublico] = (
          deltaGrau: item.deltaGrau,
          grauSugerido: item.grauSugerido,
        );
      case TipoFilaInteracao.comentario:
        final texto = item.textoComentario?.trim();
        if (texto != null && texto.isNotEmpty) {
          comentarios.insert(
            0,
            ComentarioComunidadeVia(
              uid: validarUid(item.id) ? item.id : gerarUid(),
              autorIdPublico: item.autorIdPublico,
              autorNomePublico: item.autorNomePublico,
              criadoEm: item.criadoEm,
              estiloAscensao: item.tipoAscensao,
              texto: texto,
            ),
          );
        }
      case TipoFilaInteracao.alertaSeguranca:
        final categoria = item.categoriaAlerta;
        final uidAlerta = item.alertaAlvoUid;
        if (categoria == null || uidAlerta == null) break;
        final idxCat = alertas.indexWhere((a) => a.categoria == categoria);
        if (idxCat >= 0) {
          final existente = alertas[idxCat];
          alertas[idxCat] = existente.copyWith(
            confirmacoesAtivas: existente.confirmacoesAtivas + 1,
            detalhe: item.textoComentario ?? existente.detalhe,
          );
        } else {
          alertas.insert(
            0,
            AlertaSegurancaVia.criar(
              uid: uidAlerta,
              escaladaUid: item.escaladaUid,
              categoria: categoria,
              detalhe: item.textoComentario,
              autorNomePublico: item.autorNomePublico,
              criadoEm: item.criadoEm,
            ),
          );
        }
      case TipoFilaInteracao.confirmacaoAlerta:
        final alvoUid = item.alertaAlvoUid;
        final ativo = item.alertaAtivo;
        if (alvoUid == null || ativo == null) break;
        final idx = alertas.indexWhere((a) => a.uid == alvoUid);
        if (idx >= 0) {
          if (ativo) {
            alertas[idx] = alertas[idx].copyWith(
              confirmacoesAtivas: alertas[idx].confirmacoesAtivas + 1,
            );
          } else {
            alertas.removeAt(idx);
          }
        }
    }
  }

  return DadosComunidadeVia(
    consensoGrau: consolidarConsensoDeVotos(
      votos: votosPorAutor.values.toList(growable: false),
      codigoGrauOficial: codigoGrauOficial,
      ehBoulder: ehBoulder,
    ),
    alertasAtivos: List.unmodifiable(alertas),
    comentarios: List.unmodifiable(comentarios),
  );
}
