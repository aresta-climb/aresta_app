/// Este arquivo atua como o serializador (DTO) dos metadados de feedback.
/// Ele é responsável por converter a classe pura FeedbackMetadata de e para JSON.

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
    };
  }
}
