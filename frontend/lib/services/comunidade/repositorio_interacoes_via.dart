// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/item_fila_interacao.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../utils/calculadora_delta_grau.dart';
import '../../utils/gerador_uid.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import 'cliente_fila_interacoes_supabase.dart';

/// Contrato reativo da camada de dados comunitários e alertas de segurança estilo Waze por via.
///
/// Une leitura/escrita em memória de resposta instantânea (`0ms`) na `ViaPage` com
/// sincronização PostgREST (`public.fila_interacoes`) e fila local offline (*outbox*).
abstract interface class RepositorioInteracoesVia {
  /// Notificador que incrementa sempre que alertas, votos ou comentários sofrem alteração.
  ValueListenable<int> get alteracoesListenable;

  /// Retorna o agregado comunitário atual ([DadosComunidadeVia]) para [escaladaUid].
  DadosComunidadeVia obterDadosEscalada(String escaladaUid);

  /// Drena interações offline pendentes e sincroniza o estado ativo de [escaladaUid] com o Supabase.
  Future<void> sincronizarEscalada(
    String escaladaUid, {
    int? codigoGrauOficial,
    bool ehBoulder = false,
  });

  /// Registra a avaliação de grau (`-2` a `+2`) e eventual dica pública submetida junto a uma ascensão.
  Future<void> registrarAvaliacaoAscensao({
    required String escaladaUid,
    required int deltaGrau,
    int? codigoGrauOficial,
    int? grauSugerido,
    bool ehBoulder = false,
    TipoAscensao? estiloAscensao,
    String? comentarioPublico,
  });

  /// Registra um novo alerta de segurança na via (ou reforça alerta ativo da mesma categoria).
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  });

  /// Registra a resposta do escalador à pergunta *"Ainda está lá?"* sobre [alertaUid].
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  });
}

/// Implementação reativa local-first de [RepositorioInteracoesVia] integrada ao Supabase e fila offline.
class RepositorioInteracoesViaMemoria implements RepositorioInteracoesVia {
  /// Chave usada no `SharedPreferences` para persistir a fila de envio offline (*outbox*).
  static const String chaveFilaPendente = 'fila_pendente_interacoes_via_v1';

  static RepositorioInteracoesVia? _instanciaCompartilhada;

  /// Instância singleton padrão conectada ao [ClienteFilaInteracoesSupabase].
  static RepositorioInteracoesVia get instancia =>
      _instanciaCompartilhada ??= RepositorioInteracoesViaMemoria(
        clienteFila: ClienteFilaInteracoesSupabase(),
      );

