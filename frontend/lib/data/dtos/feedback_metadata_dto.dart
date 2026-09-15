// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo atua como o serializador (DTO) dos metadados de feedback.
/// Ele é responsável por converter a classe pura FeedbackMetadata de e para JSON.
library;

import '../../data/models/feedback_metadata.dart';

class FeedbackMetadataDto {
  static FeedbackMetadata fromJson(Map<String, dynamic> json) {
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

  static Map<String, dynamic> toJson(FeedbackMetadata metadata) {
    return {
      'navigationTree': metadata.navigationTree,
      'submittedAt': metadata.submittedAt,
      'submittedAtTimestamp': metadata.submittedAtTimestamp,
      'feedbackId': metadata.feedbackId,
      'appInstanceId': metadata.appInstanceId,
      'os': metadata.os,
      'osVersion': metadata.osVersion,
      'deviceModel': metadata.deviceModel,
      'appVersion': metadata.appVersion,
      'screenSize': metadata.screenSize,
      'deviceOrientation': metadata.deviceOrientation,
      'isDarkMode': metadata.isDarkMode,
      'connectivity': metadata.connectivity,
      if (metadata.indiceSha256 != null) 'indice_sha256': metadata.indiceSha256,
      if (metadata.croquiId != null) 'croqui_id': metadata.croquiId,
      if (metadata.croquiSha256Esperado != null) 'croqui_sha256_esperado': metadata.croquiSha256Esperado,
      if (metadata.croquiSha256Real != null) 'croqui_sha256_real': metadata.croquiSha256Real,
      if (metadata.croquiStatus != null) 'croqui_status': metadata.croquiStatus,
      if (metadata.thumbnailSha256Esperado != null) 'thumbnail_sha256_esperado': metadata.thumbnailSha256Esperado,
      if (metadata.thumbnailSha256Real != null) 'thumbnail_sha256_real': metadata.thumbnailSha256Real,
      if (metadata.thumbnailStatus != null) 'thumbnail_status': metadata.thumbnailStatus,
    };
  }
}
