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
  });
}
