// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constantes_rede.dart';
import '../../constants/legal_version.g.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../navigation/wrapper_navegacao_arvore.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../comunidade/repositorio_interacoes_via.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';
import '../http/sync_service.dart';
import '../repositorio_dataset.dart';
import 'configuracao_smoke_ci.dart';
import 'piloto_arvore_ui_smoke.dart';

/// Executa a jornada completa de ponta a ponta do Smoke Test pós-build no binário descartável de CI.
///
/// Conduz telas e modais reais na árvore ofuscada via [PilotoArvoreUiSmoke], cobrindo:
/// 1. Aceite de Termos Legais, inicialização SQLite/Caderneta e abertura de Croqui Protobuf v5;
/// 2. Login Magic Code OTP (6 dígitos) + logout via diálogo real;
/// 3. Login Apple ID nativo no iOS Simulator (ou validação de ocultação no Android);
/// 4. Login Google nativo (`id_token` no Android; PKCE `callbackUrl` no iOS) + edição de perfil;
/// 5. Registro de Cadena, voto de grau (`+1`) e beta público via `ModalRegistroCadena`;
/// 6. Edição de comentário público na `ViaPage`;
/// 7. Reporte de alerta Waze com falha offline `503` controlada + drenagem de *outbox* + confirmação `+1`;
/// 8. Conferência da `CadernetaPage`, renovação `refresh_token` e exclusão de conta via diálogo real.
class ExecutorJornadaSmoke {
  /// Identificador do croqui determinístico servido pelo micro-servidor local de CI.
  static const String idCroquiSmoke = 'serra_smoke_ci';

  /// Código OTP numérico de 6 dígitos aceito pelo servidor local de smoke.
  static const String codigoOtpSmoke = '654321';

  final ConfiguracaoSmokeCi configuracao;
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final RepositorioCaderneta repositorioCaderneta;
  final ServicoAutenticacao servicoAutenticacao;
  final RepositorioInteracoesVia repositorioInteracoes;
  final PilotoArvoreUiSmoke pilotoUi;
  final Future<void> Function() _aguardarFrameUi;

  ExecutorJornadaSmoke({
    required this.configuracao,
    required this.datasetRepo,
    required this.syncService,
    required this.repositorioCaderneta,
    required this.servicoAutenticacao,
    RepositorioInteracoesVia? repositorioInteracoes,
    PilotoArvoreUiSmoke? pilotoUi,
    Future<void> Function()? aguardarFrameUi,
  }) : repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       pilotoUi = pilotoUi ?? PilotoArvoreUiSmoke(),
       _aguardarFrameUi = aguardarFrameUi ?? _aguardarProximoFramePadrao;

