// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';

/// Data Transfer Object (DTO) imutável para exibição de cards de croquis na interface (Dumb UI).
///
/// Contém exclusivamente dados primitivos já formatados para consumo por widgets de apresentação,
/// desacoplando a interface de entidades do Protobuf e de lógicas de formatação de strings.
class CardCroquiDTO {
  /// Identificador único do pico/croqui.
  final String id;

  /// Título formatado em caixa alta para exibição.
  final String titulo;

  /// Nome legível da localização (ex: 'SERRA DO CIPÓ').
  final String localizacao;

  /// Resumo textual de setores e modalidades de escalada já formatado.
  final String textoEstatisticas;

  /// Caminho relativo da miniatura visual no armazenamento local ou CDN.
  final String caminhoMiniatura;

  /// Indica se os dados do croqui já foram baixados para acesso offline.
  final bool salvoOffline;

  /// Texto formatado de distância relativa do usuário (ex: '350m' ou '12.4km'), se disponível.
  final String? textoDistancia;

