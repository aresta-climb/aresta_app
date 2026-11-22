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

}
