// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cliente_fila_interacoes_supabase_fake.dart';

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
    await expectLater(
      () => repo.registrarAvaliacaoAscensao(
        escaladaUid: '  ',
        deltaGrau: 0,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => repo.registrarAvaliacaoAscensao(
        escaladaUid: 'x8siJek3FiG3aB',
        deltaGrau: 3,
      ),
      throwsArgumentError,
    );
  });

  test('sincroniza com ClienteFilaInteracoes, enfileira offline sem sinal e reenvia quando online', () async {
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana Silva',
        userId: 'uuid-auth-mariana',
        accessToken: 'jwt-mariana',
      ),
    );

    final clienteFake = ClienteFilaInteracoesFake()
      ..semearItens([
        ItemFilaInteracao.votoGrau(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 1,
          grauSugerido: GrauVia_GrauVia.BR_7B.value,
        ),
      ]);

    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      clienteFila: clienteFake,
      preferencias: prefs,
    );

    // 1. Sincroniza estado inicial remoto
    await repo.sincronizarEscalada(
      'x8siJek3FiG3aB',
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.grauSugerido, '7b');
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.totalVotos, 1);

    // 2. Simula rocha sem sinal: voto + comentário + alertas ficam na fila offline em disco
    clienteFake.erroSimulado = const SocketException('Sem rede na falésia');
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
      estiloAscensao: TipoAscensao.flash,
      comentarioPublico: 'Chapeleta 3 longa, levar costura extensível.',
    );
    final alertaOffline = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      detalhe: 'Enxame na base',
    );
    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alertaOffline.uid,
      aindaEstaLa: true,
    );

    final dadosOffline = repo.obterDadosEscalada('x8siJek3FiG3aB');
    expect(dadosOffline.consensoGrau.totalVotos, 2);
    expect(dadosOffline.comentarios, hasLength(1));
    expect(dadosOffline.comentarios.single.rotuloEstilo, 'FLASH ★');
    expect(dadosOffline.alertasAtivos.single.confirmacoesAtivas, 2);
    expect(clienteFake.itensInseridos, hasLength(1)); // Ainda apenas o item de Pedro

    // 3. Simula reabertura a frio (nova instância lê fila pendente do SharedPreferences) e drena online
    clienteFake.erroSimulado = null;
    final repoReaberto = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      clienteFila: clienteFake,
      preferencias: prefs,
    );
    await repoReaberto.sincronizarEscalada(
      'x8siJek3FiG3aB',
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(clienteFake.itensInseridos, hasLength(5));
    expect(clienteFake.ultimoAccessTokenInsercao, 'jwt-mariana');

    // 4. Erro operacional HTTP registra erro sem derrubar o app
    clienteFake.erroSimulado = const HttpException('HTTP 500');
    await repoReaberto.sincronizarEscalada('x8siJek3FiG3aB');

    // UID rascunho não-NanoID ignora rede sem erro
    await repoReaberto.sincronizarEscalada('rascunho_local');
  });
}
