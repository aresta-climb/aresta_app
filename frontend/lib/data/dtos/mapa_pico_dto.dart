// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';

/// DTO imutável que representa um pico para exibição geográfica no mapa global (Dumb UI).
///
/// Encapsula coordenadas decimais, estatísticas e status de download para que os widgets de mapa
/// não dependam de mensagens do Protobuf nem de regras de conversão de micrograus.
class MapaPicoDTO {
  /// Identificador único do pico.
  final String id;

  /// Nome legível do pico.
  final String nome;

  /// Latitude em graus decimais.
  final double? latitude;

  /// Longitude em graus decimais.
  final double? longitude;

  /// Indica se os dados do croqui já estão baixados localmente.
  final bool estaBaixado;

  /// Total de setores catalogados.
  final int totalSetores;

  /// Total de vias/escaladas catalogadas.
  final int totalEscaladas;

  /// Caminho relativo da miniatura.
  final String caminhoMiniatura;

  /// Nome formatado da localização geográfica.
  final String localizacao;

  /// Descrição resumida do local.
  final String descricao;

  /// URL de download remoto do arquivo binário.
  final String urlDownload;

  /// Checksum SHA-256 do arquivo binário.
  final String checksumSha256;

  const MapaPicoDTO({
    required this.id,
    required this.nome,
    this.latitude,
    this.longitude,
    this.estaBaixado = false,
    this.totalSetores = 0,
    this.totalEscaladas = 0,
    this.caminhoMiniatura = '',
    this.localizacao = '',
    this.descricao = '',
    this.urlDownload = '',
    this.checksumSha256 = '',
  });

  /// Indica se o pico possui coordenadas geográficas válidas para plotagem de marcador no mapa.
  bool get temCoordenadasValidas =>
      latitude != null &&
      longitude != null &&
      (latitude! != 0.0 || longitude! != 0.0);

  /// Constrói um [MapaPicoDTO] a partir de uma entidade [ResumoCroqui] (Protobuf).
  factory MapaPicoDTO.deMetadados({
    required ResumoCroqui metadados,
    bool estaBaixado = false,
    String baseUrl = '',
  }) {
    final lat = metadados.hasLocalizacao()
        ? metadados.localizacao.latitude / 10000000.0
        : null;
    final lon = metadados.hasLocalizacao()
        ? metadados.localizacao.longitude / 10000000.0
        : null;

    final int setores =
        metadados.hasPrecomputados() ? metadados.precomputados.totalSetores : 0;
    final int escaladas =
        metadados.hasPrecomputados() ? metadados.precomputados.totalEscaladas : 0;

    final String url = baseUrl.isNotEmpty
        ? '$baseUrl/${metadados.caminhoRelativo}?v=${metadados.checksumSha256Croqui}'
        : metadados.caminhoRelativo;

    return MapaPicoDTO(
      id: metadados.id,
      nome: metadados.nome.isEmpty ? 'Pico' : metadados.nome,
      latitude: lat,
      longitude: lon,
      estaBaixado: estaBaixado,
      totalSetores: setores,
      totalEscaladas: escaladas,
      caminhoMiniatura: 'thumbnails/${metadados.id}.webp',
      localizacao: metadados.localizacaoFormatada,
      descricao: metadados.descricao,
      urlDownload: url,
      checksumSha256: metadados.checksumSha256Croqui,
    );
  }

  /// Constrói um [MapaPicoDTO] a partir de um mapa de dados legados ou mocks.
  factory MapaPicoDTO.deMapa(
    Map<String, dynamic> mapa, {
    bool estaBaixado = false,
  }) {
    return MapaPicoDTO(
      id: mapa['id']?.toString() ?? '',
      nome: mapa['nome']?.toString() ?? 'Pico',
      latitude: (mapa['latitude'] as num?)?.toDouble(),
      longitude: (mapa['longitude'] as num?)?.toDouble(),
      estaBaixado: estaBaixado || (mapa['isDownloaded'] == true),
      localizacao: mapa['local']?.toString() ?? '',
      caminhoMiniatura: mapa['thumbnailUrl']?.toString() ?? '',
    );
  }
}
