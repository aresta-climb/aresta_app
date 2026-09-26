// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../../aresta_api/proto/generated/indice.pb.dart';
import '../../../utils/formatador_tamanho.dart';
import 'estatisticas_pico.dart';
import 'resumo_pico.dart';


/// Representa de forma fortemente tipada os metadados de um croqui cadastrado no catálogo do [Indice].
///
/// Substitui o uso do nome legado [ResumoCroqui], trazendo clareza semântica e eliminando
/// a ambiguidade com o guia completo [Croqui].
typedef MetadadosIndice = ResumoCroqui;

/// Extensão com propriedades utilitárias e conversões para [MetadadosIndice].
extension ExtensaoMetadadosIndice on MetadadosIndice {
  /// Latitude em graus decimais (convertida a partir da representação inteira em micrograus do Protobuf).
  double? get latitude =>
      hasLocalizacao() ? localizacao.latitude / 10000000.0 : null;

  /// Longitude em graus decimais (convertida a partir da representação inteira em micrograus do Protobuf).
  double? get longitude =>
      hasLocalizacao() ? localizacao.longitude / 10000000.0 : null;

  /// Retorna o nome amigável da localização extraído do caminho relativo do croqui.
  String get localizacaoFormatada {
    final partes = caminhoRelativo.split('/');
    if (partes.length >= 2) {
      final pasta = partes[partes.length - 2];
      return pasta
          .replaceAll('_', ' ')
          .split(' ')
          .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');
    }
    return 'Local Desconhecido';
  }

  /// Total de escaladas cadastradas nos dados pré-computados.
  int get totalEscaladas => hasPrecomputados() ? precomputados.totalEscaladas : 0;

  /// Total de setores cadastrados nos dados pré-computados.
  int get totalSetores => hasPrecomputados() ? precomputados.totalSetores : 0;

  /// Tamanho estimado em bytes para download offline.
  int? get tamanhoDownloadBytes =>
      hasPrecomputados() && precomputados.hasTamanhoDownloadBytes()
          ? precomputados.tamanhoDownloadBytes.toInt()
          : null;

  /// Converte os metadados de catálogo para a estrutura [ResumoPico] para interoperabilidade.
  ResumoPico paraResumoPico({
    String baseUrl = '',
    bool isDownloaded = false,
  }) {
    final bytes = tamanhoDownloadBytes;
    final String urlCalculada;
    if (baseUrl.isNotEmpty) {
      urlCalculada = '$baseUrl/$caminhoRelativo?v=$checksumSha256Croqui';
    } else {
      urlCalculada = caminhoRelativo;
    }

    final String thumbnailCalculada;
    if (baseUrl.isNotEmpty) {
      thumbnailCalculada = '$baseUrl/thumbnails/$id.webp';
    } else {
      thumbnailCalculada = 'thumbnails/$id.webp';
    }

    return ResumoPico(
      id: id,
      nome: nome,
      local: localizacaoFormatada,
      descricao: descricao,
      url: urlCalculada,
      checksum: checksumSha256Croqui,
      thumbnailUrl: thumbnailCalculada,
      isDownloaded: isDownloaded,
      tamanhoBytes: bytes,
      tamanhoFormatado: FormatadorTamanho.formatarBytes(bytes),
      dataUpdate: hasTimestampUpdate()
          ? timestampUpdate.toDateTime().toIso8601String()
          : null,
      latitude: latitude,
      longitude: longitude,
      estatisticas: hasPrecomputados()
          ? EstatisticasPico(
              totalVias: precomputados.totalEscaladas,
              totalSetores: precomputados.totalSetores,
              totalEsportivas: precomputados.totalEsportivas,
              totalMoveis: precomputados.totalMoveis,
              totalBoulders: precomputados.totalBoulders,
              totalMultiplasEnfiadas: precomputados.totalMultiplasEnfiadas,
              totalHighlines: precomputados.totalHighlines,
              tamanhoDownloadBytes: bytes,
            )
          : null,
    );
  }
}

/// Extensão com métodos utilitários e conversões para a entidade [Croqui].
extension ExtensaoCroqui on Croqui {
  /// Converte a entidade completa [Croqui] para a estrutura [ResumoPico].
  ResumoPico paraResumoPico({String? capaPath}) {
    final primeiroPico = picos.isNotEmpty ? picos.first : null;
    return ResumoPico(
      id: id,
      nome: nome,
      local: primeiroPico?.estado ?? '',
      descricao: descricao,
      isDownloaded: true,
      croqui: this,
      pico: primeiroPico,
      capaPath: capaPath,
      latitude: primeiroPico?.hasLocalizacao() == true
          ? primeiroPico!.localizacao.latitude / 10000000.0
          : null,
      longitude: primeiroPico?.hasLocalizacao() == true
          ? primeiroPico!.localizacao.longitude / 10000000.0
          : null,
      estatisticas: primeiroPico?.hasPrecomputados() == true
          ? EstatisticasPico(
              totalVias: primeiroPico!.precomputados.totalEscaladas,
              totalSetores: primeiroPico.precomputados.totalSetores,
              totalEsportivas: primeiroPico.precomputados.totalEsportivas,
              totalMoveis: primeiroPico.precomputados.totalMoveis,
              totalBoulders: primeiroPico.precomputados.totalBoulders,
              totalMultiplasEnfiadas:
                  primeiroPico.precomputados.totalMultiplasEnfiadas,
              totalHighlines: primeiroPico.precomputados.totalHighlines,
            )
          : null,
    );
  }
}
