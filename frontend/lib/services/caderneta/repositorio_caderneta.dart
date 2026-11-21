// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../firebase/app_logger.dart';
import 'armazenamento_local_caderneta.dart';
import 'cliente_cadenas_supabase.dart';
import 'estatisticas_caderneta.dart';

/// Contrato abstrato do repositório reativo da caderneta pessoal de cadenas e perfil.
///
/// Desenvolvido em padrão *Local-First*, provendo reatividade imediata (`0ms`) via
/// [ValueListenable] e sincronização bidirecional resiliente com `public.cadenas` via PostgREST.
abstract interface class RepositorioCaderneta {
  /// Notificador reativo contendo a lista imutável de todas as ascensões registradas.
  ValueListenable<List<Cadena>> get cadenasNotifier;

  /// Notificador reativo da identidade esportiva pública do atleta.
  ValueListenable<PerfilEscalador> get perfilNotifier;

  /// Inicializa o repositório a partir do armazenamento local permanente.
  Future<void> inicializar();

  /// Salva ou atualiza uma ascensão esportiva na caderneta local e agenda sincronização em nuvem.
  Future<void> salvarCadena(Cadena cadena);

  /// Exclui permanentemente uma ascensão esportiva pelo seu [id] UUID local e na nuvem.
  Future<void> excluirCadena(String id);

  /// Retorna as ascensões registradas para uma via específica ([escaladaUid]),
  /// ordenadas da mais recente para a mais antiga.
  List<Cadena> obterCadenasPorEscalada(String escaladaUid);

  /// Retorna a ascensão de maior destaque esportivo em uma via específica.
  ///
  /// Prioriza estilos esportivos superiores (Flash > À Vista > Trabalhado > Tentativa)
  /// e desempata pela data de realização mais recente.
  Cadena? obterMelhorAscensao(String escaladaUid);

  /// Salva ou atualiza as informações do perfil do atleta.
  Future<void> salvarPerfil(PerfilEscalador perfil);

  /// Retorna a instância síncrona atual do perfil do atleta.
  PerfilEscalador obterPerfil();

  /// Drena mutações offline pendentes (`upsert`/`delete`) e reconcilia a caderneta com `public.cadenas`.
  Future<void> sincronizarComNuvem();

  /// Apaga permanentemente cadenas, filas de sincronização e perfil local após exclusão de conta.
  Future<void> limparDadosContaExcluida();

  /// Compila as métricas analíticas e pirâmide de graduação com os dados da caderneta.
  EstatisticasCaderneta calcularEstatisticas({
    String? Function(String escaladaUid)? obterGrauDaVia,
  });
}

/// Implementação padrão local-first de [RepositorioCaderneta], integrando persistência
/// instantânea em [ArmazenamentoLocalCaderneta] e backup bidirecional via [ClienteCadenas].
class RepositorioCadernetaLocal implements RepositorioCaderneta {
  static RepositorioCadernetaLocal? _instanciaCompartilhada;

  /// Retorna ou instancia a instância singleton do repositório conectada ao [ClienteCadenasSupabase].
  static RepositorioCadernetaLocal get instancia =>
      _instanciaCompartilhada ??= RepositorioCadernetaLocal(
        clienteCadenas: ClienteCadenasSupabase(),
      );

  /// Permite sobrescrever a instância singleton para fins de teste.
  @visibleForTesting
  static set instancia(RepositorioCadernetaLocal? substituto) {
    _instanciaCompartilhada = substituto;
  }

  final ArmazenamentoLocalCaderneta _armazenamento;
  final ClienteCadenas? _clienteCadenas;
  final Future<PerfilEscalador> Function()? _aoRenovarSessaoExpirada;

  final ValueNotifier<List<Cadena>> _cadenasNotifier =
      ValueNotifier<List<Cadena>>(const []);
  final ValueNotifier<PerfilEscalador> _perfilNotifier =
      ValueNotifier<PerfilEscalador>(PerfilEscalador.criarPadrao());

  final List<Cadena> _cadenas = [];
  final Set<String> _idsUpsertPendentes = <String>{};
  final Set<String> _idsExclusaoPendentes = <String>{};

  /// Construtor com suporte opcional a [ClienteCadenas] para sincronização PostgREST.
  RepositorioCadernetaLocal({
    SharedPreferences? preferencias,
    ArmazenamentoLocalCaderneta? armazenamento,
    ClienteCadenas? clienteCadenas,
    Future<PerfilEscalador> Function()? aoRenovarSessaoExpirada,
  }) : _armazenamento =
           armazenamento ??
           ArmazenamentoLocalCaderneta(preferencias: preferencias),
       _clienteCadenas = clienteCadenas,
       _aoRenovarSessaoExpirada = aoRenovarSessaoExpirada;

  @override
  ValueListenable<List<Cadena>> get cadenasNotifier => _cadenasNotifier;

  @override
  ValueListenable<PerfilEscalador> get perfilNotifier => _perfilNotifier;

