// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Gerenciador de persistência local responsável por identificar se a abertura
/// de um croqui representa a primeira visita do usuário naquele pico específico.
///
/// Utiliza [SharedPreferences] para armazenar a lista de IDs de croquis que já foram
/// abertos anteriormente neste dispositivo. Esse rastreamento alimenta a telemetria
/// do Firebase Analytics com o parâmetro `primeira_visita`, permitindo auditar
/// a aquisição de novos escaladores por croqui no Looker Studio.
class RegistroPrimeiraVisita {
  RegistroPrimeiraVisita._();

  /// Instância singleton principal do serviço.
  static RegistroPrimeiraVisita instancia = RegistroPrimeiraVisita._();

  /// Chave de armazenamento utilizada no [SharedPreferences].
  static const String chaveArmazenamento = 'croquis_visitados_historico';

  @visibleForTesting
  Future<SharedPreferences> Function()? obterPrefsOverride;

  @visibleForTesting
  static void resetForTesting() {
    instancia = RegistroPrimeiraVisita._();
  }

  /// Verifica se o [idCroqui] já foi visitado neste dispositivo.
  ///
  /// Caso ainda não tenha sido visitado, inclui o [idCroqui] na lista persistente,
  /// salva em [SharedPreferences] e retorna `true`.
  /// Se já constar no histórico, retorna `false`.
  Future<bool> registrarEVerificarPrimeiraVisita(String idCroqui) async {
    try {
      final prefs = obterPrefsOverride != null
          ? await obterPrefsOverride!()
          : await SharedPreferences.getInstance();
      final visitados = prefs.getStringList(chaveArmazenamento) ?? <String>[];
      if (visitados.contains(idCroqui)) {
        return false;
      }
      visitados.add(idCroqui);
      await prefs.setStringList(chaveArmazenamento, visitados);
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '⚠️ [RegistroPrimeiraVisita] Erro ao registrar visita ao croqui $idCroqui',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Consulta se o [idCroqui] já foi visitado sem registrar ou alterar o estado persistido.
  Future<bool> jaVisitou(String idCroqui) async {
    try {
      final prefs = obterPrefsOverride != null
          ? await obterPrefsOverride!()
          : await SharedPreferences.getInstance();
      final visitados = prefs.getStringList(chaveArmazenamento) ?? <String>[];
      return visitados.contains(idCroqui);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '⚠️ [RegistroPrimeiraVisita] Erro ao consultar visita ao croqui $idCroqui',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
