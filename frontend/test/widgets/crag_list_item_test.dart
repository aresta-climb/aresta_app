// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
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
      'dataUpdate': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'isDownloaded': false,
      'thumbnailUrl': '',
    };

    testWidgets('Deve renderizar os dados do pico no card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(
              sampleCrag,
              ValueNotifier<Map<String, double>>({}),
              () {},
            ),
          ),
        ),
      );

      // Verifica elementos básicos
      expect(find.text('PEDRA DO BAÚ'), findsOneWidget); // UPPER CASE NOW
    });

    testWidgets(
      'Deve abrir bottom sheet de download ao clicar se nao baixado',
      (WidgetTester tester) async {
        bool downloadChamado = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: buildCragListItem(
                sampleCrag,
                ValueNotifier<Map<String, double>>({}),
                () {
                  downloadChamado = true;
                },
              ),
            ),
          ),
        );

        // Clicar no card
        await tester.tap(find.text('PEDRA DO BAÚ'));
        await tester.pumpAndSettle();

        // Verifica se abriu o bottom sheet com botão BAIXAR CROQUI
        expect(find.text('BAIXAR CROQUI'), findsOneWidget);

        // Clicar no botão de baixar no bottom sheet
        await tester.tap(find.text('BAIXAR CROQUI'));

        expect(downloadChamado, isTrue);
      },
    );

    testWidgets('Deve chamar onOpen ao clicar no card se ja baixado', (
      WidgetTester tester,
    ) async {
      final downloadedCrag = Map<String, dynamic>.from(sampleCrag);
      downloadedCrag['isDownloaded'] = true;

      bool openChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(
              downloadedCrag,
              ValueNotifier<Map<String, double>>({}),
              () {},
              onOpen: () {
                openChamado = true;
              },
            ),
          ),
        ),
      );

      // Clicar no card
      await tester.tap(find.text('PEDRA DO BAÚ'));
      await tester.pumpAndSettle();

      expect(openChamado, isTrue);
    });
  });

  group('_buildCragIcon Tests', () {
    testWidgets(
      'Deve usar FutureBuilder<Directory> (tenta carregar arquivo local) se cragId existir',
      (WidgetTester tester) async {
        final Map<String, dynamic> crag = {
          'id': 'pico_offline',
          'nome': 'Pico Local',
          'thumbnailUrl':
              'https://serving.arestaclimb.com/v3/thumbnails/pico_offline.webp',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: buildCragListItem(
                crag,
                ValueNotifier<Map<String, double>>({}),
                () {},
              ),
            ),
          ),
        );

        final finder = find.byType(FutureBuilder<Directory>);
        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      'Deve usar icone de fallback se cragId NAO existir (sem imagens de rede)',
      (WidgetTester tester) async {
        final Map<String, dynamic> crag = {
          'nome': 'Pico Sem ID',
          'thumbnailUrl':
              'https://serving.arestaclimb.com/v3/thumbnails/pico_network.webp',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: buildCragListItem(
                crag,
                ValueNotifier<Map<String, double>>({}),
                () {},
              ),
            ),
          ),
        );

        final futureBuilderFinder = find.byType(FutureBuilder<Directory>);
        expect(futureBuilderFinder, findsNothing);

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsNothing);

        final iconFinder = find.byIcon(Icons.terrain);
        expect(iconFinder, findsOneWidget);
      },
    );
  });
}
