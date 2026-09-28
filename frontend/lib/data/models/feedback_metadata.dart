// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo define o Modelo de Domínio principal dos metadados de feedback.
/// Contém as propriedades estruturadas e a serialização direta de/para JSON.
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

  /// Reconstrói uma instância de [FeedbackMetadata] a partir do mapa [json].
  factory FeedbackMetadata.fromJson(Map<String, dynamic> json) {
    return FeedbackMetadata(
      navigationTree: json['navigationTree'] as String? ?? 'unknown',
      submittedAt: json['submittedAt'] as String? ?? 'unknown',
      submittedAtTimestamp: json['submittedAtTimestamp'] as String? ?? 'unknown',
      feedbackId: json['feedbackId'] as String? ?? 'unknown',
      appInstanceId: json['appInstanceId'] as String? ?? 'unknown',
      os: json['os'] as String? ?? 'unknown',
      osVersion: json['osVersion'] as String? ?? 'unknown',
      deviceModel: json['deviceModel'] as String? ?? 'unknown',
      appVersion: json['appVersion'] as String? ?? 'unknown',
      screenSize: json['screenSize'] as String? ?? 'unknown',
      deviceOrientation: json['deviceOrientation'] as String? ?? 'unknown',
      isDarkMode: json['isDarkMode'] as String? ?? 'unknown',
      connectivity: json['connectivity'] as String? ?? 'unknown',
      indiceSha256: (json['indice_sha256'] ?? json['indiceSha256']) as String?,
      croquiId: (json['croqui_id'] ?? json['croquiId']) as String?,
      croquiSha256Esperado: (json['croqui_sha256_esperado'] ?? json['croquiSha256Esperado']) as String?,
      croquiSha256Real: (json['croqui_sha256_real'] ?? json['croquiSha256Real']) as String?,
      croquiStatus: (json['croqui_status'] ?? json['croquiStatus']) as String?,
      thumbnailSha256Esperado: (json['thumbnail_sha256_esperado'] ?? json['thumbnailSha256Esperado']) as String?,
      thumbnailSha256Real: (json['thumbnail_sha256_real'] ?? json['thumbnailSha256Real']) as String?,
      thumbnailStatus: (json['thumbnail_status'] ?? json['thumbnailStatus']) as String?,
    );
  }

  /// Converte a instância de [FeedbackMetadata] em mapa serializável para JSON.
  Map<String, dynamic> toJson() {
    return {
      'navigationTree': navigationTree,
      'submittedAt': submittedAt,
      'submittedAtTimestamp': submittedAtTimestamp,
      'feedbackId': feedbackId,
      'appInstanceId': appInstanceId,
      'os': os,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'appVersion': appVersion,
      'screenSize': screenSize,
      'deviceOrientation': deviceOrientation,
      'isDarkMode': isDarkMode,
      'connectivity': connectivity,
      if (indiceSha256 != null) 'indice_sha256': indiceSha256,
      if (croquiId != null) 'croqui_id': croquiId,
      if (croquiSha256Esperado != null) 'croqui_sha256_esperado': croquiSha256Esperado,
      if (croquiSha256Real != null) 'croqui_sha256_real': croquiSha256Real,
      if (croquiStatus != null) 'croqui_status': croquiStatus,
      if (thumbnailSha256Esperado != null) 'thumbnail_sha256_esperado': thumbnailSha256Esperado,
      if (thumbnailSha256Real != null) 'thumbnail_sha256_real': thumbnailSha256Real,
      if (thumbnailStatus != null) 'thumbnail_status': thumbnailStatus,
    };
  }
}
