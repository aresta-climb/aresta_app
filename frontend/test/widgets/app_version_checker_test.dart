// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_version_checker.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeRemoteConfigService extends ChangeNotifier implements RemoteConfigService {
  int _hard = 0;
  int _soft = 0;
  int _rec = 0;

  @override
  int get hardMinVersion => _hard;
  @override
  int get softMinVersion => _soft;
  @override
  int get recommendedVersion => _rec;

  void updateVersions({int? hard, int? soft, int? recommended}) {
    if (hard != null) _hard = hard;
    if (soft != null) _soft = soft;
    if (recommended != null) _rec = recommended;
    notifyListeners();
  }

  @override
  int getInt(String key) => 0;
  @override
  bool getBool(String key) => false;
  @override
  String getString(String key) => "";

  String _iosUrl = "";
  @override
  String get storeUrlIos => _iosUrl;
  @override
  String get feedbackEdgeFunctionUrl => "";
  @override
  String get whatsappCommunityUrl => "";
  @override
  String get discordCommunityUrl => "";
  @override
  String get servingBaseUrl => "";
  @override
  String get officialServerUrl => "";

  Completer<void>? initCompleter;

  @override
  Future<void> initialize() async {
    if (initCompleter != null) {
      await initCompleter!.future;
    }
  }

  @override
  FirebaseRemoteConfig? debugRemoteConfig;

  @override
  void clearInitFuture() {}
}

