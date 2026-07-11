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

  group('MarkerPainter hitTest Tests', () {
    test('hitTest detects point inside and outside unrotated rectangle', () {
      final polygon = [
        const Offset(70, 80),
        const Offset(130, 80),
        const Offset(130, 120),
        const Offset(70, 120)
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
      // Outside point
      expect(painter.hitTest(const Offset(10, 14)), isFalse);
    });

    test('hitTest correctly excludes corners of AABB for rotated rectangle', () {
      // Rotate 60x40 box by 45 degrees.
      // We will just create a diamond polygon for simplicity to test the hitTest logic.
      final polygon = [
        const Offset(100, 50),
        const Offset(150, 100),
        const Offset(100, 150),
        const Offset(50, 100)
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
      final polygon = [
        const Offset(50, 100),
        const Offset(150, 100),
      ];
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
  });

  group('MapaInterativoPage Widget Tests', () {
    late Mapa mockMapa;
    late MemoryImage mockImage;
    late MockTelemetryService mockTelemetry;

    setUpAll(() {
      EditorDeCroqui(); // Instancia o singleton
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

    Widget buildApp(List<Escalada> escaladas, Mapa mapa, {bool autoZoom = true, bool hideAppBar = false}) {
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

    testWidgets('Renders AppBar when hideAppBar is false', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp([], mockMapa, hideAppBar: false));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Croqui Interativo'), findsOneWidget);
    });

    testWidgets('Does not render AppBar when hideAppBar is true', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp([], mockMapa, hideAppBar: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Croqui Interativo'), findsNothing);
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

    testWidgets('3.1: Ausência do botão "Subir" em mapas sem nível superior', (WidgetTester tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      // Pico não tem mapas gerais, setor não tem grupo
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            cragId: 'test_crag',
            pico: pico,
            mapa: mockMapa,
            setorContext: Setor()..nome = 'Setor Sul',
            imageProviderOverride: mockImage,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final btn = find.byIcon(Icons.turn_left_outlined); // assuming we use this icon for up
      final btnFallback = find.byType(ActionChip);
      
      expect(btn, findsNothing);
      expect(btnFallback, findsNothing);
    });

    testWidgets('3.2: Nomes muito grandes ficam truncados com ellipsis', (WidgetTester tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()..nome = 'Grupo com um nome absurdamente gigante para testar o truncamento de texto na interface';
      grupo.mapas.add(Mapa()..caminhoImagemMapa = 'grupo.png');
      pico.setoresOuGrupos.add(SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupo));

      await tester.pumpWidget(MaterialApp(
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
      ));

      await tester.pumpAndSettle();

      final chipFinder = find.byType(ActionChip);
      expect(chipFinder, findsOneWidget);
      
      // Ensure there's a ConstrainedBox restricting its width
      final constrainedBoxFinder = find.ancestor(
        of: chipFinder,
        matching: find.byType(ConstrainedBox),
      ).first;
      expect(constrainedBoxFinder, findsOneWidget);
      
      final ConstrainedBox constrainedBox = tester.widget(constrainedBoxFinder);
      expect(constrainedBox.constraints.maxWidth, isNotNull);
    });

    testWidgets('3.3: Clique no botão empurra a página esperada na pilha', (WidgetTester tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';
      grupo.mapas.add(Mapa()..caminhoImagemMapa = 'grupo.png');

      await tester.pumpWidget(MaterialApp(
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
      ));

      await tester.pumpAndSettle();
      

      final btn = find.text('Grupo Teste'); // Assumed label
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();
      
      // Telemetry should be fired
      expect(mockTelemetry.recordedEvents, contains('navegacao_hierarquica_mapa'));
    });

    testWidgets('Initial selected id with escaladaContext opens carousel at correct index', (WidgetTester tester) async {
      final mockMapa = Mapa(
        caminhoImagemMapa: 'mapa.webp',
        larguraMapa: 1000,
        alturaMapa: 800,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            id: 'shared_id',
            label: 'Shared Marker',
            box: BoundingBox(x: 100, y: 100, comprimento: 50, largura: 50),
          ),
        ],
      );

      final escWrong = Escalada(viaEsportiva: ViaEsportiva(nome: 'Wrong Via', dificuldade: GrauVia_GrauVia.BR_5));
      final escTarget = Escalada(boulder: Boulder(nome: 'Target Via'));

      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Wrong Via', ids: ['shared_id']));
      mockMapa.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Target Via', ids: ['shared_id']));

      final pico = Pico()..nome = 'Pico Teste';
      final setor = Setor()..nome = 'Setor Teste';
      setor.escaladas.addAll([escWrong, escTarget]);
      pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor));

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

    testWidgets('Multiple points very close should be capped at reasonable maximum zoom', (WidgetTester tester) async {
      final ponto1 = Mapa_PontoDeInteresse(
        id: 'start_id',
        circular: BoundingCircular(x: 10, y: 10, raio: 5),
      );
      final ponto2 = Mapa_PontoDeInteresse(
        id: 'middle_id',
        circular: BoundingCircular(x: 11, y: 11, raio: 5), // Very close
      );
      final mapaClose = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto1, ponto2],
      );
      mapaClose.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Boulder Perto', ids: ['start_id', 'middle_id']));

      final escBoulder = Escalada(
        boulder: Boulder(nome: 'Boulder Perto'), 
      );
      
      await tester.pumpWidget(buildApp([escBoulder], mapaClose));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_start_id')));
      await tester.pumpAndSettle(); 

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrix = interactiveViewer.transformationController!.value;
      
      // Without capping, the zoom would be close to 5.0. It should be capped at 2.5
      expect(matrix.storage[0], closeTo(2.5, 0.01));
    });

    testWidgets('Custom camera zoom in reference should override calculated zoom', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'p1',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
      );
      final mapa = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );
      
      mapa.referencias.add(Mapa_Referencia(
        setor: 'Setor Teste', 
        escalada: 'Via Custom', 
        ids: ['p1'],
        ajusteDeCamera: Mapa_AjusteDeCamera(zoom: 4.0),
      ));

      final esc = Escalada(
        boulder: Boulder(nome: 'Via Custom'), 
      );
      
      await tester.pumpWidget(buildApp([esc], mapa));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle(); 

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final matrix = interactiveViewer.transformationController!.value;
      
      // Should exactly match the custom zoom from reference
      expect(matrix.storage[0], closeTo(4.0, 0.01));
    });

    testWidgets('didUpdateWidget in experimental mode successfully re-resolves references for hot reload', (WidgetTester tester) async {
      EditorDeCroqui.instance.isExperimentalMode.value = true;
      
      Mapa testMapa = mockMapa;
      final esc1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Inicial', dificuldade: GrauVia_GrauVia.BR_5));
      
      await tester.pumpWidget(buildApp([esc1], testMapa));
      await tester.pumpAndSettle();

      // O marker p1 está no dataset original de pontos de interesse, mas como ele não tem 
      // uma referência apontando para ele, ele NÃO deve ser renderizado na UI
      expect(find.byKey(const Key('marker_p1')), findsNothing);

      // Simulando o hot-reload: O dataset foi atualizado!
      final newMapaObj = Mapa.fromBuffer(testMapa.writeToBuffer());
      newMapaObj.referencias.add(Mapa_Referencia(setor: 'Setor Teste', escalada: 'Via Inicial', ids: ['p1']));
      
      // Pump widget again with the new map object to trigger didUpdateWidget
      await tester.pumpWidget(buildApp([esc1], newMapaObj));
      await tester.pumpAndSettle();

      // Clicar no p1 de novo deve encontrar a via e abrir o card!
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Via Inicial'), findsOneWidget);
      
      EditorDeCroqui.instance.isExperimentalMode.value = false;
    });

    testWidgets('Tapping on a marker with multiple maps displays "Ver nos mapas (N)" button', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'p1',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
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
        viaEsportiva: ViaEsportiva(nome: 'Via Dupla', dificuldade: GrauVia_GrauVia.BR_5), 
      );
      
      final pico = Pico(nome: 'Pico Multi');
      final setor = Setor(nome: 'Setor Teste', mapas: [mapa1, mapa2], escaladas: [esc]);
      pico.setoresOuGrupos.add(SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            pico: pico,
            mapa: mapa1,
            cragId: 'crag1',
            setorContext: setor,
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle(); 

      expect(find.text('Ver nos mapas (2)'), findsOneWidget);
    });

    testWidgets('Setor Card with multiple maps displays "Ver Mapas do Setor (2)" and uses carousel', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'p1',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
      );
      final mapaGeral = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );
      
      final mapaSetor1 = Mapa(caminhoImagemMapa: 's1.webp');
      final mapaSetor2 = Mapa(caminhoImagemMapa: 's2.webp');
      
      final setor = Setor(nome: 'Setor Teste', mapas: [mapaSetor1, mapaSetor2]);
      
      final ref = Mapa_Referencia(
        setor: 'Setor Teste', 
        ids: ['p1'],
      );
      mapaGeral.referencias.add(ref);

      final pico = Pico(nome: 'Pico Multi');
      pico.setoresOuGrupos.add(SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            pico: pico,
            mapa: mapaGeral,
            cragId: 'crag1',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle(); 

      expect(find.text('Ver mapas (2)'), findsOneWidget);
    });

    testWidgets('Grupo Card with multiple maps displays "Ver mapas (2)" and uses carousel', (WidgetTester tester) async {
      final ponto = Mapa_PontoDeInteresse(
        id: 'p1',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
      );
      final mapaGeral = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
        pontosDeInteresse: [ponto],
      );
      
      final mapaGrupo1 = Mapa(caminhoImagemMapa: 'g1.webp');
      final mapaGrupo2 = Mapa(caminhoImagemMapa: 'g2.webp');
      
      final grupo = Grupo(nome: 'Grupo Teste', mapas: [mapaGrupo1, mapaGrupo2]);
      
      final ref = Mapa_Referencia(
        grupo: 'Grupo Teste', 
        ids: ['p1'],
      );
      mapaGeral.referencias.add(ref);

      final pico = Pico(nome: 'Pico Multi');
      pico.setoresOuGrupos.add(SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            pico: pico,
            mapa: mapaGeral,
            cragId: 'crag1',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle(); 

      expect(find.text('Ver mapas (2)'), findsOneWidget);
    });

    testWidgets('Base card action buttons use Wrap to prevent overflow on narrow screens', (WidgetTester tester) async {
      // Set a very narrow screen size to force wrapping
      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      final ponto = Mapa_PontoDeInteresse(
        id: 'p1',
        circular: BoundingCircular(x: 50, y: 50, raio: 5),
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
      
      final setor = Setor(nome: 'Setor Com Um Nome Incrivelmente Grande e Complexo', mapas: [mapaSetor1, mapaSetor2, mapaSetor3, mapaSetor4, mapaSetor5]);
      
      final ref = Mapa_Referencia(
        setor: 'Setor Com Um Nome Incrivelmente Grande e Complexo', 
        ids: ['p1'],
      );
      mapaGeral.referencias.add(ref);

      final pico = Pico(nome: 'Pico Multi');
      pico.setoresOuGrupos.add(SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapaInterativoPage(
            pico: pico,
            mapa: mapaGeral,
            cragId: 'crag1',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap marker to show the card. 
      // If it uses Row, it will overflow and throw a FlutterError failing the test.
      await tester.tap(find.byKey(const Key('marker_p1')));
      await tester.pumpAndSettle(); 

      expect(find.text('Ver mapas (5)'), findsOneWidget);
    });

    testWidgets('TDD 1.2: PageView swiping preserves MapaInterativoPage state', (WidgetTester tester) async {
      final mapa1 = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
      );
      final mapa2 = Mapa(
        larguraMapa: 100,
        alturaMapa: 100,
      );
      final pico = Pico(nome: 'Pico Teste');

      final pageController = PageController(initialPage: 0);
      await tester.pumpWidget(MaterialApp(
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
      ));

      await tester.pumpAndSettle();

      // Encontrar o InteractiveViewer da página 0
      final interactiveViewers = tester.widgetList<InteractiveViewer>(find.descendant(of: find.byKey(const ValueKey('mapa1')), matching: find.byType(InteractiveViewer))).toList();
      expect(interactiveViewers, isNotEmpty);
      final firstViewer = interactiveViewers.first;
      
      // Modificar a matriz (pan/zoom)
      firstViewer.transformationController!.value = Matrix4.identity()..scale(2.0)..translate(10.0, 10.0);
      final modifiedMatrix = firstViewer.transformationController!.value;

      // Deslizar para a página 1
      pageController.jumpToPage(1);
      await tester.pumpAndSettle();

      // Deslizar de volta para a página 0
      pageController.jumpToPage(0);
      await tester.pumpAndSettle();

      // Verificar se o estado foi preservado
      final newViewers = tester.widgetList<InteractiveViewer>(find.descendant(of: find.byKey(const ValueKey('mapa1')), matching: find.byType(InteractiveViewer))).toList();
      expect(newViewers, isNotEmpty);
      final restoredViewer = newViewers.first;
      
      expect(restoredViewer.transformationController!.value, equals(modifiedMatrix));
    });
  });

}

