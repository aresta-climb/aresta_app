// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/controlador_idioma_app.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  tearDown(() {
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  group('ControladorIdiomaApp', () {
    test(
      'inicia em português por padrão e restaura idioma persistido ao carregar do disco',
      () async {
        SharedPreferences.setMockInitialValues({
          ControladorIdiomaApp.chavePreferenciaIdioma: 'nl',
        });
        final prefs = await SharedPreferences.getInstance();
        final controlador = ControladorIdiomaApp.criarIsolado();

        expect(controlador.idiomaAtual, IdiomaApp.portugues);

        var notificacoes = 0;
        controlador.notificadorIdioma.addListener(() => notificacoes++);

        await controlador.carregarDoDisco(prefsInjetado: prefs);
        expect(controlador.idiomaAtual, IdiomaApp.holandes);
        expect(notificacoes, 1);

        // Recarregar o mesmo valor salvo não dispara notificação redundante
        await controlador.carregarDoDisco();
        expect(controlador.idiomaAtual, IdiomaApp.holandes);
        expect(notificacoes, 1);
      },
    );

    test(
      'persiste novo idioma em SharedPreferences e notifica ouvintes apenas quando o idioma muda',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final controlador = ControladorIdiomaApp.criarIsolado();

        var notificacoes = 0;
        controlador.notificadorIdioma.addListener(() => notificacoes++);

        await controlador.definirIdioma(
          IdiomaApp.espanhol,
          prefsInjetado: prefs,
        );
        expect(controlador.idiomaAtual, IdiomaApp.espanhol);
        expect(notificacoes, 1);
        expect(
          prefs.getString(ControladorIdiomaApp.chavePreferenciaIdioma),
          'es',
        );

        await controlador.definirIdioma(IdiomaApp.espanhol);
        expect(notificacoes, 1);
      },
    );

    test(
      'cicla sequencialmente pelos cinco idiomas e restaura o padrão em memória sincronamente',
      () async {
        final controlador = ControladorIdiomaApp.criarIsolado();

        expect(await controlador.ciclarProximoIdioma(), IdiomaApp.ingles);
        expect(await controlador.ciclarProximoIdioma(), IdiomaApp.espanhol);
        expect(await controlador.ciclarProximoIdioma(), IdiomaApp.alemao);
        expect(await controlador.ciclarProximoIdioma(), IdiomaApp.holandes);
        expect(await controlador.ciclarProximoIdioma(), IdiomaApp.portugues);

        await controlador.definirIdioma(IdiomaApp.alemao);
        expect(controlador.idiomaAtual, IdiomaApp.alemao);

        controlador.restaurarPadraoEmMemoria();
        expect(controlador.idiomaAtual, IdiomaApp.portugues);

        // Idempotente quando já está em português
        controlador.restaurarPadraoEmMemoria();
        expect(controlador.idiomaAtual, IdiomaApp.portugues);
      },
    );

    testWidgets(
      'EscopoIdiomaApp reconstrói dependentes ao trocar idioma e recorre à instância global quando ausente da árvore',
      (tester) async {
        final controladorIsolado = ControladorIdiomaApp.criarIsolado();

        await tester.pumpWidget(
          EscopoIdiomaApp(
            notificador: controladorIsolado.notificadorIdioma,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  final idioma = EscopoIdiomaApp.observar(context);
                  return Text('escopo:${idioma.regiaoIso}');
                },
              ),
            ),
          ),
        );

        expect(find.text('escopo:BR'), findsOneWidget);

        await controladorIsolado.definirIdioma(IdiomaApp.holandes);
        await tester.pump();
        expect(find.text('escopo:NL'), findsOneWidget);

        // Sem EscopoIdiomaApp na árvore, recorre à instância global
        await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.alemao);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final idioma = EscopoIdiomaApp.observar(context);
                return Text('global:${idioma.regiaoIso}');
              },
            ),
          ),
        );
        expect(find.text('global:DE'), findsOneWidget);
      },
    );
  });
}
