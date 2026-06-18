import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/onboarding_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  group('OnboardingPage', () {
    testWidgets('renders pages and indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OnboardingPage(),
      ));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(SmoothPageIndicator), findsOneWidget);
      expect(find.text('Começar a Usar'), findsNothing); // Botão final não aparece na primeira página
    });

    testWidgets('navigates to last page and shows finish button', (tester) async {
      bool doneCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: OnboardingPage(onDone: () => doneCalled = true),
      ));

      // Desliza para a segunda página
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      // Desliza para a terceira página (última)
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      // Agora o botão de concluir deve estar visível
      expect(find.text('Começar a Usar'), findsOneWidget);

      await tester.tap(find.text('Começar a Usar'));
      await tester.pumpAndSettle();

      expect(doneCalled, isTrue);
    });
  });
}
