// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';

void main() {
  group('ControladorCameraGlobo', () {
    test(
      'deve classificar corretamente os 4 indices de LOD, alternar 3D/2D e deslocar centro optico com a gaveta',
      () {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -19.5,
          longitudeInicial: -44.0,
          lodInicial: 0.2,
        );
        addTearDown(ctrl.dispose);

        expect(ctrl.indiceLod, equals(0));
        ctrl.definirLod(1.1);
        expect(ctrl.indiceLod, equals(1));
        ctrl.definirLod(2.0, latAlvoSuave: -20.0, lonAlvoSuave: -44.3);
        expect(ctrl.indiceLod, equals(2));
        ctrl.definirLod(2.9);
        expect(ctrl.indiceLod, equals(3));

        const tela = Size(380, 720);
        final ptGavetaBaixa = ctrl.projetarCoordenada(
          latitude: ctrl.latitudeCentral,
          longitude: ctrl.longitudeCentral,
          elevacaoMetros: 1200,
          tamanhoTela: tela,
        );
        ctrl.atualizarAlturaGaveta(360);
        final ptGavetaAlta = ctrl.projetarCoordenada(
          latitude: ctrl.latitudeCentral,
          longitude: ctrl.longitudeCentral,
          elevacaoMetros: 1200,
          tamanhoTela: tela,
        );
        expect(ptGavetaAlta.visivel, isTrue);
        expect(ptGavetaAlta.y, lessThan(ptGavetaBaixa.y));

        // Oculta pontos no hemisferio oposto em 3D e projeta plano em 2D
        ctrl.definirLod(0.3);
        final oculto = ctrl.projetarCoordenada(
          latitude: 25.0,
          longitude: 135.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
        );
        expect(oculto.visivel, isFalse);

        ctrl.alternarModo3D();
        expect(ctrl.modo3D, isFalse);
        ctrl.definirModo3D(false);
        expect(ctrl.modo3D, isFalse);
        ctrl.definirModo3D(true);
        expect(ctrl.modo3D, isTrue);
        ctrl.definirModo3D(false);
        final plano2d = ctrl.projetarCoordenada(
          latitude: -19.5,
          longitude: -44.0,
          elevacaoMetros: 1000,
          tamanhoTela: tela,
        );
        expect(plano2d.visivel, isTrue);

        // Em 2D nos cantos extremos (lat=68, lon=179), mantem escala sem esmagar X e trava topo/base dentro do mapa
        final ctrlCanto2d = ControladorCameraGlobo(
          latitudeInicial: 68.0,
          longitudeInicial: 179.0,
          lodInicial: 0.0,
          modo3DInicial: false,
        );
        addTearDown(ctrlCanto2d.dispose);
        final topoMapa2d = ctrlCanto2d.projetarCoordenada(
          latitude: 85.0,
          longitude: 185.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
          estenderBordaHorizonte: true,
        );
        final baseMapa2d = ctrlCanto2d.projetarCoordenada(
          latitude: -85.0,
          longitude: 179.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
          estenderBordaHorizonte: true,
        );
        expect(topoMapa2d.visivel, isTrue);
        expect(topoMapa2d.y, lessThanOrEqualTo(0.5));
        expect(baseMapa2d.y, greaterThanOrEqualTo(tela.height - 0.5));
        expect(topoMapa2d.x, greaterThan(tela.width * 0.5));

