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

      // Como iniciou em LOD >= limiarAtivacaoLuzViaria, a luz viária já começa acesa
      expect(vm.alvoLuzViaria, equals(1.0));
      expect(vm.progressoLuzViaria, equals(1.0));
      expect(vm.animacoesAmbienteAtivas, isTrue);
      expect(vm.obterRedeViaria(picosReferencia), isNull);

      var notificacoes = 0;
      vm.addListener(() => notificacoes++);

      final futuroInit = vm.inicializarAssetsSeNecessario();
      completerMalha.complete(malhaSintetica);
      completerTextura.complete(img);
      await futuroInit;

      expect(notificacoes, equals(1));
      expect(vm.malha, same(malhaSintetica));
      expect(vm.texturaNasa, same(img));

      // Segunda chamada com assets carregados é no-op imediato
      await vm.inicializarAssetsSeNecessario();
      expect(notificacoes, equals(1));

      final rede1 = vm.obterRedeViaria(picosReferencia);
      final rede2 = vm.obterRedeViaria(picosReferencia);
      expect(rede1, isNotNull);
      expect(rede2, same(rede1));

      final redeOutraLista = vm.obterRedeViaria(const []);
      expect(redeOutraLista, isNot(same(rede1)));

      // Memoização O(1) das curvas de nível em coordenadas fixas do mundo durante o movimento da câmera
      final ctrlCurvas = ControladorCameraGlobo(
        latitudeInicial: -19.3156,
        longitudeInicial: -43.6135,
        lodInicial: 1.20,
      );
      addTearDown(ctrlCurvas.dispose);
      expect(
        vm.obterCurvasNivelVisiveis(
          controlador: ctrlCurvas,
          tamanhoTela: const ui.Size(400, 800),
          picosReferencia: picosReferencia,
        ),
        isNull,
      );
      ctrlCurvas.definirLod(3.10);
      final curvas1 = vm.obterCurvasNivelVisiveis(
        controlador: ctrlCurvas,
        tamanhoTela: const ui.Size(400, 800),
        picosReferencia: picosReferencia,
      );
      final curvasMesmoBloco = vm.obterCurvasNivelVisiveis(
        controlador: ctrlCurvas,
        tamanhoTela: const ui.Size(400, 800),
        picosReferencia: picosReferencia,
      );
      expect(curvas1, isNotNull);
      expect(curvasMesmoBloco, same(curvas1));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(vm.amostrarElevacaoReal(-19.3156, -43.6135), isNotNull);

      // Garante segurança se descartado antes de concluir hidratação assíncrona
      final completerLento = Completer<MalhaGeograficaGlobo>();
      final vmDescartado = CenaGloboExplorarViewModel(
        lodInicialCamera: 0.2,
        carregarMalha: () => completerLento.future,
        carregarTextura: () async => img,
      );
      final futuroCancelado = vmDescartado.inicializarAssetsSeNecessario();
      vmDescartado.dispose();
      completerLento.complete(malhaSintetica);
      await futuroCancelado;
      expect(vmDescartado.malha, isNull);
    });

    test('coordena avanço e retração reversa da luz viária, timer de estrelas, clima, sonar e acessibilidade', () async {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -19.92,
        longitudeInicial: -43.94,
        lodInicial: 0.25,
      );
      addTearDown(ctrl.dispose);

      final vm = CenaGloboExplorarViewModel(
        lodInicialCamera: ctrl.lod,
        carregarMalha: () async => malhaSintetica,
        carregarTextura: _criarImagem1x1,
      );
      addTearDown(vm.dispose);

