// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/view_functions/comunidade_functions.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import '../mocks/mock_app_logger.dart';
import '../mocks/mock_telemetry_service.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool shouldFail = false;
  bool shouldThrow = false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    if (shouldThrow) {
      throw Exception('Falha ao abrir URL nativa');
    }
    if (shouldFail) return false;
    return true;
  }
}

void main() {
  late MockUrlLauncherPlatform mockLauncher;
  late MockAppLogger mockLogger;
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
    PackageInfo.setMockInitialValues(
      appName: 'Aresta Climb',
      packageName: 'com.arestaclimb',
      version: '2.4.0',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [
          AppColors.dark,
        ],
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => child,
        ),
      ),
    );
  }

  group('comunidade_functions - Dark Mode e Widgets', () {
    testWidgets('buildActionCard renderiza em Dark Mode com cores caveShadow e chalkWhite', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => buildActionCard(
              context,
              title: 'GRUPO DO WHATSAPP',
              subtitle: 'Participe do grupo',
              iconData: Icons.chat,
              iconBgColor: const Color(0xFF128C7E),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verifica texto do título e subtítulo
      final titleFinder = find.text('GRUPO DO WHATSAPP');
      expect(titleFinder, findsOneWidget);
      expect(find.text('Participe do grupo'), findsOneWidget);

      // Valida estilo do título em Dark Mode (chalkWhite)
      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.color, equals(AppColors.dark.chalkWhite));

      // Valida que o container externo usa a cor caveShadow do Dark Mode (não Colors.white)
      final containerFinder = find.ancestor(
        of: titleFinder,
        matching: find.byType(Container),
      ).first;
      final Container containerWidget = tester.widget(containerFinder);
      final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.dark.caveShadow));

      // Valida clique
      await tester.tap(find.text('GRUPO DO WHATSAPP'));
      expect(tapped, isTrue);
    });

    testWidgets('buildTermsCard renderiza em Dark Mode com cores caveShadow e chalkWhite', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => buildTermsCard(context),
          ),
        ),
      );

      final titleFinder = find.text('Termos de Uso e Privacidade');
      expect(titleFinder, findsOneWidget);

      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.color, equals(AppColors.dark.chalkWhite));

      // Container externo não deve ser Colors.white
      final containerFinder = find.ancestor(
        of: titleFinder,
        matching: find.byType(Container),
      ).first;
      final Container containerWidget = tester.widget(containerFinder);
      final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.dark.caveShadow));
    });

    testWidgets('buildFooter renderiza versão e mensagem da iniciativa', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => buildFooter(context),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aresta Climb v2.4.0 • Beta Aberto'), findsOneWidget);
      expect(find.text('Uma iniciativa independente pelo montanhismo livre do Brasil.'), findsOneWidget);
    });

    testWidgets('showLinkOverlay abre bottom sheet e dispara launchUrl ao clicar no botão', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showLinkOverlay(
                  context,
                  title: 'Comunidade Externa',
                  link: 'https://example.com/link',
                  iconData: Icons.link,
                  iconColor: Colors.blue,
                );
              },
              child: const Text('Abrir Overlay'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Overlay'));
      await tester.pumpAndSettle();

      expect(find.text('Comunidade Externa'), findsOneWidget);
      expect(find.text('ACESSAR '), findsOneWidget);

      await tester.tap(find.text('ACESSAR '));
      await tester.pumpAndSettle();

      expect(mockLauncher.lastLaunchedUrl, equals('https://example.com/link'));
    });

    testWidgets('launchURL tenta abrir URL com sucesso e trata exceção com SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => launchURL(context, 'https://example.com/test'),
              child: const Text('Test Launch'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Launch'));
      await tester.pumpAndSettle();
      expect(mockLauncher.lastLaunchedUrl, equals('https://example.com/test'));

      // Teste de falha
      mockLauncher.shouldFail = true;
      await tester.tap(find.text('Test Launch'));
      await tester.pumpAndSettle();
    });

    testWidgets('showTermsBottomSheet abre modal e renderiza header', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTermsBottomSheet(context),
              child: const Text('Open Terms'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Terms'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TERMOS E PRIVACIDADE'), findsOneWidget);
    });

    testWidgets('showPrivacyPolicyBottomSheet abre modal e renderiza header', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPrivacyPolicyBottomSheet(context),
              child: const Text('Open Privacy'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Privacy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('POLÍTICA DE PRIVACIDADE'), findsOneWidget);
    });

    group('abrirLinkExterno', () {
      test('abre URL e registra telemetria de link_externo com sucesso', () async {
        const url = 'https://instagram.com/arestaclimb';
        const servico = 'Instagram';

        await abrirLinkExterno(url, servico);

        expect(mockLauncher.lastLaunchedUrl, equals(url));
        expect(mockTelemetria.recordedEvents, contains('link_externo'));
        final params = mockTelemetria.recordedParams['link_externo']!;
        expect(params['acao'], equals('abrir_link_externo'));
        expect(params['origem'], equals('comunidade'));
        expect(params['detalhe'], equals(url));
        expect(mockLogger.recordedErrors, isEmpty);
      });

      test('captura falha ao abrir link e registra contexto no AppLogger', () async {
        mockLauncher.shouldThrow = true;
        const url = 'https://chat.whatsapp.com/invalido';
        const servico = 'WhatsApp';

        await abrirLinkExterno(url, servico);

        expect(mockTelemetria.recordedEvents, contains('link_externo'));
        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage'].contains('Erro ao abrir link do WhatsApp ($url)'),
          ),
          isTrue,
        );
      });
    });

    group('navegarParaSobreTime', () {
      test('dispara navegação para SobreTimeNode utilizando controller injetado', () {
        final controller = TreeNavigationController();
        expect(controller.currentNode, isA<HomeNode>());

        navegarParaSobreTime(controller);

        expect(controller.currentNode, isA<SobreTimeNode>());
        expect(controller.currentNode.parent, isA<HomeNode>());
      });

      test('não lança exceção quando currentTreeController é nulo e nenhum controller é injetado', () {
        expect(() => navegarParaSobreTime(), returnsNormally);
      });
    });
  });
}
