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

        // Em 3D inclinado para o Polo Norte, pontos do outro lado do polo (lon + 180) sao visiveis
        final ctrlPolo3d = ControladorCameraGlobo(
          latitudeInicial: 65.0,
          longitudeInicial: -150.0,
          lodInicial: 0.22,
          modo3DInicial: true,
        );
        addTearDown(ctrlPolo3d.dispose);
        final outroLadoPolo = ctrlPolo3d.projetarCoordenada(
          latitude: 78.0,
          longitude: 30.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
        );
        expect(outroLadoPolo.visivel, isTrue);

        // estenderBordaHorizonte projeta vertices levemente atras do limbo (z0 ~ -0.05) ate a borda do disco
        final bordaLimbo = ctrlPolo3d.projetarCoordenada(
          latitude: -27.0,
          longitude: -150.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
          estenderBordaHorizonte: true,
        );
        expect(bordaLimbo.visivel, isTrue);
      },
    );

    test(
      'deve executar voo parabolico (Fly-To) com recuo de zoom entre estados e desacelerar inercia ate parar',
      () {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -19.34,
          longitudeInicial: -43.62,
          lodInicial: 2.2,
        );
        addTearDown(ctrl.dispose);

        ctrl.iniciarVooParabolico(
          destinoLat: -15.79,
          destinoLon: -48.77,
          destinoLod: 2.2,
        );
        expect(ctrl.temAnimacaoAtiva, isTrue);

        // No meio do voo distante, o arco parabolico recua temporariamente o lod abaixo de 2.2
        var menorLodDuranteVoo = 2.2;
        for (var i = 0; i < 80 && ctrl.temAnimacaoAtiva; i++) {
          ctrl.avancarQuadroFisica(0.025);
          if (ctrl.lod < menorLodDuranteVoo) {
            menorLodDuranteVoo = ctrl.lod;
          }
        }

        expect(menorLodDuranteVoo, lessThan(2.15));
        expect(ctrl.temAnimacaoAtiva, isFalse);
        expect(ctrl.latitudeCentral, closeTo(-15.79, 0.01));
        expect(ctrl.longitudeCentral, closeTo(-48.77, 0.01));

        // Arrasto no globo gera inercia que desacelera ate parar; no LOD 3 gira azimute
        ctrl.definirLod(0.5);
        ctrl.aplicarArrasto(dxPx: 24, dyPx: -12);
        expect(ctrl.temAnimacaoAtiva, isTrue);
        for (var i = 0; i < 120 && ctrl.temAnimacaoAtiva; i++) {
          ctrl.avancarQuadroFisica(0.03);
        }
        expect(ctrl.temAnimacaoAtiva, isFalse);

        ctrl.definirModo3D(true);
        ctrl.definirLod(4.2);
        final latAntesH = ctrl.latitudeCentral;
        final lonAntesH = ctrl.longitudeCentral;
        ctrl.aplicarArrasto(dxPx: 48, dyPx: 0);
        // Em zoom maximo 3D, arrasto puramente horizontal move APENAS longitude (sem eixo diagonal!)
        expect(ctrl.longitudeCentral, isNot(equals(lonAntesH)));
        expect(ctrl.latitudeCentral, closeTo(latAntesH, 1e-6));

        final lonAntesV = ctrl.longitudeCentral;
        final latAntesV = ctrl.latitudeCentral;
        ctrl.aplicarArrasto(dxPx: 0, dyPx: -48);
        // Arrasto puramente vertical move APENAS latitude (sem eixo diagonal!)
        expect(ctrl.latitudeCentral, isNot(equals(latAntesV)));
        expect(ctrl.longitudeCentral, closeTo(lonAntesV, 1e-6));
        expect(ctrl.giroLocalRad, equals(0.0));

        // Representacao nitida do Geoide Terrestre (WGS84 achatado nos polos + ondulacoes gravitacionais NASA EGM96)
        final rEquador = ControladorCameraGlobo.raioNormalizadoGeoide(
          latitude: -5.0,
          longitude: 146.0,
        );
        final rPoloNorte = ControladorCameraGlobo.raioNormalizadoGeoide(
          latitude: 90.0,
          longitude: 0.0,
        );
        final rBaixaOceanoIndico = ControladorCameraGlobo.raioNormalizadoGeoide(
          latitude: 4.0,
          longitude: 79.0,
        );
        expect(rEquador - rPoloNorte, greaterThan(0.055));
        expect(rEquador - rBaixaOceanoIndico, greaterThan(0.045));

        ctrl.definirLod(0.22);
        final silhueta = ctrl.construirCaminhoSilhuetaGeoide(
          const Size(400, 800),
        );
        final boundsGeoide = silhueta.getBounds();
        expect(boundsGeoide.width, greaterThan(boundsGeoide.height * 1.045));
      },
    );

    test(
      'deve agrupar clusters por estado e prevenir colisao de rotulos mesmo entre multiplos itens prioritarios',
      () {
        final clusters = ControladorCameraGlobo.agruparPorEstado(const [
          (id: 'c1', uf: 'MG', lat: -19.0, lon: -43.0),
          (id: 'c2', uf: 'MG', lat: -20.0, lon: -44.0),
          (id: 'u1', uf: 'RJ', lat: -22.9, lon: -43.1),
        ]);
        expect(clusters.length, equals(2));
        final mg = clusters.firstWhere((c) => c.uf == 'MG');
        expect(mg.quantidade, equals(2));
        expect(mg.latitudeMedia, closeTo(-19.5, 0.01));

        final semColisao = ControladorCameraGlobo.selecionarIdsSemColisaoRotulos(
          const [
            (id: 'vizinho', nome: 'Pico Vizinho Longo', posicao: Offset(100, 100), prioritario: false),
            (id: 'selecionado', nome: 'Pico Selecionado', posicao: Offset(108, 104), prioritario: true),
            (id: 'outro_prio_colado', nome: 'Cidade Colada', posicao: Offset(112, 106), prioritario: true),
            (id: 'afastado', nome: 'Pico Distante', posicao: Offset(290, 240), prioritario: false),
          ],
        );

        expect(semColisao, contains('selecionado'));
        expect(semColisao, contains('afastado'));
        expect(semColisao.contains('vizinho'), isFalse);
        expect(semColisao.contains('outro_prio_colado'), isFalse);
      },
    );

    test(
      'deve calcular distancia 3D camera-objeto e nivelDetalheObjeto apenas ao redor do objeto proximo (nunca no mar aberto)',
      () {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.07,
          longitudeInicial: -44.32,
          lodInicial: 2.9,
        );
        addTearDown(ctrl.dispose);

        // Camera colada sobre Igarape -> distancia 3D curta (< 42 km) -> LOD 3 no objeto Igarape
        final distIgarape = ctrl.distanciaCameraObjetoKm(
          latitude: -20.07,
          longitude: -44.32,
        );
        final lodIgarape = ctrl.nivelDetalheObjeto(
          latitude: -20.07,
          longitude: -44.32,
        );
        expect(distIgarape, lessThan(42.0));
        expect(lodIgarape, greaterThanOrEqualTo(3.0));

        // No mesmo zoom alto (2.9), Urca esta a >340 km de distancia -> permanece em LOD 1 (< 2.0)
        final distUrca = ctrl.distanciaCameraObjetoKm(
          latitude: -22.95,
          longitude: -43.16,
        );
        final lodUrca = ctrl.nivelDetalheObjeto(
          latitude: -22.95,
          longitude: -43.16,
        );
        expect(distUrca, greaterThan(300.0));
        expect(lodUrca, lessThan(2.0));

        // Dando zoom maximo (2.9) no meio do Oceano Atlantico (-20.0, -35.0), NENHUM pico entra em LOD 2 ou 3
        final ctrlOceano = ControladorCameraGlobo(
          latitudeInicial: -20.0,
          longitudeInicial: -35.0,
          lodInicial: 2.9,
        );
        addTearDown(ctrlOceano.dispose);
        expect(
          ctrlOceano.nivelDetalheObjeto(latitude: -20.07, longitude: -44.32),
          lessThan(2.0),
        );
        expect(
          ctrlOceano.nivelDetalheObjeto(latitude: -22.95, longitude: -43.16),
          lessThan(2.0),
        );

        // Permite zoom profundo ate < 1.2 km do macico (lodMaximo >= 4.5) sem cortar montanhas altas na lente
        expect(ControladorCameraGlobo.lodMaximo, greaterThanOrEqualTo(4.5));
        final ctrlCloseUp = ControladorCameraGlobo(
          latitudeInicial: -20.07,
          longitudeInicial: -44.32,
          lodInicial: 4.5,
        )..definirElevacaoReferenciaCamera(980.0);
        addTearDown(ctrlCloseUp.dispose);
        expect(ctrlCloseUp.elevacaoReferenciaCameraMetros, equals(980.0));
        expect(ctrlCloseUp.altitudeCameraKm, lessThan(1.2));
        final ptBaseClose = ctrlCloseUp.projetarCoordenada(
          latitude: -20.07,
          longitude: -44.32,
          elevacaoMetros: 980.0,
          tamanhoTela: const Size(400, 800),
        );
        final ptTopoClose = ctrlCloseUp.projetarCoordenada(
          latitude: -20.07,
          longitude: -44.32,
          elevacaoMetros: 1430.0,
          tamanhoTela: const Size(400, 800),
        );
        expect(ptBaseClose.visivel, isTrue);
        expect(ptTopoClose.visivel, isTrue);
        expect(ptTopoClose.y, lessThan(ptBaseClose.y - 40.0));
        expect(
          ctrlCloseUp.nivelDetalheObjeto(latitude: -20.07, longitude: -44.32),
          greaterThan(3.8),
        );
        expect(
          ctrl.nivelDetalheObjeto(latitude: -19.0, longitude: -44.32),
          inInclusiveRange(2.0, 3.0),
        );
        ctrl.definirLod(0.1);
        expect(
          ctrl.nivelDetalheObjeto(latitude: -20.07, longitude: -44.32),
          lessThan(1.0),
        );
      },
    );

    test(
      'navegacao 2D possui zoom estritamente monotono desde LOD 0, pan 1:1 sob o dedo, zero folga vertical, zoom focal 1:1 e inercia apenas apos soltar o dedo',
      () {
        const tela = Size(400, 820);
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -19.5,
          longitudeInicial: -44.0,
          lodInicial: 0.0,
          modo3DInicial: false,
        );
        addTearDown(ctrl.dispose);

        // 1. Escala 2D cresce imediatamente entre LOD 0.0, 0.15 e 0.30 (sem zona morta de zoom)
        final esc0 = ctrl.calcularEscala2D(tela);
        ctrl.definirLod(0.15);
        final esc15 = ctrl.calcularEscala2D(tela);
        ctrl.definirLod(0.30);
        final esc30 = ctrl.calcularEscala2D(tela);
        expect(esc15, greaterThan(esc0 * 1.05));
        expect(esc30, greaterThan(esc15 * 1.05));

        // 2. Arrasto 1:1 em 2D: mover ponteiro (+80, -60) desloca o pico exatamente (+80, -60) px na tela
        ctrl.definirLod(1.2);
        final antesPan = ctrl.projetarCoordenada(
          latitude: -19.5,
          longitude: -44.0,
          elevacaoMetros: 900,
          tamanhoTela: tela,
        );
        ctrl.iniciarInteracaoManual();
        ctrl.aplicarGestoContinuo(
          dxPx: 80.0,
          dyPx: -60.0,
          fatorEscala: 1.0,
          pontoFocalTela: const Offset(200, 410),
          contagemPonteiros: 1,
          tamanhoTela: tela,
        );
        // Enquanto o dedo permanece apoiado na tela, avancarQuadroFisica NAO aplica inercia parasita!
        expect(ctrl.temAnimacaoAtiva, isFalse);
        expect(ctrl.avancarQuadroFisica(0.016), isFalse);

        final depoisPan = ctrl.projetarCoordenada(
          latitude: -19.5,
          longitude: -44.0,
          elevacaoMetros: 900,
          tamanhoTela: tela,
        );
        expect(depoisPan.x - antesPan.x, closeTo(80.0, 0.05));
        expect(depoisPan.y - antesPan.y, closeTo(-60.0, 0.05));
        ctrl.encerrarInteracaoManual(tamanhoTela: tela);
        expect(ctrl.temAnimacaoAtiva, isFalse);

        // 3. Zero folga (slack) nos limites polares 2D: ao bater no topo norte e inverter 24px para o sul,
        // o mapa responde imediatamente no primeiro gesto reverso
        ctrl.definirLod(0.1);
        ctrl.aplicarArrasto(dxPx: 0, dyPx: 5000, tamanhoTela: tela);
        final noTopo = ctrl.projetarCoordenada(
          latitude: 20.0,
          longitude: -44.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
        );
        ctrl.aplicarArrasto(dxPx: 0, dyPx: -24.0, tamanhoTela: tela);
        final aposReverso = ctrl.projetarCoordenada(
          latitude: 20.0,
          longitude: -44.0,
          elevacaoMetros: 0,
          tamanhoTela: tela,
        );
        expect(aposReverso.y, closeTo(noTopo.y - 24.0, 0.1));

        // 4. Zoom focal 2D em proporcao 1:1 (fatorEscala 2.0 dobra escala2D e ancora coordenada sob o ponto focal)
        ctrl.definirLod(0.8);
        const foco = Offset(115.0, 250.0);
        final coordSobFoco = ctrl.converterTelaParaCoordenada2D(
          pontoTela: foco,
          tamanhoTela: tela,
        );
        final escAntesZoom = ctrl.calcularEscala2D(tela);
        ctrl.aplicarZoomFocal(
          fatorEscala: 2.0,
          pontoFocalTela: foco,
          tamanhoTela: tela,
        );
        expect(ctrl.calcularEscala2D(tela), closeTo(escAntesZoom * 2.0, 0.5));
        final projecaoAposZoom = ctrl.projetarCoordenada(
          latitude: coordSobFoco.latitude,
          longitude: coordSobFoco.longitude,
          elevacaoMetros: 0,
          tamanhoTela: tela,
        );
        expect(projecaoAposZoom.x, closeTo(foco.dx, 0.2));
        expect(projecaoAposZoom.y, closeTo(foco.dy, 0.2));

        // 5. Soltar um flick rapido em 2D inicia inercia suave e voo pelo antimeridiano toma o menor arco
        ctrl.iniciarInteracaoManual();
        ctrl.encerrarInteracaoManual(
          velocidadePixelsPorSegundo: const Offset(-650, 320),
          tamanhoTela: tela,
        );
        expect(ctrl.temAnimacaoAtiva, isTrue);
        for (var i = 0; i < 90 && ctrl.temAnimacaoAtiva; i++) {
          ctrl.avancarQuadroFisica(0.025);
        }
        expect(ctrl.temAnimacaoAtiva, isFalse);

        // Flick rapido em 3D (com limitador de velocidade maxima) e atualizacao de gaveta em 2D
        ctrl.atualizarAlturaGaveta(290.0);
        ctrl.definirModo3D(true);
        ctrl.iniciarInteracaoManual();
        ctrl.encerrarInteracaoManual(
          velocidadePixelsPorSegundo: const Offset(2800, -400),
          tamanhoTela: tela,
        );
        expect(ctrl.temAnimacaoAtiva, isTrue);

        final ctrlPac = ControladorCameraGlobo(
          latitudeInicial: -10.0,
          longitudeInicial: 172.0,
          lodInicial: 1.0,
          modo3DInicial: false,
        );
        addTearDown(ctrlPac.dispose);
        ctrlPac.iniciarVooParabolico(
          destinoLat: -12.0,
          destinoLon: -172.0,
          destinoLod: 1.2,
        );
        ctrlPac.avancarQuadroFisica(0.25);
        expect(ctrlPac.longitudeCentral.abs(), greaterThan(165.0));
      },
    );
  });
}
