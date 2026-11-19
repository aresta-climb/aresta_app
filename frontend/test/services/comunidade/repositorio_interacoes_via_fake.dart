// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [RepositorioInteracoesVia].
///
/// Permite semear consensos de grau, comentários comunitários e alertas ativos de segurança,
/// além de inspecionar sincronizações e simular falhas determinísticas sem frameworks de mock.
class RepositorioInteracoesViaFake implements RepositorioInteracoesVia {
  final Map<String, DadosComunidadeVia> _dados = {};
  final ValueNotifier<int> _versao = ValueNotifier<int>(0);

  /// Lista de `escaladaUid` sincronizados via [sincronizarEscalada].
  final List<String> escaladasSincronizadas = [];

  /// Quando preenchido, faz com que operações mutáveis e de sincronização lancem este erro.
  Object? erroSimulado;

  @override
  ValueListenable<int> get alteracoesListenable => _versao;

  /// Semeia de forma síncrona e determinística o estado comunitário de [escaladaUid].
  void semearDados(String escaladaUid, DadosComunidadeVia dados) {
    _dados[escaladaUid] = dados;
    _versao.value++;
  }

  @override
  DadosComunidadeVia obterDadosEscalada(String escaladaUid) {
    return _dados[escaladaUid] ?? const DadosComunidadeVia.vazio();
  }

  @override
  Future<void> sincronizarEscalada(
    String escaladaUid, {
    int? codigoGrauOficial,
    bool ehBoulder = false,
  }) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    escaladasSincronizadas.add(escaladaUid);
  }

  @override
  Future<void> registrarAvaliacaoAscensao({
    required String escaladaUid,
    required int deltaGrau,
    int? codigoGrauOficial,
    int? grauSugerido,
    bool ehBoulder = false,
    TipoAscensao? estiloAscensao,
    String? comentarioPublico,
  }) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
  }

  @override
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  }) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    final atual = obterDadosEscalada(escaladaUid);
    final novo = AlertaSegurancaVia.criar(
      escaladaUid: escaladaUid,
      categoria: categoria,
      detalhe: detalhe,
      autorNomePublico: 'Escalador Teste',
    );
    _dados[escaladaUid] = atual.copyWith(
      alertasAtivos: List.unmodifiable([novo, ...atual.alertasAtivos]),
    );
    _versao.value++;
    return novo;
  }

  @override
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  }) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    final atual = obterDadosEscalada(escaladaUid);
    final lista = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final idx = lista.indexWhere((a) => a.uid == alertaUid);
    if (idx >= 0) {
      if (aindaEstaLa) {
        lista[idx] = lista[idx].copyWith(
          confirmacoesAtivas: lista[idx].confirmacoesAtivas + 1,
        );
      } else {
        lista.removeAt(idx);
      }
      _dados[escaladaUid] = atual.copyWith(
        alertasAtivos: List.unmodifiable(lista),
      );
      _versao.value++;
    }
  }
}
