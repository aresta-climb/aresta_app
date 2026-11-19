// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RepositorioInteracoesViaMemoria.redefinirParaTestes();
  });

  tearDown(RepositorioInteracoesViaMemoria.redefinirParaTestes);

  test('instancia singleton pode ser substituída e redefinida para testes', () {
    final original = RepositorioInteracoesViaMemoria.instancia;
    final custom = RepositorioInteracoesViaMemoria();
    RepositorioInteracoesViaMemoria.instancia = custom;
    expect(RepositorioInteracoesViaMemoria.instancia, same(custom));

    RepositorioInteracoesViaMemoria.redefinirParaTestes();
    expect(RepositorioInteracoesViaMemoria.instancia, isNot(same(custom)));
    expect(RepositorioInteracoesViaMemoria.instancia, isNot(same(original)));
  });

  test('reportarAlerta cria alerta ativo com apelido do perfil e notifica ouvintes', () async {
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();
    await repoCaderneta.salvarPerfil(
      PerfilEscalador.criarPadrao().copyWith(autorNomePublico: 'Camila Rocha'),
    );

    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
    );
    var notificacoes = 0;
    repo.alteracoesListenable.addListener(() => notificacoes++);

    expect(
      repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos,
      isEmpty,
    );

    final alerta = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      detalhe: 'Colmeia no crux',
    );

    expect(notificacoes, 1);
    expect(alerta.autorNomePublico, 'Camila Rocha');
    final dados = repo.obterDadosEscalada('x8siJek3FiG3aB');
    expect(dados.alertasAtivos, hasLength(1));
    expect(dados.alertasAtivos.first.uid, alerta.uid);
  });

}
