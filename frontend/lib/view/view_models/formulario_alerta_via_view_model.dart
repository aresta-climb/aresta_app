// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/interacao_via.dart';

/// ViewModel (MVVM) que encapsula o estado e a normalização do formulário rápido de alerta
/// de segurança estilo Waze na `ViaPage`, além da formatação textual de alertas ativos para Dumb UI.
class FormularioAlertaViaViewModel extends ChangeNotifier {
  CategoriaAlertaSeguranca _categoriaSelecionada;
  String _detalhe = '';

  /// Cria uma instância de [FormularioAlertaViaViewModel].
  FormularioAlertaViaViewModel({
    CategoriaAlertaSeguranca categoriaInicial =
        CategoriaAlertaSeguranca.fauna,
  }) : _categoriaSelecionada = categoriaInicial;

  /// Lista imutável de categorias disponíveis para seleção visual.
  List<CategoriaAlertaSeguranca> get opcoesCategorias =>
      CategoriaAlertaSeguranca.values;

  /// Categoria de risco atualmente selecionada.
  CategoriaAlertaSeguranca get categoriaSelecionada => _categoriaSelecionada;

  /// Descrição curta contextual da categoria selecionada.
  String get descricaoCategoriaSelecionada =>
      _categoriaSelecionada.descricaoCurta;

  /// Texto bruto digitado no campo opcional de detalhe.
  String get detalhe => _detalhe;

  /// Detalhe normalizado (`trim()`), retornando `null` quando não informado.
  String? get detalheNormalizado {
    final limpo = _detalhe.trim();
    return limpo.isNotEmpty ? limpo : null;
  }

  /// Seleciona uma nova [categoria] de alerta e notifica ouvintes se houver mudança.
  void selecionarCategoria(CategoriaAlertaSeguranca categoria) {
    if (_categoriaSelecionada == categoria) return;
    _categoriaSelecionada = categoria;
    notifyListeners();
  }

  /// Atualiza o detalhe opcional respeitando [AlertaSegurancaVia.limiteCaracteresDetalhe].
  void definirDetalhe(String valor) {
    const limite = AlertaSegurancaVia.limiteCaracteresDetalhe;
    _detalhe = valor.length > limite ? valor.substring(0, limite) : valor;
  }

  /// Executa [aoReportar] com a categoria selecionada e o [detalheNormalizado].
  Future<void> submeter(
    Future<void> Function(
      CategoriaAlertaSeguranca categoria,
      String? detalhe,
    ) aoReportar,
  ) {
    return aoReportar(_categoriaSelecionada, detalheNormalizado);
  }

  /// Formata o subtítulo de autoria, data curta e confirmações do modal *"Ainda está lá?"*.
  static String formatarSubtituloConfirmacao(AlertaSegurancaVia alerta) {
    final dia = alerta.criadoEm.day.toString().padLeft(2, '0');
    final mes = alerta.criadoEm.month.toString().padLeft(2, '0');
    return 'Reportado por ${alerta.autorNomePublico} em $dia/$mes • '
        '${alerta.confirmacoesAtivas}x confirmado';
  }

  /// Formata o detalhe opcional do alerta entre aspas tipográficas, ou `null` quando ausente.
  static String? formatarCitacaoDetalhe(AlertaSegurancaVia alerta) {
    final detalhe = alerta.detalhe;
    if (detalhe == null || detalhe.trim().isEmpty) return null;
    return '“${detalhe.trim()}”';
  }
}
