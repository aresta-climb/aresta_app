import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/browse_functions.dart';

void main() {
  group('CragListItem Widget Tests', () {
    final Map<String, dynamic> sampleCrag = {
      'nome': 'Pedra do Baú',
      'local': 'São Bento do Sapucaí, SP',
      'dataUpdate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'isDownloaded': false,
      'thumbnailUrl': '',
    };

    testWidgets('Deve renderizar inicialmente em estado colapsado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(sampleCrag, () {}),
          ),
        ),
      );

      // Verifica elementos básicos
      expect(find.text('Pedra do Baú'), findsOneWidget);
      expect(find.text('São Bento do Sapucaí, SP'), findsOneWidget);
      
      // Verifica se o AnimatedCrossFade está no estado colapsado
      final crossFade = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFade.crossFadeState, equals(CrossFadeState.showFirst));
      
      // Deve mostrar o ícone de localização
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('Deve expandir ao ser tocado e mostrar informações extras', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(sampleCrag, () {}),
          ),
        ),
      );

      // Toca no card para expandir
      await tester.tap(find.text('Pedra do Baú'));
      await tester.pumpAndSettle(); // Aguarda as animações

      // Agora deve mostrar o botão de download
      expect(find.text('BAIXAR'), findsOneWidget);
      
      // O subtítulo deve ter mudado para o tempo relativo (AnimatedSwitcher)
      expect(find.textContaining('atualizado há 2 dias'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      
      // Deve mostrar os detalhes extras na área expandida
      expect(find.text('Localização'), findsOneWidget);
      expect(find.text('Última atualização'), findsOneWidget);
    });

    testWidgets('Deve chamar o callback onDownload ao clicar no botão', (WidgetTester tester) async {
      bool downloadChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(sampleCrag, () {
              downloadChamado = true;
            }),
          ),
        ),
      );

      // Expandir primeiro
      await tester.tap(find.text('Pedra do Baú'));
      await tester.pumpAndSettle();

      // Clicar no botão de baixar
      await tester.tap(find.text('BAIXAR'));
      
      expect(downloadChamado, isTrue);
    });

    testWidgets('Deve mostrar botão para abrir se já estiver baixado', (WidgetTester tester) async {
      final downloadedCrag = Map<String, dynamic>.from(sampleCrag);
      downloadedCrag['isDownloaded'] = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(downloadedCrag, () {}),
          ),
        ),
      );

      // Expandir
      await tester.tap(find.text('Pedra do Baú'));
      await tester.pumpAndSettle();

      // Verifica se o texto do botão mudou
      expect(find.text('ABRIR CROQUI'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    });
  });
}

