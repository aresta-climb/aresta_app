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
      _atualizarCacheAlertasDaVia(uidVia, combinados);
      await _persistirCacheAlertasUsuario();

      _dadosPorEscalada[uidVia] = consolidarItensFilaEmDadosComunidade(
        combinados,
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
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
      for (final item in remotos) {
        porVia[item.escaladaUid]?.add(item);
      }
      for (final pendente in _despachante.itensPendentes) {
        porVia[pendente.escaladaUid]?.add(pendente);
      }

      for (final entrada in porVia.entries) {
        final uid = entrada.key;
        final itens = entrada.value
          ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
        _atualizarCacheAlertasDaVia(uid, itens);
        final consolidado = consolidarItensFilaEmDadosComunidade(
          itens,
          ehBoulder: false,
        );
        final anterior = _dadosPorEscalada[uid];
        _dadosPorEscalada[uid] = DadosComunidadeVia(
          consensoGrau: anterior != null && anterior.consensoGrau.possuiVotos
              ? anterior.consensoGrau
              : consolidado.consensoGrau,
          alertasAtivos: consolidado.alertasAtivos,
          comentarios: consolidado.comentarios,
        );
      }
      await _persistirCacheAlertasUsuario();
      _versaoNotifier.value++;
    } catch (e, stackTrace) {
      DespachanteFilaInteracoes.registrarFalhaRede(
        'Falha ao consultar fila_interacoes em lote (${uidsValidos.length} vias)',
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
    final votosPorAutor =
        Map<String, ({int? deltaGrau, int? grauSugerido})>.from(
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
            escaladaUid: uidVia,
            textoComentario: novoComentario.texto,
            tipoAscensao: estiloAscensao,
            criadoEm: novoComentario.criadoEm,
          ),
      ]);
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
    var jaContribuira = false;
    if (indiceExistente >= 0) {
      final anterior = alertas[indiceExistente];
      jaContribuira = anterior.jaConfirmadoPor(perfil.autorIdPublico);
      final detalheLimpo = detalhe?.trim();
      resultado = anterior.copyWith(
        confirmacoesAtivas: jaContribuira
            ? anterior.confirmacoesAtivas
            : anterior.confirmacoesAtivas + 1,
        confirmadoresUids: {
          ...anterior.confirmadoresUids,
          perfil.autorIdPublico,
        },
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
        autorIdPublico: perfil.autorIdPublico,
        autorNomePublico: perfil.autorNomePublico,
      );
      alertas.insert(0, resultado);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    if (!jaContribuira &&
        validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(resultado.uid)) {
      final evento = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: perfil.autorIdPublico,
        autorNomePublico: perfil.autorNomePublico,
        escaladaUid: uidVia,
        alertaAlvoUid: resultado.uid,
        categoriaAlerta: categoria,
        detalhe: detalhe,
      );
      await _registrarEventoAlertaLocal(evento);
      if (_clienteFila != null) {
        await _despachante.enfileirarEDespachar(_clienteFila, [evento]);
      }
    }
    _versaoNotifier.value++;
    return resultado;
  }

  @override
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  }) async {
    final uidVia = escaladaUid.trim();
    final perfil = _repositorioCaderneta.obterPerfil();
    final atual = obterDadosEscalada(uidVia);
    final alertas = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final indice = alertas.indexWhere((a) => a.uid == alertaUid);
    if (indice < 0) return;

    if (aindaEstaLa) {
      final existente = alertas[indice];
      if (existente.jaConfirmadoPor(perfil.autorIdPublico)) return;
      alertas[indice] = existente.copyWith(
        confirmacoesAtivas: existente.confirmacoesAtivas + 1,
        confirmadoresUids: {
          ...existente.confirmadoresUids,
          perfil.autorIdPublico,
        },
      );
    } else {
      alertas.removeAt(indice);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    if (validarUid(uidVia) &&
        validarUid(perfil.autorIdPublico) &&
        validarUid(alertaUid)) {
      final evento = ItemFilaInteracao.confirmacaoAlerta(
        autorIdPublico: perfil.autorIdPublico,
        autorNomePublico: perfil.autorNomePublico,
        escaladaUid: uidVia,
        alertaAlvoUid: alertaUid,
        alertaAtivo: aindaEstaLa,
      );
      await _registrarEventoAlertaLocal(evento);
      if (_clienteFila != null) {
        await _despachante.enfileirarEDespachar(_clienteFila, [evento]);
      }
    }
    _versaoNotifier.value++;
  }

  void _atualizarCacheAlertasDaVia(
    String uidVia,
    Iterable<ItemFilaInteracao> itens,
  ) {
    final filtrados = itens
        .where(
          (i) =>
              i.tipo == TipoFilaInteracao.alertaSeguranca ||
              i.tipo == TipoFilaInteracao.confirmacaoAlerta,
        )
        .toList();
    if (filtrados.isEmpty) {
      _eventosAlertasPorVia.remove(uidVia);
    } else {
      _eventosAlertasPorVia[uidVia] = filtrados;
    }
  }

  Future<void> _registrarEventoAlertaLocal(ItemFilaInteracao evento) async {
    await _hidratarEstadoLocalSeNecessario();
    _eventosAlertasPorVia
        .putIfAbsent(evento.escaladaUid, () => <ItemFilaInteracao>[])
        .add(evento);
    await _persistirCacheAlertasUsuario();
  }

  Future<void> _persistirCacheAlertasUsuario() =>
      _armazenamentoFila.salvarCacheAlertasUsuario([
        for (final lista in _eventosAlertasPorVia.values) ...lista,
      ]);

  Future<void> _hidratarEstadoLocalSeNecessario() async {
    if (_cacheCarregado) return;
    _cacheCarregado = true;
    await _despachante.garantirCarregada();
    for (final ev in await _armazenamentoFila.carregarCacheAlertasUsuario()) {
      _eventosAlertasPorVia
          .putIfAbsent(ev.escaladaUid, () => <ItemFilaInteracao>[])
          .add(ev);
    }
  }
}
