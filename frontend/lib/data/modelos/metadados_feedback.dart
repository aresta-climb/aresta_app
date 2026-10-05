// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo define o Modelo de Domínio principal dos metadados de feedback.
/// Contém as propriedades estruturadas e a serialização direta de/para JSON.
library;

import 'tipo_feedback.dart';

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

  /// Categoria do feedback ('croqui' ou 'app').
  final TipoFeedback tipoFeedback;

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

  /// Modo de acesso ao croqui no momento do feedback ('online' ou 'offline').
  final String? modoAcessoCroqui;

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
    this.tipoFeedback = TipoFeedback.aplicativo,
    this.indiceSha256,
    this.croquiId,
    this.croquiSha256Esperado,
    this.croquiSha256Real,
    this.croquiStatus,
    this.thumbnailSha256Esperado,
    this.thumbnailSha256Real,
    this.thumbnailStatus,
    this.modoAcessoCroqui,
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
      tipoFeedback: TipoFeedback.fromString(
        (json['tipo_feedback'] ?? json['tipoFeedback']) as String?,
      ),
      indiceSha256: (json['indice_sha256'] ?? json['indiceSha256']) as String?,
      croquiId: (json['croqui_id'] ?? json['croquiId']) as String?,
      croquiSha256Esperado: (json['croqui_sha256_esperado'] ?? json['croquiSha256Esperado']) as String?,
      croquiSha256Real: (json['croqui_sha256_real'] ?? json['croquiSha256Real']) as String?,
      croquiStatus: (json['croqui_status'] ?? json['croquiStatus']) as String?,
      thumbnailSha256Esperado: (json['thumbnail_sha256_esperado'] ?? json['thumbnailSha256Esperado']) as String?,
      thumbnailSha256Real: (json['thumbnail_sha256_real'] ?? json['thumbnailSha256Real']) as String?,
      thumbnailStatus: (json['thumbnail_status'] ?? json['thumbnailStatus']) as String?,
      modoAcessoCroqui: (json['modo_acesso_croqui'] ?? json['modoAcessoCroqui']) as String?,
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
      'tipo_feedback': tipoFeedback.valor,
      if (indiceSha256 != null) 'indice_sha256': indiceSha256,
      if (croquiId != null) 'croqui_id': croquiId,
      if (croquiSha256Esperado != null) 'croqui_sha256_esperado': croquiSha256Esperado,
      if (croquiSha256Real != null) 'croqui_sha256_real': croquiSha256Real,
      if (croquiStatus != null) 'croqui_status': croquiStatus,
      if (thumbnailSha256Esperado != null) 'thumbnail_sha256_esperado': thumbnailSha256Esperado,
      if (thumbnailSha256Real != null) 'thumbnail_sha256_real': thumbnailSha256Real,
      if (thumbnailStatus != null) 'thumbnail_status': thumbnailStatus,
      if (modoAcessoCroqui != null) 'modo_acesso_croqui': modoAcessoCroqui,
    };
  }

  /// Retorna uma nova instância de [FeedbackMetadata] substituindo os campos especificados.
  FeedbackMetadata copyWith({
    String? navigationTree,
    String? submittedAt,
    String? submittedAtTimestamp,
    String? feedbackId,
    String? appInstanceId,
    String? os,
    String? osVersion,
    String? deviceModel,
    String? appVersion,
    String? screenSize,
    String? deviceOrientation,
    String? isDarkMode,
    String? connectivity,
    TipoFeedback? tipoFeedback,
    String? indiceSha256,
    String? croquiId,
    String? croquiSha256Esperado,
    String? croquiSha256Real,
    String? croquiStatus,
    String? thumbnailSha256Esperado,
    String? thumbnailSha256Real,
    String? thumbnailStatus,
    String? modoAcessoCroqui,
  }) {
    return FeedbackMetadata(
      navigationTree: navigationTree ?? this.navigationTree,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedAtTimestamp: submittedAtTimestamp ?? this.submittedAtTimestamp,
      feedbackId: feedbackId ?? this.feedbackId,
      appInstanceId: appInstanceId ?? this.appInstanceId,
      os: os ?? this.os,
      osVersion: osVersion ?? this.osVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      screenSize: screenSize ?? this.screenSize,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      connectivity: connectivity ?? this.connectivity,
      tipoFeedback: tipoFeedback ?? this.tipoFeedback,
      indiceSha256: indiceSha256 ?? this.indiceSha256,
      croquiId: croquiId ?? this.croquiId,
      croquiSha256Esperado: croquiSha256Esperado ?? this.croquiSha256Esperado,
      croquiSha256Real: croquiSha256Real ?? this.croquiSha256Real,
      croquiStatus: croquiStatus ?? this.croquiStatus,
      thumbnailSha256Esperado: thumbnailSha256Esperado ?? this.thumbnailSha256Esperado,
      thumbnailSha256Real: thumbnailSha256Real ?? this.thumbnailSha256Real,
      thumbnailStatus: thumbnailStatus ?? this.thumbnailStatus,
      modoAcessoCroqui: modoAcessoCroqui ?? this.modoAcessoCroqui,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackMetadata &&
        other.navigationTree == navigationTree &&
        other.submittedAt == submittedAt &&
        other.submittedAtTimestamp == submittedAtTimestamp &&
        other.feedbackId == feedbackId &&
        other.appInstanceId == appInstanceId &&
        other.os == os &&
        other.osVersion == osVersion &&
        other.deviceModel == deviceModel &&
        other.appVersion == appVersion &&
        other.screenSize == screenSize &&
        other.deviceOrientation == deviceOrientation &&
        other.isDarkMode == isDarkMode &&
        other.connectivity == connectivity &&
        other.tipoFeedback == tipoFeedback &&
        other.indiceSha256 == indiceSha256 &&
        other.croquiId == croquiId &&
        other.croquiSha256Esperado == croquiSha256Esperado &&
        other.croquiSha256Real == croquiSha256Real &&
        other.croquiStatus == croquiStatus &&
        other.thumbnailSha256Esperado == thumbnailSha256Esperado &&
        other.thumbnailSha256Real == thumbnailSha256Real &&
        other.thumbnailStatus == thumbnailStatus &&
        other.modoAcessoCroqui == modoAcessoCroqui;
  }

  @override
  int get hashCode => Object.hashAll([
        navigationTree,
        submittedAt,
        submittedAtTimestamp,
        feedbackId,
        appInstanceId,
        os,
        osVersion,
        deviceModel,
        appVersion,
        screenSize,
        deviceOrientation,
        isDarkMode,
        connectivity,
        tipoFeedback,
        indiceSha256,
        croquiId,
        croquiSha256Esperado,
        croquiSha256Real,
        croquiStatus,
        thumbnailSha256Esperado,
        thumbnailSha256Real,
        thumbnailStatus,
        modoAcessoCroqui,
      ]);
}
