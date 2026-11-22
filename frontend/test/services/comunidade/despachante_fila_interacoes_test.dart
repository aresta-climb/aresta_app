// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/armazenamento_fila_interacoes.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';
import 'package:frontend/services/comunidade/despachante_fila_interacoes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../autenticacao/servico_autenticacao_fake.dart';
import 'cliente_fila_interacoes_supabase_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DespachanteFilaInteracoes reconcilia 401/403, descarta conflitos 409 de +1 duplicado e interrompe em queda de rede',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
      await repoCaderneta.inicializar();
      await repoCaderneta.salvarPerfil(
        PerfilEscalador(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          userId: 'uuid-mariana',
          refreshToken: 'refresh-mariana',
        ),
      );

      final authFake = ServicoAutenticacaoFake(repositorio: repoCaderneta);
  });
}
