// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/dtos/feedback_metadata_dto.dart';
import 'package:frontend/data/models/feedback_metadata.dart';

void main() {
  group('FeedbackMetadataDto', () {
    test('toJson converte FeedbackMetadata para Map corretamente', () {
      final metadata = FeedbackMetadata(
        navigationTree: 'Home -> Settings',
        submittedAt: '16 de junho de 2026 às 09:00:00 (GMT-3)',
        submittedAtTimestamp: '2026-06-16T09:00:00.000-03:00',
        feedbackId: 'test-uuid',
        appInstanceId: 'instance-123',
        os: 'android',
        osVersion: '13',
        deviceModel: 'Samsung SM-G991B',
        appVersion: '1.2.3',
        screenSize: '1080x1920',
        deviceOrientation: 'portrait',
        isDarkMode: 'true',
        connectivity: 'wifi',
        indiceSha256: 'hash_indice_123',
        croquiId: 'pico_pedra_grande',
        croquiSha256Esperado: 'hash_esperado_456',
        croquiSha256Real: 'hash_real_456',
        croquiStatus: 'INTEGRO',
        thumbnailSha256Esperado: 'hash_thumb_exp_789',
        thumbnailSha256Real: 'hash_thumb_real_789',
        thumbnailStatus: 'INTEGRO',
      );

      final json = FeedbackMetadataDto.toJson(metadata);

      expect(json['navigationTree'], 'Home -> Settings');
      expect(json['submittedAt'], '16 de junho de 2026 às 09:00:00 (GMT-3)');
      expect(json['submittedAtTimestamp'], '2026-06-16T09:00:00.000-03:00');
      expect(json['feedbackId'], 'test-uuid');
      expect(json['appInstanceId'], 'instance-123');
      expect(json['os'], 'android');
      expect(json['osVersion'], '13');
      expect(json['deviceModel'], 'Samsung SM-G991B');
      expect(json['appVersion'], '1.2.3');
      expect(json['screenSize'], '1080x1920');
      expect(json['deviceOrientation'], 'portrait');
      expect(json['isDarkMode'], 'true');
      expect(json['connectivity'], 'wifi');
      expect(json['indice_sha256'], 'hash_indice_123');
      expect(json['croqui_id'], 'pico_pedra_grande');
      expect(json['croqui_sha256_esperado'], 'hash_esperado_456');
      expect(json['croqui_sha256_real'], 'hash_real_456');
      expect(json['croqui_status'], 'INTEGRO');
      expect(json['thumbnail_sha256_esperado'], 'hash_thumb_exp_789');
      expect(json['thumbnail_sha256_real'], 'hash_thumb_real_789');
      expect(json['thumbnail_status'], 'INTEGRO');
    });

    test('fromJson converte Map para FeedbackMetadata corretamente', () {
      final json = {
        'navigationTree': 'Home -> Settings',
        'submittedAt': '16 de junho de 2026 às 09:00:00 (GMT-3)',
        'submittedAtTimestamp': '2026-06-16T09:00:00.000-03:00',
        'feedbackId': 'test-uuid',
        'appInstanceId': 'instance-123',
        'os': 'android',
        'osVersion': '13',
        'deviceModel': 'Samsung SM-G991B',
        'appVersion': '1.2.3',
        'screenSize': '1080x1920',
        'deviceOrientation': 'portrait',
        'isDarkMode': 'true',
        'connectivity': 'wifi',
        'indice_sha256': 'hash_indice_123',
        'croqui_id': 'pico_pedra_grande',
        'croqui_sha256_esperado': 'hash_esperado_456',
        'croqui_sha256_real': 'hash_real_456',
        'croqui_status': 'INTEGRO',
        'thumbnail_sha256_esperado': 'hash_thumb_exp_789',
        'thumbnail_sha256_real': 'hash_thumb_real_789',
        'thumbnail_status': 'INTEGRO',
      };

      final metadata = FeedbackMetadataDto.fromJson(json);

      expect(metadata.navigationTree, 'Home -> Settings');
      expect(metadata.submittedAt, '16 de junho de 2026 às 09:00:00 (GMT-3)');
      expect(metadata.submittedAtTimestamp, '2026-06-16T09:00:00.000-03:00');
      expect(metadata.feedbackId, 'test-uuid');
      expect(metadata.appInstanceId, 'instance-123');
      expect(metadata.os, 'android');
      expect(metadata.osVersion, '13');
      expect(metadata.deviceModel, 'Samsung SM-G991B');
      expect(metadata.appVersion, '1.2.3');
      expect(metadata.screenSize, '1080x1920');
      expect(metadata.deviceOrientation, 'portrait');
      expect(metadata.isDarkMode, 'true');
      expect(metadata.connectivity, 'wifi');
      expect(metadata.indiceSha256, 'hash_indice_123');
      expect(metadata.croquiId, 'pico_pedra_grande');
      expect(metadata.croquiSha256Esperado, 'hash_esperado_456');
      expect(metadata.croquiSha256Real, 'hash_real_456');
      expect(metadata.croquiStatus, 'INTEGRO');
      expect(metadata.thumbnailSha256Esperado, 'hash_thumb_exp_789');
      expect(metadata.thumbnailSha256Real, 'hash_thumb_real_789');
      expect(metadata.thumbnailStatus, 'INTEGRO');
    });

    test('fromJson utiliza valores default para chaves ausentes', () {
      final json = <String, dynamic>{};

      final metadata = FeedbackMetadataDto.fromJson(json);

      expect(metadata.navigationTree, 'unknown');
      expect(metadata.submittedAt, 'unknown');
      expect(metadata.submittedAtTimestamp, 'unknown');
      expect(metadata.feedbackId, 'unknown');
      expect(metadata.appInstanceId, 'unknown');
      expect(metadata.os, 'unknown');
      expect(metadata.osVersion, 'unknown');
      expect(metadata.deviceModel, 'unknown');
      expect(metadata.appVersion, 'unknown');
      expect(metadata.screenSize, 'unknown');
      expect(metadata.deviceOrientation, 'unknown');
      expect(metadata.isDarkMode, 'unknown');
      expect(metadata.connectivity, 'unknown');
    });
  });
}
