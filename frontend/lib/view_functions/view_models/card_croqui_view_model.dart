// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/dtos/card_croqui_dto.dart';

export '../../data/dtos/card_croqui_dto.dart';

/// Apelido para manter compatibilidade com componentes legados que importam [CardCroquiViewModel].
///
  /// Texto formatado de distância relativa do usuário (ex: '350m' ou '12.4km'), se disponível.
  final String? textoDistancia;

  /// Caminho opcional da imagem de capa local ou remota.
  final String? caminhoCapa;

  /// Hash SHA-256 opcional para validação de integridade e cache de imagem.
  final String? checksumSha256;

  const CardCroquiViewModel({
    required this.id,
    required this.titulo,
    this.localizacao = '',
    required this.textoEstatisticas,
    required this.caminhoMiniatura,
    this.salvoOffline = false,
    this.textoDistancia,
    this.caminhoCapa,
    this.checksumSha256,
  });
}

/// Mapeia uma entidade de catálogo [MetadadosIndice] para o modelo de apresentação [CardCroquiViewModel].
CardCroquiViewModel mapearMetadadosParaCard(
  MetadadosIndice metadados, {
  bool salvoOffline = false,
  String? textoDistancia,
  bool estatisticasDetalhadas = false,
}) {
  final String id = metadados.id;
  final String titulo =
      metadados.nome.trim().isEmpty ? 'SEM NOME' : metadados.nome.trim().toUpperCase();
  final String localizacao = metadados.localizacaoFormatada.toUpperCase();
  final String caminhoMiniatura = 'thumbnails/$id.webp';
  final String? checksumSha256 =
      metadados.hasChecksumSha256Thumbnail() ? metadados.checksumSha256Thumbnail : null;

  String textoEstatisticas = '0 setores • 0 escaladas';
  if (metadados.hasPrecomputados()) {
    final p = metadados.precomputados;
    final setores = p.totalSetores;
    final vias = p.totalEscaladas;
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
