// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/item_fila_interacao.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../utils/calculadora_delta_grau.dart';
import '../../utils/gerador_uid.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import 'armazenamento_fila_interacoes.dart';
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
  static const String chaveFilaPendente =
      ArmazenamentoFilaInteracoes.chaveFilaPendente;

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
  final ServicoAutenticacao _servicoAutenticacao;
  final ClienteFilaInteracoes? _clienteFila;
  final ArmazenamentoFilaInteracoes _armazenamentoFila;
  bool _filaCarregada = false;

  final Map<String, DadosComunidadeVia> _dadosPorEscalada = {};
  final Map<String, Map<String, ({int? deltaGrau, int? grauSugerido})>>
  _votosLocaisPorAutor = {};
  final List<ItemFilaInteracao> _filaPendente = [];
  final ValueNotifier<int> _versaoNotifier = ValueNotifier<int>(0);

  /// Cria uma instância de [RepositorioInteracoesViaMemoria].
  RepositorioInteracoesViaMemoria({
    RepositorioCaderneta? repositorioCaderneta,
    ServicoAutenticacao? servicoAutenticacao,
    ClienteFilaInteracoes? clienteFila,
    ArmazenamentoFilaInteracoes? armazenamentoFila,
    SharedPreferences? preferencias,
  }) : _repositorioCaderneta =
           repositorioCaderneta ?? RepositorioCadernetaLocal.instancia,
       _servicoAutenticacao =
           servicoAutenticacao ?? ServicoAutenticacaoLocal.instancia,
       _clienteFila = clienteFila,
       _armazenamentoFila =
           armazenamentoFila ??
           ArmazenamentoFilaInteracoes(preferencias: preferencias);

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
    await _drenarFilaPendente(cliente);

    try {
      final remotos = await cliente.buscarInteracoesPendentes(uidVia);
      final combinados = <ItemFilaInteracao>[
        ...remotos,
        ..._filaPendente.where((i) => i.escaladaUid == uidVia),
      ]..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

      final mapaVotos = <String, ({int? deltaGrau, int? grauSugerido})>{};
      for (final item in combinados) {
        if (item.tipo == TipoFilaInteracao.votoGrau) {
          mapaVotos[item.autorIdPublico] = (
            deltaGrau: item.deltaGrau,
            grauSugerido: item.grauSugerido,
          );
        }
      }
      _votosLocaisPorAutor[uidVia] = mapaVotos;

      _dadosPorEscalada[uidVia] = consolidarItensFilaEmDadosComunidade(
        combinados,
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
    final votosPorAutor = Map<String, ({int? deltaGrau, int? grauSugerido})>.from(
      _votosLocaisPorAutor[uidVia] ?? const {},
    );
    votosPorAutor[perfil.autorIdPublico] = (
      deltaGrau: deltaGrau,
      grauSugerido: codEfetivo,
    );
    _votosLocaisPorAutor[uidVia] = votosPorAutor;

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
        votos: votosPorAutor.values.toList(growable: false),
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
      ),
      comentarios: List.unmodifiable(comentarios),
    );
    _versaoNotifier.value++;

    final cliente = _clienteFila;
    if (cliente != null &&
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
      await _enfileirarEDespachar(cliente, itensParaEnviar);
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

    final cliente = _clienteFila;
    if (cliente != null &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(resultado.uid)) {
      await _enfileirarEDespachar(cliente, [
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: resultado.uid,
          categoriaAlerta: categoria,
          detalhe: detalhe,
        ),
      ]);
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

    final cliente = _clienteFila;
    final perfil = _repositorioCaderneta.obterPerfil();
    if (cliente != null &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaUid)) {
      await _enfileirarEDespachar(cliente, [
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: alertaUid,
          alertaAtivo: aindaEstaLa,
        ),
      ]);
    }
  }

  Future<void> _carregarFilaPendenteSeNecessario() async {
    if (_filaCarregada) return;
    _filaCarregada = true;
    _filaPendente
      ..clear()
      ..addAll(await _armazenamentoFila.carregarItensPendentes());
  }

  Future<void> _persistirFilaPendente() =>
      _armazenamentoFila.salvarItensPendentes(_filaPendente);

  Future<void> _enfileirarEDespachar(
    ClienteFilaInteracoes cliente,
    List<ItemFilaInteracao> novosItens,
  ) async {
    await _carregarFilaPendenteSeNecessario();
    for (final novo in novosItens) {
      if (novo.tipo == TipoFilaInteracao.votoGrau) {
        _filaPendente.removeWhere(
          (p) =>
              p.tipo == TipoFilaInteracao.votoGrau &&
              p.escaladaUid == novo.escaladaUid,
        );
      }
    }
    _filaPendente.addAll(novosItens);
    await _drenarFilaPendente(cliente);
  }

  Future<void> _drenarFilaPendente(ClienteFilaInteracoes cliente) async {
    if (_filaPendente.isEmpty) return;

    var perfilAtual = _repositorioCaderneta.obterPerfil();
    final exigeAuth = _filaPendente.any((i) => i.tipo.exigeContaAutenticada);
    if (exigeAuth &&
        perfilAtual.estaAutenticado &&
        perfilAtual.accessToken == null) {
      try {
        perfilAtual = await _servicoAutenticacao
            .garantirSessaoEPerfilSincronizados();
      } catch (e, stackTrace) {
        _registrarFalhaRede(
          'Não foi possível preparar sessão autenticada antes do envio comunitário',
          e,
          stackTrace,
        );
      }
    }

    final restantes = <ItemFilaInteracao>[];
    for (var i = 0; i < _filaPendente.length; i++) {
      var item = _filaPendente[i];
      if (item.tipo.exigeContaAutenticada &&
          perfilAtual.estaAutenticado &&
          validarUid(perfilAtual.autorIdPublico)) {
        item = item.comAutor(
          autorIdPublico: perfilAtual.autorIdPublico,
          autorNomePublico: perfilAtual.autorNomePublico,
        );
      }
      final tokenEnvio = item.tipo.exigeContaAutenticada
          ? perfilAtual.accessToken
          : null;

      try {
        await cliente.inserirInteracao(item, accessToken: tokenEnvio);
      } catch (erroInicial, stackInicial) {
        if (item.tipo.exigeContaAutenticada &&
            perfilAtual.estaAutenticado &&
            _ehFalhaSessaoOuRls(erroInicial)) {
          try {
            final eh401 =
                (erroInicial as ExcecaoComStatusHttp).codigoStatusHttp == 401;
            perfilAtual = await _servicoAutenticacao
                .garantirSessaoEPerfilSincronizados(
                  forcarRenovacaoToken: eh401,
                );
            item = item.comAutor(
              autorIdPublico: perfilAtual.autorIdPublico,
              autorNomePublico: perfilAtual.autorNomePublico,
            );
            await cliente.inserirInteracao(
              item,
              accessToken: perfilAtual.accessToken,
            );
            continue;
          } catch (erroRetentativa, stackRetentativa) {
            _registrarFalhaRede(
              'Interação retida após reconciliar sessão/perfil (${item.tipo.codigoBanco})',
              erroRetentativa,
              stackRetentativa,
            );
            restantes
              ..add(item)
              ..addAll(_filaPendente.sublist(i + 1));
            break;
          }
        }

        _registrarFalhaRede(
          'Interação retida na fila offline (${item.tipo.codigoBanco})',
          erroInicial,
          stackInicial,
        );
        restantes
          ..add(item)
          ..addAll(_filaPendente.sublist(i + 1));
        break;
      }
    }

    _filaPendente
      ..clear()
      ..addAll(restantes);
    await _persistirFilaPendente();
  }

  static bool _ehFalhaSessaoOuRls(Object erro) {
    if (erro is ExcecaoComStatusHttp) {
      return erro.codigoStatusHttp == 401 || erro.codigoStatusHttp == 403;
    }
    return false;
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
