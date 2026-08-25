// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/feedback_network_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
  });

  group('FeedbackNetworkService', () {
    late MockHttpClient mockHttpClient;
    late FeedbackNetworkService service;
    late Directory tempDir;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      tempDir = await Directory.systemTemp.createTemp('network_service_test');
      service = FeedbackNetworkService(
        httpClient: mockHttpClient,
        edgeFunctionUrl: 'https://test-supabase.supabase.co/functions/v1/app-feedback',
        appCheckToken: 'fake-app-check-jwt',
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('sendFeedback anexa cabeçalho X-Firebase-AppCheck e envia payload multipart com sucesso', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"success":true}')),
          200,
        ),
      );

      final screenshotFile = File('${tempDir.path}/screenshot.png');
      await screenshotFile.writeAsBytes([1, 2, 3]);

      await service.sendFeedback(
        description: 'Bug no mapa',
        metadata: {'os': 'android', 'feedbackId': 'uuid-123'},
        dispatcher: 'connectivity_plus',
        pngFile: screenshotFile,
      );

      final captured = verify(() => mockHttpClient.send(captureAny())).captured;
      expect(captured.length, 1);

      final request = captured.first as http.MultipartRequest;
      expect(request.url.toString(), 'https://test-supabase.supabase.co/functions/v1/app-feedback');
      expect(request.method, 'POST');
      expect(request.headers['X-Firebase-AppCheck'], 'fake-app-check-jwt');
      expect(request.headers.containsKey('x-api-key'), isFalse);
      expect(request.fields['description'], 'Bug no mapa');

      final metadata = jsonDecode(request.fields['metadata']!);
      expect(metadata['dispatcher'], 'connectivity_plus');
      expect(metadata['feedbackId'], 'uuid-123');
      expect(metadata['os'], 'android');

      expect(request.files.length, 1);
      expect(request.files.first.field, 'screenshot');
    });

    test('sendFeedback funciona corretamente sem token do App Check quando for nulo', () async {
      final serviceWithoutToken = FeedbackNetworkService(
        httpClient: mockHttpClient,
        edgeFunctionUrl: 'https://test-supabase.supabase.co/functions/v1/app-feedback',
        appCheckToken: null,
      );

      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"success":true}')),
          200,
        ),
      );

      await serviceWithoutToken.sendFeedback(
        description: 'Feedback sem token',
        metadata: {'feedbackId': 'uuid-456'},
        dispatcher: 'manual',
      );

      final captured = verify(() => mockHttpClient.send(captureAny())).captured;
      final request = captured.first as http.MultipartRequest;
      expect(request.headers.containsKey('X-Firebase-AppCheck'), isFalse);
    });

    test('sendFeedback lança exceção quando status for 403 Forbidden', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"error":"Acesso negado: Token inválido"}')),
          403,
        ),
      );

      expect(
        () => service.sendFeedback(
          description: 'Erro 403',
          metadata: {'feedbackId': 'uuid-403'},
          dispatcher: 'work_manager',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendFeedback lança exceção quando status for 429 Too Many Requests', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"error":"Muitas requisições"}')),
          429,
        ),
      );

      expect(
        () => service.sendFeedback(
          description: 'Erro 429',
          metadata: {'feedbackId': 'uuid-429'},
          dispatcher: 'work_manager',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendFeedback lança exceção quando status for 500/503 Erro do Servidor', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"error":"Servidor fora"}')),
          503,
        ),
      );

      expect(
        () => service.sendFeedback(
          description: 'Erro 503',
          metadata: {'feedbackId': 'uuid-503'},
          dispatcher: 'work_manager',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
