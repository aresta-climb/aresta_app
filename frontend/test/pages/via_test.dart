// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';

void main() {
  testWidgets('ViaPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ViaPage(
          escalada: Escalada()
            ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste'),
          cragId: 'crag1',
        ),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    final Scaffold scaffold = tester.widget(scaffoldFinder);
    expect(scaffold.body, isA<SafeArea>());

    final SafeArea safeArea = scaffold.body as SafeArea;
    expect(safeArea.bottom, isTrue);
  });

  testWidgets(
    'ViaPage should correctly receive and expose pico, setor, and grupo parameters',
    (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');

      await tester.pumpWidget(
        MaterialApp(
          home: ViaPage(
            escalada: escalada,
            cragId: 'crag1',
            pico: pico,
            setor: setor,
            grupo: grupo,
          ),
        ),
      );

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final viaPageFinder = find.byType(ViaPage);
      expect(viaPageFinder, findsOneWidget);

      final ViaPage page = tester.widget(viaPageFinder);
      expect(page.pico?.nome, 'Pico Teste');
      expect(page.setor?.nome, 'Setor Teste');
      expect(page.grupo?.nome, 'Grupo Teste');
    },
  );

  testWidgets(
    'ViaPage exibe LinhaLocalizacaoSetor com hierarquia Grupo > Setor e botão de salto',
    (tester) async {
      final pico = Pico()..nome = 'Pedra do Baú';
      final grupo = Grupo(nome: 'Face Leste');
      final setor = Setor(nome: 'Setor da Divisa');
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Sol e Chuva');

      await tester.pumpWidget(
        MaterialApp(
          home: ViaPage(
            escalada: escalada,
            cragId: 'crag1',
            pico: pico,
            setor: setor,
            grupo: grupo,
          ),
        ),
      );

      expect(find.textContaining('Face Leste > Setor da Divisa'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);
    },
  );

  testWidgets(
    'ViaPage exibe LinhaLocalizacaoSetor apenas com Setor quando grupo for nulo',
    (tester) async {
      final pico = Pico()..nome = 'Pedra do Baú';
      final setor = Setor(nome: 'Setor Principal');
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Normal do Baú');

      await tester.pumpWidget(
        MaterialApp(
          home: ViaPage(
            escalada: escalada,
            cragId: 'crag1',
            pico: pico,
            setor: setor,
          ),
        ),
      );

      expect(find.textContaining('Setor Principal'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);
    },
  );

  testWidgets('ViaPage exibe botão de registrar cadena e abre modal ao ser clicado', (tester) async {
    final escalada = Escalada()
      ..uid = 'via-uid-123'
      ..viaEsportiva = (ViaEsportiva()..nome = 'Fenda da Esperança');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: ViaPage(
          escalada: escalada,
          cragId: 'crag1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrar Cadena / Tentativa'), findsOneWidget);
    expect(find.textContaining('Encadenada'), findsNothing);

    await tester.tap(find.text('Registrar Cadena / Tentativa'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar Ascensão'), findsOneWidget);
    expect(find.text('Fenda da Esperança'), findsOneWidget);
  });

  testWidgets('ViaPage exibe selo esportivo com estilo Flash quando há ascensão registrada', (tester) async {
    final escalada = Escalada()
      ..uid = 'via-uid-encadenada'
      ..viaEsportiva = (ViaEsportiva()..nome = 'Via Master');

    final cadena = Cadena.criar(
      escaladaUid: 'via-uid-encadenada',
      dataAscensao: DateTime(2026, 9, 14),
      tipoAscensao: TipoAscensao.flash,
      notasPrivadas: 'Costurou leve e rápido',
    );

    // Mock do repositório
    final repo = RepositorioCadernetaLocal();
    await repo.salvarCadena(cadena);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: ViaPage(
          escalada: escalada,
          cragId: 'crag1',
          repositorio: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Encadenada'), findsOneWidget);
    expect(find.textContaining('Flash'), findsOneWidget);
    expect(find.textContaining('Costurou leve e rápido'), findsOneWidget);
    expect(find.text('Nova Ascensão / Tentativa'), findsOneWidget);
  });
}
