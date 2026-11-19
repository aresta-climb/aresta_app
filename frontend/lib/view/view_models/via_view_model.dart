// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';

/// Identificadores semânticos de ícones técnicos desacoplados de `Icons` concretos no ViewModel.
enum TipoIconeAtributoVia {
  extensao,
  protecoes,
  parede,
  exposicao,
  enfiadas,
  duracao,
  modalidade,
  distancia,
}

/// Par rótulo/valor exibido na grade responsiva de especificações técnicas da escalada.
@immutable
class AtributoTecnicoVia {
  /// Categoria visual do ícone associado ao atributo.
  final TipoIconeAtributoVia icone;

  /// Rótulo curto em caixa alta (ex.: `'EXTENSÃO'`, `'PROTEÇÕES'`).
  final String rotulo;

  /// Valor formatado pronto para exibição (ex.: `'28m'`, `'11+2'`).
  final String valor;

  /// Cria uma instância imutável de [AtributoTecnicoVia].
  const AtributoTecnicoVia({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });
}

/// Bloco textual estruturado da escalada (descrição oficial em Markdown, rack móvel, acesso, etc.).
@immutable
class SecaoTextoVia {
  /// Título da seção exibido acima do conteúdo.
  final String titulo;

  /// Conteúdo textual bruto ou em sintaxe Markdown.
  final String conteudo;

  /// Indica se o conteúdo deve ser renderizado via `OfflineMarkdown`.
  final bool ehMarkdown;

  /// Cria uma instância imutável de [SecaoTextoVia].
  const SecaoTextoVia({
    required this.titulo,
    required this.conteudo,
    required this.ehMarkdown,
  });
}

/// Resumo limpo e estruturado de uma enfiada individual em uma `ViaMultiplasEnfiadas`.
@immutable
class ResumoEnfiadaVia {
  /// Índice sequencial da enfiada (iniciando em 1).
  final int numero;

  /// Título combinando o número e o nome opcional da enfiada.
  final String titulo;

  /// Grau formatado da enfiada, quando definido.
  final String? grau;

  /// Extensão formatada em metros, quando definida.
  final String? extensao;

  /// Proteções fixas no formato `X+Y`, quando presentes.
  final String? protecoes;

  /// Recomendação de peças móveis da enfiada, quando presente.
  final String? equipamentoMovel;

  /// Descrição específica da enfiada, quando presente.
  final String? descricao;

  /// Cria uma instância imutável de [ResumoEnfiadaVia].
  const ResumoEnfiadaVia({
    required this.numero,
    required this.titulo,
    this.grau,
    this.extensao,
    this.protecoes,
    this.equipamentoMovel,
    this.descricao,
  });
}

/// Item clicável de mídia externa ou vídeo demonstrativo de beta da via.
@immutable
class ItemMidiaBetaVia {
  /// Título descritivo do vídeo, postagem ou artigo.
  final String titulo;

  /// URL de destino validada.
  final String url;

  /// Rótulo amigável da plataforma de origem (ex.: `'YouTube'`, `'Instagram'`, `'Blog'`, `'Vídeo'`).
  final String origemRotulo;

  /// Cria uma instância imutável de [ItemMidiaBetaVia].
  const ItemMidiaBetaVia({
    required this.titulo,
    required this.url,
    required this.origemRotulo,
  });
}

