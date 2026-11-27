// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_tempestade_globo.dart';

Future<Uint8List> _renderizarPixels({
  required ControladorCameraGlobo ctrl,
  required List<BolhaAtivaRenderizavel> bolhas,
  required double faseSegundos,
  String? bolhaRealcadaId,
  List<PicoRelevoReferencia> picos = const [],
}) async {
  const tamanho = ui.Size(220, 220);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorTempestadeGlobo.desenharTempestades(
    canvas: canvas,
    tamanhoTela: tamanho,
    controlador: ctrl,
    bolhasAtivas: bolhas,
    picosReferencia: picos,
    faseSegundos: faseSegundos,
    bolhaRealcadaId: bolhaRealcadaId,
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

  const frenteSudeste = BolhaChuvaRegional(
    id: 'frente_zcas',
    latitude: -20.5,
    longitude: -43.8,
    intensidadeMmHora: 6.5,
    ventoRumoGraus: 55.0,
    ventoVelocidadeKmh: 28.0,
    contornoExterno: [
      PontoContornoGeo(longitude: -46.2, latitude: -22.6),
      PontoContornoGeo(longitude: -41.6, latitude: -22.2),
      PontoContornoGeo(longitude: -41.8, latitude: -18.4),
      PontoContornoGeo(longitude: -46.0, latitude: -18.8),
    ],
    nucleosIntensos: [
      [
        PontoContornoGeo(longitude: -44.6, latitude: -21.2),
        PontoContornoGeo(longitude: -43.0, latitude: -21.0),
        PontoContornoGeo(longitude: -43.2, latitude: -19.8),
        PontoContornoGeo(longitude: -44.5, latitude: -20.0),
      ],
    ],
  );

  group('PintorTempestadeGlobo', () {
    test(
      'deve respeitar o contorno geografico real da tempestade, animar bandas e tracos de vento entre quadros e descartar hemisferio oculto',
      () async {
        expect(
          PintorTempestadeGlobo.contemCoordenadaNoContorno(
            longitude: -43.8,
            latitude: -20.5,
            contorno: frenteSudeste.contornoExterno,
          ),
          isTrue,
        );
        expect(
          PintorTempestadeGlobo.contemCoordenadaNoContorno(
            longitude: -52.0,
            latitude: -12.0,
            contorno: frenteSudeste.contornoExterno,
          ),
          isFalse,
        );

        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 0.55,
        );
        addTearDown(ctrl.dispose);

        final bolhas = <BolhaAtivaRenderizavel>[
          const BolhaAtivaRenderizavel(
            bolha: frenteSudeste,
            nivelIntensidade: NivelIntensidadeChuva.extrema,
          ),
          const BolhaAtivaRenderizavel(
            bolha: BolhaChuvaRegional(
              id: 'celula_forte',
              latitude: -19.0,
              longitude: -41.4,
              intensidadeMmHora: 4.8,
              ventoRumoGraus: 95.0,
              ventoVelocidadeKmh: 22.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -41.9, latitude: -19.5),
                PontoContornoGeo(longitude: -40.9, latitude: -19.4),
                PontoContornoGeo(longitude: -41.3, latitude: -18.5),
              ],
            ),
            nivelIntensidade: NivelIntensidadeChuva.forte,
          ),
          const BolhaAtivaRenderizavel(
            bolha: BolhaChuvaRegional(
              id: 'celula_moderada',
              latitude: -17.2,
              longitude: -42.5,
              intensidadeMmHora: 2.2,
              ventoRumoGraus: 120.0,
              ventoVelocidadeKmh: 16.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -43.0, latitude: -17.7),
                PontoContornoGeo(longitude: -42.0, latitude: -17.6),
                PontoContornoGeo(longitude: -42.3, latitude: -16.8),
              ],
            ),
            nivelIntensidade: NivelIntensidadeChuva.moderada,
          ),
          const BolhaAtivaRenderizavel(
            bolha: BolhaChuvaRegional(
              id: 'chuvisco_leve',
              latitude: -23.4,
              longitude: -45.5,
              intensidadeMmHora: 0.5,
              ventoRumoGraus: 25.0,
              ventoVelocidadeKmh: 9.0,
              contornoExterno: [
                PontoContornoGeo(longitude: -46.0, latitude: -23.8),
                PontoContornoGeo(longitude: -45.0, latitude: -23.7),
                PontoContornoGeo(longitude: -45.4, latitude: -23.0),
              ],
            ),
            nivelIntensidade: NivelIntensidadeChuva.fraca,
          ),
        ];

        final quadro0 = await _renderizarPixels(
          ctrl: ctrl,
          bolhas: bolhas,
          faseSegundos: 0.0,
          bolhaRealcadaId: 'frente_zcas',
        );
        final quadro1 = await _renderizarPixels(
          ctrl: ctrl,
          bolhas: bolhas,
          faseSegundos: 0.85,
        );

        // O epicentro projetado na tela esta dentro da tempestade -> pintado com tons frios de chuva (azul > vermelho, alfa > 0)
        final ptEpicentro = ctrl.projetarCoordenada(
          latitude: -20.5,
          longitude: -43.8,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idxCentro =
            (ptEpicentro.y.round() * 220 + ptEpicentro.x.round()) * 4;
        expect(quadro0[idxCentro + 3], greaterThan(20));
        expect(quadro0[idxCentro + 2], greaterThan(quadro0[idxCentro]));

        // Canto superior esquerdo (4, 4) esta longe do contorno -> permanece transparente
        const idxCanto = (4 * 220 + 4) * 4;
        expect(quadro0[idxCanto + 3], equals(0));

        // Entre t=0.0s e t=0.85s, a animacao de vento altera os pixels internos da tempestade
        var diferencaTotal = 0;
        for (var i = 0; i < quadro0.length; i += 4) {
          diferencaTotal += (quadro0[i + 2] - quadro1[i + 2]).abs() +
              (quadro0[i + 3] - quadro1[i + 3]).abs();
        }
        expect(diferencaTotal, greaterThan(500));

