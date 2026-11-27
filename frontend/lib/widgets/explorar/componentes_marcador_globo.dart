// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../idioma/tradutor_app.dart';
import '../clima/selo_umidade_pico.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Ícone vetorial oficial da marca Aresta (`logo_app_trace.svg`) usado nas bolhas de picos do mapa.
class IconeMarcaAresta extends StatelessWidget {
  final double largura;
  final Color cor;

  const IconeMarcaAresta({
    super.key,
    this.largura = 13.0,
    this.cor = PaletaUmidadePico.corPontoArestaPadrao,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo_app_trace.svg',
      width: largura,
      height: largura * 0.54,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
    );
  }
}

/// Dados visuais imutáveis de um pico projetado sobre o globo/terreno da aba `Explorar`.
class MarcadorPicoGlobo {
  final String id;
  final String nome;
  final String uf;
  final String setorPrincipal;
  final double latitude;
  final double longitude;
  final int altitudeBaseMetros;
  final int altitudePicoMetros;
  final int dimensaoGradeDem;
  final double raioGradeDemGraus;
  final List<int> gradeDemMetros;
  final EstadoUmidadePico umidade;

  const MarcadorPicoGlobo({
    required this.id,
    required this.nome,
    required this.uf,
    this.setorPrincipal = 'Setor Principal',
    required this.latitude,
    required this.longitude,
    required this.altitudeBaseMetros,
    required this.altitudePicoMetros,
    this.dimensaoGradeDem = 0,
    this.raioGradeDemGraus = 0.024,
    this.gradeDemMetros = const [],
    this.umidade = const EstadoUmidadePico.seco(),
  });

  /// Converte o marcador para referência numérica de amostragem topográfica contínua.
  PicoRelevoReferencia paraReferenciaRelevo() => PicoRelevoReferencia(
        id: id,
        latitude: latitude,
        longitude: longitude,
        altitudeBaseMetros: altitudeBaseMetros,
        altitudePicoMetros: altitudePicoMetros,
        dimensaoGradeDem: dimensaoGradeDem,
        raioGradeDemGraus: raioGradeDemGraus,
        gradeDemMetros: gradeDemMetros,
      );
}

/// Cápsula superior direita de controles rápidos do mapa (`3D/2D`, `Visão Globo` e `Minha Localização`).
class CapsulaControlesModoGlobo extends StatelessWidget {
  final bool modo3D;
  final bool temLocalizacaoUsuario;
  final bool buscandoLocalizacaoUsuario;
  final VoidCallback aoAlternarModo3D;
  final VoidCallback aoResetarGlobo;
  final VoidCallback? aoCentralizarNoUsuario;

  const CapsulaControlesModoGlobo({
    super.key,
    required this.modo3D,
    required this.temLocalizacaoUsuario,
    required this.buscandoLocalizacaoUsuario,
    required this.aoAlternarModo3D,
    required this.aoResetarGlobo,
    this.aoCentralizarNoUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC10141A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const Key('botao_alternar_3d_2d'),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            onTap: aoAlternarModo3D,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                modo3D ? '3D' : '2D',
                style: const TextStyle(
                  color: Color(0xFFE27D60),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 14, color: Colors.white12),
          InkWell(
            key: const Key('botao_resetar_globo'),
            borderRadius: aoCentralizarNoUsuario == null
                ? const BorderRadius.horizontal(right: Radius.circular(20))
                : BorderRadius.zero,
            onTap: aoResetarGlobo,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Icon(
                Icons.public,
                size: 14,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),
          if (aoCentralizarNoUsuario != null) ...[
            Container(width: 1, height: 14, color: Colors.white12),
            InkWell(
              key: const Key('botao_minha_localizacao'),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              onTap: aoCentralizarNoUsuario,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: buscandoLocalizacaoUsuario
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Color(0xFF38BDF8),
                        ),
                      )
                    : Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: temLocalizacaoUsuario
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFD1D5DB),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

