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

        // Projeta tambem sobre o relevo SRTM 3D (LOD 2.1) e no modo 2D plano
        ctrl.definirLod(2.1);
        final ptRelevo = ctrl.projetarCoordenada(
          latitude: -20.5,
          longitude: -43.8,
          elevacaoMetros: 1420.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idxRelevo =
            (ptRelevo.y.round().clamp(0, 219) * 220 +
                    ptRelevo.x.round().clamp(0, 219)) *
                4;
        final quadroRelevo = await _renderizarPixels(
          ctrl: ctrl,
          bolhas: [bolhas.first],
          faseSegundos: 0.4,
          picos: const [
            PicoRelevoReferencia(
              id: 'igarape',
              latitude: -20.5,
              longitude: -43.8,
              altitudeBaseMetros: 900,
              altitudePicoMetros: 1420,
            ),
          ],
        );
        expect(quadroRelevo[idxRelevo + 3], greaterThan(10));

        ctrl.alternarModo3D();
        final pt2D = ctrl.projetarCoordenada(
          latitude: -20.5,
          longitude: -43.8,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idx2D = (pt2D.y.round() * 220 + pt2D.x.round()) * 4;
        final quadro2D = await _renderizarPixels(
          ctrl: ctrl,
          bolhas: [bolhas.first],
          faseSegundos: 1.2,
        );
        expect(quadro2D[idx2D + 3], greaterThan(10));

        // Tempestade ciclônica cruzando o horizonte 3D (parte visivel, parte oculta) e o antimeridiano 2D (±180°)
        const ciclonePacifico = BolhaAtivaRenderizavel(
          bolha: BolhaChuvaRegional(
            id: 'ciclone_pacifico',
            latitude: 0.0,
            longitude: 179.0,
            intensidadeMmHora: 5.0,
            ventoRumoGraus: 90.0,
            ventoVelocidadeKmh: 30.0,
            contornoExterno: [
              PontoContornoGeo(longitude: 165.0, latitude: -8.0),
              PontoContornoGeo(longitude: 172.0, latitude: -8.0),
              PontoContornoGeo(longitude: 178.5, latitude: -4.0),
              PontoContornoGeo(longitude: -176.0, latitude: 0.0),
              PontoContornoGeo(longitude: -165.0, latitude: 6.0),
              PontoContornoGeo(longitude: 170.0, latitude: 7.0),
            ],
          ),
          nivelIntensidade: NivelIntensidadeChuva.forte,
        );
        final ctrlLimb3D = ControladorCameraGlobo(
          latitudeInicial: 0.0,
          longitudeInicial: 92.0,
          lodInicial: 0.0,
        );
        addTearDown(ctrlLimb3D.dispose);
        await _renderizarPixels(
          ctrl: ctrlLimb3D,
          bolhas: const [ciclonePacifico],
          faseSegundos: 0.2,
        );

        final ctrlAntimeridiano2D = ControladorCameraGlobo(
          latitudeInicial: 0.0,
          longitudeInicial: 0.0,
          lodInicial: 0.0,
        )..alternarModo3D();
        addTearDown(ctrlAntimeridiano2D.dispose);
        await _renderizarPixels(
          ctrl: ctrlAntimeridiano2D,
          bolhas: const [ciclonePacifico],
          faseSegundos: 0.2,
        );

        // Quando a camera olha para o hemisferio oposto no globo 3D, faz culling limpo (0 desenhadas)
        ctrl.alternarModo3D();
        final ctrlOposto = ControladorCameraGlobo(
          latitudeInicial: 35.0,
          longitudeInicial: 138.0,
          lodInicial: 0.25,
        );
        addTearDown(ctrlOposto.dispose);

        final gravadorOposto = ui.PictureRecorder();
        final desenhadasOposto = PintorTempestadeGlobo.desenharTempestades(
          canvas: ui.Canvas(gravadorOposto),
          tamanhoTela: const ui.Size(220, 220),
          controlador: ctrlOposto,
          bolhasAtivas: bolhas,
          picosReferencia: const [],
          faseSegundos: 0.3,
        );
        gravadorOposto.endRecording().dispose();
        expect(desenhadasOposto, equals(0));
      },
    );

    test(
      'pinta rastro passado da trajetoria da tempestade a barlavento e mantem bolhas pequenas translúcidas sem saturar de listras',
      () async {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -21.2,
          longitudeInicial: -44.8,
          lodInicial: 0.45,
        );
        addTearDown(ctrl.dispose);

        const tempestadeComRastro = BolhaAtivaRenderizavel(
          bolha: BolhaChuvaRegional(
            id: 'frente_com_rastro',
            latitude: -20.0,
            longitude: -43.5,
            intensidadeMmHora: 6.0,
            ventoRumoGraus: 45.0, // move para NE -> veio de SW (-22.2, -45.7)
            ventoVelocidadeKmh: 28.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -44.2, latitude: -20.7),
              PontoContornoGeo(longitude: -42.8, latitude: -20.7),
              PontoContornoGeo(longitude: -42.8, latitude: -19.3),
              PontoContornoGeo(longitude: -44.2, latitude: -19.3),
            ],
            rastrosPassados: [
              RastroPassadoTempestade(
                horasAtras: 6,
                contorno: [
                  PontoContornoGeo(longitude: -46.4, latitude: -22.9),
                  PontoContornoGeo(longitude: -45.0, latitude: -22.9),
                  PontoContornoGeo(longitude: -45.0, latitude: -21.5),
                  PontoContornoGeo(longitude: -46.4, latitude: -21.5),
                ],
              ),
              RastroPassadoTempestade(
                horasAtras: 3,
                contorno: [
                  PontoContornoGeo(longitude: -45.3, latitude: -21.8),
                  PontoContornoGeo(longitude: -43.9, latitude: -21.8),
                  PontoContornoGeo(longitude: -43.9, latitude: -20.4),
                  PontoContornoGeo(longitude: -45.3, latitude: -20.4),
                ],
              ),
            ],
          ),
          nivelIntensidade: NivelIntensidadeChuva.forte,
        );

        const celulaMinuscula = BolhaAtivaRenderizavel(
          bolha: BolhaChuvaRegional(
            id: 'micro_celula',
            latitude: -18.0,
            longitude: -41.0,
            intensidadeMmHora: 5.5,
            ventoRumoGraus: 30.0,
            ventoVelocidadeKmh: 18.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -41.18, latitude: -18.18),
              PontoContornoGeo(longitude: -40.82, latitude: -18.18),
              PontoContornoGeo(longitude: -40.82, latitude: -17.82),
              PontoContornoGeo(longitude: -41.18, latitude: -17.82),
            ],
          ),
          nivelIntensidade: NivelIntensidadeChuva.forte,
        );

        final pixels = await _renderizarPixels(
          ctrl: ctrl,
          bolhas: const [tempestadeComRastro, celulaMinuscula],
          faseSegundos: 0.25,
        );

        // Ponto onde a tempestade passou 6h atras (-22.2, -45.7) fica fora da bolha atual, mas exibe a sombra/contorno do rastro!
        final ptPassado6h = ctrl.projetarCoordenada(
          latitude: -22.2,
          longitude: -45.7,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final ptAtual = ctrl.projetarCoordenada(
          latitude: -20.0,
          longitude: -43.5,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idxPassado =
            (ptPassado6h.y.round() * 220 + ptPassado6h.x.round()) * 4;
        final idxAtual = (ptAtual.y.round() * 220 + ptAtual.x.round()) * 4;
        expect(pixels[idxPassado + 3], greaterThan(6));
        expect(pixels[idxPassado + 3], lessThan(pixels[idxAtual + 3]));

        // Micro-célula pequena (~8x8 px na tela) permanece translúcida e limpa (nunca vira ovo listrado opaco alfa > 210!)
        final ptMicro = ctrl.projetarCoordenada(
          latitude: -18.0,
          longitude: -41.0,
          elevacaoMetros: 0.0,
          tamanhoTela: const ui.Size(220, 220),
        );
        final idxMicro = (ptMicro.y.round() * 220 + ptMicro.x.round()) * 4;
        expect(pixels[idxMicro + 3], greaterThan(15));
        expect(pixels[idxMicro + 3], lessThan(175));
      },
    );

    test(
      'mantem gotas de chuva e emblema da nuvem ancorados ao solo (mundo) ao mover a camera em zoom aproximado',
      () async {
        // Em zoom alto (LOD 2.85), a frente é muito maior que a tela (recortada no frustum).
        // Ao mover a câmera 40 px para o leste, o emblema da nuvem DEVE sair do centro da tela
        // acompanhando a coordenada geográfica real (-20.5, -43.8), e cada gota move-se exatamente
        // com o terreno em vez de ficar colada no centro da lente!
        final ctrlA = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 2.85,
          modo3DInicial: false,
        );
        final ctrlB = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 2.85,
          modo3DInicial: false,
        );
        addTearDown(() {
          ctrlA.dispose();
          ctrlB.dispose();
        });

        const bolha = BolhaAtivaRenderizavel(
          bolha: frenteSudeste,
          nivelIntensidade: NivelIntensidadeChuva.forte,
        );

