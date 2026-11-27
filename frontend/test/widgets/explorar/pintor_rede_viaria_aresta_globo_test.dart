// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_rede_viaria_aresta_globo.dart';

Future<Uint8List> _renderizarCamadaViaria({
  required ControladorCameraGlobo ctrl,
  required RedeViariaArestaGlobo? redeViaria,
  required List<PicoRelevoReferencia> picos,
  required double fatorModoViario,
  required double progressoLuz,
}) async {
  const size = ui.Size(240, 240);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorRedeViariaArestaGlobo.desenharRedeViariaECidades(
    canvas: canvas,
    size: size,
    controlador: ctrl,
    redeViaria: redeViaria,
    picosReferencia: picos,
    fatorModoViario: fatorModoViario,
    progressoLuzViaria: progressoLuz,
  );
  final pic = gravador.endRecording();
  final img = await pic.toImage(240, 240);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  pic.dispose();
  img.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const malhaViaria = MalhaGeograficaGlobo(
    continentes: [],
    brasil: [],
    estados: [],
    localidadesProximas: [
      LocalidadeRegionalMapa(
        nome: 'Belo Horizonte',
        ehCidade: true,
        nivel: 1,
        longitude: -43.9386,
        latitude: -19.9191,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lagoa Santa',
        ehCidade: true,
        nivel: 2,
        longitude: -43.8932,
        latitude: -19.6397,
      ),
      LocalidadeRegionalMapa(
        nome: 'Vila Local Corredor',
        ehCidade: false,
        nivel: 3,
        longitude: -43.7500,
        latitude: -19.4800,
      ),
      LocalidadeRegionalMapa(
        nome: 'Cidade Referência Isolada',
        ehCidade: true,
        nivel: 1,
        longitude: -44.6500,
        latitude: -19.9000,
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'MG-010',
        verticesLonLat: [
          ui.Offset(-43.9386, -19.9191),
          ui.Offset(-43.9100, -19.7800),
          ui.Offset(-43.8932, -19.6397),
          ui.Offset(-43.7500, -19.4800),
          ui.Offset(-43.6135, -19.3156),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: false,
        codigo: 'SEC-REF',
        verticesLonLat: [
          ui.Offset(-44.6500, -19.9000),
          ui.Offset(-44.5000, -19.8500),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'ANTIMERIDIANO',
        verticesLonLat: [
          ui.Offset(179.5, 0.0),
          ui.Offset(-179.5, 0.0),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'DEGENERADA',
        verticesLonLat: [ui.Offset(-43.9386, -19.9191)],
      ),
    ],
  );

  const picos = <PicoRelevoReferencia>[
    PicoRelevoReferencia(
      id: 'cipo',
      latitude: -19.3156,
      longitude: -43.6135,
      altitudeBaseMetros: 820,
      altitudePicoMetros: 1310,
    ),
  ];

  final redePrecomputada = ConstrutorRedeViariaAresta.construir(
    rodovias: malhaViaria.rodoviasProximas,
    localidades: malhaViaria.localidadesProximas,
    picos: picos,
  );

  group('PintorRedeViariaArestaGlobo', () {
    test('propaga luz laranja de Belo Horizonte até o pico, ilumina contornos das cidades Aresta e desenha pontos brancos nas cidades de referência', () async {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -19.72,
        longitudeInicial: -44.10,
        lodInicial: 1.85,
      );
      addTearDown(ctrl.dispose);

      // Inativo quando redeViaria é nula ou quando tanto modo viário quanto luz residual são zero
      final semRede = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: null,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 1.0,
      );
      expect(semRede.every((b) => b == 0), isTrue);

      final vazio = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 0.0,
        progressoLuz: 0.0,
      );
      expect(vazio.every((b) => b == 0), isTrue);

      // Durante zoom-out (fatorModoViario já retornou a 0.0, mas progressoLuz=0.55 ainda recolhe até BH),
      // os corredores laranjas em retração permanecem visíveis apagando das pontas até Belo Horizonte!
      final qRetraindoNoZoomOut = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 0.0,
        progressoLuz: 0.55,
      );
      expect(qRetraindoNoZoomOut.any((b) => b > 0), isTrue);

