// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/item_fila_interacao.dart';
import '../../data/modelos/mutacao_fila_interacao.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../utils/calculadora_delta_grau.dart';
import '../../utils/gerador_uid.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import 'armazenamento_fila_interacoes.dart';
import 'cliente_fila_interacoes_supabase.dart';
import 'despachante_fila_interacoes.dart';

/// Contrato reativo da camada de dados comunitários e alertas de segurança estilo Waze por via.
abstract interface class RepositorioInteracoesVia {
  /// Notificador que incrementa sempre que alertas, votos ou comentários sofrem alteração.
  ValueListenable<int> get alteracoesListenable;

  /// Indica se o escalador atual possui sessão autenticada para registrar interações públicas.
  bool get usuarioEstaAutenticado;

  /// Retorna o identificador público NanoID 14c do perfil atual do escalador.
  String get autorIdPublicoAtual;

  /// Retorna o deslocamento de grau (`-2` a `+2`) votado pelo usuário atual em [escaladaUid], se houver.
  int? obterDeltaVotoUsuario(String escaladaUid);

  /// Retorna o agregado comunitário atual ([DadosComunidadeVia]) para [escaladaUid].
  DadosComunidadeVia obterDadosEscalada(String escaladaUid);

  /// Retorna todos os alertas criados (`CRIADO POR VOCÊ`) ou confirmados (`CONFIRMADO (+1)`) pelo perfil atual.
  List<AlertaContribuidoCaderneta> obterMeusAlertasContribuidos();

  /// Sincroniza com o Supabase e o cache local os alertas criados ou confirmados pelo perfil atual.
  Future<void> sincronizarMeusAlertasContribuidos();

  /// Drena interações offline pendentes e sincroniza o estado ativo de [escaladaUid] com o Supabase.
  Future<void> sincronizarEscalada(
    String escaladaUid, {
    int? codigoGrauOficial,
    bool ehBoulder = false,
  });

  /// Drena a fila offline e sincroniza em lote os alertas e interações de múltiplas vias de um mapa/setor.
  Future<void> sincronizarEscaladasEmLote(Iterable<String> escaladaUids);

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

  /// Edita o texto (`1..280` caracteres) de um comentário criado pelo próprio escalador.
  Future<void> editarComentario({
    required String escaladaUid,
    required String comentarioUid,
    required String novoTexto,
  });

  /// Exclui permanentemente um comentário criado pelo próprio escalador.
  Future<void> excluirComentario({required String escaladaUid, required String comentarioUid});

