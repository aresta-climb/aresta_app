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
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../autenticacao/servico_autenticacao_fake.dart';
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
      categoria: CategoriaAlertaSeguranca.fauna,
      detalhe: 'Colmeia no crux',
    );

    expect(notificacoes, 1);
    expect(alerta.autorNomePublico, 'Camila Rocha');
    final dados = repo.obterDadosEscalada('x8siJek3FiG3aB');
    expect(dados.alertasAtivos, hasLength(1));
    expect(dados.alertasAtivos.first.uid, alerta.uid);
  });

  test('reportarAlerta na mesma categoria incrementa apenas para novo perfil e deduplica o mesmo autor', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'autorUm0000001',
        autorNomePublico: 'Ana',
      ),
    );
    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      preferencias: prefs,
    );
    await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
    );
    // Mesmo perfil reportando novamente atualiza detalhe, mas NÃO infla confirmacoesAtivas
    final mesmoAutor = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
      detalhe: 'Ainda escorrendo água',
    );
    expect(mesmoAutor.confirmacoesAtivas, 1);
    expect(mesmoAutor.detalhe, 'Ainda escorrendo água');

    // Segundo perfil diferente incrementa para 2 sem duplicar bolha
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'autorDois00002',
        autorNomePublico: 'Bruno',
      ),
    );
    final segundoAutor = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
    );
    final alertas = repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos;
    expect(alertas, hasLength(1));
    expect(segundoAutor.confirmacoesAtivas, 2);
    expect(segundoAutor.detalhe, 'Ainda escorrendo água');
  });

  test('confirmarAlerta permite no máximo 1 +1 por perfil, sincroniza Meus Alertas offline/online e remove ao resolver', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'autorCriador01',
        autorNomePublico: 'Criador',
      ),
    );
    final clienteFake = ClienteFilaInteracoesFake();
    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      clienteFila: clienteFake,
      preferencias: prefs,
    );
    final alerta = await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
    );

    // Criador tentando auto-confirmar +1 não aumenta contagem
    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
    );
    expect(
      repo.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos.single.confirmacoesAtivas,
      1,
    );

    // Segundo perfil confirma +1 duas vezes -> conta apenas 1 vez (total = 2)
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'autorConfirm02',
        autorNomePublico: 'Confirmador',
      ),
    );
    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
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

    // Sincronizar Meus Alertas (online, erro e sem cliente) e restaurar do cache em disco
    await repo.sincronizarMeusAlertasContribuidos();
    expect(repo.obterMeusAlertasContribuidos(), hasLength(1));
    expect(
      repo.obterMeusAlertasContribuidos().single.papel,
      PapelContribuicaoAlerta.confirmadoPorMim,
    );
    clienteFake.erroSimulado = const HttpException('Falha sync caderneta');
    await repo.sincronizarMeusAlertasContribuidos();
    clienteFake.erroSimulado = null;

    final repoRehidratadoOffline = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      preferencias: prefs,
    );
    await repoRehidratadoOffline.sincronizarMeusAlertasContribuidos();
    expect(repoRehidratadoOffline.obterMeusAlertasContribuidos(), hasLength(1));

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
    await repo.sincronizarEscalada('x8siJek3FiG3aB');
  });

  test('rejeita escaladaUid vazio sob filosofia Fail-Fast', () async {
    final repo = RepositorioInteracoesViaMemoria();
    await expectLater(
      () => repo.reportarAlerta(
        escaladaUid: '  ',
        categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
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
    await expectLater(
      () => repo.editarComentario(
        escaladaUid: ' ',
        comentarioUid: 'id',
        novoTexto: 'ok',
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => repo.excluirComentario(escaladaUid: ' ', comentarioUid: 'id'),
      throwsArgumentError,
    );
    await expectLater(
      () => repo.editarAlerta(
        escaladaUid: ' ',
        alertaUid: 'id',
        novaCategoria: CategoriaAlertaSeguranca.fauna,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => repo.excluirAlerta(escaladaUid: ' ', alertaUid: 'id'),
      throwsArgumentError,
    );
  });

  test('edita e exclui comentários e alertas próprios online, offline e na reabertura a frio da Caderneta', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        fotoUrl: 'https://cdn.aresta.cc/avatars/mariana.webp',
        userId: 'uuid-mariana',
        accessToken: 'jwt-mariana',
      ),
    );
    final clienteFake = ClienteFilaInteracoesFake();
    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      clienteFila: clienteFake,
      preferencias: prefs,
    );

    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 0,
      comentarioPublico: 'Texto original',
    );
    final comentarioUid =
        repo.obterDadosEscalada('x8siJek3FiG3aB').comentarios.single.uid;

    await repo.editarComentario(
      escaladaUid: 'x8siJek3FiG3aB',
      comentarioUid: comentarioUid,
      novoTexto: 'Texto atualizado pela autora',
    );
    expect(
      repo.obterDadosEscalada('x8siJek3FiG3aB').comentarios.single.texto,
      'Texto atualizado pela autora',
    );
    expect(
      clienteFake.itensInseridos
          .firstWhere((i) => i.id == comentarioUid)
          .textoComentario,
      'Texto atualizado pela autora',
    );

    // Outro escalador não pode editar nem excluir comentário alheio
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'd4Ml0Q2y5Wx9No',
        autorNomePublico: 'Pedro',
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
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'd4Ml0Q2y5Wx9No',
          autorNomePublico: 'Pedro',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaPedro001',
          categoriaAlerta: CategoriaAlertaSeguranca.exposicaoE4Mais,
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
    await repo.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.fauna,
      detalhe: 'Enxame na base',
    );
    await repo.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: 'alertaPedro001',
      aindaEstaLa: true,
    );

    final dadosOffline = repo.obterDadosEscalada('x8siJek3FiG3aB');
    expect(dadosOffline.consensoGrau.totalVotos, 2);
    expect(dadosOffline.comentarios, hasLength(1));
    expect(dadosOffline.comentarios.single.rotuloEstilo, 'FLASH ★');
    expect(
      dadosOffline.alertasAtivos
          .firstWhere((a) => a.uid == 'alertaPedro001')
          .confirmacoesAtivas,
      2,
    );
    expect(clienteFake.itensInseridos, hasLength(2)); // Ainda apenas os 2 itens de Pedro

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
    expect(clienteFake.itensInseridos, hasLength(6));

    // 4. Erro operacional HTTP registra erro sem derrubar o app
    clienteFake.erroSimulado = const HttpException('HTTP 500');
    await repoReaberto.sincronizarEscalada('x8siJek3FiG3aB');

    // UID rascunho não-NanoID ignora rede sem erro
    await repoReaberto.sincronizarEscalada('rascunho_local');
  });

  test('garante votação confiável para contas registradas (renovação 401, reconciliação RLS 403 e deduplicação por autor)', () async {
    final prefs = await SharedPreferences.getInstance();
    final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();

    // Conta registrada sem accessToken em cache (mas com refreshToken válido)
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana Silva',
        userId: 'uuid-mariana',
        refreshToken: 'refresh-mariana',
      ),
    );

    final authFake = ServicoAutenticacaoFake(repositorio: repoCaderneta);
    final clienteFake = ClienteFilaInteracoesFake();
    final repo = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: repoCaderneta,
      servicoAutenticacao: authFake,
      clienteFila: clienteFake,
      preferencias: prefs,
    );

    // 1. Prepara sessão quando accessToken está ausente (mesmo se falhar na 1ª tentativa offline)
    authFake.erroAoGarantirSessao = const SocketException('Sem rede inicial');
    clienteFake.filaErrosInsercao.add(const SocketException('Sem rede inicial'));
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.grauSugerido, '7b');
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.totalVotos, 1);

    // 2. Mesma autora altera voto na mesma sessão -> atualiza voto sem duplicar contagem nem fila
    authFake.erroAoGarantirSessao = null;
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 0,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.grauSugerido, '7a');
    expect(repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.totalVotos, 1);
    expect(clienteFake.itensInseridos, hasLength(1));
    expect(clienteFake.ultimoAccessTokenInsercao, 'jwt_renovado_1');

    // 3. JWT expira após 1h (HTTP 401) -> renova automaticamente via refreshToken e reenvia com sucesso
    clienteFake.filaErrosInsercao.add(
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 401,
        message: 'JWT expired',
      ),
    );
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: -1,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(authFake.totalRenovacoesToken, 2);
    expect(clienteFake.ultimoAccessTokenInsercao, 'jwt_renovado_2');
    expect(clienteFake.itensInseridos.last.deltaGrau, -1);

    // 4. Violação RLS 403 (autor_id_publico divergente em public.perfis) -> reconcilia autor canônico e reenvia
    authFake.autorIdPublicoRemotoReconciliado = 'z9Yx8Wv7Ut6Sr5';
    clienteFake.filaErrosInsercao.add(
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 403,
        message: 'new row violates row-level security policy',
      ),
    );
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 2,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(clienteFake.itensInseridos.last.autorIdPublico, 'z9Yx8Wv7Ut6Sr5');
    expect(clienteFake.itensInseridos.last.deltaGrau, 2);

    // 5. Se a retentativa também falhar (ex.: desconexão durante refresh), retém na fila sem perder o voto
    clienteFake.filaErrosInsercao.addAll([
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 401,
        message: 'JWT expired',
      ),
      const SocketException('Queda durante retentativa'),
    ]);
    await repo.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
    );
    expect(repo.usuarioEstaAutenticado, isTrue);
    expect(repo.obterDeltaVotoUsuario('x8siJek3FiG3aB'), 1);
    expect(repo.obterDeltaVotoUsuario('outraViaNaoVotada'), isNull);
    expect(prefs.getString(RepositorioInteracoesViaMemoria.chaveFilaPendente), isNotNull);

    // 6. Alerta de segurança reportado após falha HTTP 500 no voto anterior NÃO sofre bloqueio de fila (chega para todos os usuários!)
    authFake.erroAoGarantirSessao = null;
    clienteFake.filaErrosInsercao.add(
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 500,
        message: 'Erro 500 apenas no voto retido',
      ),
    );
    await repo.reportarAlerta(
      escaladaUid: 'y9tjKfl4GjH4bC',
      categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
      detalhe: 'Bloco solto na saída',
    );
    expect(
      clienteFake.itensInseridos.any(
        (i) =>
            i.tipo == TipoFilaInteracao.alertaSeguranca &&
            i.escaladaUid == 'y9tjKfl4GjH4bC',
      ),
      isTrue,
    );

    // 7. Sincronização em lote mescla fila local, preserva consenso prévio e tolera erro HTTP 500
    await repo.sincronizarEscaladasEmLote(['   ']);
    await repoCaderneta.salvarPerfil(
      PerfilEscalador(
        autorIdPublico: 'd4Ml0Q2y5Wx9No',
        autorNomePublico: 'Pedro',
        userId: 'uuid-pedro',
        accessToken: 'jwt-pedro',
      ),
    );
    clienteFake.filaErrosInsercao.addAll([
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 500,
        message: 'Erro temporário 500 no voto retido',
      ),
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 500,
        message: 'Erro temporário 500 na confirmação',
      ),
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 500,
        message: 'Erro 500 ao drenar voto antes do lote',
      ),
      const ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: 500,
        message: 'Erro 500 ao drenar confirmação antes do lote',
      ),
    ]);
    await repo.confirmarAlerta(
      escaladaUid: 'y9tjKfl4GjH4bC',
      alertaUid: repo.obterDadosEscalada('y9tjKfl4GjH4bC').alertasAtivos.single.uid,
      aindaEstaLa: true,
    );
    await repo.sincronizarEscaladasEmLote(['x8siJek3FiG3aB', 'y9tjKfl4GjH4bC']);
    expect(
      repo.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.possuiVotos,
      isTrue,
    );

    clienteFake.erroSimulado = const HttpException('HTTP 500 no lote');
    await repo.sincronizarEscaladasEmLote(['y9tjKfl4GjH4bC']);
    clienteFake.erroSimulado = null;
    authFake.erroAoGarantirSessao = null;

    // 8. Sincronização em lote carrega alertas ativos de múltiplas vias para outro usuário no mapa interativo
    SharedPreferences.setMockInitialValues({});
    final prefsOutroUsuario = await SharedPreferences.getInstance();
    final repoOutroUsuario = RepositorioInteracoesViaMemoria(
      repositorioCaderneta: RepositorioCadernetaLocal(
        preferencias: prefsOutroUsuario,
      ),
      clienteFila: clienteFake,
    );
    await repoOutroUsuario.sincronizarEscaladasEmLote([
      'x8siJek3FiG3aB',
      'y9tjKfl4GjH4bC',
      'rascunho_invalido',
    ]);
    expect(
      repoOutroUsuario.obterDadosEscalada('y9tjKfl4GjH4bC').alertasAtivos,
      hasLength(1),
    );
    expect(
      repoOutroUsuario
          .obterDadosEscalada('y9tjKfl4GjH4bC')
          .alertasAtivos
          .single
          .detalhe,
      'Bloco solto na saída',
    );
  });
}
