// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/widgets.dart';
import 'controlador_idioma_app.dart';
import 'dicionario_de.dart';
import 'dicionario_en.dart';
import 'dicionario_es.dart';
import 'dicionario_nl.dart';
import 'dicionario_pt.dart';
import 'modelo_idioma_app.dart';

export 'controlador_idioma_app.dart';
export 'modelo_idioma_app.dart';

/// Motor síncrono `O(1)` de tradução e interpolação de parâmetros para os 5 idiomas do aplicativo.
abstract final class TradutorApp {
  /// Retorna o dicionário estático correspondente a [idioma].
  static Map<ChaveTexto, String> dicionarioDe(IdiomaApp idioma) {
    switch (idioma) {
      case IdiomaApp.portugues:
        return dicionarioPortugues;
      case IdiomaApp.ingles:
        return dicionarioIngles;
      case IdiomaApp.espanhol:
        return dicionarioEspanhol;
      case IdiomaApp.alemao:
        return dicionarioAlemao;
      case IdiomaApp.holandes:
        return dicionarioHolandes;
    }
  }

  /// Resolve [chave] no [idioma] informado (ou no idioma global ativo de [ControladorIdiomaApp.instancia]),
  /// substituindo marcadores `{nome}` pelos valores de [parametros].
  static String texto(
    ChaveTexto chave, {
    IdiomaApp? idioma,
    Map<String, Object?> parametros = const {},
  }) {
    final idiomaAlvo = idioma ?? ControladorIdiomaApp.instancia.idiomaAtual;
    final tabela = dicionarioDe(idiomaAlvo);
    final modelo = tabela[chave]!;
    if (parametros.isEmpty) return modelo;

    var resultado = modelo;
    for (final entrada in parametros.entries) {
      resultado = resultado.replaceAll(
        '{${entrada.key}}',
        '${entrada.value ?? ''}',
      );
    }
    return resultado;
  }

  /// Formata datas legais por extenso (`25 de Novembro de 2026` / `November 25, 2026` / etc.).
  static String formatarDataExtensoLegal(
    String dataIsoCurta, {
    IdiomaApp? idioma,
  }) {
    final partes = dataIsoCurta.split('-');
    if (partes.length != 3) return dataIsoCurta;
    final ano = partes[0];
    final mesIdx = (int.tryParse(partes[1]) ?? 1).clamp(1, 12) - 1;
    final dia = int.tryParse(partes[2])?.toString() ?? partes[2];
    final alvo = idioma ?? ControladorIdiomaApp.instancia.idiomaAtual;

