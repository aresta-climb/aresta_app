// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

/// Extrai e formata o rótulo identificador (codenome) de uma referência visual de mapa.
///
/// Itera sobre `ref.ids` e seus nós na ordem sequencial exata, coletando:
/// - Rótulos de nós de traçados vetoriais do tipo `CIRCULO_IDENTIFICADOR`,
///   `INICIO_AGACHADO` ou `FIM_TOP` que possuam `rotulo` preenchido.
/// - O campo `label` de pontos de interesse convencionais (não-linhas) que esteja preenchido.
///
/// Deduplica rótulos idênticos consecutivos (ex: nós compartilhados entre segmentos)
/// e une os identificadores com traço (ex: "5-C", "SS-1-TOP").
///
/// Se nenhum rótulo válido for encontrado, retorna uma string vazia `""`
/// (nunca realiza fallback para IDs técnicos internos como "linha_XX").
String extrairRotuloReferencia(Mapa mapa, Mapa_Referencia ref) {
  if (ref.ids.isEmpty) return '';

  final Map<String, Mapa_PontoDeInteresse> poisMap = {
    for (final p in mapa.pontosDeInteresse) p.id: p,
  };

  final List<String> rotulos = [];

  for (final id in ref.ids) {
    final p = poisMap[id];
    if (p == null) continue;

    if (p.hasLinha()) {
      final linha = p.linha;
      if (linha.hasCompilado() && linha.compilado.marcadores.isNotEmpty) {
        for (final m in linha.compilado.marcadores) {
          if (_isNoIdentificador(m.tipo)) {
            final rot = m.rotulo.trim();
            if (rot.isNotEmpty) {
              rotulos.add(rot);
            }
          }
        }
      } else if (linha.hasConteudo() && linha.conteudo.nos.isNotEmpty) {
        for (final no in linha.conteudo.nos) {
          if (_isNoIdentificador(no.tipo)) {
            final rot = no.rotulo.trim();
            if (rot.isNotEmpty) {
              rotulos.add(rot);
            }
          }
        }
      }
    } else {
      final rot = p.label.trim();
      if (rot.isNotEmpty) {
        rotulos.add(rot);
      }
    }
  }

  if (rotulos.isEmpty) return '';

  // Deduplica rótulos consecutivos idênticos
  final List<String> rotulosDeduplicados = [];
  for (final rotulo in rotulos) {
    if (rotulosDeduplicados.isEmpty || rotulosDeduplicados.last != rotulo) {
      rotulosDeduplicados.add(rotulo);
    }
  }

  return rotulosDeduplicados.join('-');
}

bool _isNoIdentificador(NoTrajeto_TipoNo tipo) {
  return tipo == NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR ||
      tipo == NoTrajeto_TipoNo.INICIO_AGACHADO ||
      tipo == NoTrajeto_TipoNo.FIM_TOP;
}
