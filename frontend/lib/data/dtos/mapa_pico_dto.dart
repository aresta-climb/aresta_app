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
