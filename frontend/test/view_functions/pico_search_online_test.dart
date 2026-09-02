// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/pico_functions.dart';

void main() {
  group('PicoSearchDelegate no modo online', () {
    late Pico picoOnline;
    late Setor setorFalasia;
    late Escalada viaSombra;
    late Escalada boulderMonstro;

    setUp(() {
      viaSombra = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Sombra e Água Fresca'
          ..grau = '7a');

      boulderMonstro = Escalada()
        ..boulder = (Boulder()
          ..nome = 'Monstro da Gruta'
          ..grau = 'V4');

      setorFalasia = Setor()
        ..nome = 'Falésia Central'
        ..escaladas.addAll([viaSombra, boulderMonstro]);

      picoOnline = Pico()
        ..nome = 'Pedra Sonora Online'
        ..setoresOuGrupos.add(
          SetorOuGrupo()
            ..setor = (SetorRef()
              ..conteudo = setorFalasia),
        );
    });

    testWidgets('busca via por nome em croqui carregado online', (tester) async {
      final delegate = PicoSearchDelegate(picoOnline, 'pedra_sonora_online');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSearch(context: context, delegate: delegate);
                },
                child: const Text('Abrir Busca'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Busca'));
      await tester.pumpAndSettle();

      // Digita nome da via
      delegate.query = 'Sombra';
      await tester.pumpAndSettle();

      expect(find.text('Sombra e Água Fresca'), findsOneWidget);
      expect(find.text('Dificuldade: 7a'), findsOneWidget);
    });

    testWidgets('busca via por grau de dificuldade em croqui online', (tester) async {
      final delegate = PicoSearchDelegate(picoOnline, 'pedra_sonora_online');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSearch(context: context, delegate: delegate);
                },
                child: const Text('Abrir Busca'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Busca'));
      await tester.pumpAndSettle();

      // Digita grau do boulder
      delegate.query = 'V4';
      await tester.pumpAndSettle();

      expect(find.text('Monstro da Gruta'), findsOneWidget);
      expect(find.text('Dificuldade: V4'), findsOneWidget);
    });

    testWidgets('busca setor por nome no croqui online', (tester) async {
      final delegate = PicoSearchDelegate(picoOnline, 'pedra_sonora_online');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSearch(context: context, delegate: delegate);
                },
                child: const Text('Abrir Busca'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Busca'));
      await tester.pumpAndSettle();

      // Digita nome do setor
      delegate.query = 'Falésia';
      await tester.pumpAndSettle();

      expect(find.text('Falésia Central'), findsOneWidget);
      expect(find.text('Setor'), findsOneWidget);
    });
  });
}
