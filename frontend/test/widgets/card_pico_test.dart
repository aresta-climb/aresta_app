import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/widgets/card_pico.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  _MockPathProvider(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    EditorDeCroqui();
    tempDir = await Directory.systemTemp.createTemp('card_pico_test_');
    PathProviderPlatform.instance = _MockPathProvider(tempDir.path);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });
  Widget buildTestCard({
    required MetadadosIndice crag,
    String? distanceStr,
    bool showDetailedStats = false,
    bool isDownloaded = false,
    VoidCallback? onDownload,
    VoidCallback? onOpen,
  }) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: [AppColors.dark],
        ),
        child: Scaffold(
          body: CragCard.deMetadados(
            metadados: crag,
            distanceStr: distanceStr,
            showDetailedStats: showDetailedStats,
            isDownloaded: isDownloaded,
            downloadingCrags: ValueNotifier(const {}),
            onDownload: onDownload ?? () {},
            onOpen: onOpen,
          ),
        ),
      ),
    );
  }

  group('CragCard', () {
    testWidgets('renderiza informações e estatísticas diretamente a partir de MetadadosIndice', (
      WidgetTester tester,
    ) async {
      final metadados = MetadadosIndice(
        id: 'pico_proto',
        nome: 'Pico Protobuf',
        descricao: 'Serra da Piedade',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 4,
          totalEscaladas: 30,
          totalBoulders: 10,
          totalEsportivas: 20,
        ),
      );

      await tester.pumpWidget(buildTestCard(
        crag: metadados,
        showDetailedStats: true,
        isDownloaded: true,
      ));

      expect(find.text('PICO PROTOBUF'), findsOneWidget);
      expect(find.textContaining('4 setores • 30 escaladas'), findsOneWidget);
      expect(find.textContaining('10 boulders, 20 esportivas'), findsOneWidget);
      expect(find.text('SALVO OFFLINE'), findsOneWidget);
    });

    testWidgets('renderiza informações básicas e estatísticas resumidas', (
      WidgetTester tester,
    ) async {
      final crag = MetadadosIndice(
        id: 'pico_alpha',
        nome: 'Pico Alpha',
        descricao: 'Serra do Cipó',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 3,
          totalEscaladas: 12,
        ),
      );

      await tester.pumpWidget(buildTestCard(crag: crag));

      expect(find.text('PICO ALPHA'), findsOneWidget);
      expect(find.text('3 setores • 12 escaladas'), findsOneWidget);
    });

    testWidgets('exibe modalidades detalhadas quando showDetailedStats for true', (
      WidgetTester tester,
    ) async {
      final crag = MetadadosIndice(
        id: 'pico_beta',
        nome: 'Pico Beta',
        descricao: 'Ubatuba',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 2,
          totalEscaladas: 8,
          totalBoulders: 5,
          totalEsportivas: 3,
        ),
      );

      await tester.pumpWidget(
        buildTestCard(crag: crag, showDetailedStats: true),
      );

      expect(find.textContaining('5 boulders, 3 esportivas'), findsOneWidget);
    });

    testWidgets('exibe badge de distância quando fornecido', (
      WidgetTester tester,
    ) async {
      final crag = MetadadosIndice(
        id: 'pico_gamma',
        nome: 'Pico Gamma',
        descricao: 'Itatiaia',
      );

      await tester.pumpWidget(
        buildTestCard(crag: crag, distanceStr: '15.4 km'),
      );

      expect(find.text('15.4 km'), findsOneWidget);
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('exibe badge de salvo offline quando isDownloaded for true', (
      WidgetTester tester,
    ) async {
      final crag = MetadadosIndice(
        id: 'pico_delta',
        nome: 'Pico Delta',
        descricao: 'Andorinhas',
      );

      await tester.pumpWidget(buildTestCard(crag: crag, isDownloaded: true));

      expect(find.text('SALVO OFFLINE'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('chama onOpen quando tocado e callback fornecido', (
      WidgetTester tester,
    ) async {
      bool abriu = false;
      final crag = MetadadosIndice(
        id: 'pico_omega',
        nome: 'Pico Omega',
        descricao: 'Pedra Bela',
      );

      await tester.pumpWidget(
        buildTestCard(
          crag: crag,
          onOpen: () => abriu = true,
        ),
      );

      await tester.tap(find.byType(CragCard));
      expect(abriu, isTrue);
    });

    testWidgets('repassa checksumSha256Thumbnail de MetadadosIndice para o widget de fundo', (
      WidgetTester tester,
    ) async {
      final metadados = MetadadosIndice(
        id: 'pico_proto_thumb',
        nome: 'Pico Protobuf',
        checksumSha256Thumbnail: 'hash_thumb_123',
      );

      await tester.pumpWidget(buildTestCard(crag: metadados));

      final bgFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CragBackgroundWidget',
      );
      expect(bgFinder, findsOneWidget);
      final dynamic bgWidget = tester.widget(bgFinder);
      expect(bgWidget.cragId, equals('pico_proto_thumb'));
      expect(bgWidget.checksumSha256, equals('hash_thumb_123'));
    });

    testWidgets('buildCragBackground aceita capaPath e checksumSha256 opcionais', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragBackground(
              'thumbnails/pico_teste.webp',
              cragId: 'pico_teste',
              capaPath: '/downloads/pico_teste/capa.webp',
              checksumSha256: 'sha256_teste',
            ),
          ),
        ),
      );

      final bgFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CragBackgroundWidget',
      );
      expect(bgFinder, findsOneWidget);
      final dynamic bgWidget = tester.widget(bgFinder);
      expect(bgWidget.capaPath, equals('/downloads/pico_teste/capa.webp'));
      expect(bgWidget.checksumSha256, equals('sha256_teste'));
    });

    testWidgets('opera como Dumb Component recebendo diretamente CardCroquiViewModel', (
      WidgetTester tester,
    ) async {
      const viewModel = CardCroquiViewModel(
        id: 'pico_dumb',
        titulo: 'PICO PASSIVO',
        localizacao: 'SERRA DO CIPÓ',
        textoEstatisticas: '5 setores • 40 escaladas',
        caminhoMiniatura: 'thumbnails/pico_dumb.webp',
        salvoOffline: true,
        textoDistancia: '500m',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AppColors.dark]),
            child: Scaffold(
              body: CragCard(
                dados: viewModel,
                downloadingCrags: ValueNotifier(const {}),
                onDownload: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('PICO PASSIVO'), findsOneWidget);
      expect(find.text('5 setores • 40 escaladas'), findsOneWidget);
      expect(find.text('SALVO OFFLINE'), findsOneWidget);
      expect(find.text('500m'), findsOneWidget);
    });

    testWidgets(
      'exibe logo_in_app.jpg sobre fundo Colors.black sem padding quando croqui não possui thumbnail nem capa no Protobuf',
      (WidgetTester tester) async {
        final cragSemThumb = MetadadosIndice(
          id: 'pico_sem_thumb_card',
          nome: 'Pico Sem Thumbnail',
          descricao: 'Betim',
        );

        await tester.pumpWidget(buildTestCard(crag: cragSemThumb));
        await tester.pump();

        expect(find.byIcon(Icons.terrain), findsNothing);
        expect(find.byIcon(Icons.broken_image), findsNothing);

        final logoFinder = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/logo_in_app.jpg' &&
              w.fit == BoxFit.contain,
        );
        expect(logoFinder, findsOneWidget);

        // Verifica que o container de fundo é preto puro cobrindo a área e sem Padding
        final containerFinder = find.ancestor(
          of: logoFinder,
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color == Colors.black,
          ),
        );
        expect(containerFinder, findsOneWidget);
        expect(find.descendant(of: containerFinder, matching: find.byType(Padding)), findsNothing);
      },
    );

    testWidgets(
      'exibe Icons.broken_image e não exibe logo_in_app.jpg quando croqui tem thumbnail declarada no Protobuf mas imagem não está disponível',
      (WidgetTester tester) async {
        final cragComThumbIndisponivel = MetadadosIndice(
          id: 'pico_com_thumb_indisponivel',
          nome: 'Pico Com Thumbnail Indisponível',
          descricao: 'Diamantina',
          checksumSha256Thumbnail: 'hash_inexistente',
        );

        await tester.pumpWidget(buildTestCard(crag: cragComThumbIndisponivel));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.broken_image), findsOneWidget);
        final Icon brokenIcon = tester.widget(find.byIcon(Icons.broken_image));
        expect(brokenIcon.color, equals(Colors.grey));
        expect(brokenIcon.size, equals(50));

        final logoFinder = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/logo_in_app.jpg',
        );
        expect(logoFinder, findsNothing);
      },
    );

    testWidgets(
      'exibe fundo neutro durante ConnectionState.waiting sem exibir logo do Aresta nem ícone de erro prematuramente',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: buildCragBackground('thumbnails/pico_aguardando.webp', cragId: 'pico_aguardando'),
            ),
          ),
        );

        // Apenas o primeiro frame antes de resolver o Future
        await tester.pump();

        expect(find.byIcon(Icons.broken_image), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == 'assets/logo_in_app.jpg',
          ),
          findsNothing,
        );
      },
    );
  });
}

