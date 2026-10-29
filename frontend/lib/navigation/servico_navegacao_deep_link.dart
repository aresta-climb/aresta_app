// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/editor_croqui.dart';
import '../services/firebase/performance_telemetria.dart';
import '../services/firebase/telemetria.dart';
import '../services/http/cliente_http_aresta.dart';
import '../services/http/servico_download_segundo_plano.dart';
import '../services/http/sync_service.dart';
import '../services/repositorio_dataset.dart';
import 'analisador_rotas_deep_link.dart';
import 'arvore_navegacao.dart';
import 'localizador_destino_uid.dart';

/// Serviço responsável por interceptar, resolver e navegar para rotas profundas
/// acionadas via Deep Links (`https://aresta.cc/...`, `https://previa.arestaclimb.com/...` e placas físicas legadas) ou leitura de QR Codes.
class DeepLinkNavigatorService {
  final DatasetRepository datasetRepo;
  final TreeNavigationController treeController;
  final TelemetryService telemetryService;
  final LocalizadorDestinoUid localizadorUid;

  /// Callback opcional para conexão com sessão de prévia/PR (retorna o `id` do croqui único, `''` para múltiplos ou `null` em caso de falha).
  final Future<String?> Function(String codigo)? conectorSessaoPrevia;

  /// Callback opcional para abertura de URL em navegador externo (ex: `/resumo/pr*`).
  final Future<bool> Function(Uri uri)? abridorUrlExterna;

  /// Callback para emissão de mensagens de aviso/erro à interface (opcional).
  void Function(String mensagem)? onMensagemAviso;

  DeepLinkNavigatorService({
    required this.datasetRepo,
    required this.treeController,
    this.onMensagemAviso,
    TelemetryService? telemetryService,
    LocalizadorDestinoUid? localizadorUid,
    this.conectorSessaoPrevia,
    this.abridorUrlExterna,
  })  : telemetryService = telemetryService ?? TelemetryService.instance,
        localizadorUid =
            localizadorUid ?? LocalizadorDestinoUid(datasetRepo: datasetRepo);

  static Uri? _converterParaUri(dynamic link) {
    if (link is Uri) return link;
    if (link is String) {
      final t = link.trim();
      if (t.isEmpty) return null;
      return Uri.tryParse(t.contains('://') ? t : 'https://$t');
    }
    return null;
  }