  /// Permite injetar instância substituta em testes de integração.
  @visibleForTesting
  static set instancia(RepositorioInteracoesVia? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Restaura a instância compartilhada para o estado inicial entre testes.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  final RepositorioCaderneta _repositorioCaderneta;
  final ClienteFilaInteracoes? _clienteFila;
  SharedPreferences? _preferencias;
  bool _filaCarregada = false;

  final Map<String, DadosComunidadeVia> _dadosPorEscalada = {};
  final Map<String, List<({int? deltaGrau, int? grauSugerido})>> _votosLocais =
      {};
  final List<ItemFilaInteracao> _filaPendente = [];
  final ValueNotifier<int> _versaoNotifier = ValueNotifier<int>(0);

  /// Cria uma instância de [RepositorioInteracoesViaMemoria].
  RepositorioInteracoesViaMemoria({
    RepositorioCaderneta? repositorioCaderneta,
    ClienteFilaInteracoes? clienteFila,
    SharedPreferences? preferencias,
  }) : _repositorioCaderneta =
           repositorioCaderneta ?? RepositorioCadernetaLocal.instancia,
       _clienteFila = clienteFila,
       _preferencias = preferencias;

  @override
  ValueListenable<int> get alteracoesListenable => _versaoNotifier;

  @override
  DadosComunidadeVia obterDadosEscalada(String escaladaUid) {
    return _dadosPorEscalada[escaladaUid] ?? const DadosComunidadeVia.vazio();
  }

  @override
  Future<void> sincronizarEscalada(
    String escaladaUid, {
    int? codigoGrauOficial,
    bool ehBoulder = false,
  }) async {
    final uidVia = escaladaUid.trim();
    final cliente = _clienteFila;
    if (cliente == null || !validarUid(uidVia)) {
      return;
    }

    await _carregarFilaPendenteSeNecessario();
    final perfil = _repositorioCaderneta.obterPerfil();
    await _drenarFilaPendente(cliente, accessToken: perfil.accessToken);

    try {
      final remotos = await cliente.buscarInteracoesPendentes(uidVia);
      final pendentesVia = _filaPendente.where((i) => i.escaladaUid == uidVia);
      _dadosPorEscalada[uidVia] = consolidarItensFilaEmDadosComunidade(
        [...remotos, ...pendentesVia],
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
      );
      _versaoNotifier.value++;
    } catch (e, stackTrace) {
      _registrarFalhaRede(
        'Falha ao consultar fila_interacoes para $uidVia',
        e,
        stackTrace,
      );
    }
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
    final uidVia = escaladaUid.trim();
    if (uidVia.isEmpty) {
      throw ArgumentError.value(
        escaladaUid,
        'escaladaUid',
        'O identificador da escalada não pode ser vazio ao registrar avaliação.',
      );
    }
    if (deltaGrau < -2 || deltaGrau > 2) {
      throw ArgumentError.value(
        deltaGrau,
        'deltaGrau',
        'O delta de grau deve estar entre -2 e +2.',
      );
    }

    final perfil = _repositorioCaderneta.obterPerfil();
    final codEfetivo =
        grauSugerido ??
        deslocarCodigoGrau(codigoGrauOficial, deltaGrau, ehBoulder: ehBoulder);

    final atual = obterDadosEscalada(uidVia);
    final votos = List<({int? deltaGrau, int? grauSugerido})>.from(
      _votosLocais[uidVia] ?? const [],
    );
    if (votos.isEmpty && atual.consensoGrau.possuiVotos) {
      atual.consensoGrau.distribuicaoDeltas.forEach((delta, qtd) {
        for (var i = 0; i < qtd; i++) {
          votos.add((
            deltaGrau: delta,
            grauSugerido: deslocarCodigoGrau(
              codigoGrauOficial,
              delta,
              ehBoulder: ehBoulder,
            ),
          ));
        }
      });
    }
    votos.add((deltaGrau: deltaGrau, grauSugerido: codEfetivo));
    _votosLocais[uidVia] = votos;

    final comentarios = List<ComentarioComunidadeVia>.from(atual.comentarios);
    final textoLimpo = comentarioPublico?.trim();
    ComentarioComunidadeVia? novoComentario;
    if (textoLimpo != null && textoLimpo.isNotEmpty) {
      novoComentario = ComentarioComunidadeVia(
        uid: gerarUid(),
        autorIdPublico: perfil.autorIdPublico,
        autorNomePublico: perfil.autorNomePublico,
        criadoEm: DateTime.now().toUtc(),
        estiloAscensao: estiloAscensao,
        texto: textoLimpo,
      );
      comentarios.insert(0, novoComentario);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      consensoGrau: consolidarConsensoDeVotos(
        votos: votos,
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
      ),
      comentarios: List.unmodifiable(comentarios),
    );
    _versaoNotifier.value++;

    if (_clienteFila != null &&
        perfil.estaAutenticado &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico)) {
      final itensParaEnviar = <ItemFilaInteracao>[
        ItemFilaInteracao.votoGrau(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          deltaGrau: deltaGrau,
          grauSugerido: codEfetivo,
          tipoAscensao: estiloAscensao,
        ),
        if (novoComentario != null)
          ItemFilaInteracao.comentario(
            id: novoComentario.uid,
            autorIdPublico: perfil.autorIdPublico,
            autorNomePublico: perfil.autorNomePublico,
            escaladaUid: uidVia,
            textoComentario: novoComentario.texto,
            tipoAscensao: estiloAscensao,
            criadoEm: novoComentario.criadoEm,
          ),
      ];
      await _enfileirarEDespachar(
        itensParaEnviar,
        accessToken: perfil.accessToken,
      );
    }
  }