  @override
  Future<void> inicializar() async {
    _perfilNotifier.value = await _armazenamento.carregarOuCriarPerfil();
    _cadenas
      ..clear()
      ..addAll(await _armazenamento.carregarCadenas());
    _idsUpsertPendentes
      ..clear()
      ..addAll(await _armazenamento.carregarIdsUpsertPendentes());
    _idsExclusaoPendentes
      ..clear()
      ..addAll(await _armazenamento.carregarIdsExclusaoPendentes());
    _cadenasNotifier.value = List.unmodifiable(_cadenas);

    if (_clienteCadenas != null && _perfilNotifier.value.estaAutenticado) {
      unawaited(sincronizarComNuvem());
    }
  }

  @override
  Future<void> salvarCadena(Cadena cadena) async {
    final indiceExistente = _cadenas.indexWhere((c) => c.id == cadena.id);
    if (indiceExistente >= 0) {
      _cadenas[indiceExistente] = cadena;
    } else {
      _cadenas.insert(0, cadena);
    }

    await _armazenamento.salvarCadenas(_cadenas);
    _cadenasNotifier.value = List.unmodifiable(_cadenas);

    if (validarUid(cadena.escaladaUid)) {
      _idsUpsertPendentes.add(cadena.id);
      _idsExclusaoPendentes.remove(cadena.id);
      await _armazenamento.salvarFilaSincronizacao(
        idsUpsertPendentes: _idsUpsertPendentes,
        idsExclusaoPendentes: _idsExclusaoPendentes,
      );
      if (_clienteCadenas != null && obterPerfil().estaAutenticado) {
        await sincronizarComNuvem();
      }
    }
  }

  @override
  Future<void> excluirCadena(String id) async {
    _cadenas.removeWhere((c) => c.id == id);
    await _armazenamento.salvarCadenas(_cadenas);
    _cadenasNotifier.value = List.unmodifiable(_cadenas);

    _idsUpsertPendentes.remove(id);
    if (obterPerfil().estaAutenticado) {
      _idsExclusaoPendentes.add(id);
    }
    await _armazenamento.salvarFilaSincronizacao(
      idsUpsertPendentes: _idsUpsertPendentes,
      idsExclusaoPendentes: _idsExclusaoPendentes,
    );
    if (_clienteCadenas != null && obterPerfil().estaAutenticado) {
      await sincronizarComNuvem();
    }
  }

  @override
  Future<void> sincronizarComNuvem() async {
    final cliente = _clienteCadenas;
    final perfilInicial = obterPerfil();
    if (cliente == null || !perfilInicial.estaAutenticado) {
      return;
    }

    for (final local in _cadenas) {
      if (validarUid(local.escaladaUid) &&
          local.userId != perfilInicial.userId) {
        _idsUpsertPendentes.add(local.id);
      }
    }

  }

  static bool _ehErroNaoAutorizado(Object erro) =>
      erro is ExcecaoComStatusHttp && erro.codigoStatusHttp == 401;

  static void _registrarFalhaSincronizacao(
    String contexto,
    Object erro,
    StackTrace stackTrace,
  ) {
    if (AppLogger.isFalhaConexaoOuTimeout(erro)) {
      AppLogger.instance.logAviso('$contexto ($erro)');
    } else {
      AppLogger.instance.logError(
        contexto,
        error: erro,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> limparDadosContaExcluida() async {
    _cadenas.clear();
    _idsUpsertPendentes.clear();
    _idsExclusaoPendentes.clear();
    await _armazenamento.limparDadosLocais();

    final novoPerfil = PerfilEscalador.criarPadrao();
    await _armazenamento.salvarPerfil(novoPerfil);
    _perfilNotifier.value = novoPerfil;
    _cadenasNotifier.value = const [];
  }

  @override
  List<Cadena> obterCadenasPorEscalada(String escaladaUid) {
    final filtradas = _cadenas
        .where((c) => c.escaladaUid == escaladaUid)
        .toList();
    filtradas.sort((a, b) => b.dataAscensao.compareTo(a.dataAscensao));
    return List.unmodifiable(filtradas);
  }

  @override
  Cadena? obterMelhorAscensao(String escaladaUid) {
    final ascensoes = obterCadenasPorEscalada(escaladaUid);
    if (ascensoes.isEmpty) return null;

    final ordenadas = List<Cadena>.from(ascensoes)
      ..sort((a, b) {
        final prioridade = b.prioridadeVisual.compareTo(a.prioridadeVisual);
        if (prioridade != 0) return prioridade;
        return b.dataAscensao.compareTo(a.dataAscensao);
      });

    return ordenadas.first;
  }

  @override
  Future<void> salvarPerfil(PerfilEscalador perfil) async {
    _perfilNotifier.value = perfil;
    await _armazenamento.salvarPerfil(perfil);
  }

  @override
  PerfilEscalador obterPerfil() => _perfilNotifier.value;

  @override
  EstatisticasCaderneta calcularEstatisticas({
    String? Function(String escaladaUid)? obterGrauDaVia,
  }) {
    return EstatisticasCaderneta.calcular(
      _cadenas,
      obterGrauDaVia: obterGrauDaVia,
    );
  }
}
