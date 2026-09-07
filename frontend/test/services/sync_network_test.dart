// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/http/sync_network.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../mocks/mock_app_logger.dart';

void main() {
  late MockAppLogger mockLogger;

  setUp(() {
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
  });

  group('SyncNetwork', () {
    test(
      'fetchIndiceWithRetries retorna IndiceUpdated na primeira tentativa (200)',
      () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), 'https://base.com/indice.binarypb');
          expect(request.headers['If-None-Match'], 'etag_123');
          // Uint8List(0) parses successfully into an empty Indice
          return http.Response.bytes(
            Uint8List(0),
            200,
            headers: {'etag': 'new_etag_321'},
          );
        });

        final network = SyncNetwork(client);
        final response = await network.fetchIndiceWithRetries(
          'https://base.com',
          'etag_123',
        );

        expect(response, isA<IndiceUpdated>());
        final updated = response as IndiceUpdated;
        expect(updated.newEtag, 'new_etag_321');
        expect(updated.rawBytes.isEmpty, true);
      },
    );

    test(
      'fetchIndiceWithRetries adiciona parametro ?t= quando forceBypassCache é true',
      () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), contains('?t='));
          return http.Response.bytes(
            Uint8List(0),
            200,
            headers: {'etag': 'new_etag_321'},
          );
        });

        final network = SyncNetwork(client);
        final response = await network.fetchIndiceWithRetries(
          'https://base.com',
          'etag_123',
          forceBypassCache: true,
        );

        expect(response, isA<IndiceUpdated>());
      },
    );

    test('fetchIndiceWithRetries retorna IndiceUnchanged (304)', () async {
      final client = MockClient((request) async {
        return http.Response('', 304);
      });

      final network = SyncNetwork(client);
      final response = await network.fetchIndiceWithRetries(
        'https://base.com',
        'etag_123',
      );

      expect(response, isA<IndiceUnchanged>());
    });

    test(
      'fetchIndiceWithRetries tenta novamente apos falha de rede transitória registrando logAviso e retorna sucesso',
      () async {
        int attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            throw const SocketException('Connection failed');
          }
          return http.Response.bytes(Uint8List(0), 200);
        });

        final network = SyncNetwork(client);
        final response = await network.fetchIndiceWithRetries(
          'https://base.com',
          null,
          retries: 2,
        );

        expect(response, isA<IndiceUpdated>());
        expect(attempts, 2);
        expect(mockLogger.recordedWarnings, isNotEmpty);
        expect(mockLogger.recordedWarnings.first, contains('Falha transitória na tentativa de fetch'));
        expect(mockLogger.recordedErrors, isEmpty);
      },
    );

    test(
      'fetchIndiceWithRetries retorna null apos falhar todas as tentativas e registra logAviso',
      () async {
        int attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          throw const SocketException('Always fails');
        });

        final network = SyncNetwork(client);
        final response = await network.fetchIndiceWithRetries(
          'https://base.com',
          null,
          retries: 2,
        );

        expect(response, isNull);
        expect(attempts, 2);
        expect(mockLogger.recordedErrors, isEmpty);
        expect(mockLogger.recordedWarnings.any((w) => w.contains('Falha de conexão após várias tentativas')), isTrue);
      },
    );

    test(
      'fetchIndiceWithRetries com binário corrompido registra logError com stackTrace',
      () async {
        final client = MockClient((request) async {
          // Bytes inválidos que falham ao parsear Indice
          return http.Response.bytes(Uint8List.fromList([0xFF, 0xFF, 0xFF]), 200);
        });

        final network = SyncNetwork(client);
        final response = await network.fetchIndiceWithRetries(
          'https://base.com',
          null,
        );

        expect(response, isNull);
        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(mockLogger.recordedErrors.first['contextMessage'], contains('Falha ao parsear binário do índice'));
        expect(mockLogger.recordedErrors.first['stackTrace'], isNotNull);
      },
    );

    test(
      'downloadFile retorna Uint8List do GET na primeira tentativa',
      () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), 'https://file.com/image.png');
          return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
        });

        final network = SyncNetwork(client);
        final bytes = await network.downloadFile('https://file.com/image.png');

        expect(bytes, isNotNull);
        expect(bytes, [1, 2, 3]);
      },
    );

    test('downloadFile retorna null em caso de erro', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final network = SyncNetwork(client);
      final bytes = await network.downloadFile('https://file.com/image.png');

      expect(bytes, isNull);
    });
  });
}