  /// Registra um novo alerta de segurança na via (ou reforça alerta ativo da mesma categoria).
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  });

  /// Edita a categoria e/ou o detalhe (`<= 100` caracteres) de um alerta do próprio escalador.
  Future<AlertaSegurancaVia> editarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required CategoriaAlertaSeguranca novaCategoria,
    String? detalhe,
  });

  /// Exclui permanentemente um alerta de segurança criado pelo próprio escalador.
  Future<void> excluirAlerta({required String escaladaUid, required String alertaUid});

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
  static const String chaveFilaPendente = ArmazenamentoFilaInteracoes.chaveFilaPendente;
  static RepositorioInteracoesVia? _instanciaCompartilhada;

  /// Instância singleton padrão conectada ao [ClienteFilaInteracoesSupabase].
  static RepositorioInteracoesVia get instancia => _instanciaCompartilhada ??=
      RepositorioInteracoesViaMemoria(clienteFila: ClienteFilaInteracoesSupabase());

  /// Permite injetar instância substituta em testes de integração.
  @visibleForTesting
  static set instancia(RepositorioInteracoesVia? valor) => _instanciaCompartilhada = valor;

  /// Restaura a instância compartilhada para o estado inicial entre testes.
  @visibleForTesting
  static void redefinirParaTestes() => _instanciaCompartilhada = null;

  final RepositorioCaderneta _repositorioCaderneta;
  final ClienteFilaInteracoes? _clienteFila;
  final ArmazenamentoFilaInteracoes _armazenamentoFila;
  final DespachanteFilaInteracoes _despachante;
  bool _cacheCarregado = false;

  final Map<String, DadosComunidadeVia> _dadosPorEscalada = {};
  final Map<String, Map<String, ({int? deltaGrau, int? grauSugerido})>>
  _votosLocaisPorAutor = {};
  final ValueNotifier<int> _versaoNotifier = ValueNotifier<int>(0);

  /// Cria uma instância de [RepositorioInteracoesViaMemoria].
  RepositorioInteracoesViaMemoria({
    RepositorioCaderneta? repositorioCaderneta,
    ServicoAutenticacao? servicoAutenticacao,
    ClienteFilaInteracoes? clienteFila,
    ArmazenamentoFilaInteracoes? armazenamentoFila,
    SharedPreferences? preferencias,
  }) : this._(
         repositorioCaderneta:
             repositorioCaderneta ?? RepositorioCadernetaLocal.instancia,
         servicoAutenticacao:
             servicoAutenticacao ?? ServicoAutenticacaoLocal.instancia,
         clienteFila: clienteFila,
         armazenamentoFila:
             armazenamentoFila ??
             ArmazenamentoFilaInteracoes(preferencias: preferencias),
       );

  RepositorioInteracoesViaMemoria._({
    required RepositorioCaderneta repositorioCaderneta,
    required ServicoAutenticacao servicoAutenticacao,
    required ClienteFilaInteracoes? clienteFila,
    required ArmazenamentoFilaInteracoes armazenamentoFila,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _clienteFila = clienteFila,
       _armazenamentoFila = armazenamentoFila,
       _despachante = DespachanteFilaInteracoes(
         repositorioCaderneta: repositorioCaderneta,
         servicoAutenticacao: servicoAutenticacao,
         armazenamentoFila: armazenamentoFila,
       );

  @override
  ValueListenable<int> get alteracoesListenable => _versaoNotifier;

  @override
  bool get usuarioEstaAutenticado => _repositorioCaderneta.obterPerfil().estaAutenticado;

  @override
  String get autorIdPublicoAtual => _repositorioCaderneta.obterPerfil().autorIdPublico;

  @override
  int? obterDeltaVotoUsuario(String escaladaUid) =>
      _votosLocaisPorAutor[escaladaUid.trim()]?[autorIdPublicoAtual]?.deltaGrau;

  @override
  DadosComunidadeVia obterDadosEscalada(String escaladaUid) =>
      _dadosPorEscalada[escaladaUid] ?? const DadosComunidadeVia.vazio();

  @override
  List<AlertaContribuidoCaderneta> obterMeusAlertasContribuidos() {
    final base = <String, ItemFilaInteracao>{
      for (final lista in _armazenamentoFila.eventosAlertasPorVia.values)
        for (final item in lista) item.id: item,
      for (final pendente in _despachante.itensPendentes) pendente.id: pendente,
    };
    return consolidarAlertasContribuidosPeloAutor(
      aplicarMutacoesSobreItens(base.values, _despachante.mutacoesPendentes),
      autorIdPublico: autorIdPublicoAtual,
    );
  }

  @override
  Future<void> sincronizarMeusAlertasContribuidos() async {
    await _hidratarEstadoLocalSeNecessario();
    final cliente = _clienteFila;
    final autorId = autorIdPublicoAtual.trim();
    if (cliente == null || !validarUid(autorId)) {
      _versaoNotifier.value++;
      return;
    }

    await _despachante.drenar(cliente);
    try {
      final remotos = await cliente.buscarInteracoesRelacionadasAoAutor(autorId);
      await _armazenamentoFila.substituirTodosEventosAlertas(
        aplicarMutacoesSobreItens(remotos, _despachante.mutacoesPendentes),
      );
      _versaoNotifier.value++;
    } catch (e, stackTrace) {
      DespachanteFilaInteracoes.registrarFalhaRede(
        'Falha ao sincronizar alertas contribuídos da Caderneta',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> sincronizarEscalada(
    String escaladaUid, {
    int? codigoGrauOficial,
    bool ehBoulder = false,
  }) async {
    final uidVia = escaladaUid.trim();
    final cliente = _clienteFila;
    if (cliente == null || !validarUid(uidVia)) return;

    await _hidratarEstadoLocalSeNecessario();
    await _despachante.drenar(cliente);

    try {
      final remotos = await cliente.buscarInteracoesPendentes(uidVia);
      final combinados = _ordenarComMutacoesDaVia(uidVia, [
        ...remotos,
        ..._despachante.itensPendentes.where((i) => i.escaladaUid == uidVia),
      ]);
      _votosLocaisPorAutor[uidVia] = {
        for (final i in combinados)
          if (i.tipo == TipoFilaInteracao.votoGrau)
            i.autorIdPublico: (
              deltaGrau: i.deltaGrau,
              grauSugerido: i.grauSugerido,
            ),
      };
      _armazenamentoFila.atualizarEventosDaVia(uidVia, combinados);
      await _armazenamentoFila.persistirMemoriaAlertas();
      _dadosPorEscalada[uidVia] = consolidarItensFilaEmDadosComunidade(
        combinados,
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
        avataresPorAutor: _mapaAvatarPerfilLocal(),
      );
      _versaoNotifier.value++;
    } catch (e, stackTrace) {
      DespachanteFilaInteracoes.registrarFalhaRede(
        'Falha ao consultar fila_interacoes para $uidVia',
        e,
        stackTrace,
      );
    }
  }

  @override
  Future<void> sincronizarEscaladasEmLote(
    Iterable<String> escaladaUids,
  ) async {
    final cliente = _clienteFila;
    if (cliente == null) return;
    final uidsValidos = escaladaUids
        .map((u) => u.trim())
        .where(validarUid)
        .toSet()
        .toList(growable: false);
    if (uidsValidos.isEmpty) return;

    await _hidratarEstadoLocalSeNecessario();
    await _despachante.drenar(cliente);

    try {
      final remotos = await cliente.buscarInteracoesPendentesEmLote(uidsValidos);
      final porVia = <String, List<ItemFilaInteracao>>{
        for (final uid in uidsValidos) uid: <ItemFilaInteracao>[],
      };
      for (final i in remotos) {
        porVia[i.escaladaUid]?.add(i);
      }
      for (final p in _despachante.itensPendentes) {
        porVia[p.escaladaUid]?.add(p);
      }
      for (final e in porVia.entries) {
        final itens = _ordenarComMutacoesDaVia(e.key, e.value);
        _armazenamentoFila.atualizarEventosDaVia(e.key, itens);
        final cons = consolidarItensFilaEmDadosComunidade(
          itens,
          ehBoulder: false,
          avataresPorAutor: _mapaAvatarPerfilLocal(),
        );
        final ant = _dadosPorEscalada[e.key];
        _dadosPorEscalada[e.key] = DadosComunidadeVia(
          consensoGrau: ant != null && ant.consensoGrau.possuiVotos
              ? ant.consensoGrau
              : cons.consensoGrau,
          alertasAtivos: cons.alertasAtivos,
          comentarios: cons.comentarios,
        );
      }
      await _armazenamentoFila.persistirMemoriaAlertas();
      _versaoNotifier.value++;
    } catch (e, stackTrace) {
      DespachanteFilaInteracoes.registrarFalhaRede(
        'Falha ao consultar fila_interacoes em lote (${uidsValidos.length} vias)',
        e,
        stackTrace,
      );
    }
  }

  List<ItemFilaInteracao> _ordenarComMutacoesDaVia(
    String uidVia,
    Iterable<ItemFilaInteracao> eventos,
  ) => aplicarMutacoesSobreItens(
    eventos,
    _despachante.mutacoesPendentes.where((m) => m.escaladaUid == uidVia),
  )..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

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
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    if (deltaGrau < -2 || deltaGrau > 2) {
      throw ArgumentError.value(deltaGrau, 'deltaGrau', 'Esperado -2..+2.');
    }

    final perfil = _repositorioCaderneta.obterPerfil();
    final codEfetivo =
        grauSugerido ??
        deslocarCodigoGrau(codigoGrauOficial, deltaGrau, ehBoulder: ehBoulder);

    final atual = obterDadosEscalada(uidVia);
    final votosPorAutor =
        Map<String, ({int? deltaGrau, int? grauSugerido})>.from(
          _votosLocaisPorAutor[uidVia] ?? const {},
        )..[perfil.autorIdPublico] = (
          deltaGrau: deltaGrau,
          grauSugerido: codEfetivo,
        );
    _votosLocaisPorAutor[uidVia] = votosPorAutor;

    final comentarios = List<ComentarioComunidadeVia>.from(atual.comentarios);
    final textoLimpo = comentarioPublico?.trim();
    ComentarioComunidadeVia? novoComentario;
    if (textoLimpo != null && textoLimpo.isNotEmpty) {
      novoComentario = ComentarioComunidadeVia(
        uid: const Uuid().v4(),
        autorIdPublico: perfil.autorIdPublico,
        autorNomePublico: perfil.autorNomePublico,
        autorAvatarUrl: perfil.fotoUrl,
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
      await _despachante.enfileirarEDespachar(cliente, [
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
            autorAvatarUrl: perfil.fotoUrl,
            escaladaUid: uidVia,
            textoComentario: novoComentario.texto,
            tipoAscensao: estiloAscensao,
            criadoEm: novoComentario.criadoEm,
          ),
      ]);
    }
  }

  @override
  Future<void> editarComentario({
    required String escaladaUid,
    required String comentarioUid,
    required String novoTexto,
  }) async {
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    final perfil = _repositorioCaderneta.obterPerfil();
    _dadosPorEscalada[uidVia] = obterDadosEscalada(uidVia).comComentarioEditado(
      comentarioUid: comentarioUid,
      autorIdPublico: perfil.autorIdPublico,
      novoTexto: novoTexto,
    );
    _versaoNotifier.value++;
    if (validarUid(uidVia) && validarUid(perfil.autorIdPublico)) {
      final mut = MutacaoFilaInteracao.editarComentario(
        alvoUid: comentarioUid,
        escaladaUid: uidVia,
        autorIdPublico: perfil.autorIdPublico,
        novoTexto: novoTexto,
      );
      await _despachante.registrarMutacao(_clienteFila, mut);
    }
  }

  @override
  Future<void> excluirComentario({
    required String escaladaUid,
    required String comentarioUid,
  }) async {
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    final perfil = _repositorioCaderneta.obterPerfil();
    _dadosPorEscalada[uidVia] = obterDadosEscalada(uidVia).semComentarioDoAutor(
      comentarioUid: comentarioUid,
      autorIdPublico: perfil.autorIdPublico,
    );
    _versaoNotifier.value++;
    if (validarUid(uidVia) && validarUid(perfil.autorIdPublico)) {
      final mut = MutacaoFilaInteracao.excluirComentario(
        alvoUid: comentarioUid,
        escaladaUid: uidVia,
        autorIdPublico: perfil.autorIdPublico,
      );
      await _despachante.registrarMutacao(_clienteFila, mut);
    }
  }

  @override
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  }) async {
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    final perfil = _repositorioCaderneta.obterPerfil();
    final (atualizado, resultado, jaContribuira) = obterDadosEscalada(uidVia)
        .comAlertaReportado(
          escaladaUid: uidVia,
          categoria: categoria,
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          detalhe: detalhe,
        );
    _dadosPorEscalada[uidVia] = atualizado;
    if (!jaContribuira &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(resultado.uid)) {
      await _persistirEDespacharEventoAlerta(
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: resultado.uid,
          categoriaAlerta: categoria,
          detalhe: detalhe,
        ),
      );
    }
    _versaoNotifier.value++;
    return resultado;
  }

  @override
  Future<AlertaSegurancaVia> editarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required CategoriaAlertaSeguranca novaCategoria,
    String? detalhe,
  }) async {
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    await _hidratarDadosViaAPartirCacheAlertas(uidVia);
    final perfil = _repositorioCaderneta.obterPerfil();
    final (dadosAtualizados, alertaAtualizado) = obterDadosEscalada(uidVia)
        .comAlertaEditado(
          alertaUid: alertaUid,
          autorIdPublico: perfil.autorIdPublico,
          novaCategoria: novaCategoria,
          detalhe: detalhe,
        );
    _dadosPorEscalada[uidVia] = dadosAtualizados;

    if (validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaAtualizado.uid)) {
      await _persistirEDespacharMutacaoAlerta(
        uidVia,
        MutacaoFilaInteracao.editarAlerta(
          alvoUid: alertaAtualizado.uid,
          escaladaUid: uidVia,
          autorIdPublico: perfil.autorIdPublico,
          novaCategoria: novaCategoria,
          detalhe: detalhe,
        ),
      );
    }
    _versaoNotifier.value++;
    return alertaAtualizado;
  }

  @override
  Future<void> excluirAlerta({
    required String escaladaUid,
    required String alertaUid,
  }) async {
    final uidVia = _exigirEscaladaUidNaoVazio(escaladaUid);
    await _hidratarDadosViaAPartirCacheAlertas(uidVia);
    final perfil = _repositorioCaderneta.obterPerfil();
    _dadosPorEscalada[uidVia] = obterDadosEscalada(uidVia).semAlertaDoAutor(
      alertaUid: alertaUid,
      autorIdPublico: perfil.autorIdPublico,
    );

    if (validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaUid)) {
      await _persistirEDespacharMutacaoAlerta(
        uidVia,
        MutacaoFilaInteracao.excluirAlerta(
          alvoUid: alertaUid,
          escaladaUid: uidVia,
          autorIdPublico: perfil.autorIdPublico,
        ),
      );
    }
    _versaoNotifier.value++;
  }

  @override
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  }) async {
    final uidVia = escaladaUid.trim();
    final perfil = _repositorioCaderneta.obterPerfil();
    final atualizado = obterDadosEscalada(uidVia).comConfirmacaoAlerta(
      alertaUid: alertaUid,
      autorIdPublico: perfil.autorIdPublico,
      aindaEstaLa: aindaEstaLa,
    );
    if (atualizado == null) return;
    _dadosPorEscalada[uidVia] = atualizado;
    if (validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaUid)) {
      await _persistirEDespacharEventoAlerta(
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: perfil.autorIdPublico,
          autorNomePublico: perfil.autorNomePublico,
          escaladaUid: uidVia,
          alertaAlvoUid: alertaUid,
          alertaAtivo: aindaEstaLa,
        ),
      );
    }
    _versaoNotifier.value++;
  }

  Future<void> _persistirEDespacharEventoAlerta(
    ItemFilaInteracao evento,
  ) async {
    await _hidratarEstadoLocalSeNecessario();
    await _armazenamentoFila.adicionarEventoAlerta(evento);
    if (_clienteFila != null) {
      await _despachante.enfileirarEDespachar(_clienteFila, [evento]);
    }
  }

  Future<void> _persistirEDespacharMutacaoAlerta(
    String uidVia,
    MutacaoFilaInteracao mutacao,
  ) async {
    await _armazenamentoFila.aplicarMutacaoAlertaNaVia(uidVia, mutacao);
    await _despachante.registrarMutacao(_clienteFila, mutacao);
  }

  Future<void> _hidratarDadosViaAPartirCacheAlertas(String uidVia) async {
    await _hidratarEstadoLocalSeNecessario();
    if (_dadosPorEscalada.containsKey(uidVia)) return;
    final evs = [
      ...?_armazenamentoFila.eventosAlertasPorVia[uidVia],
      ..._despachante.itensPendentes.where((i) => i.escaladaUid == uidVia),
    ];
    if (evs.isEmpty) return;
    _dadosPorEscalada[uidVia] = consolidarItensFilaEmDadosComunidade(
      aplicarMutacoesSobreItens(evs, _despachante.mutacoesPendentes),
      ehBoulder: false,
      avataresPorAutor: _mapaAvatarPerfilLocal(),
    );
  }

  static String _exigirEscaladaUidNaoVazio(String escaladaUid) {
    final limpo = escaladaUid.trim();
    if (limpo.isEmpty) {
      throw ArgumentError.value(escaladaUid, 'escaladaUid', 'UID vazio.');
    }
    return limpo;
  }

  Map<String, String> _mapaAvatarPerfilLocal() {
    final p = _repositorioCaderneta.obterPerfil();
    final f = p.fotoUrl?.trim();
    return (f != null && f.isNotEmpty && p.autorIdPublico.isNotEmpty)
        ? {p.autorIdPublico: f}
        : const {};
  }

  Future<void> _hidratarEstadoLocalSeNecessario() async {
    if (_cacheCarregado) return;
    _cacheCarregado = true;
    await _despachante.garantirCarregada();
    await _armazenamentoFila.hidratarMemoriaAlertas();
  }
}
