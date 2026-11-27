// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'componentes_marcador_globo.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

export 'componentes_marcador_globo.dart';

/// Projetor declarativo das camadas espaciais sobrepostas ao globo/mapa:
/// localidades reais do IBGE sem colisão, ponto GPS do usuário, clusters por UF (`LOD 0`),
/// bolhas compactas Aresta e pílula expandida do pico selecionado.
abstract final class CamadaMarcadoresGloboExplorar {
  /// Constrói todas as camadas de widgets posicionados (`Positioned`) sobre o canvas do planeta.
  static List<Widget> construirCamadas({
    required BuildContext context,
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo? redeViaria,
    required List<MarcadorPicoGlobo> picos,
    required List<PicoRelevoReferencia> referenciasRelevo,
    required String? picoSelecionadoId,
    required ({double latitude, double longitude})? localizacaoUsuario,
    required double recuoSuperiorControles,
    double progressoLuzViaria = 1.0,
    required void Function(MarcadorPicoGlobo pico, {double? lodExplicito})
        aoSelecionarPico,
  }) {
    return <Widget>[
      ..._construirRotulosLocalidadesProximas(
        tamanho: tamanho,
        controlador: controlador,
        redeViaria: redeViaria,
        picos: picos,
        referencias: referenciasRelevo,
        picoSelecionadoId: picoSelecionadoId,
        recuoSuperiorControles: recuoSuperiorControles,
        progressoLuzViaria: progressoLuzViaria,
      ),
      ..._construirMarcadorLocalizacaoUsuario(
        tamanho: tamanho,
        controlador: controlador,
        localizacaoUsuario: localizacaoUsuario,
        referencias: referenciasRelevo,
        recuoSuperiorControles: recuoSuperiorControles,
      ),
      ..._construirMarcadoresLod(
        tamanho: tamanho,
        controlador: controlador,
        picos: picos,
        referencias: referenciasRelevo,
        picoSelecionadoId: picoSelecionadoId,
        recuoSuperiorControles: recuoSuperiorControles,
        aoSelecionarPico: aoSelecionarPico,
      ),
    ];
  }

  static List<Widget> _construirMarcadorLocalizacaoUsuario({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required ({double latitude, double longitude})? localizacaoUsuario,
    required List<PicoRelevoReferencia> referencias,
    required double recuoSuperiorControles,
  }) {
    final loc = localizacaoUsuario;
    if (loc == null) return const [];
    final pesoTerreno =
        ControladorCameraGlobo.smoothstep(1.35, 2.05, controlador.lod);
    final elev = pesoTerreno > 0.01
        ? math.max(
              0.0,
              GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
                latitude: loc.latitude,
                longitude: loc.longitude,
                picosReferencia: referencias,
              ),
            ) *
            pesoTerreno
        : 0.0;
    final pt = controlador.projetarCoordenada(
      latitude: loc.latitude,
      longitude: loc.longitude,
      elevacaoMetros: elev,
      tamanhoTela: tamanho,
    );
    final limiteInferior = tamanho.height - controlador.alturaGavetaPx + 8.0;
    final limiteSuperior = recuoSuperiorControles + 8.0;
    if (!pt.visivel ||
        pt.x < 10 ||
        pt.x > tamanho.width - 10 ||
        pt.y < limiteSuperior ||
        pt.y > limiteInferior) {
      return const [];
    }

