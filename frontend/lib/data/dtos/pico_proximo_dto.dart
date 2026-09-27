// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import 'card_croqui_dto.dart';

/// DTO imutável que representa um pico próximo ao usuário para exibição em carrosséis ou listas (Dumb UI).
///
/// Encapsula dados primitivos prontos para apresentação na UI, como distância calculada e formatada,
/// desacoplando widgets visuais dos cálculos geodésicos e esquemas do Protobuf.
class PicoProximoDTO {
  /// Identificador único do pico.
  final String id;

  /// Nome amigável do pico de escalada.
  final String nome;

  /// Nome formatado da localização geográfica ou estado.
  final String localizacao;

  /// Distância em quilômetros em relação ao usuário, se calculada.
  final double? distanciaKm;

  /// Caminho relativo ou URL da miniatura.
  final String caminhoMiniatura;

  /// Indica se os dados do croqui já se encontram armazenados localmente.
  final bool estaBaixado;

  /// Total pré-computado de setores.
  final int totalSetores;

  /// Total pré-computado de vias/escaladas.
