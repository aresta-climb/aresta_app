// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../services/controlador_interacoes_usuario.dart';
import '../../services/firebase/app_logger.dart';
import '../../utils/consulta_dataset.dart';
import '../../utils/formatador_escalada.dart';

/// Modelo imutável de apresentação de uma bolha de alerta estilo Waze projetada sobre um `Mapa`.
@immutable
class BolhaAlertaMapaApresentacao {
  /// Alerta ativo exibido na bolha.
  final AlertaSegurancaVia alerta;

  /// Identificador NanoID da escalada associada ao alerta.
  final String escaladaUid;

  /// Nome legível da escalada onde o risco foi reportado.
  final String nomeEscalada;

  /// Coordenada horizontal normalizada (`0.0` a `1.0`) no espaço da imagem do mapa.
  final double relX;

  /// Coordenada vertical normalizada (`0.0` a `1.0`) no espaço da imagem do mapa.
  final double relY;

  /// Cria uma instância constante de [BolhaAlertaMapaApresentacao].
  const BolhaAlertaMapaApresentacao({
    required this.alerta,
    required this.escaladaUid,
    required this.nomeEscalada,
    required this.relX,
    required this.relY,
  });
}

/// ViewModel (MVVM) responsável por sincronizar em lote os alertas ativos das vias de um [Mapa]
/// e projetar suas bolhas vermelhas estilo Waze nas coordenadas exatas da parede/setor.
class AlertasMapaInterativoViewModel extends ChangeNotifier {
  /// Repositório reativo compartilhado de alertas e interações.
  final RepositorioInteracoesVia repositorioInteracoes;

  /// Controlador de recursos ativos no ambiente.
  final ControladorInteracoesUsuario controladorInteracoes;

  /// Duração da janela para desfazer resolução de alerta antes de persistir no Supabase.
  final Duration duracaoJanelaDesfazer;

  Mapa _mapa;
  Map<Mapa_Referencia, ResolvedDataset> _referenciasResolvidas;
  final Map<String, ({String escaladaUid, Timer timer})>
  _resolucoesPendentes = {};
  final Set<String> _uidsJaSincronizados = <String>{};
  bool _descartado = false;

  /// Cria uma instância de [AlertasMapaInterativoViewModel] e dispara a busca em lote inicial.
  AlertasMapaInterativoViewModel({
    required Mapa mapa,
    required Map<Mapa_Referencia, ResolvedDataset> referenciasResolvidas,
    RepositorioInteracoesVia? repositorioInteracoes,
    ControladorInteracoesUsuario? controladorInteracoes,
    this.duracaoJanelaDesfazer = const Duration(seconds: 4),
  }) : _mapa = mapa,
       _referenciasResolvidas = Map.unmodifiable(referenciasResolvidas),
       repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia {
    this.repositorioInteracoes.alteracoesListenable.addListener(_notificar);
    this.controladorInteracoes.interacoesAtivasNotifier.addListener(_notificar);
    _sincronizarViasDoMapa();
  }

  /// Atualiza o [mapa] e as [referenciasResolvidas] quando o mapa ativo muda no carrossel.
  void atualizarContextoMapa({
    required Mapa mapa,
    required Map<Mapa_Referencia, ResolvedDataset> referenciasResolvidas,
  }) {
    _mapa = mapa;
    _referenciasResolvidas = Map.unmodifiable(referenciasResolvidas);
    _sincronizarViasDoMapa();
    _notificar();
  }

  bool get _habilitado => controladorInteracoes.recursoHabilitadoNoAmbiente;

  void _sincronizarViasDoMapa() {
    if (!_habilitado) return;
    final novosUids = <String>{};
    for (final resolvido in _referenciasResolvidas.values) {
      for (final esc in _coletarEscaladasDoAlvo(resolvido)) {
        final uid = esc.uid.trim();
        if (uid.isNotEmpty && _uidsJaSincronizados.add(uid)) {
          novosUids.add(uid);
        }
      }
    }
    if (novosUids.isEmpty) return;
    unawaited(
      repositorioInteracoes.sincronizarEscaladasEmLote(novosUids).catchError((
        Object e,
      ) {
        AppLogger.instance.logAviso(
          'Sincronização em lote de alertas do mapa adiada: $e',
        );
      }),
    );
  }

  void _notificar() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    final pendentes = _resolucoesPendentes.entries.toList(growable: false);
    _resolucoesPendentes.clear();
    for (final entrada in pendentes) {
      entrada.value.timer.cancel();
      unawaited(
        confirmarAlerta(
          entrada.value.escaladaUid,
          entrada.key,
          aindaEstaLa: false,
        ),
      );
    }
    repositorioInteracoes.alteracoesListenable.removeListener(_notificar);
    controladorInteracoes.interacoesAtivasNotifier.removeListener(_notificar);
    super.dispose();
  }

  /// Retorna os alertas ativos visíveis de [escaladaUid] (excluindo janelas pendentes de Desfazer).
  List<AlertaSegurancaVia> obterAlertasDaEscalada(String escaladaUid) {
    if (!_habilitado || escaladaUid.trim().isEmpty) return const [];
    return repositorioInteracoes
        .obterDadosEscalada(escaladaUid.trim())
        .alertasAtivos
        .where((a) => !_resolucoesPendentes.containsKey(a.uid))
        .toList(growable: false);
  }

  /// Determina o estado de permissão e deduplicação do usuário atual sobre [alerta] no mapa.
  EstadoInteracaoAlertaUsuario estadoInteracaoDoAlerta(
    AlertaSegurancaVia alerta,
  ) => alerta.resolverEstadoParaUsuario(
    estaAutenticado: repositorioInteracoes.usuarioEstaAutenticado,
    autorIdPublicoUsuario: repositorioInteracoes.autorIdPublicoAtual,
  );

  /// Retorna todos os alertas ativos agregados das vias pertencentes a [setor].
  List<AlertaSegurancaVia> obterAlertasDoSetor(Setor setor) {
    if (!_habilitado) return const [];
    final resultado = <AlertaSegurancaVia>[];
    for (final esc in setor.escaladas) {
      resultado.addAll(obterAlertasDaEscalada(esc.uid));
    }
    return List.unmodifiable(resultado);
  }

  /// Projeta todas as bolhas ativas nas coordenadas normalizadas `(relX, relY)` do [_mapa].
  List<BolhaAlertaMapaApresentacao> get bolhasNoMapa {
    if (!_habilitado || _mapa.larguraMapa <= 0 || _mapa.alturaMapa <= 0) {
      return const [];
    }
    final poiPorUid = <String, Mapa_PontoDeInteresse>{
      for (final p in _mapa.pontosDeInteresse)
        if (p.uid.isNotEmpty) p.uid: p,
    };
  }
}
