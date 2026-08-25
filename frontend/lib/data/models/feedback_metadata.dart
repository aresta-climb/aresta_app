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
  });
}