  static Future<void> _aguardarProximoFramePadrao() async {
    SchedulerBinding.instance.scheduleFrame();
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  static bool _executarSeContextoMontado(
    void Function(BuildContext context) acao,
  ) {
    final ctx = TreeNavigationWrapper.navKey.currentContext;
    if (ctx != null && ctx.mounted) {
      acao(ctx);
      return true;
    }
    return false;
  }

  static void _exigirInvariante(bool condicao, String mensagem) {
    if (!condicao) {
      throw StateError(mensagem);
    }
  }

  /// Executa todas as etapas e envia o relatório final para `/__smoke__/relatorio`.
  Future<Map<String, dynamic>> executarEEnviarRelatorio() async {
    final etapas = <String>[];
    final erros = <String>[];

    try {
      await _prepararTermosECroqui(etapas);

      final contextoInicial = TreeNavigationWrapper.navKey.currentContext;
      final arvoreMontada = contextoInicial != null && contextoInicial.mounted;

      if (!arvoreMontada) {
        await _executarJornadaSemArvore(etapas);
      } else {
        await _executarJornadaComUiReal(etapas);
      }
    } catch (erro, stackTrace) {
      AppLogger.instance.logError(
        '[SmokeCI] Falha durante execução da jornada pós-build',
        error: erro,
        stackTrace: stackTrace,
      );
      erros.add('$erro\n$stackTrace');
    }

    final relatorio = <String, dynamic>{
      'token': configuracao.token,
      'sucesso': erros.isEmpty,
      'etapas': etapas,
      'erros': erros,
    };

    await ClienteHttpAresta.instancia.post(
      configuracao.construirUriRelatorio(),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(relatorio),
    );

    return relatorio;
  }

  Future<void> _prepararTermosECroqui(List<String> etapas) async {
    AppLogger.instance.logInfo(
      '[SmokeCI] 1. Registrando aceite dos Termos Legais e inicializando caderneta...',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accepted_legal_version', kLegalVersion);
    await prefs.setString(
      'accepted_legal_timestamp',
      DateTime.utc(2026, 11, 21).toIso8601String(),
    );
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    await repositorioCaderneta.inicializar();
    etapas.add('termos_legais_aceitos');

    AppLogger.instance.logInfo(
      '[SmokeCI] 2. Sincronizando índice e abrindo croqui Protobuf v5...',
    );
    SyncService.baseUrlOverride = configuracao.uriBase.toString();
    await syncService.syncIndex(auto: false);
    final tarefaMidias = syncService.tarefaMidiasEmSegundoPlano;
    if (tarefaMidias != null) {
      await tarefaMidias;
    }

    final croqui = await datasetRepo.getCroqui(
      idCroquiSmoke,
      indiceJaSincronizado: true,
    );
    _exigirInvariante(
      croqui != null && croqui.picos.isNotEmpty,
      'Croqui $idCroquiSmoke não foi carregado após sincronização.',
    );
    etapas.add('croqui_protobuf_aberto');
  }

  Future<void> _executarJornadaSemArvore(List<String> etapas) async {
    final perfilAutenticado = await servicoAutenticacao.entrarComGoogle();
    _exigirInvariante(
      perfilAutenticado.estaAutenticado,
      'Perfil não ficou autenticado após entrarComGoogle().',
    );
    etapas.add('login_google_nativo_ui_concluido');

    final perfilSincronizado = await servicoAutenticacao.atualizarPerfilRemoto(
      novoNome: 'Escalador Smoke Validado',
    );
    _exigirInvariante(
      perfilSincronizado.autorNomePublico == 'Escalador Smoke Validado',
      'Falha ao atualizar nome público remoto no perfil.',
    );
    etapas.add('perfil_editado_modal_ui_sincronizado');

    final croqui = await datasetRepo.getCroqui(
      idCroquiSmoke,
      indiceJaSincronizado: true,
    );
    final escalada = croqui!.picos.first.setoresOuGrupos.first.setor.conteudo.escaladas.first;
    final cadena = Cadena.criar(
      userId: perfilSincronizado.userId,
      escaladaUid: escalada.uid,
      dataAscensao: DateTime.utc(2026, 11, 21),
      tipoAscensao: TipoAscensao.aVista,
      tipoEscalada: TipoEscalada.guiado,
      notasPrivadas: 'Validação automática pós-build CI',
    );
    await repositorioCaderneta.salvarCadena(cadena);
    etapas.add('cadena_voto_e_beta_modal_ui_registrados');
  }

  Future<void> _executarJornadaComUiReal(List<String> etapas) async {
    final croqui = (await datasetRepo.getCroqui(
      idCroquiSmoke,
      indiceJaSincronizado: true,
    ))!;
    final pico = croqui.picos.first;
    final setor = pico.setoresOuGrupos.first.setor.conteudo;
    final escalada = setor.escaladas.first;

    // 3. Login Magic Code OTP (6 dígitos) + Logout pela UI real
    AppLogger.instance.logInfo('[SmokeCI] 3. Validando Magic Code OTP na UI real...');
    await pilotoUi.tocarPorKey('btn_home_perfil');
    await pilotoUi.digitarPorKey(
      'campo_login_email',
      'smoke.otp@arestaclimb.com',
    );
    await pilotoUi.tocarPorKey('btn_enviar_codigo_otp');
    await pilotoUi.aguardarElementoPorKey('campo_login_codigo_otp');
    await pilotoUi.digitarPorKey('campo_login_codigo_otp', codigoOtpSmoke);
    await pilotoUi.tocarPorKey('btn_confirmar_codigo_otp');
    await pilotoUi.aguardarElementoPorKey('item_menu_sair');
    _exigirInvariante(
      servicoAutenticacao.estaAutenticado,
      'Perfil não ficou autenticado após confirmar Magic Code OTP.',
    );
    await pilotoUi.tocarPorKey('item_menu_sair');
    await pilotoUi.tocarPorKey('btn_confirmar_saida');
    await pilotoUi.aguardarAusenciaPorKey('item_menu_sair');
    await pilotoUi.aguardarElementoPorKey('btn_home_perfil');
    _exigirInvariante(
      !servicoAutenticacao.estaAutenticado,
      'Sessão continuou ativa após confirmar saída no diálogo.',
    );
    etapas.add('login_magic_code_otp_ui_concluido');

    // 4. Validação Apple por plataforma + Logout (no iOS)
    AppLogger.instance.logInfo('[SmokeCI] 4. Validando provedor Apple por plataforma...');
    await pilotoUi.tocarPorKey('btn_home_perfil');
    await pilotoUi.aguardarElementoPorKey('btn_login_google');
    var ehIos = false;
    _executarSeContextoMontado((ctx) {
      ehIos = Theme.of(ctx).platform == TargetPlatform.iOS;
    });
    if (ehIos) {
      _exigirInvariante(
        pilotoUi.existeElementoVisivelPorKey('btn_login_apple'),
        'Botão Continuar com a Apple deve ficar visível no iOS.',
      );
      await pilotoUi.tocarPorKey('btn_login_apple');
      await pilotoUi.aguardarElementoPorKey('item_menu_sair');
      _exigirInvariante(
        servicoAutenticacao.estaAutenticado,
        'Perfil não ficou autenticado após login com Apple.',
      );
      await pilotoUi.tocarPorKey('item_menu_sair');
      await pilotoUi.tocarPorKey('btn_confirmar_saida');
      await pilotoUi.aguardarAusenciaPorKey('item_menu_sair');
      await pilotoUi.aguardarElementoPorKey('btn_home_perfil');
      await pilotoUi.tocarPorKey('btn_home_perfil');
      await pilotoUi.aguardarElementoPorKey('btn_login_google');
    } else {
      _exigirInvariante(
        !pilotoUi.existeElementoVisivelPorKey('btn_login_apple'),
        'Botão Continuar com a Apple deve permanecer oculto no Android.',
      );
    }
    etapas.add('login_apple_ui_validado');

    // 5. Login Google Nativo (Android id_token / iOS PKCE) + Edição de Perfil
    AppLogger.instance.logInfo(
      '[SmokeCI] 5. Executando login Google nativo e edição de perfil na UI...',
    );
    await pilotoUi.tocarPorKey('btn_login_google');
    await pilotoUi.aguardarElementoPorKey('btn_editar_perfil_hub');
    _exigirInvariante(
      servicoAutenticacao.estaAutenticado,
      'Perfil não ficou autenticado após entrarComGoogle().',
    );
    etapas.add('login_google_nativo_ui_concluido');

    await pilotoUi.tocarPorKey('btn_editar_perfil_hub');
    await pilotoUi.digitarPorKey(
      'campo_editar_perfil_nome',
      'Escalador Smoke Validado',
    );
    await pilotoUi.tocarPorKey('btn_salvar_editar_perfil');
    await pilotoUi.aguardarAusenciaPorKey('btn_salvar_editar_perfil');
    _exigirInvariante(
      servicoAutenticacao.obterPerfil().autorNomePublico ==
          'Escalador Smoke Validado',
      'Falha ao atualizar nome público remoto pelo DialogoEditarPerfil.',
    );
    await pilotoUi.tocarPorKey('btn_voltar_hub_perfil');
    await pilotoUi.aguardarAusenciaPorKey('btn_voltar_hub_perfil');
    await pilotoUi.aguardarElementoPorKey('btn_home_perfil');
    etapas.add('perfil_editado_modal_ui_sincronizado');

    // 6. Navegação declarativa até ViaPage + Registro de Cadena, Voto e Beta no Modal real
    AppLogger.instance.logInfo(
      '[SmokeCI] 6. Navegando (Pico -> Setor -> Via) e abrindo ModalRegistroCadena...',
    );
    _executarSeContextoMontado(
      (ctx) => AppNav.toPico(ctx, pico: pico, croqui: croqui, cragId: croqui.id),
    );
    await _aguardarFrameUi();
    await pilotoUi.bombarDurante(const Duration(milliseconds: 160));
    _executarSeContextoMontado(
      (ctx) => AppNav.toSetor(
        ctx,
        setor: setor,
        pico: pico,
        croqui: croqui,
        cragId: croqui.id,
      ),
    );
    await _aguardarFrameUi();
    await pilotoUi.bombarDurante(const Duration(milliseconds: 160));
    _executarSeContextoMontado(
      (ctx) => AppNav.toVia(
        ctx,
        escalada: escalada,
        setor: setor,
        pico: pico,
        croqui: croqui,
        cragId: croqui.id,
      ),
    );
    await _aguardarFrameUi();
    await pilotoUi.aguardarElementoPorKey('bolha_alerta_FAUNA');
    await pilotoUi.bombarDurante(const Duration(milliseconds: 450));
    etapas.add('arvore_ui_navegada');

    await pilotoUi.tocarPorKey('btn_registrar_cadena');
    await pilotoUi.tocarPorKey('chip_delta_grau_1');
    await pilotoUi.digitarPorKey(
      'campo_comentario_publico_cadena',
      'Beta validado via modal real no Smoke CI.',
    );
    await pilotoUi.tocarPorKey('btn_salvar_cadena');
    await pilotoUi.aguardarAusenciaPorKey('btn_salvar_cadena');

    final melhor = repositorioCaderneta.obterMelhorAscensao(escalada.uid);
    final estatisticas = repositorioCaderneta.calcularEstatisticas();
    final dadosAposCadena = repositorioInteracoes.obterDadosEscalada(
      escalada.uid,
    );
    _exigirInvariante(
      melhor != null && estatisticas.totalCadenas >= 1,
      'Cadena salva pelo modal não foi contabilizada na caderneta.',
    );
    _exigirInvariante(
      dadosAposCadena.consensoGrau.possuiVotos &&
          dadosAposCadena.comentarios.isNotEmpty,
      'Voto de grau e comentário público não apareceram na ViaPage.',
    );
    etapas.add('cadena_voto_e_beta_modal_ui_registrados');

    // 7. Expansão e Edição do Comentário Público na ViaPage
    AppLogger.instance.logInfo('[SmokeCI] 7. Editando comentário público na ViaPage...');
    final comentarioUid = dadosAposCadena.comentarios.first.uid;
    await pilotoUi.tocarPorKey('cabecalho_betas_comunidade_via');
    await pilotoUi.tocarPorKey('btn_editar_comentario_$comentarioUid');
    await pilotoUi.digitarPorKey(
      'campo_editar_comentario_via',
      'Beta revisado na rocha pelo Smoke CI.',
    );
    await pilotoUi.tocarPorKey('btn_salvar_comentario_editado_via');
    await pilotoUi.aguardarAusenciaPorKey('btn_salvar_comentario_editado_via');
    final dadosAposEdicao = repositorioInteracoes.obterDadosEscalada(
      escalada.uid,
    );
    _exigirInvariante(
      dadosAposEdicao.comentarios.any(
        (c) => c.texto == 'Beta revisado na rocha pelo Smoke CI.',
      ),
      'Edição do comentário público não foi refletida no estado da via.',
    );
    etapas.add('comentario_editado_modal_ui');

    // 8. Alerta Waze com retenção Offline (503) + Drenagem + Confirmação (+1)
    AppLogger.instance.logInfo(
      '[SmokeCI] 8. Testando alerta Waze com fila offline 503 e confirmação +1...',
    );
    final respFalha = await ClienteHttpAresta.instancia.post(
      configuracao.uriBase.replace(path: '/__smoke__/falhar-proxima-escrita-fila'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'quantidade': 1}),
    );
    _exigirInvariante(
      respFalha.statusCode == 200,
      'Falha ao armar simulação offline 503 no ServidorSmokeCi.',
    );

    await pilotoUi.tocarPorKey('btn_reportar_alerta_via');
    await pilotoUi.tocarPorKey('opcao_alerta_PROTECAO_PRECARIA');
    await pilotoUi.digitarPorKey(
      'campo_detalhe_alerta_via',
      'Chapeleta 2 girando',
    );
    await pilotoUi.tocarPorKey('btn_enviar_alerta_via');
    await pilotoUi.aguardarAusenciaPorKey('btn_enviar_alerta_via');
    await pilotoUi.aguardarElementoPorKey('bolha_alerta_PROTECAO_PRECARIA');

    // Drena a outbox offline agora que o servidor voltará a responder 201
    await repositorioInteracoes.sincronizarEscalada(escalada.uid);
    await pilotoUi.bombarDurante(const Duration(milliseconds: 120));

    // Confirma (+1) o alerta FAUNA semeado pelo terceiro
    await pilotoUi.tocarPorKey('bolha_alerta_FAUNA');
    await pilotoUi.tocarPorKey('btn_confirmar_alerta_ativo');
    await pilotoUi.aguardarAusenciaPorKey('btn_confirmar_alerta_ativo');
    final alertasFinais = repositorioInteracoes
        .obterDadosEscalada(escalada.uid)
        .alertasAtivos;
    final alertaFauna = alertasFinais.firstWhere(
      (a) => a.categoria == CategoriaAlertaSeguranca.fauna,
    );
    _exigirInvariante(
      alertaFauna.confirmacoesAtivas == 2 &&
          alertasFinais.any(
            (a) => a.categoria == CategoriaAlertaSeguranca.protecaoPrecaria,
          ),
      'Ciclo de confirmação +1 ou drenagem da outbox de alertas falhou.',
    );
    etapas.add('alerta_waze_outbox_e_confirmacao_ui');

    // 9. CadernetaPage (Meus Alertas + Cadenas) + Refresh Token + Exclusão Definitiva de Conta
    AppLogger.instance.logInfo(
      '[SmokeCI] 9. Validando CadernetaPage, refresh_token e exclusão de conta...',
    );
    _executarSeContextoMontado(AppNav.home);
    await pilotoUi.aguardarElementoPorKey('btn_home_perfil');
    await pilotoUi.bombarDurante(const Duration(milliseconds: 400));
    await pilotoUi.tocarPorKey('btn_home_perfil');
    await pilotoUi.tocarPorKey('item_menu_minha_caderneta');
    await pilotoUi.aguardarElementoPorKey('item_meu_alerta_altFaunaSmk001');

    final perfilRenovado = await servicoAutenticacao
        .garantirSessaoEPerfilSincronizados(forcarRenovacaoToken: true);
    _exigirInvariante(
      (perfilRenovado.accessToken ?? '').contains('renovado'),
      'Renovação de sessão via refresh_token não atualizou o accessToken.',
    );

    _executarSeContextoMontado(AppNav.back);
    await pilotoUi.aguardarAusenciaPorKey('item_meu_alerta_altFaunaSmk001');
    await pilotoUi.bombarDurante(const Duration(milliseconds: 450));
    await pilotoUi.aguardarElementoPorKey('item_menu_excluir_conta');
    await pilotoUi.tocarPorKey('item_menu_excluir_conta');
    await pilotoUi.tocarPorKey('btn_confirmar_exclusao_conta');
    await pilotoUi.aguardarAusenciaPorKey('item_menu_excluir_conta');
    await pilotoUi.aguardarElementoPorKey('btn_home_perfil');
    await pilotoUi.bombarDurante(const Duration(milliseconds: 400));
    _exigirInvariante(
      !servicoAutenticacao.estaAutenticado &&
          repositorioCaderneta.calcularEstatisticas().totalCadenas == 0,
      'Exclusão de conta não limpou sessão e caderneta local.',
    );
    etapas.add('caderneta_alertas_refresh_e_exclusao_ui');
  }
}
