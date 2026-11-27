// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_incendio_globo.dart';

Future<Uint8List> _renderizarIncendios({
  required ControladorCameraGlobo ctrl,
  required List<BolhaIncendioAtivaRenderizavel> incendios,
  required double faseSegundos,
  List<PicoRelevoReferencia> picos = const [],
  List<BolhaAtivaRenderizavel> bolhasChuva = const [],
}) async {
  const tamanho = ui.Size(220, 220);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorIncendioGlobo.desenharIncendios(
    canvas: canvas,
    tamanhoTela: tamanho,
    controlador: ctrl,
    incendiosAtivos: incendios,
    bolhasChuvaAtivas: bolhasChuva,
    picosReferencia: picos,
    faseSegundos: faseSegundos,
  );
  final picture = gravador.endRecording();
  final imagem = await picture.toImage(220, 220);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  imagem.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const incendioCipo = BolhaIncendioRegional(
    id: 'incendio_cipo',
    latitude: -19.35,
    longitude: -43.60,
    potenciaFrpMw: 92.0,
    totalFocos: 9,
    ventoRumoGraus: 280.0,
    ventoVelocidadeKmh: 24.0,
    fonteSatelite: 'NASA_FIRMS_VIIRS_375M',
    contornoExterno: [
      PontoContornoGeo(longitude: -44.2, latitude: -20.0),
      PontoContornoGeo(longitude: -43.0, latitude: -19.9),
      PontoContornoGeo(longitude: -43.1, latitude: -18.7),
      PontoContornoGeo(longitude: -44.1, latitude: -18.8),
    ],
    nucleosIntensos: [
      [
        PontoContornoGeo(longitude: -43.8, latitude: -19.6),
        PontoContornoGeo(longitude: -43.4, latitude: -19.5),
        PontoContornoGeo(longitude: -43.5, latitude: -19.1),
      ],
    ],
  );

  group('PintorIncendioGlobo', () {
    test(
      'renderiza perimetro termal ambar/carmim, nucleos em brasa e pluma de fumaca orientada pelo vento em 3D e 2D, descartando face oculta',
      () async {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -19.35,
          longitudeInicial: -43.60,
          lodInicial: 0.75,
        );
        addTearDown(ctrl.dispose);

        final lista = <BolhaIncendioAtivaRenderizavel>[
          BolhaIncendioAtivaRenderizavel(incendio: incendioCipo),
          const BolhaIncendioAtivaRenderizavel(
            incendio: BolhaIncendioRegional(
              id: 'foco_baixo',
              latitude: -20.1,
              longitude: -44.3,
              potenciaFrpMw: 9.0,
              totalFocos: 1,
              ventoRumoGraus: 45.0,
              ventoVelocidadeKmh: 12.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -44.34, latitude: -20.14),
                PontoContornoGeo(longitude: -44.26, latitude: -20.14),
                PontoContornoGeo(longitude: -44.30, latitude: -20.06),
              ],
            ),
          ),
          const BolhaIncendioAtivaRenderizavel(
            incendio: BolhaIncendioRegional(
              id: 'foco_moderado',
              latitude: -19.8,
              longitude: -42.8,
              potenciaFrpMw: 21.0,
              totalFocos: 5,
              ventoRumoGraus: 110.0,
              ventoVelocidadeKmh: 14.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -42.95, latitude: -19.95),
                PontoContornoGeo(longitude: -42.65, latitude: -19.95),
                PontoContornoGeo(longitude: -42.80, latitude: -19.65),
              ],
            ),
          ),
          const BolhaIncendioAtivaRenderizavel(
            incendio: BolhaIncendioRegional(
              id: 'foco_alto',
              latitude: -18.3,
              longitude: -43.5,
              potenciaFrpMw: 42.0,
              totalFocos: 9,
              ventoRumoGraus: 180.0,
              ventoVelocidadeKmh: 16.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -43.7, latitude: -18.5),
                PontoContornoGeo(longitude: -43.3, latitude: -18.5),
                PontoContornoGeo(longitude: -43.5, latitude: -18.1),
              ],
            ),
          ),
        ];

        final q0 = await _renderizarIncendios(
          ctrl: ctrl,
          incendios: lista,
          faseSegundos: 0.0,
        );
        final q1 = await _renderizarIncendios(
          ctrl: ctrl,
          incendios: lista,
          faseSegundos: 2.2,
        );
        expect(q0, isNot(equals(q1)));

        // Verifica dominancia quente (vermelho > azul) no centro projetado do incendio
        final ptCentroFogo = ctrl.projetarCoordenada(
          latitude: -19.35,
          longitude: -43.60,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idxCentro =
            (ptCentroFogo.y.round() * 220 + ptCentroFogo.x.round()) * 4;
        expect(q0[idxCentro], greaterThan(q0[idxCentro + 2] + 30));

        // Sobre relevo 3D (LOD >= 1.6) e em modo 2D
        ctrl.definirLod(1.75);
        final qRelevo = await _renderizarIncendios(
          ctrl: ctrl,
          incendios: lista,
          faseSegundos: 1.0,
          picos: const [
            PicoRelevoReferencia(
              id: 'cipo',
              latitude: -19.35,
              longitude: -43.60,
              altitudeBaseMetros: 820,
              altitudePicoMetros: 1310,
            ),
          ],
        );
        expect(qRelevo.any((b) => b > 0), isTrue);

