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
        nome: 'Sete Lagoas',
        ehCidade: true,
        nivel: 2,
        longitude: -44.2467,
        latitude: -19.4658,
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-040',
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
        nivelViario: 2,
        codigo: 'BR-262',
        verticesLonLat: [
          ui.Offset(-43.9800, -19.9400),
          ui.Offset(-43.9100, -19.9000),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: false,
        nivelViario: 3,
        codigo: 'ACESSO-PICO',
        verticesLonLat: [
          ui.Offset(-43.9300, -19.9100),
          ui.Offset(-43.8900, -19.8700),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-101',
        verticesLonLat: [
          ui.Offset(45.0, 0.0),
          ui.Offset(135.0, 0.0),
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
    test('propaga luz laranja pelas rodovias principais desde Belo Horizonte até o pico, renderiza escudos BR-xxx e evita bolinhas órfãs', () async {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -19.86,
        longitudeInicial: -43.93,
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
      // os corredores laranjas em retração permanecem visíveis apagando das pontas até Belo Horizonte
      final qRetraindoNoZoomOut = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 0.0,
        progressoLuz: 0.55,
      );
      expect(qRetraindoNoZoomOut.any((b) => b > 0), isTrue);

      // Progresso 0.0 -> malha P&B sem luz; Progresso 0.45 -> onda com ponta quente; Progresso 1.0 -> corredor + escudos BR-xxx
      final qInicio = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 0.0,
      );
      final qMeio = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 0.45,
      );
      ctrl.definirLod(3.25);
      final qCompleto = await _renderizarCamadaViaria(
        ctrl: ctrl,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 1.0,
      );

      expect(qInicio.any((b) => b > 0), isTrue);
      expect(qMeio, isNot(equals(qInicio)));
      expect(qCompleto, isNot(equals(qMeio)));

      // Verifica pixels quentes laranja (R > B + 25) presentes no corredor aceso e ausentes quando progressoLuz == 0
      int contarPixelsQuentes(Uint8List rgba) {
        var total = 0;
        for (var i = 0; i < rgba.length; i += 4) {
          if (rgba[i] > 120 && rgba[i] > rgba[i + 2] + 25) {
            total++;
          }
        }
        return total;
      }

      expect(contarPixelsQuentes(qInicio), equals(0));
      expect(contarPixelsQuentes(qCompleto), greaterThan(15));

      // Horizonte esférico 3D descarta vértices ocultos atrás do limbo sem artefato
      final ctrlLimbo3D = ControladorCameraGlobo(
        latitudeInicial: 0.0,
        longitudeInicial: 0.0,
        lodInicial: 0.35,
        modo3DInicial: true,
      );
      addTearDown(ctrlLimbo3D.dispose);
      final qLimbo3D = await _renderizarCamadaViaria(
        ctrl: ctrlLimbo3D,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 0.5,
      );
      expect(qLimbo3D, isNotNull);

      // Modo 2D cruzando o antimeridiano descarta saltos horizontais abruptos sem artefato
      final ctrl2D = ControladorCameraGlobo(
        latitudeInicial: 0.0,
        longitudeInicial: 0.0,
        lodInicial: 1.85,
        modo3DInicial: false,
      );
      addTearDown(ctrl2D.dispose);
      final q2D = await _renderizarCamadaViaria(
        ctrl: ctrl2D,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 0.5,
      );
      expect(q2D, isNotNull);

      // No zoom máximo (LOD 4.35), uma rodovia cujos vértices originais estão muito fora da tela
      // permanece contínua cruzando o centro da tela sem desaparecer
      final ctrlZoomMaximo = ControladorCameraGlobo(
        latitudeInicial: -19.84955,
        longitudeInicial: -43.9243,
        lodInicial: 4.35,
      );
      addTearDown(ctrlZoomMaximo.dispose);
      final qZoomMaximo = await _renderizarCamadaViaria(
        ctrl: ctrlZoomMaximo,
        redeViaria: redePrecomputada,
        picos: picos,
        fatorModoViario: 1.0,
        progressoLuz: 1.0,
      );
      expect(qZoomMaximo.any((b) => b > 120), isTrue);
    });
  });
}
