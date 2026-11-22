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

    final bolhas = <BolhaAlertaMapaApresentacao>[];
    final alertasJaProjetados = <String>{};

    for (final entrada in _referenciasResolvidas.entries) {
      final ref = entrada.key;
      final resolvido = entrada.value;
      final ancora = _resolverAncoraReferencia(ref, poiPorUid);
      if (ancora == null) continue;

      final relX = (ancora.$1 / _mapa.larguraMapa).clamp(0.04, 0.96);
      final relY = (ancora.$2 / _mapa.alturaMapa).clamp(0.04, 0.96);

      for (final esc in _coletarEscaladasDoAlvo(resolvido)) {
        final alertas = obterAlertasDaEscalada(esc.uid);
        if (alertas.isEmpty) continue;
        final principal = alertas.first;
        if (!alertasJaProjetados.add('${ref.hashCode}_${principal.uid}')) {
          continue;
        }
        bolhas.add(
          BolhaAlertaMapaApresentacao(
            alerta: principal,
            escaladaUid: esc.uid,
            nomeEscalada: obterNomeEscalada(esc),
            relX: relX,
            relY: relY,
          ),
        );
        break;
      }
    }
    return List.unmodifiable(bolhas);
  }

  /// Oculta imediatamente [alertaUid] no mapa e agenda sua resolução definitiva após [duracaoJanelaDesfazer].
  void iniciarResolucaoAlertaComDesfazer(String escaladaUid, String alertaUid) {
    _resolucoesPendentes.remove(alertaUid)?.timer.cancel();
    _resolucoesPendentes[alertaUid] = (
      escaladaUid: escaladaUid,
      timer: Timer(duracaoJanelaDesfazer, () {
        _resolucoesPendentes.remove(alertaUid);
        unawaited(confirmarAlerta(escaladaUid, alertaUid, aindaEstaLa: false));
      }),
    );
    _notificar();
  }

  /// Cancela a resolução pendente de [alertaUid], restaurando a bolha no mapa.
  void desfazerResolucaoAlerta(String alertaUid) {
    final pendente = _resolucoesPendentes.remove(alertaUid);
    if (pendente != null) {
      pendente.timer.cancel();
      _notificar();
    }
  }

  /// Registra a resposta *"Ainda está lá?"* sobre [alertaUid] na via [escaladaUid].
  Future<bool> confirmarAlerta(
    String escaladaUid,
    String alertaUid, {
    required bool aindaEstaLa,
  }) async {
    try {
      await repositorioInteracoes.confirmarAlerta(
        escaladaUid: escaladaUid,
        alertaUid: alertaUid,
        aindaEstaLa: aindaEstaLa,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao confirmar alerta $alertaUid pelo mapa na via $escaladaUid',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static List<Escalada> _coletarEscaladasDoAlvo(ResolvedDataset resolvido) {
    if (resolvido.escalada != null) {
      return [resolvido.escalada!];
    }
    if (resolvido.setor != null) {
      return resolvido.setor!.escaladas;
    }
    if (resolvido.grupo != null) {
      return [
        for (final s in resolvido.grupo!.setores)
          if (s.hasConteudo()) ...s.conteudo.escaladas,
      ];
    }
    return const [];
  }

  static (double, double)? _resolverAncoraReferencia(
    Mapa_Referencia ref,
    Map<String, Mapa_PontoDeInteresse> poiPorUid,
  ) {
    for (final uid in ref.pontosUids) {
      final poi = poiPorUid[uid];
      if (poi == null) continue;
      final ancora = _extrairCoordenadaAncora(poi);
      if (ancora != null) return ancora;
    }
    return null;
  }

  static (double, double)? _extrairCoordenadaAncora(
    Mapa_PontoDeInteresse ponto,
  ) {
    switch (ponto.whichTipoArea()) {
      case Mapa_PontoDeInteresse_TipoArea.circulo:
        return (ponto.circulo.x.toDouble(), ponto.circulo.y.toDouble());
      case Mapa_PontoDeInteresse_TipoArea.quadrado:
        return (ponto.quadrado.x.toDouble(), ponto.quadrado.y.toDouble());
      case Mapa_PontoDeInteresse_TipoArea.retangulo:
        return (ponto.retangulo.x.toDouble(), ponto.retangulo.y.toDouble());
      case Mapa_PontoDeInteresse_TipoArea.poligono:
        final coords = ponto.poligono.coordenadas;
        if (coords.length < 2) return null;
        var somaX = 0.0;
        var somaY = 0.0;
        final totalVertices = coords.length ~/ 2;
        for (var i = 0; i < totalVertices * 2; i += 2) {
          somaX += coords[i];
          somaY += coords[i + 1];
        }
        return (somaX / totalVertices, somaY / totalVertices);
      case Mapa_PontoDeInteresse_TipoArea.linha:
        final linha = ponto.linha;
        if (linha.hasCompilado()) {
          for (final m in linha.compilado.marcadores) {
            if (m.tipo == NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR ||
                m.tipo == NoTrajeto_TipoNo.INICIO_AGACHADO) {
              return (m.x.toDouble(), m.y.toDouble());
            }
          }
          if (linha.compilado.hasCaixaDelimitadora()) {
            return (
              linha.compilado.caixaDelimitadora.x.toDouble(),
              linha.compilado.caixaDelimitadora.y.toDouble(),
            );
          }
        }
        if (linha.hasConteudo() && linha.conteudo.nos.isNotEmpty) {
          final primeiro = linha.conteudo.nos.first;
          return (primeiro.x.toDouble(), primeiro.y.toDouble());
        }
        return null;
      case Mapa_PontoDeInteresse_TipoArea.notSet:
        return null;
    }
  }
}
