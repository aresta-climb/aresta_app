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
  group('MapHelper', () {
    test('resolveMapaAndContext should find map in pico.mapasGerais', () {
      final mapa = Mapa()
        ..caminhoImagemMapa = 'mapas_gerais/mapa.png';

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

    Widget buildApp(List<Escalada> escaladas, Mapa mapa, {bool autoZoom = true}) {
      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Teste';
      setor.escaladas.addAll(escaladas);
      pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor));

      return MaterialApp(
        home: MapaInterativoPage(
          mapa: mapa,
          pico: pico,
          cragId: 'test_crag',
          autoZoomEnabled: autoZoom,
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

    testWidgets('Selecting a marker shows floating card', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste', dificuldade: GrauVia_GrauVia.BR_5));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Teste', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);
      
      final clickEvents = mockTelemetry.recordedEvents.where((e) => e == 'acao_escalada').toList();
      expect(clickEvents.length, 1);
      expect(mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'], 'Via Teste');
    });

    testWidgets('Clicking "Mais Info" on floating card fires logAcaoEscalada telemetry', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste', dificuldade: GrauVia_GrauVia.BR_5));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Teste', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      await tester.tap(find.text('Mais Info'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      expect(mockTelemetry.recordedParams['acao_escalada']!['acao'], 'abrir_detalhes');
    });

    testWidgets('Tapping background de-selects marker', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste'));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Teste', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Via Teste'), findsOneWidget);

      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Toggle auto-zoom button changes state', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp([], mockMapa, autoZoom: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

      await tester.tap(find.byIcon(Icons.gps_fixed));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.gps_not_fixed), findsOneWidget);
    });

    testWidgets('Closing floating card de-selects marker', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Teste'));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Teste', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([esc1], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Via Teste'), findsNothing);
    });

    testWidgets('Handles zero-size map gracefully', (WidgetTester tester) async {
      final smallMapa = Mapa(larguraMapa: 0, alturaMapa: 0);
      await tester.pumpWidget(buildApp([], smallMapa));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('Clicking Mapa Geral triggers telemetry and navigation', (WidgetTester tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final setorSul = Setor()..nome = 'Setor Sul';
      pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorSul));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            cragId: 'test_crag',
            pico: pico,
            mapa: mockMapa,
            setorContext: setorSul,
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
      expect(mockTelemetry.recordedParams['acao_escalada']?['nome_escalada'], 'Geral');
    });

    testWidgets('MapaInterativoPage deve renderizar o botão de feedback (bug_report)', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp([], mockMapa));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('Tapping a grouped marker shows carousel with arrows and swiping/clicking fires telemetry', (WidgetTester tester) async {
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1'));
      final esc2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 2'));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via 1', ids: ['p1']));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via 2', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([esc1, esc2], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Via 1'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Via 2'), findsOneWidget);
    });

    testWidgets('Single point marker with duplicate ids should zoom to 2.5 instead of 5.0', (WidgetTester tester) async {
      final pontoDuplicado = Mapa_PontoDeInteresse(
        id: 'dup_id',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
      );
      final mapaUnico = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [pontoDuplicado],
      );
      mapaUnico.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Dupla', ids: ['dup_id', 'dup_id']));

      final escDuplicada = Escalada(
        boulder: Boulder(nome: 'Dupla'), 
      );
      
      await tester.pumpWidget(buildApp([escDuplicada], mapaUnico));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_dup_id')));
      await tester.pumpAndSettle(); 

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrix = interactiveViewer.transformationController!.value;
      
      expect(matrix.storage[0], closeTo(2.5, 0.01));
    });

    testWidgets('Multiple points without inicio and fim should use bounding box zoom', (WidgetTester tester) async {
      final ponto1 = Mapa_PontoDeInteresse(
        id: 'start_id',
        circular: BoundingCircular(x: 10, y: 10, raio: 5),
      );
      final ponto2 = Mapa_PontoDeInteresse(
        id: 'middle_id',
        circular: BoundingCircular(x: 90, y: 90, raio: 5), // Far apart
      );
      final mapaMulti = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto1, ponto2],
      );
      // ref has inicio and meio, but NO fim (ids[2] is empty/missing)
      mapaMulti.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Boulder Longe', ids: ['start_id', 'middle_id']));

      final escBoulder = Escalada(
        boulder: Boulder(nome: 'Boulder Longe'), 
      );
      
      await tester.pumpWidget(buildApp([escBoulder], mapaMulti));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_start_id')));
      await tester.pumpAndSettle(); 

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrix = interactiveViewer.transformationController!.value;
      
      // Because they are far apart (from 10 to 90 out of 100), boxWidthRel = 0.8
      // The bounding box logic will compute a scale based on available space, which is typically around 1.0 - 1.5, not 2.5
      expect(matrix.storage[0], lessThan(2.5));
    });
    testWidgets('Base card layout uses Wrap to prevent overflow with long titles', (WidgetTester tester) async {
      final escLong = Escalada(viaEsportiva: ViaEsportiva(nome: 'A very very very very very very very very very long via name', dificuldade: GrauVia_GrauVia.BR_5));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'A very very very very very very very very very long via name', ids: ['p1']));
      
      await tester.pumpWidget(buildApp([escLong], mockMapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();

      // Ensure that the card rendered and contains a Wrap widget (which replaced the Row)
      // to handle the overflow gracefully.
      expect(find.textContaining('A very very very'), findsOneWidget);
      expect(find.byType(Wrap), findsWidgets);
    });
  });

}

