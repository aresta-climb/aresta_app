// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/application_managers/feedback/orquestrador_feedback.dart';
import 'package:frontend/services/autenticacao/autenticador_nativo.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/smoke_ci/configuracao_smoke_ci.dart';
import 'package:frontend/services/smoke_ci/main_smoke_ci.dart' as smoke_entry;
import '../../mocks/mock_geolocator_platform.dart';
import '../../../tool/release_tools/servidor_smoke_ci.dart';

class _PathProviderTemp extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _PathProviderTemp(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;

  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late Directory tempDir;

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FeedbackOrchestrator.debugIsConfiguredOverride = false;
    AutenticadorNativoCanal.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
    RepositorioInteracoesViaMemoria.redefinirParaTestes();
    tempDir = Directory.systemTemp.createTempSync('main_smoke_ci_aresta_');
    PathProviderPlatform.instance = _PathProviderTemp(tempDir.path);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ConfiguracaoSmokeCi.nomeCanalPadrao),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(AutenticadorNativoCanal.nomeCanal),
          null,
        );
    SyncService.baseUrlOverride = null;
    FeedbackOrchestrator.debugIsConfiguredOverride = null;
    AutenticadorNativoCanal.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
    RepositorioInteracoesViaMemoria.redefinirParaTestes();
    RepositorioCadernetaLocal.instancia = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets(
    'main() monta a árvore do app e conclui o envio do relatório de smoke via canal nativo',
    (WidgetTester tester) async {
      HttpOverrides.global = null;
      tester.view.physicalSize = const Size(1236, 2745);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok_main_1');
        try {
          const canalSmoke = MethodChannel(ConfiguracaoSmokeCi.nomeCanalPadrao);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(canalSmoke, (MethodCall call) async {
            return <String, dynamic>{
              'ativo': true,
              'servidorUrl': servidor.uriLocalHost.toString(),
              'token': 'tok_main_1',
            };
          });

          const canalAuth = MethodChannel(AutenticadorNativoCanal.nomeCanal);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(canalAuth, (MethodCall call) async {
            final client = HttpClient();
            final req = await client.postUrl(
              servidor.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
            );
            req.headers.contentType = ContentType.json;
            req.write(jsonEncode(<String, dynamic>{
              'rawNonce': 'nonce_main_smoke',
              'webClientId': 'smoke-web-client',
            }));
            final resp = await req.close();
            final mapa = jsonDecode(
              await utf8.decoder.bind(resp).join(),
            ) as Map<String, dynamic>;
            client.close(force: true);
            return mapa;
          });

          final futuroRelatorio = servidor.aguardarRelatorio();
          smoke_entry.main();
          final relatorio = await futuroRelatorio;
          expect(relatorio['sucesso'], isTrue);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        } finally {
          await servidor.encerrar();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
