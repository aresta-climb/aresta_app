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

