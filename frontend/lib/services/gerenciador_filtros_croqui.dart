// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../utils/filtro_grau_escalada.dart';

/// Gerenciador centralizado de estado dos filtros e ordenação por croqui.
///
/// Mantém as preferências de filtros do usuário (graus, modalidades ativas,
/// localização, conquistadores e ordenação) preservadas de forma global durante a
/// navegação em um croqui específico, sincronizando a visualização entre
/// a página principal de exploração de setores e as subpáginas de grupos.
class GerenciadorFiltrosCroqui extends ChangeNotifier {
  /// Instância singleton compartilhada na aplicação.
  static final GerenciadorFiltrosCroqui instance = GerenciadorFiltrosCroqui._();

  GerenciadorFiltrosCroqui._();

  /// Armazena o estado de filtros ativo para cada croqui, indexado pelo seu identificador (cragId).
  final Map<String, EstadoFiltrosUnificado> _filtrosPorCroqui = {};

  /// Obtém o estado de filtros ativo para o croqui indicado por [cragId].
  ///
  /// Se nenhum filtro foi definido previamente para este croqui, retorna
  /// um [EstadoFiltrosUnificado] padrão.
  EstadoFiltrosUnificado obterFiltros(String cragId) {
    return _filtrosPorCroqui[cragId] ?? const EstadoFiltrosUnificado();
  }

  /// Atualiza o estado de filtros associado ao croqui [cragId] e notifica os ouvintes.
  void atualizarFiltros(String cragId, EstadoFiltrosUnificado novoEstado) {
    _filtrosPorCroqui[cragId] = novoEstado;
    notifyListeners();
  }

  /// Reseta os filtros configurados para o croqui [cragId] e notifica os ouvintes.
  void limparFiltros(String cragId) {
    _filtrosPorCroqui.remove(cragId);
    notifyListeners();
  }

  /// Redefine todos os estados armazenados de todos os croquis.
  ///
  /// Útil principalmente em rotinas de testes unitários para garantir isolamento.
  @visibleForTesting
  void redefinir() {
    _filtrosPorCroqui.clear();
  }
}
