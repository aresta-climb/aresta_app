// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/theme/app_colors.dart';

void main() {
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
    expect(find.text('Produto/Marketing'), findsOneWidget);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('Frontend'), findsOneWidget);
  });

  testWidgets('Tapping a quadrant expands to show detailed content', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on Eduardo (Frontend)
    await tester.tap(find.text('Frontend'));
    await tester.pumpAndSettle();

    // After expanding, it should show GitHub and LinkedIn buttons if available
    expect(find.text('GitHub'), findsWidgets);
    expect(find.text('LinkedIn'), findsWidgets);
    
    // The name text should be visible in detail view
    expect(find.text('EDUARDO UTSCH'), findsWidgets);
  });

  testWidgets('Tapping background when expanded collapses the quadrant', (WidgetTester tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Expand Eduardo
    await tester.tap(find.text('Frontend'));
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
    await tester.tap(find.text('Designer'));
    await tester.pumpAndSettle();

    expect(find.text('LORENA CARLA'), findsWidgets);

    // Tap AppBar back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify it collapsed instead of popping
    expect(find.text('LORENA CARLA'), findsNothing);
    expect(find.text('Designer'), findsOneWidget);
  });
}
