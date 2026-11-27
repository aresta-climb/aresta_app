// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/view/view_models/cena_globo_explorar_view_model.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/superficie_globo_explorar.dart';

void main() {
  final picosTeste = <MarcadorPicoGlobo>[
    MarcadorPicoGlobo(
      id: 'igarape',
      nome: 'Pedra Grande',
      uf: 'MG',
      setorPrincipal: 'Parede Principal',
      latitude: -20.07,
      longitude: -44.32,
      altitudeBaseMetros: 980,
      altitudePicoMetros: 1430,
      dimensaoGradeDem: 3,
      raioGradeDemGraus: 0.024,
      gradeDemMetros: const [
        980, 1020, 1060,
        1120, 1280, 1390,
        1180, 1340, 1430,
      ],
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 4,
        diasDesdeChuva: 0,
        dataUltimaChuva: DateTime.utc(2026, 11, 25),
        milimetrosEvento: 22.0,
        bolhaIdAssociada: 'bolha_mg',
      ),
    ),
    MarcadorPicoGlobo(
      id: 'ouro_preto',
      nome: 'Parque das Andorinhas',
      uf: 'MG',
      setorPrincipal: 'Cachoeira',
      latitude: -20.35,
      longitude: -43.50,
      altitudeBaseMetros: 1120,
      altitudePicoMetros: 1580,
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 3,
        diasDesdeChuva: 1,
        dataUltimaChuva: DateTime.utc(2026, 11, 24),
        milimetrosEvento: 10.0,
        bolhaIdAssociada: 'bolha_op',
      ),
    ),
    MarcadorPicoGlobo(
      id: 'cipo',
      nome: 'Serra do Cipó',
      uf: 'MG',
      setorPrincipal: 'Grupo 1',
      latitude: -19.34,
      longitude: -43.62,
      altitudeBaseMetros: 820,
      altitudePicoMetros: 1290,
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 4,
        diasDesdeChuva: 0,
        dataUltimaChuva: DateTime.utc(2026, 11, 25),
        milimetrosEvento: 3.0,
        bolhaIdAssociada: 'bolha_cipo',
      ),
    ),
    const MarcadorPicoGlobo(
      id: 'urca',
      nome: 'Pão de Açúcar',
      uf: 'RJ',
      setorPrincipal: 'Costão',
      latitude: -22.95,
      longitude: -43.16,
      altitudeBaseMetros: 12,
      altitudePicoMetros: 396,
      umidade: EstadoUmidadePico.seco(),
    ),
  ];

  final bolhasTeste = <BolhaAtivaRenderizavel>[
    const BolhaAtivaRenderizavel(
      bolha: BolhaChuvaRegional(
        id: 'bolha_mg',
        latitude: -20.05,
        longitude: -43.95,
        intensidadeMmHora: 6.2,
        ventoRumoGraus: 48.0,
        ventoVelocidadeKmh: 26.0,
        contornoExterno: [
          PontoContornoGeo(longitude: -45.2, latitude: -21.2),
          PontoContornoGeo(longitude: -42.8, latitude: -20.9),
          PontoContornoGeo(longitude: -43.1, latitude: -18.8),
          PontoContornoGeo(longitude: -45.0, latitude: -19.0),
        ],
        nucleosIntensos: [
          [
            PontoContornoGeo(longitude: -44.6, latitude: -20.5),
            PontoContornoGeo(longitude: -43.4, latitude: -20.4),
            PontoContornoGeo(longitude: -43.8, latitude: -19.5),
          ],
        ],
      ),
      nivelIntensidade: NivelIntensidadeChuva.forte,
    ),
  ];

  group('SuperficieGloboExplorar', () {
    testWidgets(
      'carrega malha assincronamente quando cache frio e renderiza clusters separados por UF no LOD 0',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 0.25,
        );
        addTearDown(ctrl.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SuperficieGloboExplorar(
                controlador: ctrl,
                picos: picosTeste,
                bolhasAtivas: bolhasTeste,
                picoSelecionadoId: null,
                aoSelecionarPicoNoMapa: (_) {},
              ),
            ),
          ),
        );
        // Desbloqueia Isolate.run e os dois passos nativos do codec da textura NASA
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump();

        expect(MalhaGeograficaGlobo.cacheMemoria, isNotNull);
        expect(TexturaGloboNasa.cacheMemoria, isNotNull);
        expect(find.text('MG 3'), findsOneWidget);
        expect(find.text('RJ 1'), findsOneWidget);
      },
    );

    testWidgets(
      'transiciona pelos 4 LODs ao tocar clusters e pinos, suporta pinch/duplo-toque, alterna 3D/2D e reage a troca de controlador',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 0.25,
        );
        addTearDown(ctrl.dispose);

        final alturaGaveta = ValueNotifier<double>(180);
        addTearDown(alturaGaveta.dispose);
        String? selecionadoNoMapa;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SuperficieGloboExplorar(
                controlador: ctrl,
                picos: picosTeste,
                bolhasAtivas: bolhasTeste,
                picoSelecionadoId: 'igarape',
                alturaGavetaNotificador: alturaGaveta,
                localizacaoUsuario: (latitude: -19.92, longitude: -43.94),
                aoCentralizarNoUsuario: () {},
                aoSelecionarPicoNoMapa: (id) => selecionadoNoMapa = id,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const Key('marcador_localizacao_usuario')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('botao_minha_localizacao')),
          findsOneWidget,
        );

        // Toque no cluster MG 3 aproxima para LOD 1 sem colidir com RJ 1
        await tester.tap(find.byKey(const Key('cluster_uf_MG')));
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(selecionadoNoMapa, equals('igarape'));
        expect(ctrl.indiceLod, equals(1));

        // Em LOD 1 baixo (~1.05), pinos nao selecionados sao pontos compactos clicaveis
        ctrl.definirLod(1.05);
        await tester.pump();
        final pontoCipo = tester
            .widgetList<GestureDetector>(find.byType(GestureDetector))
            .toList();
        expect(pontoCipo.length, greaterThanOrEqualTo(3));

        // Toca no pino rotulado do pico selecionado para voar ate o LOD 3
        await tester.tap(find.text('Pedra Grande'));
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }

        // Verifica LOD 2 intermediario com curvas 250m e rotulo autoexplicativo de altitude acima do nivel do mar
        ctrl.definirLod(2.05);
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.text('Pedra Grande'), findsOneWidget);
        expect(find.text('1430 m acima do mar'), findsOneWidget);

        // Verifica LOD 3 no objeto proximo: terreno continuo detalhado com cidades reais e SEM trilha ficticia!
        ctrl.iniciarVooParabolico(
          destinoLat: -20.07,
          destinoLon: -44.32,
          destinoLod: 3.45,
        );
        for (var i = 0; i < 32; i++) {
          await tester.pump(const Duration(milliseconds: 45));
        }
        expect(find.text('Base / Trilha'), findsNothing);
        expect(find.text('Igarapé'), findsOneWidget);

        // Ao dar zoom alto (2.9) no meio do Oceano Atlantico (longe de qualquer pico),
        // NAO exibe Base / Trilha e pinta azul oceanico puro (sem grama falsa!)
        ctrl.iniciarVooParabolico(
          destinoLat: -20.0,
          destinoLon: -35.0,
          destinoLod: 2.9,
        );
        for (var i = 0; i < 32; i++) {
          await tester.pump(const Duration(milliseconds: 45));
        }
        expect(find.text('Base / Trilha'), findsNothing);
        final boundaryMar = tester.renderObject<RenderRepaintBoundary>(
          find.descendant(
            of: find.byType(SuperficieGloboExplorar),
            matching: find.byType(RepaintBoundary),
          ).first,
        );
        late ui.Image imgMar;
        await tester.runAsync(() async {
          imgMar = await boundaryMar.toImage(pixelRatio: 0.5);
        });
        final bytesMar = (await tester.runAsync(
          () => imgMar.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final wMar = imgMar.width;
        final hMar = imgMar.height;
        imgMar.dispose();
        final cxMar = wMar ~/ 2;
        final cyMar = hMar ~/ 2;
        final idxMar = (cyMar * wMar + cxMar) * 4;
        final rMar = bytesMar.getUint8(idxMar);
        final gMar = bytesMar.getUint8(idxMar + 1);
        final bMar = bytesMar.getUint8(idxMar + 2);
        expect(bMar, greaterThan(gMar + 15));
        expect(bMar, greaterThan(rMar + 20));

        // Muda altura da gaveta e valida notificacao ao controlador
        alturaGaveta.value = 320;
        await tester.pump();
        expect(ctrl.alturaGavetaPx, equals(320));

        // Gesto de pinch com 2 ponteiros e duplo toque na superficie
        final centro = tester.getCenter(find.byType(SuperficieGloboExplorar));
        final g1 = await tester.startGesture(centro + const Offset(-30, 0));
        final g2 = await tester.startGesture(centro + const Offset(30, 0));
        await g1.moveBy(const Offset(-25, 0));
        await g2.moveBy(const Offset(25, 0));
        await tester.pump();
        await g1.up();
        await g2.up();
        await tester.pump();

        // Volta para LOD 1 e testa duplo-toque + arrasto 1 dedo
        ctrl.definirLod(1.0);
        await tester.pump();
        await tester.tapAt(centro);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(centro);
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }

        // Toque em um pino compacto nao-selecionado no LOD 1
        ctrl.definirLod(1.02);
        await tester.pump();
        final ptOuroPreto = ctrl.projetarCoordenada(
          latitude: -20.35,
          longitude: -43.50,
          elevacaoMetros: 0,
          tamanhoTela: const Size(420, 800),
        );
        await tester.tapAt(Offset(ptOuroPreto.x, ptOuroPreto.y));
        await tester.pump(const Duration(milliseconds: 80));
        expect(selecionadoNoMapa, equals('ouro_preto'));

        // Exercita faixa costeira/oceanica (<0m e <650m) na regiao da Urca (RJ)
        ctrl.iniciarVooParabolico(
          destinoLat: -22.98,
          destinoLon: -43.16,
          destinoLod: 1.85,
        );
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 45));
        }

        // Alterna para 2D, renderiza relevo plano, arrasta ate os cantos/antimeridiano e verifica ausencia de falha
        ctrl.definirLod(1.9);
        await tester.tap(find.byKey(const Key('botao_alternar_3d_2d')));
        await tester.pump();
        expect(ctrl.modo3D, isFalse);
        expect(find.text('2D'), findsOneWidget);

        // Exercita canto extremo 2D no antimeridiano (zoom 0) e visao polar 3D (Polo Norte)
        ctrl.definirLod(0.0);
        ctrl.aplicarArrasto(dxPx: -900, dyPx: 900);
        await tester.pump();

        await tester.tap(find.byKey(const Key('botao_alternar_3d_2d')));
        await tester.pump();
        expect(ctrl.modo3D, isTrue);
        ctrl.aplicarArrasto(dxPx: 400, dyPx: 500);
        await tester.pump();

        await tester.tap(find.byKey(const Key('botao_resetar_globo')));
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 45));
        }

        // Arrasto manual e troca de controlador/notificador em didUpdateWidget
        await tester.drag(
          find.byType(SuperficieGloboExplorar),
          const Offset(36, -18),
        );
        await tester.pump(const Duration(milliseconds: 80));

        final ctrl2 = ControladorCameraGlobo(lodInicial: 2.95);
        addTearDown(ctrl2.dispose);
        final alturaGaveta2 = ValueNotifier<double>(210);
        addTearDown(alturaGaveta2.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SuperficieGloboExplorar(
                controlador: ctrl2,
                picos: const [],
                bolhasAtivas: bolhasTeste,
                picoSelecionadoId: null,
                alturaGavetaNotificador: alturaGaveta2,
                buscandoLocalizacaoUsuario: true,
                aoCentralizarNoUsuario: () {},
                aoSelecionarPicoNoMapa: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Respeita preferencia de acessibilidade disableAnimations pausando o ticker continuo
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SuperficieGloboExplorar(
                  controlador: ctrl2,
                  picos: const [],
                  bolhasAtivas: bolhasTeste,
                  picoSelecionadoId: null,
                  alturaGavetaNotificador: alturaGaveta2,
                  aoSelecionarPicoNoMapa: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      },
    );

    testWidgets(
      'exibe bolhas compactas com icone Aresta em qualquer zoom e expande descricao exclusivamente ao clicar na bolha',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Cluster denso com dois picos proximos (~3.8 km) em zoom alto (LOD 3.2):
        // sem selecao, NENHUM texto ou Base / Trilha deve aparecer sobreposto!
        final clusterDenso = <MarcadorPicoGlobo>[
          ...picosTeste,
          const MarcadorPicoGlobo(
            id: 'vizinho_colado',
            nome: 'Santuário Vizinho',
            uf: 'MG',
            latitude: -20.095,
            longitude: -44.295,
            altitudeBaseMetros: 960,
            altitudePicoMetros: 1380,
          ),
        ];

        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.07,
          longitudeInicial: -44.32,
          lodInicial: 3.20,
        );
        addTearDown(ctrl.dispose);

        String? selecionadoId;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SuperficieGloboExplorar(
                    controlador: ctrl,
                    picos: clusterDenso,
                    bolhasAtivas: const [],
                    incendiosAtivos: const [
                      BolhaIncendioAtivaRenderizavel(
                        incendio: BolhaIncendioRegional(
                          id: 'incendio_vizinho',
                          latitude: -20.06,
                          longitude: -44.31,
                          potenciaFrpMw: 45.0,
                          totalFocos: 3,
                          ventoRumoGraus: 270.0,
                          ventoVelocidadeKmh: 16.0,
                          contornoExterno: [
                            PontoContornoGeo(longitude: -44.34, latitude: -20.08),
                            PontoContornoGeo(longitude: -44.28, latitude: -20.08),
                            PontoContornoGeo(longitude: -44.31, latitude: -20.04),
                          ],
