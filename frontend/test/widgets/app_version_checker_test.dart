import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_version_checker.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeRemoteConfigService implements RemoteConfigService {
  int _hard = 0;
  int _soft = 0;
  int _rec = 0;

  @override
  int get hardMinVersion => _hard;
  @override
  int get softMinVersion => _soft;
  @override
  int get recommendedVersion => _rec;

  @override
  int getInt(String key) => 0;
  @override
  bool getBool(String key) => false;
  @override String getString(String key) => "";
  
  String _iosUrl = "";
  @override String get storeUrlIos => _iosUrl;

  @override
  Future<void> initialize() async {}

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
      'Deve exibir erro crítico quando hardMinVersion for maior que buildNumber',
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
      },
    );

    testWidgets(
      'Deve exibir banner soft quando softMinVersion for maior que buildNumber',
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
    test('getStoreUrl retorna a url correta baseada no Remote Config e Plataforma', () {
      final fakeConfig = FakeRemoteConfigService();
      
      // Quando vazio, retorna padrão
      fakeConfig._iosUrl = '';
      expect(AppVersionChecker.getStoreUrl(fakeConfig, isIOS: false), 'market://details?id=app.escalada.croquis');
      expect(AppVersionChecker.getStoreUrl(fakeConfig, isIOS: true), 'https://apps.apple.com/app/idXXXXXXXXX');

      // Quando preenchido, retorna o remote config
      fakeConfig._iosUrl = 'https://testflight.apple.com/test';
      expect(AppVersionChecker.getStoreUrl(fakeConfig, isIOS: false), 'market://details?id=app.escalada.croquis');
      expect(AppVersionChecker.getStoreUrl(fakeConfig, isIOS: true), 'https://testflight.apple.com/test');
    });
  });
}
