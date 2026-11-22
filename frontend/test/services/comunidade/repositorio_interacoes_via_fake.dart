// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:frontend/utils/calculadora_delta_grau.dart';
import 'package:frontend/utils/gerador_uid.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [RepositorioInteracoesVia].
///
/// Permite semear consensos de grau, comentários comunitários e alertas ativos de segurança,
/// além de inspecionar sincronizações e simular falhas determinísticas sem frameworks de mock.
class RepositorioInteracoesViaFake implements RepositorioInteracoesVia {
  final Map<String, DadosComunidadeVia> _dados = {};
  final Map<String, int> _votosUsuario = {};
  final List<AlertaContribuidoCaderneta> _meusAlertas = [];
  final ValueNotifier<int> _versao = ValueNotifier<int>(0);

  /// Lista de `escaladaUid` sincronizados via [sincronizarEscalada].
  final List<String> escaladasSincronizadas = [];

  /// Indica se o usuário simulado está autenticado para votar e interagir com alertas.
  bool autenticadoSimulado = true;

  /// Identificador NanoID 14c do perfil simulado atual.
  String autorIdSimulado = 'c3Lk9P1x4Vw8Mn';

  /// Quantidade de sincronizações de alertas da Caderneta disparadas.
  int sincronizacoesMeusAlertas = 0;

  /// Quando preenchido, faz com que operações mutáveis e de sincronização lancem este erro.
  Object? erroSimulado;

  @override
  ValueListenable<int> get alteracoesListenable => _versao;

  @override
  bool get usuarioEstaAutenticado => autenticadoSimulado;

  @override
  String get autorIdPublicoAtual => autorIdSimulado;

  @override
  int? obterDeltaVotoUsuario(String escaladaUid) => _votosUsuario[escaladaUid];

  /// Semeia de forma síncrona e determinística o estado comunitário de [escaladaUid].
  void semearDados(String escaladaUid, DadosComunidadeVia dados) {
    _dados[escaladaUid] = dados;
    _versao.value++;
  }

  /// Semeia a lista de alertas criados ou confirmados pelo usuário na Caderneta.
  void semearMeusAlertas(Iterable<AlertaContribuidoCaderneta> itens) {
    _meusAlertas
      ..clear()
      ..addAll(itens);
    _versao.value++;
  }

  @override
  List<AlertaContribuidoCaderneta> obterMeusAlertasContribuidos() =>
      List.unmodifiable(_meusAlertas);

  @override
  Future<void> sincronizarMeusAlertasContribuidos() async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    sincronizacoesMeusAlertas++;
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
  Future<void> sincronizarEscaladasEmLote(
    Iterable<String> escaladaUids,
  ) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    escaladasSincronizadas.addAll(escaladaUids);
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
    final atual = obterDadosEscalada(escaladaUid);
    final dist = Map<int, int>.from(atual.consensoGrau.distribuicaoDeltas);
    final votoAnterior = _votosUsuario[escaladaUid];
    if (votoAnterior != null && (dist[votoAnterior] ?? 0) > 0) {
      dist[votoAnterior] = dist[votoAnterior]! - 1;
    }
    dist[deltaGrau] = (dist[deltaGrau] ?? 0) + 1;
    _votosUsuario[escaladaUid] = deltaGrau;
    final total = votoAnterior != null
        ? atual.consensoGrau.totalVotos
        : atual.consensoGrau.totalVotos + 1;
    final codEfetivo =
        grauSugerido ??
        deslocarCodigoGrau(codigoGrauOficial, deltaGrau, ehBoulder: ehBoulder);
    final textoGrau =
        formatarGrauPorCodigo(codEfetivo, ehBoulder: ehBoulder) ??
        atual.consensoGrau.grauSugerido ??
        '—';

    final comentarios = List<ComentarioComunidadeVia>.from(atual.comentarios);
    final comentarioLimpo = comentarioPublico?.trim();
    if (comentarioLimpo != null && comentarioLimpo.isNotEmpty) {
      comentarios.insert(
        0,
        ComentarioComunidadeVia(
          uid: gerarUid(),
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Escalador Teste',
          criadoEm: DateTime.now().toUtc(),
          estiloAscensao: estiloAscensao,
          texto: comentarioLimpo,
        ),
      );
    }

    _dados[escaladaUid] = atual.copyWith(
      consensoGrau: ConsensoGrauVia(
        grauSugerido: textoGrau,
        totalVotos: total,
        distribuicaoDeltas: Map.unmodifiable(dist),
      ),
      comentarios: List.unmodifiable(comentarios),
    );
    _versao.value++;
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
      autorIdPublico: autorIdSimulado,
      autorNomePublico: 'Escalador Teste',
    );
    _dados[escaladaUid] = atual.copyWith(
      alertasAtivos: List.unmodifiable([novo, ...atual.alertasAtivos]),
    );
    _meusAlertas.insert(
      0,
      AlertaContribuidoCaderneta(
        alerta: novo,
        papel: PapelContribuicaoAlerta.criadoPorMim,
        ativo: true,
        ultimaInteracaoEm: novo.criadoEm,
      ),
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
        final existente = lista[idx];
        if (existente.jaConfirmadoPor(autorIdSimulado)) return;
        final atualizado = existente.copyWith(
          confirmacoesAtivas: existente.confirmacoesAtivas + 1,
          confirmadoresUids: {...existente.confirmadoresUids, autorIdSimulado},
        );
        lista[idx] = atualizado;
        _meusAlertas.insert(
          0,
          AlertaContribuidoCaderneta(
            alerta: atualizado,
            papel: PapelContribuicaoAlerta.confirmadoPorMim,
            ativo: true,
            ultimaInteracaoEm: DateTime.now().toUtc(),
          ),
        );
      } else {
        final removido = lista.removeAt(idx);
        final idxMeu = _meusAlertas.indexWhere(
          (m) => m.alerta.uid == removido.uid,
        );
        if (idxMeu >= 0) {
          _meusAlertas[idxMeu] = AlertaContribuidoCaderneta(
            alerta: removido,
            papel: _meusAlertas[idxMeu].papel,
            ativo: false,
            ultimaInteracaoEm: DateTime.now().toUtc(),
          );
        }
      }
      _dados[escaladaUid] = atual.copyWith(
        alertasAtivos: List.unmodifiable(lista),
      );
      _versao.value++;
    }
  }
}
