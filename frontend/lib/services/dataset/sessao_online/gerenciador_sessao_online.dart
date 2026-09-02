// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../../aresta_api/proto/generated/croqui.pb.dart';

/// Gerencia o estado de picos abertos em modo online (sob demanda).
///
/// Mantém os croquis desserializados em memória e rastreia seus ETags
/// para validação leve de modificações remotas.
class GerenciadorSessaoOnline {
  final Map<String, Croqui> _croquisEmMemoria = {};
  final Map<String, String> _etagsEmMemoria = {};

  /// Notifica a interface sobre picos com atualizações remotas detectadas (picoId -> novoEtag).
  final ValueNotifier<Map<String, String>> atualizacoesPendentes = ValueNotifier({});

  /// Retorna uma visualização somente-leitura dos croquis atualmente carregados em memória.
  Map<String, Croqui> get croquisEmMemoria => Map.unmodifiable(_croquisEmMemoria);

  /// Recupera o [Croqui] ativo em sessão online pelo [picoId].
  Croqui? obterCroquiOnline(String picoId) {
    return _croquisEmMemoria[picoId];
  }

  /// Registra um [Croqui] em memória para acesso durante a sessão online.
  void registrarCroquiOnline(String picoId, Croqui croqui, {String? etag}) {
    _croquisEmMemoria[picoId] = croqui;
    if (etag != null && etag.isNotEmpty) {
      _etagsEmMemoria[picoId] = etag;
    }
  }

  /// Registra que uma nova versão foi detectada pelo polling de ETag.
  void registrarAtualizacaoPendente(String picoId, String novoEtag) {
    final mapa = Map<String, String>.from(atualizacoesPendentes.value);
    mapa[picoId] = novoEtag;
    atualizacoesPendentes.value = mapa;
  }

  /// Limpa o aviso de atualização pendente para um pico.
  void limparAtualizacaoPendente(String picoId) {
    if (!atualizacoesPendentes.value.containsKey(picoId)) return;
    final mapa = Map<String, String>.from(atualizacoesPendentes.value);
    mapa.remove(picoId);
    atualizacoesPendentes.value = mapa;
  }

  /// Obtém o ETag atualmente associado ao croqui online.
  String? obterEtag(String picoId) {
    return _etagsEmMemoria[picoId];
  }

  /// Remove a sessão online do pico indicado.
  void removerSessao(String picoId) {
    _croquisEmMemoria.remove(picoId);
    _etagsEmMemoria.remove(picoId);
    limparAtualizacaoPendente(picoId);
  }

  /// Limpa todas as sessões online em memória.
  void limparTudo() {
    _croquisEmMemoria.clear();
    _etagsEmMemoria.clear();
    atualizacoesPendentes.value = {};
  }
}
