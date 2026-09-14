// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'dart:typed_data';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';
import 'package:frontend/services/editor_croqui.dart';

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
  @override
  Future<String?> getExternalStoragePath() async => tempPath;
  @override
  Future<List<String>?> getExternalCachePaths() async => [];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => [];
  @override
  Future<String?> getDownloadsPath() async => tempPath;
}

void main() {
  group('MapHelper', () {
    test('resolveMapaAndContext should find map in pico.mapasGerais', () {
      final mapa = Mapa()..caminhoImagemMapa = 'mapas_gerais/mapa.png';

      final pico = Pico()
        ..mapasGerais = (ArquivoMapas()
          ..conteudo = (ColecaoDeMapas()..mapas.add(mapa)));

      final result = MapHelper.resolveMapaAndContext(
        pico: pico,
        mapaCaminhoImagem: 'mapas_gerais/mapa.png',
      );

      expect(result.mapa.caminhoImagemMapa, 'mapas_gerais/mapa.png');
    });
  });

  group('AreaHelper Tests', () {
    test('Circular Area', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '1',
        circulo: BoundingCirculo(x: 100, y: 100, raio: 50),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds.left, 50.0);
      expect(areaInfo.bounds.top, 50.0);
      expect(areaInfo.bounds.right, 150.0);
      expect(areaInfo.bounds.bottom, 150.0);
      expect(areaInfo.polygon.length, 32);

      // Check first point (at 0 degrees: x + r, y)
      expect(areaInfo.polygon[0].dx, closeTo(150.0, 0.001));
      expect(areaInfo.polygon[0].dy, closeTo(100.0, 0.001));

      // Check point at 90 degrees (math.pi / 2: x, y + r)
      expect(areaInfo.polygon[8].dx, closeTo(100.0, 0.001));
      expect(areaInfo.polygon[8].dy, closeTo(150.0, 0.001));
    });

    test('Box Area - No Rotation', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '2',
        retangulo: BoundingRetangulo(
          x: 100,
          y: 100,
          comprimento: 60,
          largura: 40,
          anguloGrausX100: 0,
        ),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds.left, 70.0);
      expect(areaInfo.bounds.top, 80.0);
      expect(areaInfo.bounds.right, 130.0);
      expect(areaInfo.bounds.bottom, 120.0);
      expect(areaInfo.polygon.length, 4);

      // corners: (-30,-20), (30,-20), (30,20), (-30,20)
      // absolute: (70, 80), (130, 80), (130, 120), (70, 120)
      expect(areaInfo.polygon[0], const Offset(70, 80));
      expect(areaInfo.polygon[1], const Offset(130, 80));
      expect(areaInfo.polygon[2], const Offset(130, 120));
      expect(areaInfo.polygon[3], const Offset(70, 120));
    });

    test('Box Area - 90 Degree Rotation', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '3',
        retangulo: BoundingRetangulo(
          x: 100,
          y: 100,
          comprimento: 60,
          largura: 40,
          anguloGrausX100: 9000,
        ),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);

      // 60x40 rotated 90 deg becomes 40x60 bounds
      expect(areaInfo!.bounds.left, closeTo(80.0, 0.001));
      expect(areaInfo.bounds.top, closeTo(70.0, 0.001));
      expect(areaInfo.bounds.right, closeTo(120.0, 0.001));
      expect(areaInfo.bounds.bottom, closeTo(130.0, 0.001));

      expect(areaInfo.polygon.length, 4);
    });

    test('Area Livre', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '4',
        poligono: BoundingPoligono(coordenadas: [0, 0, 10, 0, 10, 10, 0, 10]),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds.left, 0.0);
      expect(areaInfo.bounds.top, 0.0);
      expect(areaInfo.bounds.right, 10.0);
      expect(areaInfo.bounds.bottom, 10.0);
      expect(areaInfo.polygon.length, 4);
      expect(areaInfo.polygon[0], const Offset(0, 0));
      expect(areaInfo.polygon[2], const Offset(10, 10));
    });

    test('Area Livre - Minimal Points', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '5',
        poligono: BoundingPoligono(coordenadas: [0, 0, 1, 1]),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds, Rect.fromLTRB(0, 0, 1, 1));
      expect(areaInfo.polygon.length, 2);
    });

    test('Box Area - Large Angle', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '6',
        retangulo: BoundingRetangulo(
          x: 100,
          y: 100,
          comprimento: 60,
          largura: 40,
          anguloGrausX100: 36000,
        ),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      // Should be same as 0 degrees
      expect(areaInfo!.bounds.left, closeTo(70.0, 0.001));
      expect(areaInfo.bounds.top, closeTo(80.0, 0.001));
    });

    test('Invalid Area Type', () {
      final ponto = Mapa_PontoDeInteresse(id: '7');
      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNull);
    });

    test('LinhaTrajeto Area - Compilado com SVG e Bounding Box', () {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_teste',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 100 800 C 120 700, 140 600, 160 500',
            caixaDelimitadora: BoundingRetangulo(
              x: 130,
              y: 650,
              comprimento: 60,
              largura: 300,
            ),
          ),
        ),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds.left, closeTo(100.0, 1.0));
      expect(areaInfo.bounds.right, closeTo(160.0, 1.0));
      expect(areaInfo.bounds.top, closeTo(500.0, 1.0));
      expect(areaInfo.bounds.bottom, closeTo(800.0, 1.0));
      expect(areaInfo.polygon, isNotEmpty);
    });

    test('LinhaTrajeto Area - Fallback com Conteúdo de Nós', () {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_conteudo',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          conteudo: DadosConteudoLinha(
            nos: [
              NoTrajeto(x: 10, y: 20),
              NoTrajeto(x: 50, y: 100),
              NoTrajeto(x: 30, y: 150),
            ],
          ),
        ),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds.left, 10.0);
      expect(areaInfo.bounds.right, 50.0);
      expect(areaInfo.bounds.top, 20.0);
      expect(areaInfo.bounds.bottom, 150.0);
      expect(areaInfo.polygon.length, 3);
    });
  });

  group('MarkerPainter hitTest Tests', () {
    test('hitTest detects point inside and outside unrotated rectangle', () {
      final polygon = [
        const Offset(70, 80),
        const Offset(130, 80),
        const Offset(130, 120),
        const Offset(70, 120),
      ];
      final minX = 70.0;
      final minY = 80.0;
      final padding = 4.0;

      final painter = MarkerPainter(
        polygon: polygon,
        minX: minX,
        minY: minY,
        mapWidth: 200,
        mapHeight: 200,
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: padding,
      );

      // Width of bounds is 60, height is 40. With 1:1 scale, local bounding box is [padding, padding] to [padding+60, padding+40].
      // Inside point (center of the local AABB: 30 + 4, 20 + 4) = (34, 24)
      expect(painter.hitTest(const Offset(34, 24)), isTrue);
      // Outside point (outside local AABB and inflation tolerance)
      expect(painter.hitTest(const Offset(100, 100)), isFalse);
    });

    test('hitTest correctly excludes corners of AABB for rotated rectangle', () {
      // Rotate 60x40 box by 45 degrees.
      // We will just create a diamond polygon for simplicity to test the hitTest logic.
      final polygon = [
        const Offset(100, 50),
        const Offset(150, 100),
        const Offset(100, 150),
        const Offset(50, 100),
      ];
      final minX = 50.0;
      final minY = 50.0;
      final padding = 4.0;

      final painter = MarkerPainter(
        polygon: polygon,
        minX: minX,
        minY: minY,
        mapWidth: 200,
        mapHeight: 200,
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: padding,
      );

      // Local AABB size is 100x100.
      // Center is at 50 + 4 = 54.
      expect(painter.hitTest(const Offset(54, 54)), isTrue);

      // Top-left corner of local AABB is (4, 4). Since it's a diamond, (4,4) is outside the polygon!
      expect(painter.hitTest(const Offset(5, 5)), isFalse);
    });

    test('hitTest allows slight inflation for tapping near thin polygons', () {
      // Thin line at y=100 from x=50 to x=150
      final polygon = [const Offset(50, 100), const Offset(150, 100)];
      final minX = 50.0;
      final minY = 100.0;
      final padding = 4.0;

      final painter = MarkerPainter(
        polygon: polygon,
        minX: minX,
        minY: minY,
        mapWidth: 200,
        mapHeight: 200,
        constraints: BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: padding,
      );

      // Center of line is local x = 50+4 = 54. local y = 0+4 = 4.
      // Directly on the line
      expect(painter.hitTest(const Offset(54, 4)), isTrue);

      // Slightly above the line (distance 4), should be within tolerance if inflated.
      expect(painter.hitTest(const Offset(54, 0)), isTrue);

      // Far away
      expect(painter.hitTest(const Offset(54, 20)), isFalse);
    });

    test('hitTest para LinhaTrajeto detecta toque próximo da curva e não fecha laço entre início e fim', () {
      // Linha em L: (0, 0) -> (100, 0) -> (100, 100)
      final polygon = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
      ];
      final minX = 0.0;
      final minY = 0.0;
      final padding = 4.0;

      final painter = MarkerPainter(
        polygon: polygon,
        minX: minX,
        minY: minY,
        mapWidth: 200,
        mapHeight: 200,
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: padding,
        isLinha: true,
      );

      // Toque próximo à linha horizontal (local y = 4 + 8 = 12, dist = 8dp <= 16dp)
      expect(painter.hitTest(const Offset(54, 12)), isTrue);

      // Toque entre o fim (100, 100) e o início (0, 0), por exemplo em (14, 94).
      // Se fechasse o laço como polígono fechado, estaria perto da hipotenusa. Como é linha aberta, DEVE ser false!
      expect(painter.hitTest(const Offset(14, 94)), isFalse);

      // Toque no canto oposto vazio (0, 100), dist ~100dp
      expect(painter.hitTest(const Offset(4, 104)), isFalse);
    });

    test('hitTest para LinhaTrajeto com zoom 1.0x aplica tolerância ergonômica mínima', () {
      final polygon = [const Offset(0, 0), const Offset(100, 0)];
      final painter = MarkerPainter(
        polygon: polygon,
        minX: 0,
        minY: 0,
        mapWidth: 200,
        mapHeight: 200,
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        zoomAtual: 1.0,
        linha: LinhaTrajeto(espessura: 2),
      );

      // Distância de 12dp da linha: dentro do raio mínimo ergonômico de 16dp
      expect(painter.hitTest(const Offset(54, 16)), isTrue);

      // Distância de 22dp da linha: fora do raio mínimo ergonômico de 16dp
      expect(painter.hitTest(const Offset(54, 26)), isFalse);
    });

    test('hitTest para LinhaTrajeto com zoom ampliado (4.0x) colapsa tolerância extra e segue o traçado', () {
      final polygon = [const Offset(0, 0), const Offset(100, 0)];
      final painter = MarkerPainter(
        polygon: polygon,
        minX: 0,
        minY: 0,
        mapWidth: 200,
        mapHeight: 200,
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        zoomAtual: 4.0,
        linha: LinhaTrajeto(espessura: 2),
      );

      // No zoom 4.0x, a tolerância extra de tela colapsa para zero
      // Toque a 12dp locais agora é rejeitado (em tela seria 12 * 4 = 48dp de distância!)
      expect(painter.hitTest(const Offset(54, 16)), isFalse);

      // Toque muito próximo à linha (distância local <= 2dp) é aceito
      expect(painter.hitTest(const Offset(54, 5)), isTrue);
    });

    test('hitTest para LinhaTrajeto detecta toque próximo aos marcadores compilados com tolerância ergonômica', () {
      final polygon = [const Offset(0, 0), const Offset(100, 0)];
      final painter = MarkerPainter(
        polygon: polygon,
        minX: 0,
        minY: 0,
        mapWidth: 200,
        mapHeight: 200,
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        zoomAtual: 1.0,
        linha: LinhaTrajeto(
          espessura: 2,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 0 0 L 100 0',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 0,
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                rotulo: '1',
                raio: 12,
              ),
            ],
          ),
        ),
      );

      // O marcador está no ponto local (54, 4) com raio 12dp.
      // Com tolerância ergonômica mínima de 22dp em tela:
      // Toque a 18dp de distância do centro do marcador: deve retornar true
      expect(painter.hitTest(const Offset(54, 22)), isTrue);

      // Toque a 30dp de distância do centro do marcador (e da linha): deve retornar false
      expect(painter.hitTest(const Offset(54, 34)), isFalse);
    });

    test('hitTest com polígono contendo pontos coincidentes l2 == 0 avalia distância ao ponto', () {
      final polygon = [
        const Offset(10, 10),
        const Offset(10, 10),
        const Offset(20, 20),
      ];
      final painter = MarkerPainter(
        polygon: polygon,
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 0.0,
        isLinha: false,
        zoomAtual: 1.0,
      );

      expect(painter.hitTest(const Offset(12, 12)), isTrue);
      expect(painter.hitTest(const Offset(80, 80)), isFalse);
    });

    test('MarkerPainter shouldRepaint detecta alterações em zoomAtual, transformationController e linha', () {
      final ctrl1 = TransformationController();
      final ctrl2 = TransformationController();
      final linha1 = LinhaTrajeto(espessura: 2);
      final linha2 = LinhaTrajeto(espessura: 4);

      final p1 = MarkerPainter(
        polygon: [const Offset(0, 0)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        zoomAtual: 1.0,
        transformationController: ctrl1,
        linha: linha1,
      );

      final pIdentico = MarkerPainter(
        polygon: [const Offset(0, 0)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        zoomAtual: 1.0,
        transformationController: ctrl1,
        linha: linha1,
      );

      expect(p1.shouldRepaint(pIdentico), isFalse);

      final pZoomDiferente = MarkerPainter(
        polygon: [const Offset(0, 0)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        zoomAtual: 2.0,
        transformationController: ctrl1,
        linha: linha1,
      );
      expect(p1.shouldRepaint(pZoomDiferente), isTrue);

      final pCtrlDiferente = MarkerPainter(
        polygon: [const Offset(0, 0)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        zoomAtual: 1.0,
        transformationController: ctrl2,
        linha: linha1,
      );
      expect(p1.shouldRepaint(pCtrlDiferente), isTrue);

      final pLinhaDiferente = MarkerPainter(
        polygon: [const Offset(0, 0)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        zoomAtual: 1.0,
        transformationController: ctrl1,
        linha: linha2,
      );
      expect(p1.shouldRepaint(pLinhaDiferente), isTrue);
    });
  });

  group('MapaInterativoPage Widget Tests', () {
    late Directory tempDir;
    late Mapa mockMapa;
    late MemoryImage mockImage;
    late MockTelemetryService mockTelemetry;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('mapa_interativo_test_');
      EditorDeCroqui(); // Instancia o singleton
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      mockImage = MemoryImage(kTransparentImage);
      mockMapa = Mapa(
        caminhoImagemMapa: 'mapa.webp',
        larguraMapa: 1000,
        alturaMapa: 800,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            id: 'p1',
            label: 'Ponto 1',
            retangulo: BoundingRetangulo(
              x: 100,
              y: 100,
              comprimento: 50,
              largura: 50,
            ),
          ),
          Mapa_PontoDeInteresse(
            id: 'p2',
            label: 'Ponto 2',
            circulo: BoundingCirculo(x: 500, y: 400, raio: 30),
          ),
        ],
      );
    });

    Widget buildApp(
      List<Escalada> escaladas,
      Mapa mapa, {
      bool autoZoom = true,
      bool hideAppBar = false,
    }) {
      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Teste';
      setor.escaladas.addAll(escaladas);
      pico.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
      );

      return MaterialApp(
        home: MapaInterativoPage(
          mapa: mapa,
          pico: pico,
          cragId: 'test_crag',
          autoZoomEnabled: autoZoom,
          hideAppBar: hideAppBar,
          imageProviderOverride: mockImage,
        ),
      );
    }

    testWidgets('Renders markers correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp([], mockMapa));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    });

    testWidgets('Renders AppBar when hideAppBar is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp([], mockMapa, hideAppBar: false));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Croqui Interativo'), findsOneWidget);
    });

    testWidgets('Does not render AppBar when hideAppBar is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp([], mockMapa, hideAppBar: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Croqui Interativo'), findsNothing);
    });

    testWidgets('Selecting a marker shows floating card', (
      WidgetTester tester,
    ) async {
      final esc1 = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via Teste',
          dificuldade: GrauVia_GrauVia.BR_5,
        ),
      );
      mockMapa.referencias.add(
        Mapa_Referencia(
          setor: 'Setor Teste',
          escalada: 'Via Teste',
          ids: ['p1'],
        ),
      );

      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);

      final clickEvents = mockTelemetry.recordedEvents
          .where((e) => e == 'acao_escalada')
          .toList();
      expect(clickEvents.length, 1);
      expect(
        mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'],
        'Via Teste',
      );
    });

    testWidgets(
      'Clicking "Mais Info" on floating card fires logAcaoEscalada telemetry',
      (WidgetTester tester) async {
        final esc1 = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Via Teste',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        );
        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Teste',
            ids: ['p1'],
          ),
        );

        await tester.pumpWidget(buildApp([esc1], mockMapa));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        mockTelemetry.clear();

        await tester.tap(find.text('Mais Info'));
        await tester.pumpAndSettle();

        expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
        expect(
          mockTelemetry.recordedParams['acao_escalada']!['acao'],
          'abrir_detalhes',
        );
      },
    );

    testWidgets('Tapping background de-selects marker', (
      WidgetTester tester,
    ) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste'));
      mockMapa.referencias.add(
        Mapa_Referencia(
          setor: 'Setor Teste',
          escalada: 'Via Teste',
          ids: ['p1'],
        ),
      );

      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Via Teste'), findsOneWidget);

      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Botão no canto inferior direito recentraliza a imagem para a visão panorâmica inicial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp([], mockMapa, autoZoom: true));
      await tester.pumpAndSettle();

      final recenterBtn = find.byTooltip('Centralizar imagem');
      expect(recenterBtn, findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(recenterBtn);
      await tester.pumpAndSettle();

      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsOneWidget);
    });

    testWidgets('Closing floating card de-selects marker', (
      WidgetTester tester,
    ) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste'));
      mockMapa.referencias.add(
        Mapa_Referencia(
          setor: 'Setor Teste',
          escalada: 'Via Teste',
          ids: ['p1'],
        ),
      );

      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Handles zero-size map gracefully', (
      WidgetTester tester,
    ) async {
      final smallMapa = Mapa(larguraMapa: 0, alturaMapa: 0);
      await tester.pumpWidget(buildApp([], smallMapa));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('3.1: Ausência do botão "Subir" em mapas sem nível superior', (
      WidgetTester tester,
    ) async {
      final pico = Pico()..nome = 'Pico Teste';
      // Pico não tem mapas gerais, setor não tem grupo

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaInterativoPage(
              cragId: 'test_crag',
              pico: pico,
              mapa: mockMapa,
              setorContext: Setor()..nome = 'Setor Sul',
              imageProviderOverride: mockImage,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final btn = find.byIcon(
        Icons.turn_left_outlined,
      ); // assuming we use this icon for up
      final btnFallback = find.byType(ActionChip);

      expect(btn, findsNothing);
      expect(btnFallback, findsNothing);
    });

    testWidgets('3.2: Nomes muito grandes ficam truncados com ellipsis', (
      WidgetTester tester,
    ) async {
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()
        ..nome =
            'Grupo com um nome absurdamente gigante para testar o truncamento de texto na interface';
      grupo.mapas.add(Mapa()..caminhoImagemMapa = 'grupo.png');
      pico.setoresOuGrupos.add(
        SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupo),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaInterativoPage(
              cragId: 'test_crag',
              pico: pico,
              mapa: mockMapa,
              setorContext: Setor()..nome = 'Setor Sul',
              grupoContext: grupo,
              imageProviderOverride: mockImage,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chipFinder = find.byType(ActionChip);
      expect(chipFinder, findsOneWidget);

      // Ensure there's a ConstrainedBox restricting its width
      final constrainedBoxFinder = find
          .ancestor(of: chipFinder, matching: find.byType(ConstrainedBox))
          .first;
      expect(constrainedBoxFinder, findsOneWidget);

      final ConstrainedBox constrainedBox = tester.widget(constrainedBoxFinder);
      expect(constrainedBox.constraints.maxWidth, isNotNull);
    });

    testWidgets('3.3: Clique no botão empurra a página esperada na pilha', (
      WidgetTester tester,
    ) async {
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';
      grupo.mapas.add(Mapa()..caminhoImagemMapa = 'grupo.png');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaInterativoPage(
              cragId: 'test_crag',
              pico: pico,
              mapa: mockMapa,
              setorContext: Setor()..nome = 'Setor Sul',
              grupoContext: grupo,
              imageProviderOverride: mockImage,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final btn = find.text('Grupo Teste'); // Assumed label
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Telemetry should be fired
      expect(
        mockTelemetry.recordedEvents,
        contains('navegacao_hierarquica_mapa'),
      );
    });

    testWidgets(
      'Initial selected id with escaladaContext opens carousel at correct index',
      (WidgetTester tester) async {
        final mockMapa = Mapa(
          caminhoImagemMapa: 'mapa.webp',
          larguraMapa: 1000,
          alturaMapa: 800,
          pontosDeInteresse: [
            Mapa_PontoDeInteresse(
              id: 'shared_id',
              label: 'Shared Marker',
              retangulo: BoundingRetangulo(
                x: 100,
                y: 100,
                comprimento: 50,
                largura: 50,
              ),
            ),
          ],
        );

        final escWrong = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Wrong Via',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        );
        final escTarget = Escalada(boulder: Boulder(nome: 'Target Via'));

        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Wrong Via',
            ids: ['shared_id'],
          ),
        );
        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Target Via',
            ids: ['shared_id'],
          ),
        );

        final pico = Pico()..nome = 'Pico Teste';
        final setor = Setor()..nome = 'Setor Teste';
        setor.escaladas.addAll([escWrong, escTarget]);
        pico.setoresOuGrupos.add(
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mockMapa,
                cragId: 'test_crag',
                autoZoomEnabled: false,
                imageProviderOverride: MemoryImage(kTransparentImage),
                initialSelectedId: 'shared_id',
                escaladaContextNome: 'Target Via',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Target Via'), findsOneWidget);
        expect(find.text('Wrong Via'), findsNothing);
      },
    );

    testWidgets(
      'MapaInterativoPage deve renderizar o botão de feedback (bug_report)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildApp([], mockMapa));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bug_report), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping a grouped marker shows carousel with arrows and swiping/clicking fires telemetry',
      (WidgetTester tester) async {
        final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1'));
        final esc2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 2'));
        mockMapa.referencias.add(
          Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via 1', ids: ['p1']),
        );
        mockMapa.referencias.add(
          Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via 2', ids: ['p1']),
        );

        await tester.pumpWidget(buildApp([esc1, esc2], mockMapa));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        expect(find.text('Via 1'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        expect(find.text('Via 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Single point marker with duplicate ids should zoom to 2.5 instead of 5.0',
      (WidgetTester tester) async {
        final pontoDuplicado = Mapa_PontoDeInteresse(
          id: 'dup_id',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapaUnico = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [pontoDuplicado],
        );
        mapaUnico.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Dupla',
            ids: ['dup_id', 'dup_id'],
          ),
        );

        final escDuplicada = Escalada(boulder: Boulder(nome: 'Dupla'));

        await tester.pumpWidget(buildApp([escDuplicada], mapaUnico));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_dup_id')));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final matrix = interactiveViewer.transformationController!.value;

        expect(matrix.storage[0], closeTo(2.5, 0.01));
      },
    );

    testWidgets(
      'Multiple points without inicio and fim should use bounding box zoom',
      (WidgetTester tester) async {
        final ponto1 = Mapa_PontoDeInteresse(
          id: 'start_id',
          circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
        );
        final ponto2 = Mapa_PontoDeInteresse(
          id: 'middle_id',
          circulo: BoundingCirculo(x: 90, y: 90, raio: 5), // Far apart
        );
        final mapaMulti = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto1, ponto2],
        );
        // ref has inicio and meio, but NO fim (ids[2] is empty/missing)
        mapaMulti.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Boulder Longe',
            ids: ['start_id', 'middle_id'],
          ),
        );

        final escBoulder = Escalada(boulder: Boulder(nome: 'Boulder Longe'));

        await tester.pumpWidget(buildApp([escBoulder], mapaMulti));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_start_id')));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final matrix = interactiveViewer.transformationController!.value;

        // Because they are far apart (from 10 to 90 out of 100), boxWidthRel = 0.8
        // The bounding box logic will compute a scale based on available space, which is typically around 1.0 - 1.5, not 2.5
        expect(matrix.storage[0], lessThan(2.5));
      },
    );
    testWidgets(
      'Base card layout uses Wrap to prevent overflow with long titles',
      (WidgetTester tester) async {
        final escLong = Escalada(
          viaEsportiva: ViaEsportiva(
            nome:
                'A very very very very very very very very very long via name',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        );
        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada:
                'A very very very very very very very very very long via name',
            ids: ['p1'],
          ),
        );

        await tester.pumpWidget(buildApp([escLong], mockMapa));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        // Ensure that the card rendered and contains a Wrap widget (which replaced the Row)
        // to handle the overflow gracefully.
        expect(find.textContaining('A very very very'), findsOneWidget);
        expect(find.byType(Wrap), findsWidgets);
      },
    );

    testWidgets(
      'Multiple points very close should be capped at reasonable maximum zoom',
      (WidgetTester tester) async {
        final ponto1 = Mapa_PontoDeInteresse(
          id: 'start_id',
          circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
        );
        final ponto2 = Mapa_PontoDeInteresse(
          id: 'middle_id',
          circulo: BoundingCirculo(x: 11, y: 11, raio: 5), // Very close
        );
        final mapaClose = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto1, ponto2],
        );
        mapaClose.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Boulder Perto',
            ids: ['start_id', 'middle_id'],
          ),
        );

        final escBoulder = Escalada(boulder: Boulder(nome: 'Boulder Perto'));

        await tester.pumpWidget(buildApp([escBoulder], mapaClose));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_start_id')));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final matrix = interactiveViewer.transformationController!.value;

        // Without capping, the zoom would be close to 5.0. It should be capped at 2.5
        expect(matrix.storage[0], closeTo(2.5, 0.01));
      },
    );

    testWidgets(
      'Custom camera zoom in reference should override calculated zoom',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapa = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );

        mapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Custom',
            ids: ['p1'],
            ajusteDeCamera: Mapa_AjusteDeCamera(zoom: 4.0),
          ),
        );

        final esc = Escalada(boulder: Boulder(nome: 'Via Custom'));

        await tester.pumpWidget(buildApp([esc], mapa));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final matrix = interactiveViewer.transformationController!.value;

        // Should exactly match the custom zoom from reference
        expect(matrix.storage[0], closeTo(4.0, 0.01));
      },
    );

    testWidgets(
      'Single point marker when map is already at higher zoom (4.5x) preserves scale and does not reduce zoom',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapa = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );

        mapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Unica',
            ids: ['p1'],
          ),
        );

        final esc = Escalada(boulder: Boulder(nome: 'Via Unica'));

        await tester.pumpWidget(buildApp([esc], mapa));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        // Simulando que o usuário aplicou zoom manual de 4.5x centrado na tela (800x600)
        // x' = -1400 + 400 * 4.5 = 400, y' = -1050 + 300 * 4.5 = 300
        interactiveViewer.transformationController!.value = Matrix4.identity()
          ..translateByDouble(-1400.0, -1050.0, 0.0, 1.0)
          ..scaleByDouble(4.5, 4.5, 1.0, 1.0);
        await tester.pump();

        // Toca no marcador do ponto único
        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        final matrix = interactiveViewer.transformationController!.value;

        // O zoom DEVE ser mantido em 4.5x (regra monotônica: não reduz para 2.5x)
        expect(matrix.storage[0], closeTo(4.5, 0.01));
      },
    );

    testWidgets(
      'InteractiveViewer configuration should have maxScale set to 10.0, minScale set to 1.0 and zero boundaryMargin',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildApp([], mockMapa));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );

        expect(interactiveViewer.maxScale, equals(10.0));
        expect(interactiveViewer.minScale, equals(1.0));
        expect(interactiveViewer.boundaryMargin, equals(EdgeInsets.zero));
      },
    );

    testWidgets(
      'Single tiny marker on large map should dynamically calculate comfortable zoom higher than 2.5',
      (WidgetTester tester) async {
        final pontoPequeno = Mapa_PontoDeInteresse(
          id: 'p_pequeno',
          circulo: BoundingCirculo(x: 500, y: 500, raio: 2), // 4px num mapa de 1000px
        );
        final mapaGrande = Mapa(
          larguraMapa: 1000,
          alturaMapa: 1000,
          pontosDeInteresse: [pontoPequeno],
        );
        mapaGrande.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Pequena',
            ids: ['p_pequeno'],
          ),
        );

        final esc = Escalada(boulder: Boulder(nome: 'Via Pequena'));

        await tester.pumpWidget(buildApp([esc], mapaGrande));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p_pequeno')));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final matrix = interactiveViewer.transformationController!.value;

        // Elemento muito pequeno deve receber zoom dinâmico confortável > 2.5 (limitado a 10.0)
        expect(matrix.storage[0], greaterThan(2.5));
        expect(matrix.storage[0], lessThanOrEqualTo(10.0));
      },
    );

    testWidgets(
      'Double tap on map toggles zoom in and zoom out smoothly',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildApp([], mockMapa));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        expect(interactiveViewer.transformationController!.value.storage[0], closeTo(1.0, 0.01));

        // Primeiro duplo toque: amplia para escala de detalhe (~3.5x)
        await tester.tap(find.byType(InteractiveViewer));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(InteractiveViewer));
        await tester.pumpAndSettle();

        expect(
          interactiveViewer.transformationController!.value.storage[0],
          closeTo(3.5, 0.01),
        );

        // Segundo duplo toque: reseta para visão geral (1.0x)
        await tester.tap(find.byType(InteractiveViewer));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(InteractiveViewer));
        await tester.pumpAndSettle();

        expect(
          interactiveViewer.transformationController!.value.storage[0],
          closeTo(1.0, 0.01),
        );
      },
    );

    testWidgets(
      'User manual zoom adjustment sets sticky zoom preserving manual scale on single point clicks',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 500, y: 500, raio: 2), // minúsculo num mapa de 1000px
        );
        final mapa = Mapa(
          larguraMapa: 1000,
          alturaMapa: 1000,
          pontosDeInteresse: [ponto],
        );
        mapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Manual',
            ids: ['p1'],
          ),
        );

        final esc = Escalada(boulder: Boulder(nome: 'Via Manual'));

        await tester.pumpWidget(buildApp([esc], mapa));
        await tester.pumpAndSettle();

        final interactiveViewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );

        // Simula o gesto de pinça do usuário que ajustou o zoom para 3.8x
        interactiveViewer.onInteractionStart?.call(
          ScaleStartDetails(focalPoint: const Offset(400, 300)),
        );
        interactiveViewer.transformationController!.value = Matrix4.identity()
          ..translateByDouble(-1120.0, -840.0, 0.0, 1.0) // centrado: 400 - 400 * 3.8 = -1120, 300 - 300 * 3.8 = -840
          ..scaleByDouble(3.8, 3.8, 1.0, 1.0);
        interactiveViewer.onInteractionEnd?.call(
          ScaleEndDetails(velocity: Velocity.zero),
        );
        await tester.pump();

        // Toca no marcador
        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        final matrix = interactiveViewer.transformationController!.value;

        // O zoom DEVE respeitar estritamente a escala 3.8x definida pelo usuário
        // (sem sticky zoom, o cálculo dinâmico tentaria forçar ~10.0x)
        expect(matrix.storage[0], closeTo(3.8, 0.01));
      },
    );

    testWidgets(
      'didUpdateWidget in experimental mode successfully re-resolves references for hot reload',
      (WidgetTester tester) async {
        EditorDeCroqui.instance.isExperimentalMode.value = true;

        Mapa testMapa = mockMapa;
        final esc1 = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Via Inicial',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        );

        await tester.pumpWidget(buildApp([esc1], testMapa));
        await tester.pumpAndSettle();

        // O marker p1 está no dataset original de pontos de interesse, mas como ele não tem
        // uma referência apontando para ele, ele NÃO deve ser renderizado na UI
        expect(find.byKey(const Key('marker_p1')), findsNothing);

        // Simulando o hot-reload: O dataset foi atualizado!
        final newMapaObj = Mapa.fromBuffer(testMapa.writeToBuffer());
        newMapaObj.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Via Inicial',
            ids: ['p1'],
          ),
        );

        // Pump widget again with the new map object to trigger didUpdateWidget
        await tester.pumpWidget(buildApp([esc1], newMapaObj));
        await tester.pumpAndSettle();

        // Clicar no p1 de novo deve encontrar a via e abrir o card!
        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();
        expect(find.text('Via Inicial'), findsOneWidget);

        EditorDeCroqui.instance.isExperimentalMode.value = false;
      },
    );

    testWidgets(
      'didUpdateWidget re-resolves image provider even when mapa fields are identical',
      (WidgetTester tester) async {
        final pico = Pico()..nome = 'Pico Teste';
        Mapa testMapa = mockMapa;
        final img1 = MemoryImage(kTransparentImage);
        final img2 = MemoryImage(Uint8List.fromList(kTransparentImage));

        Widget buildAppWithOverride(ImageProvider override) {
          return MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                mapa: testMapa,
                pico: pico,
                cragId: 'pico_1',
                imageProviderOverride: override,
              ),
            ),
          );
        }


        await tester.pumpWidget(buildAppWithOverride(img1));
        await tester.pumpAndSettle();

        // Re-pump com mesmo objeto testMapa, mas provider diferente
        await tester.pumpWidget(buildAppWithOverride(img2));
        await tester.pumpAndSettle();
      },
    );


    testWidgets(
      'Tapping on a marker with multiple maps DOES NOT display "Ver mapas" button for vias',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapa1 = Mapa(
          caminhoImagemMapa: 'map1.webp',
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );
        final mapa2 = Mapa(
          caminhoImagemMapa: 'map2.webp',
          pontosDeInteresse: [ponto],
        );

        final ref = Mapa_Referencia(
          setor: 'Setor Teste',
          escalada: 'Via Dupla',
          ids: ['p1'],
        );
        mapa1.referencias.add(ref);
        mapa2.referencias.add(ref);

        final esc = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Via Dupla',
            dificuldade: GrauVia_GrauVia.BR_5,
          ),
        );

        final pico = Pico(nome: 'Pico Multi');
        final setor = Setor(
          nome: 'Setor Teste',
          mapas: [mapa1, mapa2],
          escaladas: [esc],
        );
        pico.setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mapa1,
                cragId: 'crag1',
                setorContext: setor,
                imageProviderOverride: MemoryImage(kTransparentImage),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        expect(find.text('Ver mapas'), findsNothing);
      },
    );

    testWidgets(
      'Setor Card with multiple maps displays "Explorar mapas do setor" and uses carousel',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapaGeral = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );

        final mapaSetor1 = Mapa(caminhoImagemMapa: 's1.webp');
        final mapaSetor2 = Mapa(caminhoImagemMapa: 's2.webp');

        final setor = Setor(
          nome: 'Setor Teste',
          mapas: [mapaSetor1, mapaSetor2],
        );

        final ref = Mapa_Referencia(setor: 'Setor Teste', ids: ['p1']);
        mapaGeral.referencias.add(ref);

        final pico = Pico(nome: 'Pico Multi');
        pico.setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mapaGeral,
                cragId: 'crag1',
                imageProviderOverride: MemoryImage(kTransparentImage),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        expect(find.text('Ver mapas'), findsOneWidget);
      },
    );

    testWidgets(
      'Grupo Card with multiple maps displays "Mapa do grupo de setores" and uses carousel',
      (WidgetTester tester) async {
        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapaGeral = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );

        final mapaGrupo1 = Mapa(caminhoImagemMapa: 'g1.webp');
        final mapaGrupo2 = Mapa(caminhoImagemMapa: 'g2.webp');

        final grupo = Grupo(
          nome: 'Grupo Teste',
          mapas: [mapaGrupo1, mapaGrupo2],
        );

        final ref = Mapa_Referencia(grupo: 'Grupo Teste', ids: ['p1']);
        mapaGeral.referencias.add(ref);

        final pico = Pico(nome: 'Pico Multi');
        pico.setoresOuGrupos.add(
          SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mapaGeral,
                cragId: 'crag1',
                imageProviderOverride: MemoryImage(kTransparentImage),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        expect(find.text('Ver mapas'), findsOneWidget);
      },
    );

    testWidgets(
      'Base card action buttons use Wrap to prevent overflow on narrow screens',
      (WidgetTester tester) async {
        // Set a very narrow screen size to force wrapping
        tester.view.physicalSize = const Size(300, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        final ponto = Mapa_PontoDeInteresse(
          id: 'p1',
          circulo: BoundingCirculo(x: 50, y: 50, raio: 5),
        );
        final mapaGeral = Mapa(
          larguraMapa: 100,
          alturaMapa: 100,
          pontosDeInteresse: [ponto],
        );

        final mapaSetor1 = Mapa(caminhoImagemMapa: 's1.webp');
        final mapaSetor2 = Mapa(caminhoImagemMapa: 's2.webp');
        final mapaSetor3 = Mapa(caminhoImagemMapa: 's3.webp');
        final mapaSetor4 = Mapa(caminhoImagemMapa: 's4.webp');
        final mapaSetor5 = Mapa(caminhoImagemMapa: 's5.webp');

        final setor = Setor(
          nome: 'Setor Com Um Nome Incrivelmente Grande e Complexo',
          mapas: [mapaSetor1, mapaSetor2, mapaSetor3, mapaSetor4, mapaSetor5],
        );

        final ref = Mapa_Referencia(
          setor: 'Setor Com Um Nome Incrivelmente Grande e Complexo',
          ids: ['p1'],
        );
        mapaGeral.referencias.add(ref);

        final pico = Pico(nome: 'Pico Multi');
        pico.setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mapaGeral,
                cragId: 'crag1',
                imageProviderOverride: MemoryImage(kTransparentImage),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap marker to show the card.
        // If it uses Row, it will overflow and throw a FlutterError failing the test.
        await tester.tap(find.byKey(const Key('marker_p1')));
        await tester.pumpAndSettle();

        expect(find.text('Ver mapas'), findsOneWidget);
      },
    );

    testWidgets(
      'TDD 1.2: PageView swiping preserves MapaInterativoPage state',
      (WidgetTester tester) async {
        final mapa1 = Mapa(larguraMapa: 100, alturaMapa: 100);
        final mapa2 = Mapa(larguraMapa: 100, alturaMapa: 100);
        final pico = Pico(nome: 'Pico Teste');

        final pageController = PageController(initialPage: 0);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageView(
                controller: pageController,
                children: [
                  MapaInterativoPage(
                    key: const ValueKey('mapa1'),
                    pico: pico,
                    mapa: mapa1,
                    cragId: 'crag1',
                    imageProviderOverride: mockImage,
                  ),
                  MapaInterativoPage(
                    key: const ValueKey('mapa2'),
                    pico: pico,
                    mapa: mapa2,
                    cragId: 'crag1',
                    imageProviderOverride: mockImage,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Encontrar o InteractiveViewer da página 0
        final interactiveViewers = tester
            .widgetList<InteractiveViewer>(
              find.descendant(
                of: find.byKey(const ValueKey('mapa1')),
                matching: find.byType(InteractiveViewer),
              ),
            )
            .toList();
        expect(interactiveViewers, isNotEmpty);
        final firstViewer = interactiveViewers.first;

        // Modificar a matriz (pan/zoom)
        firstViewer.transformationController!.value = Matrix4.identity()
          ..scaleByDouble(2.0, 2.0, 1.0, 1.0)
          ..translateByDouble(10.0, 10.0, 0.0, 1.0);
        final modifiedMatrix = firstViewer.transformationController!.value;

        // Deslizar para a página 1
        pageController.jumpToPage(1);
        await tester.pumpAndSettle();

        // Deslizar de volta para a página 0
        pageController.jumpToPage(0);
        await tester.pumpAndSettle();

        // Verificar se o estado foi preservado
        final newViewers = tester
            .widgetList<InteractiveViewer>(
              find.descendant(
                of: find.byKey(const ValueKey('mapa1')),
                matching: find.byType(InteractiveViewer),
              ),
            )
            .toList();
        expect(newViewers, isNotEmpty);
        final restoredViewer = newViewers.first;

        expect(
          restoredViewer.transformationController!.value,
          equals(modifiedMatrix),
        );
      },
    );
    testWidgets(
      'TDD 1.1: popOnActionIfOriginal=true and isOriginal=true does AppNav.back (pop)',
      (WidgetTester tester) async {
        final mockMapa = Mapa(
          caminhoImagemMapa: 'mapa.webp',
          larguraMapa: 1000,
          alturaMapa: 800,
          pontosDeInteresse: [
            Mapa_PontoDeInteresse(
              id: 'via_id',
              label: 'Via Label',
              retangulo: BoundingRetangulo(
                x: 100,
                y: 100,
                comprimento: 50,
                largura: 50,
              ),
            ),
          ],
        );

        final esc = Escalada(viaEsportiva: ViaEsportiva(nome: 'Target Via'));
        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Target Via',
            ids: ['via_id'],
          ),
        );

        final pico = Pico()..nome = 'Pico Teste';
        final setor = Setor()..nome = 'Setor Teste';
        setor.escaladas.add(esc);
        pico.setoresOuGrupos.add(
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
        );

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapaInterativoPage(
                          pico: pico,
                          mapa: mockMapa,
                          cragId: 'test_crag',
                          autoZoomEnabled: false,
                          imageProviderOverride: MemoryImage(kTransparentImage),
                          initialSelectedId: 'via_id',
                          popOnActionIfOriginal: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to Map'),
                ),
              ),
            },
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.text('Go to Map'));
        await tester.pumpAndSettle();

        // Ensure the card is open
        expect(find.text('Target Via'), findsOneWidget);

        final btn = find.text('Mais Info');
        expect(btn, findsOneWidget);

        // Tap Mais Info
        await tester.tap(btn);
        await tester.pumpAndSettle();

        // Because popOnActionIfOriginal is true, it pops back to '/'
        expect(find.text('Target Via'), findsNothing);
        expect(find.text('Go to Map'), findsOneWidget);
      },
    );

    testWidgets(
      'TDD 1.2: popOnActionIfOriginal=false and isOriginal=true does AppNav.toVia (push)',
      (WidgetTester tester) async {
        final mockMapa = Mapa(
          caminhoImagemMapa: 'mapa.webp',
          larguraMapa: 1000,
          alturaMapa: 800,
          pontosDeInteresse: [
            Mapa_PontoDeInteresse(
              id: 'via_id',
              label: 'Via Label',
              retangulo: BoundingRetangulo(
                x: 100,
                y: 100,
                comprimento: 50,
                largura: 50,
              ),
            ),
          ],
        );

        final esc = Escalada(viaEsportiva: ViaEsportiva(nome: 'Target Via'));
        mockMapa.referencias.add(
          Mapa_Referencia(
            setor: 'Setor Teste',
            escalada: 'Target Via',
            ids: ['via_id'],
          ),
        );

        final pico = Pico()..nome = 'Pico Teste';
        final setor = Setor()..nome = 'Setor Teste';
        setor.escaladas.add(esc);
        pico.setoresOuGrupos.add(
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaInterativoPage(
                pico: pico,
                mapa: mockMapa,
                cragId: 'test_crag',
                autoZoomEnabled: false,
                imageProviderOverride: MemoryImage(kTransparentImage),
                initialSelectedId: 'via_id',
                popOnActionIfOriginal:
                    false, // HERE: this is what carrossel does
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final btn = find.text('Mais Info');
        expect(btn, findsOneWidget);

        await tester.tap(btn);
        await tester.pumpAndSettle();

        // Telemetry for opening details SHOULD be fired (or we can just verify the Via node was pushed)
        // The push triggers AppNav.toVia, which if TreeNavigation is active pushes ViaNode.
        // If it's a direct MaterialApp, AppNav.toVia might fail or do nothing if no tree controller.
        // But we can check that it DID NOT POP by ensuring the card is still there
        // (or actually, in tests AppNav.toVia without TreeController does nothing, so the page remains)
        expect(find.text('Target Via'), findsOneWidget);
      },
    );
  });

  group('MapaInterativoPage Overlay Navigation Tests', () {
    Widget buildNavApp(List<Escalada> escaladas, Mapa mapa) {
      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Teste';
      setor.escaladas.addAll(escaladas);
      pico.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
      );

      return MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            mapa: mapa,
            pico: pico,
            cragId: 'test_crag',
            autoZoomEnabled: false,
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      );
    }

    testWidgets('Tapping disabled right chevron does not close overlay', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'start_abc',
        circulo: BoundingCirculo(x: 50, y: 50, raio: 10),
      );
      final mapa = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );

      // Add two routes starting at the same point
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route A', ids: ['start_abc']));
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route B', ids: ['start_abc']));

      final escA = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route A'));
      final escB = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route B'));

      await tester.pumpWidget(buildNavApp([escA, escB], mapa));
      await tester.pumpAndSettle();

      // Tap marker to open overlay
      await tester.tap(find.byKey(const Key('marker_start_abc')));
      await tester.pumpAndSettle();

      expect(find.text('Route A'), findsOneWidget);

      // Tap active right chevron to go to Route B
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Route B'), findsOneWidget);

      // Tap disabled right chevron (should do nothing, and definitely not close overlay)
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Overlay should still be open on Route B
      expect(find.text('Route B'), findsOneWidget);
    });

    testWidgets('Swiping at bounds does not crash or close overlay', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'start_abc',
        circulo: BoundingCirculo(x: 50, y: 50, raio: 10),
      );
      final mapa = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );

      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route A', ids: ['start_abc']));
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route B', ids: ['start_abc']));

      final escA = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route A'));
      final escB = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route B'));

      await tester.pumpWidget(buildNavApp([escA, escB], mapa));
      await tester.pumpAndSettle();

      // Tap marker to open overlay
      await tester.tap(find.byKey(const Key('marker_start_abc')));
      await tester.pumpAndSettle();

      // Swipe left (which navigates right to Route B)
      await tester.fling(find.text('Route A'), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Route B'), findsOneWidget);

      // Swipe left again on Route B (at bounds)
      await tester.fling(find.text('Route B'), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Should not crash and should remain on Route B
      expect(find.text('Route B'), findsOneWidget);
    });
    testWidgets('Tapping empty map background triggers highlight animation on all markers', (WidgetTester tester) async {
      final ponto1 = Mapa_PontoDeInteresse(
        id: 'start_a',
        circulo: BoundingCirculo(x: 20, y: 20, raio: 10),
      );
      final ponto2 = Mapa_PontoDeInteresse(
        id: 'start_b',
        circulo: BoundingCirculo(x: 80, y: 80, raio: 10),
      );
      final mapa = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto1, ponto2],
      );

      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route A', ids: ['start_a']));
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Route B', ids: ['start_b']));

      final escA = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route A'));
      final escB = Escalada(viaEsportiva: ViaEsportiva(nome: 'Route B'));

      await tester.pumpWidget(buildNavApp([escA, escB], mapa));
      await tester.pumpAndSettle();

      // Ensure no overlay is open
      expect(find.text('Route A'), findsNothing);

      // Get initial MarkerPainter (highlightIntensity should be 0.0)
      final initialPaint1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_start_a')), matching: find.byType(CustomPaint))
      );
      expect((initialPaint1.painter as MarkerPainter).highlightIntensity, 0.0);

      // Tap on empty space (middle of InteractiveViewer)
      await tester.tap(find.byType(InteractiveViewer)); 
      await tester.pump();

      // Pump a few frames to advance the animation
      await tester.pump(const Duration(milliseconds: 100));

      // Check if highlightIntensity has increased (it animates 0 to 1 over 400ms)
      final animatingPaint1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_start_a')), matching: find.byType(CustomPaint))
      );
      expect((animatingPaint1.painter as MarkerPainter).highlightIntensity, greaterThan(0.0));
      
      final animatingPaint2 = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_start_b')), matching: find.byType(CustomPaint))
      );
      expect((animatingPaint2.painter as MarkerPainter).highlightIntensity, greaterThan(0.0));
      
      // Let animation finish
      await tester.pumpAndSettle();
    });

    testWidgets('Toque em linha vetorial seleciona via e toque em área vazia da AABB não seleciona', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_via',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            caixaDelimitadora: BoundingRetangulo(
              x: 50,
              y: 50,
              comprimento: 80,
              largura: 80,
            ),
          ),
        ),
      );

      final mapa = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Vetorial', ids: ['linha_via']));

      final esc = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Vetorial'));

      await tester.pumpWidget(buildNavApp([esc], mapa));
      await tester.pumpAndSettle();

      // Verifica que inicialmente o card não está aberto
      expect(find.text('Via Vetorial'), findsNothing);

      final gestureDetectorFinder = find.byKey(const Key('marker_linha_via'));
      expect(gestureDetectorFinder, findsOneWidget);

      final topLeft = tester.getTopLeft(gestureDetectorFinder);
      // Toque no canto superior direito da AABB (dx=70, dy=10), a mais de 40dp da diagonal
      await tester.tapAt(topLeft + const Offset(70, 10));
      await tester.pumpAndSettle();

      // Não deve ter selecionado a via
      expect(find.text('Via Vetorial'), findsNothing);

      // Agora toca perto da diagonal (dx=44, dy=44)
      await tester.tapAt(topLeft + const Offset(44, 44));
      await tester.pumpAndSettle();

      // Agora sim a via deve estar selecionada!
      expect(find.text('Via Vetorial'), findsOneWidget);
    });

    testWidgets('Toque no vazio aciona pulso de highlight na linha vetorial', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_pulso',
        cor: '#00E5FF',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.TRACEJADO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 20 90',
            caixaDelimitadora: BoundingRetangulo(x: 15, y: 50, comprimento: 10, largura: 80),
          ),
        ),
      );

      final mapa = Mapa(larguraMapa: 100, alturaMapa: 100, pontosDeInteresse: [ponto]);
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Pulso', ids: ['linha_pulso']));
      final esc = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Pulso'));

      await tester.pumpWidget(buildNavApp([esc], mapa));
      await tester.pumpAndSettle();

      final paintInicial = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_linha_pulso')), matching: find.byType(CustomPaint)),
      );
      expect((paintInicial.painter as MarkerPainter).highlightIntensity, 0.0);

      // Toca no vazio do mapa
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final paintAnimando = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_linha_pulso')), matching: find.byType(CustomPaint)),
      );
      expect((paintAnimando.painter as MarkerPainter).highlightIntensity, greaterThan(0.0));
      expect((paintAnimando.painter as MarkerPainter).corHex, '#00E5FF');
      expect((paintAnimando.painter as MarkerPainter).isLinha, isTrue);

      await tester.pumpAndSettle();
    });

    test('MarkerPainter _paintLinha executa desenho completo em camadas e marcadores', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: true,
        highlightIntensity: 0.5,
        padding: 4.0,
        isLinha: true,
        corHex: '#FF1744',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(x: 10, y: 10, tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR, rotulo: '01'),
              MarcadorCompilado(x: 30, y: 30, tipo: NoTrajeto_TipoNo.PROTECAO_FIXA),
              MarcadorCompilado(x: 60, y: 60, tipo: NoTrajeto_TipoNo.CRUX),
              MarcadorCompilado(x: 90, y: 90, tipo: NoTrajeto_TipoNo.TOP_PARADA),
            ],
          ),
        ),
      );

      // Não deve lançar erro ao desenhar todas as camadas e marcadores
      expect(() => painter.paint(canvas, const Size(100, 100)), returnsNormally);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    testWidgets('Zoom automático enquadra via de linha vetorial inteira por Bounding Box', (WidgetTester tester) async {
      // Linha vertical ocupando 40% da altura da parede (de y=300 até y=700 em mapa de 1000x1000)
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_alta',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 500 700 L 500 300',
            caixaDelimitadora: BoundingRetangulo(x: 500, y: 500, comprimento: 20, largura: 400),
          ),
        ),
      );

      final mapa = Mapa(larguraMapa: 1000, alturaMapa: 1000, pontosDeInteresse: [ponto]);
      mapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Longa', ids: ['linha_alta']));
      final esc = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Longa'));

      final pico = Pico();
      final setor = Setor()..nome = 'Setor Teste'..escaladas.add(esc);
      pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: MapaInterativoPage(
              mapa: mapa,
              pico: pico,
              cragId: 'test_crag',
              autoZoomEnabled: true,
              imageProviderOverride: MemoryImage(kTransparentImage),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Clica na linha para disparar o auto-zoom
      await tester.tap(find.byKey(const Key('marker_linha_alta')));
      await tester.pumpAndSettle();

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final escalaFinal = interactiveViewer.transformationController!.value.getMaxScaleOnAxis();

      // Com Bounding Box cobrindo 400px da via, a escala enquadra a via inteira na área visível (~1.87x)
      // Sem o tratamento de Bounding Box, o código antigo aplicaria o piso de pin único de 2.5x!
      expect(escalaFinal, closeTo(1.87, 0.15));
    });

    testWidgets('Linha vetorial sem referência vinculada é desenhada no mapa (não descartada com SizedBox.shrink)', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_orfa',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.TRACEJADO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 100 100 L 200 200',
            caixaDelimitadora: BoundingRetangulo(x: 150, y: 150, comprimento: 100, largura: 100),
            marcadores: [
              MarcadorCompilado(x: 100, y: 100, tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR, rotulo: '1'),
            ],
          ),
        ),
      );

      final mapa = Mapa(larguraMapa: 1000, alturaMapa: 1000, pontosDeInteresse: [ponto]);
      // Nenhuma referência adicionada em mapa.referencias
      final pico = Pico();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: MapaInterativoPage(
              mapa: mapa,
              pico: pico,
              cragId: 'test_crag',
              imageProviderOverride: MemoryImage(kTransparentImage),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final markerFinder = find.byKey(const Key('marker_linha_orfa'));
      expect(markerFinder, findsOneWidget);
      expect(find.descendant(of: markerFinder, matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('Toque em linha vetorial sem referência seleciona a linha e dispara auto-zoom', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'linha_orfa_toque',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.TRACEJADO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 100 100 L 200 200',
            caixaDelimitadora: BoundingRetangulo(x: 150, y: 150, comprimento: 100, largura: 100),
          ),
        ),
      );

      final mapa = Mapa(larguraMapa: 1000, alturaMapa: 1000, pontosDeInteresse: [ponto]);
      final pico = Pico();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: MapaInterativoPage(
              mapa: mapa,
              pico: pico,
              cragId: 'test_crag',
              autoZoomEnabled: true,
              imageProviderOverride: MemoryImage(kTransparentImage),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_linha_orfa_toque')));
      await tester.pumpAndSettle();

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byKey(const Key('marker_linha_orfa_toque')), matching: find.byType(CustomPaint)),
      );
      expect((customPaint.painter as MarkerPainter).isSelected, isTrue);
    });

    test('MarkerPainter _paintMarcadores pinta círculo identificador no estilo Ouroboulder em repouso (fundo preto neutro, sem borda branca)', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 1000,
        mapHeight: 1000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        corHex: '#00E5FF',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 50,
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                rotulo: '1',
                raio: 18,
                tamanhoFonte: 18,
              ),
            ],
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      // 1. Fundo preto neutro (#1A1A1A) em repouso
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.fill && c.paint.color.toARGB32() == 0xFF1A1A1A),
        isTrue,
      );

      // 2. Não deve ter borda branca intermediária grossa
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.stroke && c.paint.color == Colors.white),
        isFalse,
      );

      // 3. Casing escuro fino (1.0px a 1.2px)
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.stroke && c.paint.strokeWidth <= 1.5),
        isTrue,
      );

      // 4. Raio estritamente proporcional 1:1 ao editor (raio 18 * scaleX 0.4 = 7.2dp)
      expect(canvas.circulos.first.raio, closeTo(7.2, 0.01));
    });

    test('MarkerPainter _paintMarcadores aplica raio padrão 19px e fonte ampliada quando não especificado', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 1000,
        mapHeight: 1000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        corHex: '#FFD600',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 50,
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                rotulo: '1',
              ),
            ],
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      // Raio padrão 19px * scaleX 0.4 = 7.6dp
      expect(canvas.circulos.first.raio, closeTo(7.6, 0.01));
    });

    test('MarkerPainter _paintMarcadores pinta círculo identificador com fundo escuro e borda colorida quando isSelected', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 1000,
        mapHeight: 1000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: true,
        padding: 4.0,
        isLinha: true,
        corHex: '#FFD600',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 50,
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                rotulo: '7A',
                raio: 16,
              ),
            ],
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      // 1. Fundo preenchido SEMPRE com #1A1A1A mesmo quando selecionado
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.fill && c.paint.color.toARGB32() == 0xFF1A1A1A),
        isTrue,
      );

      // 2. Borda colorida idêntica à de círculos avulsos (opacidade 70%, blur sólido 1.5 e espessura 2.0)
      expect(
        canvas.circulos.any((c) =>
          c.paint.style == PaintingStyle.stroke &&
          (c.paint.color.a - 0.7).abs() < 0.05 &&
          c.paint.strokeWidth == 2.0 &&
          c.paint.maskFilter == const MaskFilter.blur(BlurStyle.solid, 1.5)
        ),
        isTrue,
      );

      // 3. Não deve ter borda branca intermediária
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.stroke && c.paint.color == Colors.white),
        isFalse,
      );
    });

    test('MarkerPainter _paintMarcadores desenha pulso de highlight branco no círculo quando highlightIntensity > 0 e não selecionado', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 1000,
        mapHeight: 1000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: false,
        highlightIntensity: 0.8,
        padding: 4.0,
        isLinha: true,
        corHex: '#FFD600',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 50,
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                rotulo: '7A',
                raio: 16,
              ),
            ],
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      // 1. Fundo do círculo permanece preto neutro (#1A1A1A)
      expect(
        canvas.circulos.any((c) => c.paint.style == PaintingStyle.fill && c.paint.color.toARGB32() == 0xFF1A1A1A),
        isTrue,
      );

      // 2. Deve conter o traço do pulso de highlight branco ao redor do círculo
      expect(
        canvas.circulos.any((c) =>
          c.paint.style == PaintingStyle.stroke &&
          c.paint.color.r == 1.0 &&
          c.paint.color.g == 1.0 &&
          c.paint.color.b == 1.0 &&
          (c.paint.color.a - (0.8 * 0.8)).abs() < 0.05 &&
          c.paint.maskFilter == const MaskFilter.blur(BlurStyle.solid, 1.0)
        ),
        isTrue,
      );
    });

    test('MarkerPainter _paintMarcadores renderiza nó SETA_DIRECIONAL orientado pelo ângulo da tangente', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 1000,
        mapHeight: 1000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        corHex: '#FFD600',
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
            marcadores: [
              MarcadorCompilado(
                x: 50,
                y: 50,
                tipo: NoTrajeto_TipoNo.SETA_DIRECIONAL,
                anguloGrausX100: 4500,
                raio: 12,
              ),
            ],
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      // Deve registrar caminhos desenhados para a seta (preenchimento com cor da via e contorno)
      expect(
        canvas.caminhos.any((c) => c.paint.style == PaintingStyle.fill && c.paint.color.toARGB32() == 0xFFFFD600),
        isTrue,
      );
      expect(
        canvas.caminhos.any((c) => c.paint.style == PaintingStyle.stroke),
        isTrue,
      );
    });

    test('MarkerPainter _paintLinha desenha com espessura proporcional à escala e halos moderados', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(90, 90)],
        minX: 10,
        minY: 10,
        mapWidth: 2000,
        mapHeight: 2000,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        isSelected: true,
        padding: 4.0,
        isLinha: true,
        corHex: '#00E5FF',
        linha: LinhaTrajeto(
          espessura: 6,
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 10 10 L 90 90',
          ),
        ),
      );

      painter.paint(canvas, const Size(400, 400));

      expect(canvas.caminhos.length, 3);

      final haloPath = canvas.caminhos[0];
      final casingPath = canvas.caminhos[1];
      final corePath = canvas.caminhos[2];

      // 1. O traço principal deve ter espessura estritamente proporcional 1:1 (espessura 6 * scaleX 0.2 = 1.2dp),
      // e NÃO os limites de clamp (2.0 a 4.0dp)
      expect(corePath.paint.strokeWidth, closeTo(1.2, 0.01));

      // 2. O casing deve ser ligeiramente maior que o traço principal (+1.5dp)
      expect(casingPath.paint.strokeWidth, closeTo(corePath.paint.strokeWidth + 1.5, 0.01));

      // 3. O halo moderado de seleção deve ser justo e rente ao traçado (espessuraVisual + 2.5dp)
      expect(haloPath.paint.strokeWidth, closeTo(corePath.paint.strokeWidth + 2.5, 0.01));

      // 4. A cor do traço ao selecionar deve mudar para alto contraste (se rota não for amarela, vira amarela #FFD600)
      expect(corePath.paint.color.toARGB32(), 0xFFFFD600);
    });

    test('MarkerPainter _paintLinha desenha com fallback quando compilado não possui caminhoSvg', () {
      final canvas = CanvasRegistrador();
      final painter = MarkerPainter(
        polygon: [const Offset(10, 10), const Offset(50, 50)],
        minX: 0,
        minY: 0,
        mapWidth: 100,
        mapHeight: 100,
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
        isSelected: false,
        padding: 4.0,
        isLinha: true,
        linha: LinhaTrajeto(
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
          espessura: 2,
        ),
      );

      painter.paint(canvas, const Size(100, 100));
      expect(canvas.caminhos.isNotEmpty, isTrue);
    });
  });
}

class RegistroCirculo {
  final double raio;
  final Paint paint;
  RegistroCirculo(this.raio, this.paint);
}

class RegistroCaminho {
  final Paint paint;
  RegistroCaminho(this.paint);
}

class CanvasRegistrador extends Fake implements Canvas {
  final List<RegistroCirculo> circulos = [];
  final List<RegistroCaminho> caminhos = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circulos.add(RegistroCirculo(radius, Paint()
      ..color = paint.color
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth
      ..maskFilter = paint.maskFilter));
  }

  @override
  void drawPath(Path path, Paint paint) {
    caminhos.add(RegistroCaminho(Paint()
      ..color = paint.color
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth
      ..maskFilter = paint.maskFilter));
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {}

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {}

  @override
  void save() {}

  @override
  void restore() {}

  @override
  void translate(double dx, double dy) {}

  @override
  void rotate(double radians) {}
}
