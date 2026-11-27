// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/componentes_marcador_globo.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_planeta_globo.dart';

Future<ui.Image> _criarTexturaTeste16x8() async {
  final pixels = Uint8List(16 * 8 * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    pixels[i] = 40;
    pixels[i + 1] = 110;
    pixels[i + 2] = 180;
    pixels[i + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descritor = ui.ImageDescriptor.raw(
    buffer,
    width: 16,
    height: 8,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descritor.instantiateCodec();
  final quadro = await codec.getNextFrame();
  codec.dispose();
  descritor.dispose();
  buffer.dispose();
  return quadro.image;
}

void main() {
  const malhaTeste = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          ui.Offset(-50.0, -25.0),
          ui.Offset(-38.0, -25.0),
          ui.Offset(-38.0, -14.0),
          ui.Offset(-50.0, -14.0),
        ],
      ),
    ],
    brasil: [
      ui.Offset(-50.0, -25.0),
      ui.Offset(-38.0, -25.0),
      ui.Offset(-38.0, -14.0),
      ui.Offset(-50.0, -14.0),
    ],
    estados: [
      PoligonoGeografico(
        id: 'MG',
        verticesLonLat: [
          ui.Offset(-46.0, -22.0),
          ui.Offset(-41.0, -22.0),
          ui.Offset(-41.0, -16.0),
          ui.Offset(-46.0, -16.0),
        ],
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-381',
        verticesLonLat: [
          ui.Offset(-44.2, -20.1),
          ui.Offset(-43.9, -19.9),
        ],
      ),
    ],
  );

  group('PintorPlanetaGlobo e PintorFenomenosAtmosfericosGlobo', () {
    test('compõe esfera texturizada NASA em 3D e 2D e fallback vetorial quando textura está ausente', () async {
      final textura = await _criarTexturaTeste16x8();
      final ctrl3D = ControladorCameraGlobo(lodInicial: 0.45);
      final ctrl2D = ControladorCameraGlobo(
        lodInicial: 0.45,
        modo3DInicial: false,
      );
      addTearDown(() {
        textura.dispose();
        ctrl3D.dispose();
        ctrl2D.dispose();
      });

      const tela = ui.Size(400, 800);
      final gravador = ui.PictureRecorder();
      final canvas = ui.Canvas(gravador);

      final pintorComTextura3D = PintorPlanetaGlobo(
        controlador: ctrl3D,
        malha: malhaTeste,
        texturaNasa: textura,
        picosReferencia: const [],
        sonarPico: null,
        progressoSonar: 1.0,
        progressoLuzViaria: 0.0,
      );
      pintorComTextura3D.paint(canvas, tela);

      final pintorComTextura2D = PintorPlanetaGlobo(
        controlador: ctrl2D,
        malha: malhaTeste,
        texturaNasa: textura,
        picosReferencia: const [],
        sonarPico: null,
        progressoSonar: 1.0,
        progressoLuzViaria: 0.4,
      );
      pintorComTextura2D.paint(canvas, tela);

      final pintorFallbackMalha = PintorPlanetaGlobo(
        controlador: ctrl3D,
        malha: malhaTeste,
        texturaNasa: null,
        picosReferencia: const [],
        sonarPico: null,
        progressoSonar: 1.0,
        progressoLuzViaria: 0.0,
      );
      pintorFallbackMalha.paint(canvas, tela);
      expect(pintorComTextura3D.shouldRepaint(pintorFallbackMalha), isTrue);

      gravador.endRecording().dispose();
    });

    test('compõe terreno contínuo P&B, onda sonar e camada atmosférica superior (orbital e local)', () async {
      final textura = await _criarTexturaTeste16x8();
      final ctrlOrbital = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 0.45,
      );
      final ctrlLocal = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 2.95,
      );
      addTearDown(() {
        textura.dispose();
        ctrlOrbital.dispose();
        ctrlLocal.dispose();
      });

      const picoSonar = MarcadorPicoGlobo(
        id: 'p1',
        nome: 'Pedra Grande',
        uf: 'MG',
        latitude: -20.0,
        longitude: -44.0,
        altitudeBaseMetros: 900,
        altitudePicoMetros: 1420,
      );

      const bolhas = <BolhaAtivaRenderizavel>[
        BolhaAtivaRenderizavel(
          nivelIntensidade: NivelIntensidadeChuva.forte,
          bolha: BolhaChuvaRegional(
            id: 'b1',
            latitude: -20.0,
            longitude: -44.0,
            intensidadeMmHora: 3.5,
            ventoRumoGraus: 120.0,
            ventoVelocidadeKmh: 18.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -44.1, latitude: -20.1),
              PontoContornoGeo(longitude: -43.9, latitude: -20.1),
              PontoContornoGeo(longitude: -44.0, latitude: -19.9),
            ],
          ),
        ),
      ];
      const incendios = <BolhaIncendioAtivaRenderizavel>[
        BolhaIncendioAtivaRenderizavel(
          incendio: BolhaIncendioRegional(
            id: 'f1',
            latitude: -19.7,
            longitude: -43.7,
            potenciaFrpMw: 35.0,
            totalFocos: 4,
            ventoRumoGraus: 260.0,
            ventoVelocidadeKmh: 14.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -43.75, latitude: -19.75),
              PontoContornoGeo(longitude: -43.65, latitude: -19.75),
              PontoContornoGeo(longitude: -43.70, latitude: -19.65),
            ],
          ),
        ),
      ];

      final gravador = ui.PictureRecorder();
      final canvas = ui.Canvas(gravador);
      const tela = ui.Size(400, 800);

      final referencias = [picoSonar.paraReferenciaRelevo()];
      final redeViaria = ConstrutorRedeViariaAresta.construir(
        rodovias: malhaTeste.rodoviasProximas,
        localidades: malhaTeste.localidadesProximas,
        picos: referencias,
      );

      final pintorLocal = PintorPlanetaGlobo(
        controlador: ctrlLocal,
        malha: malhaTeste,
        redeViaria: redeViaria,
        texturaNasa: textura,
        picosReferencia: referencias,
        sonarPico: picoSonar,
        progressoSonar: 0.45,
        progressoLuzViaria: 1.0,
      );
      pintorLocal.paint(canvas, tela);

      final atmosferaVazia = PintorFenomenosAtmosfericosGlobo(
        controlador: ctrlOrbital,
        picosReferencia: const [],
        bolhasAtivas: const [],
        incendiosAtivos: const [],
        sonarBolhaId: null,
        faseTempestadeSegundos: 0.0,
      );
      atmosferaVazia.paint(canvas, tela);

      final atmosferaOrbital = PintorFenomenosAtmosfericosGlobo(
        controlador: ctrlOrbital,
        picosReferencia: [picoSonar.paraReferenciaRelevo()],
        bolhasAtivas: bolhas,
        incendiosAtivos: incendios,
        sonarBolhaId: 'b1',
        faseTempestadeSegundos: 1.2,
      );
      atmosferaOrbital.paint(canvas, tela);

      final atmosferaLocal = PintorFenomenosAtmosfericosGlobo(
        controlador: ctrlLocal,
        picosReferencia: [picoSonar.paraReferenciaRelevo()],
        bolhasAtivas: bolhas,
        incendiosAtivos: incendios,
        sonarBolhaId: 'b1',
        faseTempestadeSegundos: 1.5,
      );
      atmosferaLocal.paint(canvas, tela);
      expect(atmosferaLocal.shouldRepaint(atmosferaOrbital), isTrue);

      gravador.endRecording().dispose();
    });
  });
}