  @override
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  }) async {
    final uidVia = escaladaUid.trim();
    if (uidVia.isEmpty) {
      throw ArgumentError.value(
        escaladaUid,
        'escaladaUid',
        'O identificador da escalada não pode ser vazio ao reportar um alerta.',
      );
    }

    final perfil = _repositorioCaderneta.obterPerfil();
    final atual = obterDadosEscalada(uidVia);
    final alertas = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final indiceExistente = alertas.indexWhere((a) => a.categoria == categoria);

    final AlertaSegurancaVia resultado;
    if (indiceExistente >= 0) {
      final anterior = alertas[indiceExistente];
      final detalheLimpo = detalhe?.trim();
      resultado = anterior.copyWith(
        confirmacoesAtivas: anterior.confirmacoesAtivas + 1,
        detalhe: (detalheLimpo != null && detalheLimpo.isNotEmpty)
            ? detalheLimpo
            : anterior.detalhe,
      );
      alertas[indiceExistente] = resultado;
    } else {
      resultado = AlertaSegurancaVia.criar(
        escaladaUid: uidVia,
        categoria: categoria,
        detalhe: detalhe,
        autorNomePublico: perfil.autorNomePublico,
      );
      alertas.insert(0, resultado);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    _versaoNotifier.value++;

    if (_clienteFila != null &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(resultado.uid)) {
      await _enfileirarEDespachar([
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: resultado.uid,
          categoriaAlerta: categoria,
          detalhe: detalhe,
        ),
      ], accessToken: perfil.accessToken);
    }

    return resultado;
  }

  @override
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  }) async {
    final uidVia = escaladaUid.trim();
    final atual = obterDadosEscalada(uidVia);
    final alertas = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final indice = alertas.indexWhere((a) => a.uid == alertaUid);
    if (indice < 0) return;

    if (aindaEstaLa) {
      final existente = alertas[indice];
      alertas[indice] = existente.copyWith(
        confirmacoesAtivas: existente.confirmacoesAtivas + 1,
      );
    } else {
      alertas.removeAt(indice);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    _versaoNotifier.value++;

    final perfil = _repositorioCaderneta.obterPerfil();
    if (_clienteFila != null &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaUid)) {
      await _enfileirarEDespachar([
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: alertaUid,
          alertaAtivo: aindaEstaLa,
        ),
      ], accessToken: perfil.accessToken);
    }
  }

  Future<void> _carregarFilaPendenteSeNecessario() async {
    if (_filaCarregada) return;
    _filaCarregada = true;
    final prefs = _preferencias ??= await SharedPreferences.getInstance();
    final bruto = prefs.getString(chaveFilaPendente);
    if (bruto == null || bruto.isEmpty) return;

    final lista = jsonDecode(bruto) as List<dynamic>;
    _filaPendente
      ..clear()
      ..addAll(
        lista.whereType<Map<String, dynamic>>().map(ItemFilaInteracao.fromJson),
      );
  }

  Future<void> _persistirFilaPendente() async {
    final prefs = _preferencias ??= await SharedPreferences.getInstance();
    if (_filaPendente.isEmpty) {
      await prefs.remove(chaveFilaPendente);
      return;
    }
    final serializado = jsonEncode(
      _filaPendente.map((i) => i.toJson()).toList(growable: false),
    );
    await prefs.setString(chaveFilaPendente, serializado);
  }

  Future<void> _enfileirarEDespachar(
    List<ItemFilaInteracao> novosItens, {
    String? accessToken,
  }) async {
    final cliente = _clienteFila;
    if (cliente == null) return;
    await _carregarFilaPendenteSeNecessario();
    _filaPendente.addAll(novosItens);
    await _drenarFilaPendente(cliente, accessToken: accessToken);
  }

  Future<void> _drenarFilaPendente(
    ClienteFilaInteracoes cliente, {
    String? accessToken,
  }) async {
    if (_filaPendente.isEmpty) return;

    final restantes = <ItemFilaInteracao>[];
    for (var i = 0; i < _filaPendente.length; i++) {
      final item = _filaPendente[i];
      try {
        await cliente.inserirInteracao(item, accessToken: accessToken);
      } catch (e, stackTrace) {
        _registrarFalhaRede(
          'Interação retida na fila offline (${item.tipo.codigoBanco})',
          e,
          stackTrace,
        );
        restantes.addAll(_filaPendente.sublist(i));
        break;
      }
    }

    _filaPendente
      ..clear()
      ..addAll(restantes);
    await _persistirFilaPendente();
  }

  static void _registrarFalhaRede(
    String contexto,
    Object erro,
    StackTrace stackTrace,
  ) {
    if (AppLogger.isFalhaConexaoOuTimeout(erro)) {
      AppLogger.instance.logAviso('$contexto: $erro');
    } else {
      AppLogger.instance.logError(
        contexto,
        error: erro,
        stackTrace: stackTrace,
      );
    }
  }
}
