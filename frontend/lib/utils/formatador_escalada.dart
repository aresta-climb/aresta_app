// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';

/// Extrai o nome legível de uma [Escalada] Protobuf de acordo com a modalidade ativa.
///
/// Mantém esta regra de domínio desacoplada da camada de apresentação (`view/`) para
/// que serviços, compiladores de estatísticas e a árvore de navegação possam consultá-la
/// sem violar o fluxo unidirecional de dependências da Clean Architecture.
String obterNomeEscalada(Escalada escalada, {String padrao = 'Sem Nome'}) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return escalada.viaEsportiva.nome;
    case Escalada_Tipo.viaMovel:
      return escalada.viaMovel.nome;
    case Escalada_Tipo.boulder:
      return escalada.boulder.nome;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return escalada.viaMultiplasEnfiadas.nome;
    case Escalada_Tipo.highline:
      return escalada.highline.nome;
    case Escalada_Tipo.notSet:
      return padrao;
  }
}

/// Formata o identificador textual de um enum Protobuf de dificuldade (ex.: `BR_4`, `BR_6SUP`,
/// `BR_7A_BARRA_7B`, `V4`) para notação esportiva brasileira legível (`4º`, `6ºsup`, `7a/7b`, `v4`).
///
/// Retorna string vazia quando o grau não foi informado ou é `INDEFINIDO`.
String formatarTextoGrau(String nomeEnumGrau) {
  if (nomeEnumGrau.isEmpty || nomeEnumGrau.toUpperCase().contains('INDEFINIDO')) {
    return '';
  }
  final textoNormalizado = nomeEnumGrau
      .replaceAll('BR_', '')
      .replaceAll('_BARRA_', '/')
      .replaceAll('_', ' ')
      .toLowerCase();

  return textoNormalizado.replaceAllMapped(RegExp(r'\b([1-9])\s?(sup)?\b'), (match) {
    final numero = match.group(1) ?? '';
    final sufixoSuperior = match.group(2) != null ? 'sup' : '';
    return '$numeroº$sufixoSuperior';
  });
}

/// Extrai e formata a graduação esportiva oficial de uma [Escalada] Protobuf.
///
/// Retorna string vazia para modalidades sem graduação esportiva (como highline) ou indefinidas.
String obterTextoGrauEscalada(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return formatarTextoGrau(escalada.viaEsportiva.dificuldade.name);
    case Escalada_Tipo.viaMovel:
      return formatarTextoGrau(escalada.viaMovel.dificuldade.name);
    case Escalada_Tipo.boulder:
      return formatarTextoGrau(escalada.boulder.dificuldade.name);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return formatarTextoGrau(escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name);
    case Escalada_Tipo.highline:
    case Escalada_Tipo.notSet:
      return '';
  }
}

/// Retorna o código inteiro oficial do enum Protobuf de dificuldade da [escalada]
/// (`GrauVia_GrauVia.value` ou `GrauBoulder_GrauBoulder.value`), ou `null` quando
/// a modalidade não possui grau esportivo ou quando o grau é `INDEFINIDO`/`PROJETO`.
int? obterCodigoGrauOficial(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      final grau = escalada.viaEsportiva.dificuldade;
      return grau.value >= 2 ? grau.value : null;
    case Escalada_Tipo.viaMovel:
      final grau = escalada.viaMovel.dificuldade;
      return grau.value >= 2 ? grau.value : null;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      final grau = escalada.viaMultiplasEnfiadas.dificuldadeMaxima;
      return grau.value >= 2 ? grau.value : null;
    case Escalada_Tipo.boulder:
      final grau = escalada.boulder.dificuldade;
      return grau.value >= 1 ? grau.value : null;
    case Escalada_Tipo.highline:
    case Escalada_Tipo.notSet:
      return null;
  }
}

/// Normaliza strings brutas de graduação vindas do catálogo SQLite ou de Protobufs
/// para os rótulos canônicos esperados pela pirâmide esportiva (ex.: `'6sup'` -> `'6ºsup'`,
/// `'5'` -> `'5º'`, `'v4'` -> `'V4'`), descartando metragens de `'highline'`.
String? normalizarGrauEscalada(
  String? grauBruto, {
  String? tipoEscalada,
}) {
  if (tipoEscalada == 'highline' || grauBruto == null) {
    return null;
  }
  final texto = grauBruto.trim();
  if (texto.isEmpty) {
    return null;
  }

  final ehBoulder =
      tipoEscalada == 'boulder' ||
      RegExp(r'^[vV]([bB]|\d+)').hasMatch(texto);
  if (ehBoulder) {
    return texto.toUpperCase();
  }

  return texto
      .split('/')
      .map((parte) {
        final limpa = parte.trim();
        final match = RegExp(
          r'^([1-9])\s*(sup)?$',
          caseSensitive: false,
        ).firstMatch(limpa);
        if (match != null) {
          final numero = match.group(1)!;
          final sufixo = match.group(2) != null ? 'sup' : '';
          return '$numeroº$sufixo';
        }
        return limpa;
      })
      .join('/');
}

/// Percorre de forma preguiçosa todas as [Escalada]s contidas nos setores diretos
/// e grupos aninhados de um [Croqui].
Iterable<Escalada> iterarEscaladasDoCroqui(Croqui croqui) sync* {
  for (final pico in croqui.picos) {
    for (final item in pico.setoresOuGrupos) {
      if (item.hasSetor()) {
        yield* item.setor.conteudo.escaladas;
      } else if (item.hasGrupo()) {
        for (final arquivoSetor in item.grupo.conteudo.setores) {
          yield* arquivoSetor.conteudo.escaladas;
        }
      }
    }
  }
}

