import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'dart:typed_data';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
  @override
  Future<String?> getApplicationSupportPath() async => '.';
  @override
  Future<String?> getLibraryPath() async => '.';
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getExternalStoragePath() async => '.';
  @override
  Future<List<String>?> getExternalCachePaths() async => [];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [];
  @override
  Future<String?> getDownloadsPath() async => '.';
}

void main() {
  group('AreaHelper Tests', () {
    test('Circular Area', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '1',
        circular: BoundingCircular(x: 100, y: 100, raio: 50),
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
        box: BoundingBox(x: 100, y: 100, comprimento: 60, largura: 40, anguloGrausX100: 0),
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
        box: BoundingBox(x: 100, y: 100, comprimento: 60, largura: 40, anguloGrausX100: 9000),
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
        areaLivre: BoundingAreaLivre(coordenadas: [0, 0, 10, 0, 10, 10, 0, 10]),
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
        areaLivre: BoundingAreaLivre(coordenadas: [0, 0, 1, 1]),
      );

      final areaInfo = AreaHelper.getAreaInfo(ponto);
      expect(areaInfo, isNotNull);
      expect(areaInfo!.bounds, Rect.fromLTRB(0, 0, 1, 1));
      expect(areaInfo.polygon.length, 2);
    });

    test('Box Area - Large Angle', () {
      final ponto = Mapa_PontoDeInteresse(
        id: '6',
        box: BoundingBox(x: 100, y: 100, comprimento: 60, largura: 40, anguloGrausX100: 36000),
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
  });

  group('MapHelper Tests', () {
    test('getEscaladaIdsNoMapa returns correct IDs for all types', () {
      final esportiva = Escalada(
        viaEsportiva: ViaEsportiva(idNoMapa: 'e1', idNoMapaMeio: 'e1m', idNoMapaFim: 'e1f'),
      );
      expect(MapHelper.getEscaladaIdsNoMapa(esportiva), ['e1', 'e1m', 'e1f']);

      final movel = Escalada(
        viaMovel: ViaMovel(idNoMapa: 'm1', idNoMapaMeio: 'm1m', idNoMapaFim: 'm1f'),
      );
      expect(MapHelper.getEscaladaIdsNoMapa(movel), ['m1', 'm1m', 'm1f']);

      final boulder = Escalada(
        boulder: Boulder(idNoMapa: 'b1', idNoMapaMeio: 'b1m', idNoMapaFim: 'b1f'),
      );
      expect(MapHelper.getEscaladaIdsNoMapa(boulder), ['b1', 'b1m', 'b1f']);

      final multi = Escalada(
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(idNoMapa: 'mu1', idNoMapaMeio: 'mu1m', idNoMapaFim: 'mu1f'),
      );
      expect(MapHelper.getEscaladaIdsNoMapa(multi), ['mu1', 'mu1m', 'mu1f']);

      final highline = Escalada(
        highline: Highline(idNoMapa: 'h1', idNoMapaMeio: 'h1m', idNoMapaFim: 'h1f'),
      );
      expect(MapHelper.getEscaladaIdsNoMapa(highline), ['h1', 'h1m', 'h1f']);
    });

    test('buildIdMap correctly maps escaladas and setores', () {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'esc1', nome: 'Esc 1'));
      final setor1 = ArquivoSetor(
        conteudo: Setor(
          idNoMapa: 'set1',
          nome: 'Setor 1',
          escaladas: [
            Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'esc2', nome: 'Esc 2')),
          ],
        ),
      );

      final idMap = MapHelper.buildIdMap(
        escaladas: [esc1],
        setores: [setor1],
      );

      expect(idMap['esc1'], esc1);
      expect(idMap['set1'], setor1.conteudo);
      expect(idMap['esc2'], setor1.conteudo.escaladas[0]);
    });

    test('buildIdMap handles duplicates by removing them', () {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'dup', nome: 'Esc 1'));
      final esc2 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'dup', nome: 'Esc 2'));

      final idMap = MapHelper.buildIdMap(
        escaladas: [esc1, esc2],
        setores: [],
      );

      expect(idMap.containsKey('dup'), isFalse);
    });
  });

  group('MapaInterativoPage Widget Tests', () {
    late Mapa mockMapa;
    late MemoryImage mockImage;
    late MockTelemetryService mockTelemetry;

    setUpAll(() {
      PathProviderPlatform.instance = MockPathProviderPlatform();
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
            box: BoundingBox(x: 100, y: 100, comprimento: 50, largura: 50),
          ),
          Mapa_PontoDeInteresse(
            id: 'p2',
            label: 'Ponto 2',
            circular: BoundingCircular(x: 500, y: 400, raio: 30),
          ),
        ],
      );
    });

    testWidgets('Renders markers correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            autoZoomEnabled: true,
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find InteractiveViewer
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Should find CustomPaint markers (GestureDetectors inside Positioned)
      // We have 2 points of interest
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    });

    testWidgets('Selecting a marker shows floating card', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'p1', nome: 'Via Teste', dificuldade: GrauVia_GrauVia.BR_5));
      
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            escaladas: [esc1],
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the first marker
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      // Floating card should be visible with the via name
      expect(find.text('Via Teste'), findsOneWidget);
      expect(find.textContaining('5º'), findsOneWidget); // formatGrade logic
      
      // Verify telemetry
      final clickEvents = mockTelemetry.recordedEvents.where((e) => e == 'acao_escalada').toList();
      expect(clickEvents.length, 1, reason: 'Deve logar o clique apenas 1 vez (evitando duplicidade com o auto-zoom)');
      expect(mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'], 'Via Teste');
      expect(mockTelemetry.recordedParams['acao_escalada']!['acao'], 'selecionar_no_mapa');
    });

    testWidgets('Clicking "Mais" on floating card fires logAcaoEscalada telemetry', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'p1', nome: 'Via Teste', dificuldade: GrauVia_GrauVia.BR_5));
      
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            escaladas: [esc1],
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the marker
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      // Tap on the "Mais" button
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      // Verify telemetry
      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      expect(mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'], 'Via Teste');
      expect(mockTelemetry.recordedParams['acao_escalada']!['acao'], 'abrir_detalhes');
      expect(mockTelemetry.recordedParams['acao_escalada']!['origem'], 'mapa');
    });

    testWidgets('Tapping background de-selects marker', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'p1', nome: 'Via Teste'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            escaladas: [esc1],
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select marker
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Via Teste'), findsOneWidget);

      // Tap background far away from marker
      await tester.tapAt(const Offset(400, 400));
      await tester.pumpAndSettle();

      // Card should disappear
      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Toggle auto-zoom button changes state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            autoZoomEnabled: true,
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially enabled (gps_fixed icon)
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.gps_fixed));
      await tester.pumpAndSettle();

      // Now disabled (gps_not_fixed icon)
      expect(find.byIcon(Icons.gps_not_fixed), findsOneWidget);
    });

    testWidgets('Closing floating card de-selects marker', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(idNoMapa: 'p1', nome: 'Via Teste'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: mockMapa,
            cragId: 'test_crag',
            escaladas: [esc1],
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select marker
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      // Tap close button on card
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Handles zero-size map gracefully', (WidgetTester tester) async {
      final smallMapa = Mapa(larguraMapa: 0, alturaMapa: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: MapaInterativoPage(
            mapa: smallMapa,
            cragId: 'test_crag',
            imageProviderOverride: mockImage,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('Clicking Mapa Geral triggers telemetry and navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            cragId: 'test_crag',
            mapa: mockMapa,
            escaladas: const [],
            setores: const [],
            setorContext: Setor()..nome = 'Setor Sul',
            imageProviderOverride: mockImage,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final btn = find.text('Mapa Geral');
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      final lastEvent = mockTelemetry.recordedParams['acao_escalada'];
      expect(lastEvent?['id_croqui'], 'test_crag');
      expect(lastEvent?['nome_setor'], 'Setor Sul');
      expect(lastEvent?['nome_escalada'], 'Geral');
      expect(lastEvent?['acao'], 'abrir_mapa_geral');
      expect(lastEvent?['origem'], 'mapa_setor');
    });
  });
}
