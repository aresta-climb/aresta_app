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

