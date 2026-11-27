// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/item_fila_interacao.dart';
import '../../data/modelos/mutacao_fila_interacao.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import 'armazenamento_fila_interacoes.dart';
import 'cliente_fila_interacoes_supabase.dart';

/// Orquestra a fila persistente de envio offline (*outbox*) para `public.fila_interacoes`,
/// coalescendo inserções, edições e exclusões locais e reconciliando sessão/perfil em `401`/`403`.
class DespachanteFilaInteracoes {
  final RepositorioCaderneta _repositorioCaderneta;
  final ServicoAutenticacao _servicoAutenticacao;
  final ArmazenamentoFilaInteracoes _armazenamentoFila;

  final List<ItemFilaInteracao> _filaPendente = [];
  final List<MutacaoFilaInteracao> _mutacoesPendentes = [];
  bool _carregada = false;

  /// Cria uma instância de [DespachanteFilaInteracoes].
  DespachanteFilaInteracoes({
    required RepositorioCaderneta repositorioCaderneta,
    required ServicoAutenticacao servicoAutenticacao,
    required ArmazenamentoFilaInteracoes armazenamentoFila,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _servicoAutenticacao = servicoAutenticacao,
       _armazenamentoFila = armazenamentoFila;

  /// Itens de criação atualmente retidos na fila offline aguardando conectividade ou sessão válida.
  List<ItemFilaInteracao> get itensPendentes => List.unmodifiable(_filaPendente);

  /// Mutações de edição/exclusão atualmente retidas na fila offline.
  List<MutacaoFilaInteracao> get mutacoesPendentes =>
      List.unmodifiable(_mutacoesPendentes);

  /// Garante a hidratação inicial da fila offline a partir do armazenamento local.
  Future<void> garantirCarregada() async {
    if (_carregada) return;
    _carregada = true;
    _filaPendente
      ..clear()
      ..addAll(await _armazenamentoFila.carregarItensPendentes());
    _mutacoesPendentes
      ..clear()
      ..addAll(await _armazenamentoFila.carregarMutacoesPendentes());
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

  /// Registra uma edição ou exclusão, coalescendo em memória caso o item original ainda esteja
  /// retido em [_filaPendente] (sem jamais enviar tráfego desnecessário à rede), ou enfileirando
  /// em [_mutacoesPendentes] e drenando quando `cliente` estiver disponível.
  Future<void> registrarMutacao(
    ClienteFilaInteracoes? cliente,
    MutacaoFilaInteracao mutacao,
  ) async {
    await garantirCarregada();
    if (_absorverMutacaoEmItemAindaNaoEnviado(mutacao)) {
      await _armazenamentoFila.salvarItensPendentes(_filaPendente);
      return;
    }

    _mutacoesPendentes.removeWhere(
      (p) =>
          p.alvoUid == mutacao.alvoUid &&
          _pertenceAoMesmoDominio(p.tipo, mutacao.tipo),
    );
    _mutacoesPendentes.add(mutacao);
    await _armazenamentoFila.salvarMutacoesPendentes(_mutacoesPendentes);

    if (cliente != null) {
      await drenar(cliente);
    }
  }

  bool _absorverMutacaoEmItemAindaNaoEnviado(MutacaoFilaInteracao mutacao) {
    switch (mutacao.tipo) {
      case TipoMutacaoFilaInteracao.editarComentario:
        final idx = _filaPendente.indexWhere(
          (p) =>
              p.tipo == TipoFilaInteracao.comentario && p.id == mutacao.alvoUid,
        );
        if (idx < 0) return false;
        _filaPendente[idx] = _filaPendente[idx].comTextoComentario(
          mutacao.novoTexto!,
        );
        return true;
      case TipoMutacaoFilaInteracao.excluirComentario:
        final antes = _filaPendente.length;
        _filaPendente.removeWhere(
          (p) =>
              p.tipo == TipoFilaInteracao.comentario && p.id == mutacao.alvoUid,
        );
        return _filaPendente.length != antes;
      case TipoMutacaoFilaInteracao.editarAlerta:
        final idx = _filaPendente.indexWhere(
          (p) =>
              p.tipo == TipoFilaInteracao.alertaSeguranca &&
              p.alertaAlvoUid == mutacao.alvoUid,
        );
        if (idx < 0) return false;
        _filaPendente[idx] = _filaPendente[idx].comEdicaoAlerta(
          categoria: mutacao.novaCategoria!,
          detalhe: mutacao.novoTexto,
        );
        return true;
      case TipoMutacaoFilaInteracao.excluirAlerta:
        final antes = _filaPendente.length;
        _filaPendente.removeWhere(
          (p) =>
              p.tipo == TipoFilaInteracao.alertaSeguranca &&
              p.alertaAlvoUid == mutacao.alvoUid,
        );
        return _filaPendente.length != antes;
    }
  }

  static bool _pertenceAoMesmoDominio(
    TipoMutacaoFilaInteracao a,
    TipoMutacaoFilaInteracao b,
  ) {
    final aEhComentario =
        a == TipoMutacaoFilaInteracao.editarComentario ||
        a == TipoMutacaoFilaInteracao.excluirComentario;
    final bEhComentario =
        b == TipoMutacaoFilaInteracao.editarComentario ||
        b == TipoMutacaoFilaInteracao.excluirComentario;
    return aEhComentario == bEhComentario;
  }

  /// Envia os itens e mutações pendentes para [cliente] com token JWT e reconciliação automática.
  Future<void> drenar(ClienteFilaInteracoes cliente) async {
    await garantirCarregada();
    if (_filaPendente.isEmpty && _mutacoesPendentes.isEmpty) return;

    var perfilAtual = await _prepararPerfilAutenticado();

    if (_filaPendente.isNotEmpty) {
      perfilAtual = await _drenarInsercoes(cliente, perfilAtual);
    }
    if (_mutacoesPendentes.isNotEmpty) {
      await _drenarMutacoes(cliente, perfilAtual);
    }
  }

  Future<PerfilEscalador> _prepararPerfilAutenticado() async {
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
    return perfilAtual;
  }

  Future<PerfilEscalador> _drenarInsercoes(
    ClienteFilaInteracoes cliente,
    PerfilEscalador perfilInicial,
  ) async {
    var perfilAtual = perfilInicial;
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
    return perfilAtual;
  }

  Future<void> _drenarMutacoes(
    ClienteFilaInteracoes cliente,
    PerfilEscalador perfilInicial,
  ) async {
    var perfilAtual = perfilInicial;
    final restantes = <MutacaoFilaInteracao>[];
    for (var i = 0; i < _mutacoesPendentes.length; i++) {
      var mut = _mutacoesPendentes[i];
      if (perfilAtual.estaAutenticado && validarUid(perfilAtual.autorIdPublico)) {
        mut = mut.comAutor(perfilAtual.autorIdPublico);
      }

      try {
        await _executarMutacaoRemota(cliente, mut, perfilAtual.accessToken);
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
            mut = mut.comAutor(perfilAtual.autorIdPublico);
            await _executarMutacaoRemota(cliente, mut, perfilAtual.accessToken);
            continue;
          } catch (erroRetentativa, stackRetentativa) {
            if (_ehConflitoDuplicado(erroRetentativa)) continue;
            registrarFalhaRede(
              'Mutação retida após reconciliar sessão (${mut.tipo.codigo})',
              erroRetentativa,
              stackRetentativa,
            );
            restantes.add(mut);
            if (AppLogger.isFalhaConexaoOuTimeout(erroRetentativa)) {
              restantes.addAll(_mutacoesPendentes.sublist(i + 1));
              break;
            }
            continue;
          }
        }

        registrarFalhaRede(
          'Mutação retida na fila offline (${mut.tipo.codigo})',
          erroInicial,
          stackInicial,
        );
        if (AppLogger.isFalhaConexaoOuTimeout(erroInicial)) {
          restantes
            ..add(mut)
            ..addAll(_mutacoesPendentes.sublist(i + 1));
          break;
        }
        restantes.add(mut);
      }
    }

    _mutacoesPendentes
      ..clear()
      ..addAll(restantes);
    await _armazenamentoFila.salvarMutacoesPendentes(_mutacoesPendentes);
  }

  Future<void> _executarMutacaoRemota(
    ClienteFilaInteracoes cliente,
    MutacaoFilaInteracao mutacao,
    String? accessToken,
  ) {
    return switch (mutacao.tipo) {
      TipoMutacaoFilaInteracao.editarComentario => cliente.atualizarComentario(
        comentarioId: mutacao.alvoUid,
        autorIdPublico: mutacao.autorIdPublico,
        novoTexto: mutacao.novoTexto!,
        accessToken: accessToken,
      ),
      TipoMutacaoFilaInteracao.excluirComentario => cliente.excluirComentario(
        comentarioId: mutacao.alvoUid,
        autorIdPublico: mutacao.autorIdPublico,
        accessToken: accessToken,
      ),
      TipoMutacaoFilaInteracao.editarAlerta => cliente.atualizarAlerta(
        alertaAlvoUid: mutacao.alvoUid,
        autorIdPublico: mutacao.autorIdPublico,
        categoria: mutacao.novaCategoria!,
        detalhe: mutacao.novoTexto,
        accessToken: accessToken,
      ),
      TipoMutacaoFilaInteracao.excluirAlerta => cliente.excluirAlerta(
        alertaAlvoUid: mutacao.alvoUid,
        autorIdPublico: mutacao.autorIdPublico,
        accessToken: accessToken,
      ),
    };
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
