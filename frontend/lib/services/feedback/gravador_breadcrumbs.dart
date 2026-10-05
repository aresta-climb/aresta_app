// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Serviço responsável por registrar e manter um buffer circular em memória com as últimas
/// ações e eventos de telemetria disparados pelo usuário no aplicativo.
///
/// Este histórico (breadcrumbs) é anexado aos relatórios de diagnóstico de feedback no Supabase
/// para auxiliar na reprodução de comportamentos anômalos e bugs relatados pela comunidade.
class GravadorBreadcrumbs {
  /// Capacidade padrão de armazenamento em memória (últimas 50 ações).
  static const int capacidadePadrao = 50;

  /// Limite máximo de entradas retidas no buffer circular.
  final int capacidadeMaxima;

  /// Fila interna FIFO para armazenamento dos eventos.
  final ListQueue<Map<String, dynamic>> _breadcrumbs = ListQueue<Map<String, dynamic>>();

  /// Instância singleton utilizada pelo aplicativo.
  static GravadorBreadcrumbs instance = GravadorBreadcrumbs();

  /// Cria uma nova instância do gravador com a capacidade máxima especificada.
  GravadorBreadcrumbs({this.capacidadeMaxima = capacidadePadrao});

  /// Redefine a instância singleton para isolamento em testes unitários.
  @visibleForTesting
  static void resetForTesting() {
    instance = GravadorBreadcrumbs();
  }

  /// Quantidade total de eventos atualmente retidos no buffer.
  int get total => _breadcrumbs.length;

  /// Registra uma nova ação ou evento no buffer circular.
  ///
  /// Caso a quantidade de eventos atinja [capacidadeMaxima], o registro mais antigo
  /// é automaticamente descartado para abrir espaço para o mais recente (FIFO).
  void registrar({
    required String evento,
    Map<String, dynamic>? parametros,
    DateTime? timestamp,
  }) {
    final momento = timestamp ?? DateTime.now();

    final entrada = <String, dynamic>{
      'timestamp': momento.toIso8601String(),
      'evento': evento,
      'parametros': parametros != null ? Map<String, dynamic>.from(parametros) : <String, dynamic>{},
    };

    if (_breadcrumbs.length >= capacidadeMaxima) {
      _breadcrumbs.removeFirst();
    }

    _breadcrumbs.addLast(entrada);
  }

  /// Retorna uma lista imutável com todos os eventos retidos, em ordem cronológica.
  List<Map<String, dynamic>> obterBreadcrumbs() {
    return List<Map<String, dynamic>>.unmodifiable(_breadcrumbs);
  }

  /// Remove todos os registros acumulados no buffer.
  void limpar() {
    _breadcrumbs.clear();
  }
}
