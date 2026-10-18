// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../services/repositorio_dataset.dart';
import '../services/firebase/telemetria.dart';
import 'analisador_rotas_deep_link.dart';
import 'arvore_navegacao.dart';
import 'localizador_destino_uid.dart';

/// Serviço responsável por interceptar, resolver e navegar para rotas profundas
/// acionadas via Deep Links (`https://aresta.cc/...` e placas físicas legadas) ou leitura de QR Codes.
class DeepLinkNavigatorService {
  final DatasetRepository datasetRepo;
  final TreeNavigationController treeController;
  final TelemetryService telemetryService;
  final LocalizadorDestinoUid localizadorUid;

  /// Callback para emissão de mensagens de aviso/erro à interface (opcional).
  void Function(String mensagem)? onMensagemAviso;

  DeepLinkNavigatorService({
    required this.datasetRepo,
    required this.treeController,
    this.onMensagemAviso,
    TelemetryService? telemetryService,
    LocalizadorDestinoUid? localizadorUid,
  })  : telemetryService = telemetryService ?? TelemetryService.instance,
        localizadorUid =
            localizadorUid ?? LocalizadorDestinoUid(datasetRepo: datasetRepo);

  /// Processa uma URL ou Uri de deep link.
  ///
  /// Retorna `true` se o link foi processado e a navegação executada com sucesso,
  /// ou `false` caso o link seja inválido, o croqui não possa ser carregado ou o destino não exista.
  Future<bool> processarLink(
    dynamic link, {
    BuildContext? context,
    String? tipoStart,
  }) async {
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
      await telemetryService.logDeepLinkAberto(
        idCroqui: uid,
        destino: 'uid_desconhecido',
        sucesso: false,
        tipoStart: tipoStart,
        origemLink: rota.origemLink,
        abrirMapa: rota.abrirMapa,
        motivoErro: 'uid_nao_encontrado_no_acervo',
        parametrosUtm: parametrosUtm,
      );

      final mensagem =
          'Não foi possível encontrar a via ou setor correspondente ao código "$uid". Verifique sua conexão à internet ou baixe o pico previamente.';
      _notificarAviso(
        mensagem,
        context != null && context.mounted ? context : null,
      );
      return false;
    }

    treeController.navigateTo(destino.noNavegacao);
    await telemetryService.logDeepLinkAberto(
      idCroqui: destino.idCroqui,
      destino: destino.tipoDestino,
      sucesso: true,
      tipoStart: tipoStart,
      origemLink: rota.origemLink,
      abrirMapa: rota.abrirMapa,
      parametrosUtm: parametrosUtm,
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