  Future<String?> _conectarSessaoPreviaPadrao(String codigo) async {
    try {
      final editor = datasetRepo.editorDeCroqui;
      final urlResolvida = await editor.resolverUrlHibrida(codigo);
      final httpClient = ClienteHttpAresta.instancia;
      final response = await httpClient
          .get(Uri.parse('$urlResolvida/indice.binarypb'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      await editor.activateExperimental(url: urlResolvida);
      final servicoSync = SyncService(
        datasetRepository: datasetRepo,
        client: httpClient,
      );
      await servicoSync.syncIndex(auto: false, forceBypassCache: true);
      await datasetRepo.init();

      final croquis = datasetRepo.indiceData.value?.croquis ?? [];
      if (croquis.length == 1) {
        final resumo = croquis.first;
        try {
          await ServicoDownloadSegundoPlano(syncService: servicoSync)
              .executarDownload(resumo);
          await datasetRepo.init();
        } catch (_) {}
        return resumo.id;
      }
      return '';
    } catch (_) {
      return null;
    }
  }

  /// Processa uma URL ou Uri de deep link.
  ///
  /// Retorna `true` se o link foi processado e a navegação executada com sucesso,
  /// ou `false` caso o link seja inválido, o croqui não possa ser carregado ou o destino não exista.
  Future<bool> processarLink(
    dynamic link, {
    BuildContext? context,
    String? tipoStart,
  }) async {
    final uri = _converterParaUri(link);
    if (uri != null &&
        uri.host.toLowerCase() == EditorDeCroqui.dominioPrevia &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first.toLowerCase() == 'resumo') {
      final abridor = abridorUrlExterna ??
          ((u) => launchUrl(u, mode: LaunchMode.externalApplication));
      await abridor(uri);
      return false;
    }

    final codigoPrevia = EditorDeCroqui.extrairCodigoPreviaDeLink(link);
    if (codigoPrevia != null) {
      final conector = conectorSessaoPrevia ?? _conectarSessaoPreviaPadrao;
      final idCroqui = await conector(codigoPrevia);
      if (idCroqui == null) {
        final msg =
            'Não foi possível conectar à sessão de prévia "${EditorDeCroqui.formatarCodigo(codigoPrevia)}".';
        _notificarAviso(
          msg,
          context != null && context.mounted ? context : null,
        );
        return false;
      }
      if (idCroqui.isNotEmpty) {
        treeController.navigateTo(
          PicoNode(cragId: idCroqui, parent: const HomeNode()),
        );
      } else {
        treeController.navigateTo(const BrowseNode(HomeNode()));
      }
      return true;
    }

    final cronometro = Stopwatch()..start();
    final rota = DeepLinkRouteParser.parse(link);
    if (rota == null) {
      return false;
    }

    final parametrosUtm = rota.parametros.isEmpty ? null : rota.parametros;
    final uid = rota.uid;
    final destino = await localizadorUid.localizar(
      uid,
      abrirMapa: rota.abrirMapa,
    );

    if (destino == null) {
      cronometro.stop();
      final int duracaoErroMs = (tipoStart == 'cold_start' &&
              ServicoPerformance.instancia.obterElapsedMsColdStart() > 0)
          ? ServicoPerformance.instancia.obterElapsedMsColdStart()
          : cronometro.elapsedMilliseconds;
      await ServicoPerformance.instancia.registrarAberturaDeepLink(
        idCroqui: uid,
        destino: 'uid_desconhecido',
        sucesso: false,
        tipoStart: tipoStart ?? 'warm_start',
        duracaoMs: duracaoErroMs,
        origemLink: rota.origemLink,
        abrirMapa: rota.abrirMapa,
        motivoErro: 'uid_nao_encontrado_no_acervo',
        parametrosUtm: parametrosUtm,
        servicoTelemetria: telemetryService,
      );

      final mensagem =
          'Não foi possível encontrar a via ou setor correspondente ao código "$uid". Verifique sua conexão à internet ou baixe o pico previamente.';
      _notificarAviso(
        mensagem,
        context != null && context.mounted ? context : null,
      );
      return false;
    }

    final String modoAcesso =
        datasetRepo.obterUltimaOrigemResolucao(destino.idCroqui) ??
            (datasetRepo.isPicoDownloaded(destino.idCroqui)
                ? 'offline'
                : 'memoria');

    treeController.navigateTo(destino.noNavegacao);
    await ServicoPerformance.instancia.concluirMedicaoPosFrame(
      cronometro,
      (duracaoLocalMs) async {
        final int duracaoFinalMs = (tipoStart == 'cold_start' &&
                ServicoPerformance.instancia.obterElapsedMsColdStart() > 0)
            ? ServicoPerformance.instancia.obterElapsedMsColdStart()
            : duracaoLocalMs;
        await ServicoPerformance.instancia.registrarAberturaDeepLink(
          idCroqui: destino.idCroqui,
          destino: destino.tipoDestino,
          sucesso: true,
          tipoStart: tipoStart ?? 'warm_start',
          duracaoMs: duracaoFinalMs,
          modoAcesso: modoAcesso,
          origemLink: rota.origemLink,
          abrirMapa: rota.abrirMapa,
          parametrosUtm: parametrosUtm,
          servicoTelemetria: telemetryService,
        );
      },
    );
    return true;
  }

  void _notificarAviso(String mensagem, BuildContext? context) {
    if (onMensagemAviso != null) {
      onMensagemAviso!(mensagem);
    } else if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
