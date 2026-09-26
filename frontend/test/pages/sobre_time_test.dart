// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/theme/app_colors.dart';
import '../mocks/mock_telemetry_service.dart';

class FakeRemoteConfigService extends Fake implements RemoteConfigService {
  String discordUrl = 'https://discord.gg/NT9uSKJWYs';

  @override
  String get discordCommunityUrl => discordUrl;
}

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }
}

void main() {
  late MockTelemetryService mockTelemetria;
  late MockUrlLauncherPlatform mockLauncher;
  late FakeRemoteConfigService fakeRemoteConfig;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
    fakeRemoteConfig = FakeRemoteConfigService();
    RemoteConfigService.instance = fakeRemoteConfig;
  });
  Widget createTestWidget() {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: [
            AppColors.dark,
          ],
        ),
        child: const SobreTimePage(),
      ),
    );
  }

  void setScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0; // Typical mobile density (360x800 logical)
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('SobreTimePage renders initial state correctly', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('SOBRE O TIME'), findsOneWidget);
    expect(find.text('CONHEÇA QUEM FAZ O ARESTA'), findsOneWidget);

    // Initial state: collapsed content should be visible
    expect(find.text('Designer'), findsOneWidget);
    expect(find.text('Produto/\nMarketing'), findsOneWidget);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('Frontend'), findsOneWidget);
  });

  testWidgets('Tapping a quadrant expands to show detailed content without description', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on Eduardo (Frontend)
    await tester.tap(find.text('Frontend'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // After expanding, it should show GitHub and LinkedIn buttons if available
    expect(find.text('GitHub'), findsWidgets);
    expect(find.text('LinkedIn'), findsWidgets);
    
    // The name text should be visible in detail view
    expect(find.text('EDUARDO UTSCH'), findsWidgets);

    // Description paragraph should no longer be displayed
    expect(find.textContaining('Desenvolvimento da interface'), findsNothing);
  });

  testWidgets('Tapping background when expanded collapses the quadrant', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Expand Eduardo
    await tester.tap(find.text('Frontend'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify it expanded (GitHub/LinkedIn buttons visible)
    expect(find.text('LinkedIn'), findsWidgets);

    // Tap background (the topmost GestureDetector)
    // We can tap the title text which is in the SafeArea but outside the quadrant
    await tester.tap(find.text('CONHEÇA QUEM FAZ O ARESTA'));
    await tester.pumpAndSettle();

    // Detailed buttons should not be visible anymore since it collapsed back to phase 1
    // Wait, pumpAndSettle should finish the reverse animation
    expect(find.text('GitHub'), findsNothing);
    expect(find.text('LinkedIn'), findsNothing);
  });
  testWidgets('Pressing AppBar back button when expanded collapses the quadrant', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Expand Lorena
    await tester.tap(find.text('Designer'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('LORENA CARLA'), findsWidgets);

    // Tap AppBar back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify it collapsed instead of popping
    expect(find.text('LORENA CARLA'), findsNothing);
    expect(find.text('Designer'), findsOneWidget);
  });

  testWidgets('SobreTimePage dispara logLinkExterno ao tocar no Discord e links dos membros', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Toca no card do Discord no rodapé
    mockTelemetria.clear();
    await tester.tap(find.text('O ARESTA É OPEN SOURCE'));
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    var params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['acao'], 'abrir_link_externo');
    expect(params['origem'], 'sobre_time');
    expect(params['detalhe'], fakeRemoteConfig.discordCommunityUrl);

    // 2. Expande o quadrante Frontend (Eduardo)
    await tester.tap(find.text('Frontend'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 3. Toca em LinkedIn
    mockTelemetria.clear();
    await tester.tap(find.text('LinkedIn'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['acao'], 'abrir_link_externo');
    expect(params['origem'], 'sobre_time');
    expect(params['detalhe'], 'https://www.linkedin.com/in/eduardo-utsch-205745350/');

    // 4. Toca em GitHub
    mockTelemetria.clear();
    await tester.tap(find.text('GitHub'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('link_externo'));
    params = mockTelemetria.recordedParams['link_externo']!;
    expect(params['acao'], 'abrir_link_externo');
    expect(params['origem'], 'sobre_time');
    expect(params['detalhe'], 'https://github.com/eduardoutsch');
  });

  testWidgets('Ao clicar no banner inferior de contribuição, abre o link do Discord via RemoteConfigService', (WidgetTester tester) async {
    setScreenSize(tester);
    fakeRemoteConfig.discordUrl = 'https://discord.gg/NT9uSKJWYs';
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('O ARESTA É OPEN SOURCE'));
    await tester.tap(find.text('O ARESTA É OPEN SOURCE'));
    await tester.pumpAndSettle();

    expect(mockLauncher.lastLaunchedUrl, 'https://discord.gg/NT9uSKJWYs');
  });
}
