// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_tiles_elevacao_terrarium.dart';
import 'package:frontend/view/view_models/cena_globo_explorar_view_model.dart';
import 'package:frontend/widgets/explorar/componentes_marcador_globo.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

import '../../fakes/fonte_tiles_elevacao_fake.dart';

Future<ui.Image> _criarImagem1x1() async {
  final pixels = Uint8List.fromList([30, 80, 140, 255]);
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final desc = ui.ImageDescriptor.raw(
    buffer,
    width: 1,
    height: 1,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await desc.instantiateCodec();
  final frame = await codec.getNextFrame();
  codec.dispose();
  desc.dispose();
  buffer.dispose();
  return frame.image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const malhaSintetica = MalhaGeograficaGlobo(
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
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'MG-010',
        verticesLonLat: [
          ui.Offset(-43.9386, -19.9191),
          ui.Offset(-43.6135, -19.3156),
        ],
      ),
    ],
  );

  const picosReferencia = <PicoRelevoReferencia>[
    PicoRelevoReferencia(
      id: 'cipo',
      latitude: -19.3156,
      longitude: -43.6135,
      altitudeBaseMetros: 820,
      altitudePicoMetros: 1310,
    ),
  ];

  group('CenaGloboExplorarViewModel', () {
    test('hidrata assets assincronamente, ignora retorno pós-dispose e memoiza RedeViariaArestaGlobo por instância', () async {
      final img = await _criarImagem1x1();
      addTearDown(img.dispose);

      final completerMalha = Completer<MalhaGeograficaGlobo>();
      final completerTextura = Completer<ui.Image>();

      final servicoTiles = ServicoTilesElevacaoTerrarium(
        fonteRemota: FonteTilesElevacaoFake(altitudePadraoMetros: 1050),
      );
      addTearDown(servicoTiles.dispose);

      final vm = CenaGloboExplorarViewModel(
        lodInicialCamera: 2.0,
        carregarMalha: () => completerMalha.future,
        carregarTextura: () => completerTextura.future,
        servicoElevacao: servicoTiles,
      );
      addTearDown(vm.dispose);

