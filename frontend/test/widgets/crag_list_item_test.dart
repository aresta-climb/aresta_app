import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

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
            body: buildCragListItem(sampleCrag, null, () {}),
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
            body: buildCragListItem(sampleCrag, null, () {}),
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
            body: buildCragListItem(sampleCrag, null, () {
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
            body: buildCragListItem(downloadedCrag, null, () {}),
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
    testWidgets('Deve chamar o callback onOpen ao clicar no botão ABRIR CROQUI se já baixado', (WidgetTester tester) async {
      final downloadedCrag = Map<String, dynamic>.from(sampleCrag);
      downloadedCrag['isDownloaded'] = true;

      bool openChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(downloadedCrag, null, () {}, onOpen: () {
              openChamado = true;
            }),
          ),
        ),
      );

      // Expandir primeiro
      await tester.tap(find.text('Pedra do Baú'));
      await tester.pumpAndSettle();

      // Clicar no botão de abrir
      await tester.tap(find.text('ABRIR CROQUI'));
      
      expect(openChamado, isTrue);
    });
  });

  group('_buildCragIcon Tests', () {
    testWidgets('Deve usar FutureBuilder<Directory> (tenta carregar arquivo local) se cragId existir', (WidgetTester tester) async {
      final Map<String, dynamic> crag = {
        'id': 'pico_offline',
        'nome': 'Pico Local',
        'thumbnailUrl': 'https://serving.arestaclimb.com/v3/thumbnails/pico_offline.webp',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(crag, null, () {}),
          ),
        ),
      );

      final finder = find.byType(FutureBuilder<Directory>);
      expect(finder, findsOneWidget);
    });

    testWidgets('Deve usar icone de fallback se cragId NAO existir (sem imagens de rede)', (WidgetTester tester) async {
      final Map<String, dynamic> crag = {
        'nome': 'Pico Sem ID',
        'thumbnailUrl': 'https://serving.arestaclimb.com/v3/thumbnails/pico_network.webp',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(crag, null, () {}),
          ),
        ),
      );

      final futureBuilderFinder = find.byType(FutureBuilder<Directory>);
      expect(futureBuilderFinder, findsNothing);
      
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsNothing);

      final iconFinder = find.byIcon(Icons.terrain);
      expect(iconFinder, findsOneWidget);
    });
  });
}
