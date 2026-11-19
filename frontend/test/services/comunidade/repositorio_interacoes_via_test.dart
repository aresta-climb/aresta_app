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

  test('reportarAlerta na mesma categoria incrementa confirmações sem duplicar bolha', () async {
    final repo = RepositorioInteracoesViaMemoria();
    await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.viaMolhada,
    );
    final atualizado = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.viaMolhada,
      detalhe: 'Ainda escorrendo água',
    );

    final alertas = repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos;
    expect(alertas, hasLength(1));
    expect(atualizado.confirmacoesAtivas, 2);
    expect(atualizado.detalhe, 'Ainda escorrendo água');

    final semNovoDetalhe = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.viaMolhada,
    );
    expect(semNovoDetalhe.confirmacoesAtivas, 3);
    expect(semNovoDetalhe.detalhe, 'Ainda escorrendo água');
  });

  test('confirmarAlerta incrementa contagem quando ativo e remove alerta quando resolvido', () async {
    final repo = RepositorioInteracoesViaMemoria();
    final alerta = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
    );

    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
    );
    expect(
      repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos.single.confirmacoesAtivas,
      2,
    );

    // Confirmar alerta inexistente não corrompe estado
    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: 'inexistente0001',
      aindaEstaLa: true,
    );
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos, hasLength(1));

    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: false,
    );
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos, isEmpty);
  });

  test('rejeita escaladaUid vazio sob filosofia Fail-Fast', () async {
    final repo = RepositorioInteracoesViaMemoria();
    await expectLater(
      () => repo.reportarAlerta(
        escaladaUid: '  ',
        categoria: CategoriaAlertaSeguranca.riscoExposicao,
      ),
      throwsArgumentError,
    );
  });
}