void main() {
  group('AppVersionChecker Widget Tests', () {
    late FakeRemoteConfigService fakeConfig;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'Aresta',
        packageName: 'com.aresta.climb',
        version: '1.0.0',
        buildNumber: '10', // Versão atual: 10
        buildSignature: '',
      );
      fakeConfig = FakeRemoteConfigService();
      TelemetryService.instance = MockTelemetryService();
    });

    testWidgets('Deve exibir o filho imediatamente no primeiro frame sem tela preta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppVersionChecker(
            remoteConfigService: fakeConfig,
            child: const Text('App Normal'),
          ),
        ),
      );

      // No PRIMEIRO frame (sem pumpAndSettle / sem aguardar futures de rede), a tela deve renderizar o filho
      expect(find.text('App Normal'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == Colors.black,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'Deve manter a UI visível mesmo se a inicialização do Remote Config demorar (simulação de rede lenta)',
      (WidgetTester tester) async {
        // Simula um future de rede travado/pendurado no Remote Config
        final completer = Completer<void>();
        fakeConfig.initCompleter = completer;

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Offline Funcional'),
            ),
          ),
        );

        // A interface deve estar imediatamente visível e utilizável
        expect(find.text('App Offline Funcional'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == Colors.black,
          ),
          findsNothing,
        );

        // Agora a resposta da rede finalmente chega
        completer.complete();
        await tester.pump();

        expect(find.text('App Offline Funcional'), findsOneWidget);
      },
    );

    testWidgets(
      'Deve atualizar a UI de forma reativa quando o Remote Config notificar uma nova versão mínima em segundo plano',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('App Normal'), findsOneWidget);
        expect(find.text('ATUALIZAÇÃO\nNECESSÁRIA'), findsNothing);

        // Simula a chegada assíncrona de uma versão de bloqueio vinda do Remote Config em background
        fakeConfig.updateVersions(hard: 15);
        await tester.pump();

        // A tela de bloqueio deve surgir reativamente sem reiniciar o app
        expect(find.text('App Normal'), findsNothing);
        expect(find.text('ATUALIZAÇÃO\nNECESSÁRIA'), findsOneWidget);
      },
    );

    testWidgets(
      'didUpdateWidget deve trocar de instância do RemoteConfigService e atualizar listeners',
      (WidgetTester tester) async {
        final configA = FakeRemoteConfigService();
        final configB = FakeRemoteConfigService();

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: configA,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('App Normal'), findsOneWidget);

        // Troca para configB
        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: configB,
              child: const Text('App Normal'),
            ),
          ),
        );
        await tester.pump();

        // configB dispara nova versão hard
        configB.updateVersions(hard: 20);
        await tester.pump();

        expect(find.text('ATUALIZAÇÃO\nNECESSÁRIA'), findsOneWidget);
      },
    );

    testWidgets('Deve exibir o filho quando não houver problemas de versão', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppVersionChecker(
            remoteConfigService: fakeConfig,
            child: const Text('App Normal'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('App Normal'), findsOneWidget);
      expect(
        find.text('Atualização Recomendada: uma nova versão está disponível.'),
        findsNothing,
      );
      expect(find.text('Atualização Necessária'), findsNothing);
    });

    testWidgets(
      'Deve exibir erro crítico quando hardMinVersion for maior que buildNumber e disparar clique no botão',
      (WidgetTester tester) async {
        fakeConfig._hard = 11;

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('App Normal'), findsNothing);
        expect(find.text('ATUALIZAÇÃO\nNECESSÁRIA'), findsOneWidget);

        final mockTelemetry = TelemetryService.instance as MockTelemetryService;
        expect(mockTelemetry.recordedEvents.contains('migracao_db'), isTrue);
        expect(
          mockTelemetry.recordedParams['migracao_db']?['acao'],
          'tela_hard_block_mostrada',
        );

        // Clica no botão de atualizar da tela crítica
        await tester.tap(find.widgetWithText(FilledButton, 'ATUALIZAR AGORA'));
        await tester.pump();
      },
    );

    testWidgets(
      'Deve exibir banner soft quando softMinVersion for maior que buildNumber e disparar clique no botão',
      (WidgetTester tester) async {
        fakeConfig._soft = 11;

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('App Normal'), findsOneWidget);
        expect(
          find.text(
            'Atualize o Aresta para voltar a baixar e sincronizar croquis.',
          ),
          findsOneWidget,
        );

        final mockTelemetry = TelemetryService.instance as MockTelemetryService;
        expect(mockTelemetry.recordedEvents.contains('migracao_db'), isTrue);
        expect(
          mockTelemetry.recordedParams['migracao_db']?['acao'],
          'banner_soft_block_mostrado',
        );

        // Clica no botão ATUALIZAR do banner
        await tester.tap(find.widgetWithText(TextButton, 'ATUALIZAR'));
        await tester.pump();
      },
    );

    testWidgets(
      'Deve exibir banner recommended quando recommendedVersion for maior',
      (WidgetTester tester) async {
        fakeConfig._rec = 11;

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('App Normal'), findsOneWidget);
        expect(
          find.text(
            'Atualização Recomendada: uma nova versão está disponível.',
          ),
          findsOneWidget,
        );

        final mockTelemetry = TelemetryService.instance as MockTelemetryService;
        expect(mockTelemetry.recordedEvents.contains('migracao_db'), isTrue);
        expect(
          mockTelemetry.recordedParams['migracao_db']?['acao'],
          'banner_versao_recomendada_mostrado',
        );
      },
    );

    testWidgets(
      'Deve permitir fechar o banner de atualização recomendada ao clicar no X',
      (WidgetTester tester) async {
        fakeConfig._rec = 11;

        await tester.pumpWidget(
          MaterialApp(
            home: AppVersionChecker(
              remoteConfigService: fakeConfig,
              child: const Text('App Normal'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          find.text(
            'Atualização Recomendada: uma nova versão está disponível.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Toca no ícone de fechar (Icons.close)
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verifica se o banner sumiu
        expect(
          find.text(
            'Atualização Recomendada: uma nova versão está disponível.',
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.close), findsNothing);
        // Mas o app normal continua visível
        expect(find.text('App Normal'), findsOneWidget);
      },
    );
    test(
      'getStoreUrl retorna a url correta baseada no Remote Config e Plataforma',
      () {
        final fakeConfig = FakeRemoteConfigService();

        // Quando vazio, retorna padrão
        fakeConfig._iosUrl = '';
        expect(
          AppVersionChecker.getStoreUrl(fakeConfig, isIOS: false),
          'market://details?id=app.escalada.croquis',
        );
        expect(
          AppVersionChecker.getStoreUrl(fakeConfig, isIOS: true),
          'https://apps.apple.com/app/idXXXXXXXXX',
        );

        // Quando preenchido, retorna o remote config
        fakeConfig._iosUrl = 'https://testflight.apple.com/test';
        expect(
          AppVersionChecker.getStoreUrl(fakeConfig, isIOS: false),
          'market://details?id=app.escalada.croquis',
        );
        expect(
          AppVersionChecker.getStoreUrl(fakeConfig, isIOS: true),
          'https://testflight.apple.com/test',
        );
      },
    );
  });
}
