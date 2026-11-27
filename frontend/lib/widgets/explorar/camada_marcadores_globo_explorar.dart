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

    return [
      Positioned(
        left: pt.x - 11,
        top: pt.y - 11,
        child: IgnorePointer(
          child: Container(
            key: const Key('marcador_localizacao_usuario'),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x3838BDF8),
              border: Border.all(color: const Color(0x5538BDF8)),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7),
                border: Border.all(color: Colors.white, width: 2.0),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  static List<Widget> _construirMarcadoresLod({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required List<MarcadorPicoGlobo> picos,
    required List<PicoRelevoReferencia> referencias,
    required String? picoSelecionadoId,
    required double recuoSuperiorControles,
    required void Function(MarcadorPicoGlobo pico, {double? lodExplicito})
        aoSelecionarPico,
  }) {
    final limiteInferior = tamanho.height - controlador.alturaGavetaPx + 8.0;
    final limiteSuperior = recuoSuperiorControles + 12.0;

    if (controlador.altitudeCameraKm >= 1800.0) {
      return _construirClustersPorUf(
        tamanho: tamanho,
        controlador: controlador,
        picos: picos,
        limiteSuperior: limiteSuperior,
        limiteInferior: limiteInferior,
        aoSelecionarPico: aoSelecionarPico,
      );
    }

    final visiveis = <({MarcadorPicoGlobo pico, PontoProjetadoTela pt})>[];
    final pesoTerreno =
        ControladorCameraGlobo.smoothstep(1.35, 2.05, controlador.lod);
    for (final p in picos) {
      final elev = pesoTerreno > 0.01
          ? math.max(
                0.0,
                GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
                  latitude: p.latitude,
                  longitude: p.longitude,
                  picosReferencia: referencias,
                ),
              ) *
              pesoTerreno
          : 0.0;
      final pt = controlador.projetarCoordenada(
        latitude: p.latitude,
        longitude: p.longitude,
        elevacaoMetros: elev,
        tamanhoTela: tamanho,
      );
      if (pt.visivel &&
          pt.x > 16 &&
          pt.x < tamanho.width - 16 &&
          pt.y > limiteSuperior &&
          pt.y < limiteInferior) {
        visiveis.add((pico: p, pt: pt));
      }
    }

    visiveis.sort((a, b) {
      final prioA = a.pico.id == picoSelecionadoId ? 1 : 0;
      final prioB = b.pico.id == picoSelecionadoId ? 1 : 0;
      return prioA.compareTo(prioB);
    });

