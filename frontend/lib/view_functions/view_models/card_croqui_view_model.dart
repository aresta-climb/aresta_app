// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/dtos/card_croqui_dto.dart';

export '../../data/dtos/card_croqui_dto.dart';

/// Apelido para manter compatibilidade com componentes legados que importam [CardCroquiViewModel].
///
/// O modelo canônico de transferência de dados para Dumb UI agora reside em [CardCroquiDTO].
    textoEstatisticas = '$setores setores • $vias escaladas';

    if (estatisticasDetalhadas) {
      final List<String> modalidades = [];
      if (p.totalBoulders > 0) modalidades.add('${p.totalBoulders} boulders');
      if (p.totalEsportivas > 0) modalidades.add('${p.totalEsportivas} esportivas');
      if (p.totalMoveis > 0) modalidades.add('${p.totalMoveis} móveis');
      if (p.totalMultiplasEnfiadas > 0) {
        modalidades.add('${p.totalMultiplasEnfiadas} múltiplas enfiadas');
      }
      if (p.totalHighlines > 0) modalidades.add('${p.totalHighlines} highlines');
      if (modalidades.isNotEmpty) {
        textoEstatisticas += ' (${modalidades.join(', ')})';
      }
    }
  }

  return CardCroquiViewModel(
    id: id,
    titulo: titulo,
    localizacao: localizacao,
    textoEstatisticas: textoEstatisticas,
    caminhoMiniatura: caminhoMiniatura,
    salvoOffline: salvoOffline,
    textoDistancia: textoDistancia,
    checksumSha256: checksumSha256,
  );
}

/// Mapeia um guia completo offline [Croqui] para o modelo de apresentação [CardCroquiViewModel].
CardCroquiViewModel mapearCroquiParaCard(
  Croqui croqui, {
  String? textoDistancia,
}) {
  final String id = croqui.id;
  final nomeFonte = croqui.nome.trim().isNotEmpty
      ? croqui.nome.trim()
      : (croqui.picos.isNotEmpty ? croqui.picos.first.nome.trim() : '');
  final String titulo =
      nomeFonte.isEmpty ? 'SEM NOME' : nomeFonte.toUpperCase();

  final localFonte = croqui.picos.isNotEmpty && croqui.picos.first.estado.trim().isNotEmpty
      ? croqui.picos.first.estado.trim()
      : '';
  final String localizacao =
      localFonte.isEmpty ? 'LOCAL DESCONHECIDO' : localFonte.toUpperCase();

  String textoEstatisticas = '0 setores • 0 escaladas';
  if (croqui.picos.isNotEmpty && croqui.picos.first.hasPrecomputados()) {
    final stats = croqui.picos.first.precomputados;
    textoEstatisticas = '${stats.totalSetores} setores • ${stats.totalEscaladas} escaladas';
  }

  return CardCroquiViewModel(
    id: id,
    titulo: titulo,
    localizacao: localizacao,
    textoEstatisticas: textoEstatisticas,
    caminhoMiniatura: 'thumbnails/$id.webp',
    salvoOffline: true,
    textoDistancia: textoDistancia,
  );
}
