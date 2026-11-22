// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/item_fila_interacao.dart';
import '../../utils/gerador_uid.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import 'armazenamento_fila_interacoes.dart';
import 'cliente_fila_interacoes_supabase.dart';

/// Orquestra a fila persistente de envio offline (*outbox*) para `public.fila_interacoes`,
/// reconciliando sessão/perfil autenticado em falhas `401`/`403` e descartando conflitos `409`.
class DespachanteFilaInteracoes {
  final RepositorioCaderneta _repositorioCaderneta;
  final ServicoAutenticacao _servicoAutenticacao;
  final ArmazenamentoFilaInteracoes _armazenamentoFila;

  final List<ItemFilaInteracao> _filaPendente = [];
  bool _carregada = false;

  /// Cria uma instância de [DespachanteFilaInteracoes].
  DespachanteFilaInteracoes({
    required RepositorioCaderneta repositorioCaderneta,
    required ServicoAutenticacao servicoAutenticacao,
    required ArmazenamentoFilaInteracoes armazenamentoFila,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _servicoAutenticacao = servicoAutenticacao,
       _armazenamentoFila = armazenamentoFila;

  /// Itens atualmente retidos na fila offline aguardando conectividade ou sessão válida.
  List<ItemFilaInteracao> get itensPendentes => List.unmodifiable(_filaPendente);

  /// Garante a hidratação inicial da fila offline a partir do armazenamento local.
  Future<void> garantirCarregada() async {
    if (_carregada) return;
    _carregada = true;
    _filaPendente
      ..clear()
      ..addAll(await _armazenamentoFila.carregarItensPendentes());
  }

  /// Adiciona [novosItens] à fila (substituindo voto anterior da mesma via) e drena em [cliente].
  Future<void> enfileirarEDespachar(
    ClienteFilaInteracoes cliente,
    List<ItemFilaInteracao> novosItens,
  ) async {
    await garantirCarregada();
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
    await drenar(cliente);
  }

  /// Envia os itens pendentes para [cliente] com token JWT autenticado e reconciliação automática.
  Future<void> drenar(ClienteFilaInteracoes cliente) async {
    await garantirCarregada();
    if (_filaPendente.isEmpty) return;

    var perfilAtual = _repositorioCaderneta.obterPerfil();
    if (perfilAtual.estaAutenticado && perfilAtual.accessToken == null) {
      try {
        perfilAtual = await _servicoAutenticacao
            .garantirSessaoEPerfilSincronizados();
      } catch (e, stackTrace) {
        registrarFalhaRede(
          'Não foi possível preparar sessão autenticada antes do envio comunitário',
          e,
          stackTrace,
        );
      }
    }

    final restantes = <ItemFilaInteracao>[];
    for (var i = 0; i < _filaPendente.length; i++) {
      var item = _filaPendente[i];
      if (perfilAtual.estaAutenticado && validarUid(perfilAtual.autorIdPublico)) {
        item = item.comAutor(
          autorIdPublico: perfilAtual.autorIdPublico,
          autorNomePublico: perfilAtual.autorNomePublico,
        );
      }

      try {
        await cliente.inserirInteracao(item, accessToken: perfilAtual.accessToken);
      } catch (erroInicial, stackInicial) {
        if (_ehConflitoDuplicado(erroInicial)) continue;
        if (perfilAtual.estaAutenticado && _ehFalhaSessaoOuRls(erroInicial)) {
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
            if (_ehConflitoDuplicado(erroRetentativa)) continue;
            registrarFalhaRede(
              'Interação retida após reconciliar sessão/perfil (${item.tipo.codigoBanco})',
              erroRetentativa,
              stackRetentativa,
            );
            restantes.add(item);
            if (AppLogger.isFalhaConexaoOuTimeout(erroRetentativa)) {
              restantes.addAll(_filaPendente.sublist(i + 1));
              break;
            }
            continue;
          }
        }

        registrarFalhaRede(
          'Interação retida na fila offline (${item.tipo.codigoBanco})',
          erroInicial,
          stackInicial,
        );
        if (AppLogger.isFalhaConexaoOuTimeout(erroInicial)) {
          restantes
            ..add(item)
            ..addAll(_filaPendente.sublist(i + 1));
          break;
        }
        restantes.add(item);
      }
    }

    _filaPendente
      ..clear()
      ..addAll(restantes);
    await _armazenamentoFila.salvarItensPendentes(_filaPendente);
  }

  /// Registra falhas transitórias de conectividade como aviso e demais falhas como erro.
  static void registrarFalhaRede(
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

  static bool _ehConflitoDuplicado(Object erro) =>
      erro is ExcecaoComStatusHttp && erro.codigoStatusHttp == 409;

  static bool _ehFalhaSessaoOuRls(Object erro) =>
      erro is ExcecaoComStatusHttp &&
      (erro.codigoStatusHttp == 401 || erro.codigoStatusHttp == 403);
}
