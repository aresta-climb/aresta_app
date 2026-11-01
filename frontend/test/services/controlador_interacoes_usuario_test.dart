// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  group('ControladorInteracoesUsuario', () {
    test('inicia com interações ativas habilitadas por padrão quando não há preferência salva', () async {
      final controlador = ControladorInteracoesUsuario();
      await controlador.inicializar();

      expect(controlador.interacoesAtivas, isTrue);
      expect(controlador.interacoesAtivasNotifier.value, isTrue);
    });

    test('carrega estado desativado previamente persistido no SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        ControladorInteracoesUsuario.chavePreferenciaInteracoes: false,
      });

      final controlador = ControladorInteracoesUsuario();
      await controlador.inicializar();

      expect(controlador.interacoesAtivas, isFalse);
    });

    test('persiste alteração de preferência e notifica ouvintes reativamente', () async {
      final controlador = ControladorInteracoesUsuario();
      var notificacoes = 0;
      controlador.interacoesAtivasNotifier.addListener(() {
        notificacoes++;
      });

      await controlador.definirInteracoesAtivas(false);

      expect(controlador.interacoesAtivas, isFalse);
      expect(notificacoes, equals(1));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(ControladorInteracoesUsuario.chavePreferenciaInteracoes),
        isFalse,
      );
    });

    test('exibirElementosInterativos exige simultaneamente perfilHabilitado e preferência ativa do usuário', () async {
      final controlador = ControladorInteracoesUsuario.instancia;
      await controlador.inicializar();

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      expect(controlador.exibirElementosInterativos, isFalse);

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      expect(controlador.exibirElementosInterativos, isTrue);

      await controlador.definirInteracoesAtivas(false);
      expect(controlador.exibirElementosInterativos, isFalse);
    });

    test('permite substituir e redefinir a instância singleton para isolamento em testes', () {
      final customizado = ControladorInteracoesUsuario();
      ControladorInteracoesUsuario.instancia = customizado;

      expect(identical(ControladorInteracoesUsuario.instancia, customizado), isTrue);

      ControladorInteracoesUsuario.redefinirParaTestes();
      expect(identical(ControladorInteracoesUsuario.instancia, customizado), isFalse);
    });
  });
}
