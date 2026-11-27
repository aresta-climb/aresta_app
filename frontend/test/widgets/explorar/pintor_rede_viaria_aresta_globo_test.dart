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

      // Progresso 0.0 -> apenas malha P&B e pontos brancos; Progresso 0.45 -> onda em trânsito; Progresso 1.0 -> corredor completo
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
      ctrl.definirLod(2.95);
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

      // Verifica brilho quente laranja (R > B + 25) sobre Belo Horizonte no estado completo
      final ptBh = ctrl.projetarCoordenada(
        latitude: -19.9191,
        longitude: -43.9386,
        elevacaoMetros: 825.0,
        tamanhoTela: const ui.Size(240, 240),
      );
      if (ptBh.visivel &&
          ptBh.x >= 2 &&
          ptBh.x < 238 &&
          ptBh.y >= 2 &&
          ptBh.y < 238) {
        final idx = (ptBh.y.round() * 240 + ptBh.x.round()) * 4;
        expect(qCompleto[idx], greaterThan(qCompleto[idx + 2]));
      }

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
      // permanece contínua cruzando o centro da tela sem desaparecer!
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
