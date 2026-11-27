// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';

/// Idiomas suportados nativamente em toda a experiência do Aresta Climb.
///
/// Inclui Português Brasileiro (padrão), Inglês, Espanhol, Alemão (`Deutsch`)
/// e Neerlandês/Holandês (`Nederlands` — idioma oficial e mais falado dos Países Baixos).
enum IdiomaApp {
  portugues(
    codigoIso: 'pt',
    regiaoIso: 'BR',
    nomeNativo: 'Português',
    subtituloRegiao: 'Brasil',
  ),
  ingles(
    codigoIso: 'en',
    regiaoIso: 'US',
    nomeNativo: 'English',
    subtituloRegiao: 'International',
  ),
  espanhol(
    codigoIso: 'es',
    regiaoIso: 'ES',
    nomeNativo: 'Español',
    subtituloRegiao: 'América Latina / España',
  ),
  alemao(
    codigoIso: 'de',
    regiaoIso: 'DE',
    nomeNativo: 'Deutsch',
    subtituloRegiao: 'Deutschland / Alpen',
  ),
  holandes(
    codigoIso: 'nl',
    regiaoIso: 'NL',
    nomeNativo: 'Nederlands',
    subtituloRegiao: 'Nederland / België',
  );

  /// Código ISO 639-1 em letras minúsculas (`pt`, `en`, `es`, `de`, `nl`).
  final String codigoIso;

  /// Código regional ISO 3166-1 (`BR`, `US`, `ES`, `DE`, `NL`).
  final String regiaoIso;

  /// Nome autônimo do idioma apresentado no seletor de bolhas.
  final String nomeNativo;

  /// Contexto regional exibido como legenda secundária no seletor.
  final String subtituloRegiao;

  const IdiomaApp({
    required this.codigoIso,
    required this.regiaoIso,
    required this.nomeNativo,
    required this.subtituloRegiao,
  });

  /// [Locale] completo correspondente ao idioma selecionado.
  Locale get locale => Locale(codigoIso, regiaoIso);

  /// [Locale] compatível com o pacote `feedback` (que possui delegados nativos para `en`, `de` e `es`,
  /// recorrendo a `en` quando o pacote de terceiros não embute `nl` ou `pt_BR` em todas as versões).
  Locale get localeFeedbackCompativel {
    switch (this) {
      case IdiomaApp.alemao:
        return const Locale('de');
      case IdiomaApp.espanhol:
        return const Locale('es');
      case IdiomaApp.portugues:
        return const Locale('pt', 'BR');
      case IdiomaApp.ingles:
      case IdiomaApp.holandes:
        return const Locale('en');
    }
  }

  /// Resolve um [IdiomaApp] a partir do seu [codigoIso] persistido, retornando [IdiomaApp.portugues]
  /// apenas quando o código é nulo ou desconhecido.
  static IdiomaApp deCodigoIso(String? codigo) {
    if (codigo == null || codigo.isEmpty) return IdiomaApp.portugues;
    final limpo = codigo.trim().toLowerCase();
    for (final item in IdiomaApp.values) {
      if (item.codigoIso == limpo) return item;
    }
    return IdiomaApp.portugues;
  }

