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
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../navigation/wrapper_navegacao_arvore.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../controlador_interacoes_usuario.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';
import '../http/sync_service.dart';
import '../repositorio_dataset.dart';
import 'configuracao_smoke_ci.dart';

/// Executa a jornada de ponta a ponta do Smoke Test pós-build dentro do binário descartável de CI.
///
/// Valida em tempo de execução com minificação R8/Xcode e ofuscação Dart ativas:
/// 1. Persistência do aceite de Termos de Uso e inicialização da Caderneta Local;
/// 2. Sincronização do `indice.binarypb` e abertura de um `Croqui` Protobuf v5 via [DatasetRepository];
/// 3. Navegação declarativa real na árvore de UI (`Pico` → `Setor` → `Via` → `Home`);
/// 4. Autenticação Google OIDC pelo `MethodChannel` nativo + Supabase GoTrue + `public.perfis`;
/// 5. Registro de uma [Cadena] real, cálculo de estatísticas e renderização de Perfil/Caderneta;
/// 6. Entrega do relatório JSON autenticado ao orquestrador local via [ClienteHttpAresta.instancia].
class ExecutorJornadaSmoke {
  /// Identificador do croqui determinístico servido pelo micro-servidor local de CI.
  static const String idCroquiSmoke = 'serra_smoke_ci';

  final ConfiguracaoSmokeCi configuracao;
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final RepositorioCaderneta repositorioCaderneta;
  final ServicoAutenticacao servicoAutenticacao;
  final Future<void> Function() _aguardarFrameUi;

  ExecutorJornadaSmoke({
    required this.configuracao,
    required this.datasetRepo,
    required this.syncService,
    required this.repositorioCaderneta,
    required this.servicoAutenticacao,
    Future<void> Function()? aguardarFrameUi,
  }) : _aguardarFrameUi = aguardarFrameUi ?? _aguardarProximoFramePadrao;

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
      await ControladorInteracoesUsuario.instancia.inicializar();
      await ControladorInteracoesUsuario.instancia.definirInteracoesAtivas(true);
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
      final pico = croqui!.picos.first;
      final setor = pico.setoresOuGrupos.first.setor.conteudo;
      final escalada = setor.escaladas.first;
      etapas.add('croqui_protobuf_aberto');

      if (_executarSeContextoMontado(
        (ctx) => AppNav.toPico(ctx, pico: pico, croqui: croqui, cragId: croqui.id),
      )) {
        AppLogger.instance.logInfo(
          '[SmokeCI] 3. Navegando na árvore declarativa (Pico -> Setor -> Via)...',
        );
        await _aguardarFrameUi();
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
        _executarSeContextoMontado(AppNav.home);
        await _aguardarFrameUi();
        etapas.add('arvore_ui_navegada');
      }

      AppLogger.instance.logInfo(
        '[SmokeCI] 4. Executando login Google OIDC via canal nativo...',
      );
      final perfilAutenticado = await servicoAutenticacao.entrarComGoogle();
      _exigirInvariante(
        perfilAutenticado.estaAutenticado,
        'Perfil não ficou autenticado após entrarComGoogle().',
      );
      etapas.add('login_oidc_concluido');

      final perfilSincronizado = await servicoAutenticacao.atualizarPerfilRemoto(
        novoNome: 'Escalador Smoke Validado',
      );
      _exigirInvariante(
        perfilSincronizado.autorNomePublico == 'Escalador Smoke Validado',
        'Falha ao atualizar nome público remoto no perfil.',
      );
      etapas.add('perfil_remoto_sincronizado');

      AppLogger.instance.logInfo(
        '[SmokeCI] 5. Registrando Cadena e validando estatísticas da caderneta...',
      );
      final cadena = Cadena.criar(
        userId: perfilSincronizado.userId,
        escaladaUid: escalada.uid,
        dataAscensao: DateTime.utc(2026, 11, 21),
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.guiado,
        notasPrivadas: 'Validação automática pós-build CI',
      );
      await repositorioCaderneta.salvarCadena(cadena);
      final melhor = repositorioCaderneta.obterMelhorAscensao(escalada.uid);
      final estatisticas = repositorioCaderneta.calcularEstatisticas();
      _exigirInvariante(
        melhor?.id == cadena.id && estatisticas.totalCadenas >= 1,
        'Cadena salva não foi contabilizada nas estatísticas.',
      );
      etapas.add('cadena_registrada_e_contabilizada');

      if (_executarSeContextoMontado(AppNav.toPerfil)) {
        await _aguardarFrameUi();
        _executarSeContextoMontado(AppNav.toCaderneta);
        await _aguardarFrameUi();
        _executarSeContextoMontado(AppNav.home);
        await _aguardarFrameUi();
        etapas.add('caderneta_ui_renderizada');
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
}
