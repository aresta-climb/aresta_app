// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_malha_viaria_offline.dart';
import 'package:frontend/services/clima/servico_tiles_elevacao_terrarium.dart';
import 'package:frontend/view/view_models/cena_globo_explorar_view_model.dart';
import 'package:frontend/widgets/explorar/componentes_marcador_globo.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

import '../../fakes/fonte_tiles_elevacao_fake.dart';

class _FonteMalhaViariaDeterministica implements FonteRemotaMalhaViaria {
  String? versaoRemota;
  SnapshotMalhaViariaOffline? snapshotRemoto;

  @override
  Future<String?> consultarVersaoRemota() async => versaoRemota;

  @override
  Future<SnapshotMalhaViariaOffline> buscarSnapshotRemoto() async {
    final snap = snapshotRemoto;
    if (snap == null) throw const HttpException('Sem snapshot');
    return snap;
  }
}

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

      final tempViario = await Directory.systemTemp.createTemp('cena_vm_viario_');
      addTearDown(() => tempViario.delete(recursive: true));
      final fonteViaria = _FonteMalhaViariaDeterministica();
      final servicoViario = ServicoMalhaViariaOffline(
        armazenamento: ArmazenamentoMalhaViariaLocal(
          provedorDiretorioBase: () async => tempViario.path,
        ),
        fonteRemota: fonteViaria,
      );
      addTearDown(servicoViario.dispose);

      final vm = CenaGloboExplorarViewModel(
        lodInicialCamera: 2.0,
        carregarMalha: () => completerMalha.future,
        carregarTextura: () => completerTextura.future,
        servicoElevacao: servicoTiles,
        servicoMalhaViaria: servicoViario,
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

      // Quando o serviço offline-first sincroniza nova versão viária no Supabase, atualiza a malha reativamente
      fonteViaria.versaoRemota = 'osm-v2-atualizada';
      fonteViaria.snapshotRemoto = SnapshotMalhaViariaOffline(
        geradoEm: DateTime.utc(2026, 11, 27, 16, 0),
        versaoHash: 'osm-v2-atualizada',
        rodovias: [
          RodoviaRegionalMapa.comLimites(
            ehPrincipal: true,
            nivelViario: 1,
            codigo: 'BR-040',
            verticesLonLat: const [
              ui.Offset(-43.9386, -19.9191),
              ui.Offset(-43.8000, -20.2000),
            ],
          ),
        ],
      );
      expect(await servicoViario.sincronizarSeDisponivel(forcar: true), isTrue);
      expect(vm.malha?.versaoMalhaViaria, equals('osm-v2-atualizada'));
      expect(vm.malha?.rodoviasProximas.single.codigo, equals('BR-040'));

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

      // Exercita camada fina (LOD >= 3.18), reuso de tiles no zoom e evicção LRU de tiles de curvas em pan longo
      ctrlCurvas.definirLod(3.60);
      final curvasFinas = vm.obterCurvasNivelVisiveis(
        controlador: ctrlCurvas,
        tamanhoTela: const ui.Size(400, 800),
        picosReferencia: picosReferencia,
      );
      expect(curvasFinas, isNotNull);
      for (var passoPan = 0; passoPan < 10; passoPan++) {
        ctrlCurvas.aplicarArrasto(
          dxPx: -320.0,
          dyPx: 260.0,
          tamanhoTela: const ui.Size(400, 800),
        );
        ctrlCurvas.definirLod(2.15);
        vm.obterCurvasNivelVisiveis(
          controlador: ctrlCurvas,
          tamanhoTela: const ui.Size(400, 800),
          picosReferencia: picosReferencia,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(vm.amostrarElevacaoReal(-19.3156, -43.6135), isNotNull);

      // Garante segurança se descartado antes de concluir hidratação assíncrona
      final completerLento = Completer<MalhaGeograficaGlobo>();
      final vmDescartado = CenaGloboExplorarViewModel(
        lodInicialCamera: 0.2,
        carregarMalha: () => completerLento.future,
        carregarTextura: () async => img,
        servicoMalhaViaria: servicoViario,
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

      // Ativa timer esparso de estrelas em 3D quando o ticker principal está parado
      vm.sincronizarEstadoCena(controlador: ctrl, tickerAtivo: false);
      final faseAntes = vm.faseEstrelasSegundos.value;
      await Future<void>.delayed(const Duration(milliseconds: 220));
      expect(vm.faseEstrelasSegundos.value, greaterThan(faseAntes));

      // Ao entrar em 2D, cancela o timer de estrelas
      ctrl.definirModo3D(false);
      vm.sincronizarEstadoCena(controlador: ctrl, tickerAtivo: false);
      ctrl.definirModo3D(true);

      // Zoom-in acima do limiar dispara ida progressiva da luz viária (0 -> 1 em 1.60s)
      ctrl.definirLod(1.90);
      vm.sincronizarEstadoCena(controlador: ctrl, tickerAtivo: true);
      expect(vm.alvoLuzViaria, equals(1.0));
      expect(
        vm.precisaAnimarQuadro(controlador: ctrl, temFenomenoAoVivo: false),
        isTrue,
      );

      vm.avancarQuadro(
        dtSegundos: 0.80,
        controlador: ctrl,
        temFenomenoAoVivo: true,
      );
      expect(vm.progressoLuzViaria, closeTo(0.50, 0.05));
      expect(vm.faseTempestadeSegundos, greaterThan(0.0));

      vm.avancarQuadro(
        dtSegundos: 1.00,
        controlador: ctrl,
        temFenomenoAoVivo: false,
      );
      expect(vm.progressoLuzViaria, equals(1.0));

      // Zoom-out abaixo do limiar dispara retração reversa (1 -> 0 em 1.35s)
      ctrl.definirLod(1.00);
      vm.avancarQuadro(
        dtSegundos: 0.675,
        controlador: ctrl,
        temFenomenoAoVivo: false,
      );
      expect(vm.alvoLuzViaria, equals(0.0));
      expect(vm.progressoLuzViaria, closeTo(0.50, 0.05));

      vm.avancarQuadro(
        dtSegundos: 0.80,
        controlador: ctrl,
        temFenomenoAoVivo: false,
      );
      expect(vm.progressoLuzViaria, equals(0.0));

      // Com animações desativadas (acessibilidade), transições acontecem instantaneamente
      vm.atualizarPreferenciaAnimacoesAmbiente(false);
      ctrl.definirLod(1.95);
      vm.sincronizarEstadoCena(controlador: ctrl, tickerAtivo: false);
      expect(vm.progressoLuzViaria, equals(1.0));
      ctrl.definirLod(0.95);
      vm.sincronizarEstadoCena(controlador: ctrl, tickerAtivo: false);
      expect(vm.progressoLuzViaria, equals(0.0));
    });

    test('resolve pico focado, escalona LODs de seleção, executa duplo-toque 2D/3D e reseta visão orbital', () {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -20.05,
        longitudeInicial: -44.30,
        lodInicial: 0.50,
      );
      addTearDown(ctrl.dispose);

      final vm = CenaGloboExplorarViewModel(
        lodInicialCamera: ctrl.lod,
        carregarMalha: () async => malhaSintetica,
        carregarTextura: _criarImagem1x1,
      );
      addTearDown(vm.dispose);

      const pico = MarcadorPicoGlobo(
        id: 'igarape',
        nome: 'Pedra Grande',
        uf: 'MG',
        latitude: -20.07,
        longitude: -44.32,
        altitudeBaseMetros: 980,
        altitudePicoMetros: 1430,
        umidade: EstadoUmidadePico(
          nivel: NivelUmidadePico.possivelmenteUmido,
          diasParaSecar: 3,
          bolhaIdAssociada: 'b_mg',
        ),
      );

      expect(
        vm.resolverPicoFocado(
          picos: const [],
          picoSelecionadoId: null,
          controlador: ctrl,
        ),
        isNull,
      );
      expect(
        vm.resolverPicoFocado(
          picos: const [pico],
          picoSelecionadoId: 'igarape',
          controlador: ctrl,
        )?.id,
        equals('igarape'),
      );
      expect(
        vm.resolverPicoFocado(
          picos: const [pico],
          picoSelecionadoId: null,
          controlador: ctrl,
        )?.id,
        equals('igarape'),
      );

      // Escalonamento de LODs não selecionado (<1.35, <2.65, >=2.65) e já selecionado (<2.75, <3.90, >=3.90) + explícito
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: null,
        controlador: ctrl,
      );
      expect(vm.sonarPicoId, equals('igarape'));
      expect(vm.sonarBolhaId, equals('b_mg'));
      expect(vm.progressoSonar, equals(0.0));
      vm.avancarQuadro(
        dtSegundos: 0.5,
        controlador: ctrl,
        temFenomenoAoVivo: false,
      );
      expect(vm.progressoSonar, equals(1.0));

      ctrl.definirLod(1.80);
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: null,
        controlador: ctrl,
      );
      ctrl.definirLod(3.00);
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: null,
        controlador: ctrl,
      );

      ctrl.definirLod(2.10);
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: 'igarape',
        controlador: ctrl,
      );
      ctrl.definirLod(3.50);
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: 'igarape',
        controlador: ctrl,
      );
      ctrl.definirLod(4.10);
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: 'igarape',
        controlador: ctrl,
      );
      vm.selecionarPicoNoMapa(
        pico: pico,
        picoSelecionadoAtualId: 'igarape',
        controlador: ctrl,
        lodExplicito: 1.18,
      );

      // Duplo-toque 3D e 2D + resetar visão do globo
      vm.executarDuploToqueMapa(
        tamanhoTela: const ui.Size(400, 800),
        posicaoToque: const ui.Offset(200, 400),
        picoFocado: pico,
        controlador: ctrl,
      );
      ctrl.definirModo3D(false);
      vm.executarDuploToqueMapa(
        tamanhoTela: const ui.Size(400, 800),
        posicaoToque: const ui.Offset(120, 260),
        picoFocado: null,
        controlador: ctrl,
      );
      vm.resetarVisaoGlobo(ctrl);
      expect(ctrl.temAnimacaoAtiva, isTrue);
    });
  });
}
