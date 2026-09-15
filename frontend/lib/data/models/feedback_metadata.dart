// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo define o Modelo de Domínio (Blueprint) principal dos metadados de feedback.
/// Contém apenas as propriedades puras, sem lógica de formatação JSON (que fica no DTO).
library;

class FeedbackMetadata {
  final String navigationTree;
  final String submittedAt;
  final String submittedAtTimestamp;
  final String feedbackId;
  final String appInstanceId;
  final String os;
  final String osVersion;
  final String deviceModel;
  final String appVersion;
  final String screenSize;
  final String deviceOrientation;
  final String isDarkMode;
  final String connectivity;

  /// Checksum SHA-256 do arquivo `indice.binarypb` local.
  final String? indiceSha256;

  /// Identificador do croqui/pico ativo em visualização no momento do feedback.
  final String? croquiId;

  /// Checksum SHA-256 esperado do croqui conforme informado no índice mestre.
  final String? croquiSha256Esperado;

  /// Checksum SHA-256 real calculado a partir do binário local do croqui.
  final String? croquiSha256Real;

  /// Status de integridade do croqui ('INTEGRO', 'DIVERGENTE' ou 'NAO_BAIXADO').
  final String? croquiStatus;

  /// Checksum SHA-256 esperado da thumbnail conforme informado no índice mestre.
  final String? thumbnailSha256Esperado;

  /// Checksum SHA-256 real calculado a partir do arquivo de thumbnail local.
  final String? thumbnailSha256Real;

  /// Status de integridade da thumbnail ('INTEGRO', 'DIVERGENTE' ou 'NAO_BAIXADO').
  final String? thumbnailStatus;

  const FeedbackMetadata({
    required this.navigationTree,
    required this.submittedAt,
    required this.submittedAtTimestamp,
    required this.feedbackId,
    required this.appInstanceId,
    required this.os,
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
    required this.screenSize,
    required this.deviceOrientation,
    required this.isDarkMode,
    required this.connectivity,
    this.indiceSha256,
    this.croquiId,
    this.croquiSha256Esperado,
    this.croquiSha256Real,
    this.croquiStatus,
    this.thumbnailSha256Esperado,
    this.thumbnailSha256Real,
    this.thumbnailStatus,
  });
}
