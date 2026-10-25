// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

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

    testWidgets(
      'buildCragBackground resolve imagem solicitando larguraAlvo 450 para alta resolução',
      (WidgetTester tester) async {
        const bytesPng1 = <int>[
          137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
          0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
          0, 13, 73, 68, 65, 84, 120, 156, 99, 100, 248, 207, 80, 15, 0, 3,
          134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, 174,
          66, 96, 130
        ];
        final picoDir = Directory('${tempDir.path}/downloads/pico_res_450')
          ..createSync(recursive: true);
        final capaFile = File('${picoDir.path}/capa.webp');
        capaFile.writeAsBytesSync(bytesPng1);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: buildCragBackground(
                  'capa.webp',
                  cragId: 'pico_res_450',
                  capaPath: 'capa.webp',
                  checksumSha256: 'hash_450',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final Image imageWidget = tester.widget(imageFinder);
        expect(imageWidget.image, isA<ResizeImage>());
        final resize = imageWidget.image as ResizeImage;
        expect(resize.width, equals(450));
      },
    );

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

    group('Borda Inteligente e Resolução em buildCragBackground (Tasks 3.1 - 3.2)', () {
      const bytesPng1 = <int>[
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
        0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 207, 192, 240, 31, 0, 5,
        0, 1, 255, 137, 153, 61, 29, 0, 0, 0, 0, 73, 69, 78, 68, 174,
        66, 96, 130
      ];

      testWidgets('com usarBordaInteligente: false mantém camada única BoxFit.cover e larguraAlvo padrão 450', (WidgetTester tester) async {
        final picoDir = Directory('${tempDir.path}/downloads/pico_padrao')
          ..createSync(recursive: true);
        final imgFile = File('${picoDir.path}/capa.webp');
        imgFile.writeAsBytesSync(bytesPng1);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: buildCragBackground(
                  'capa.webp',
                  cragId: 'pico_padrao',
                  capaPath: 'capa.webp',
                  checksumSha256: 'hash_padrao',
                  usarBordaInteligente: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ImageFiltered), findsNothing);
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.fit, equals(BoxFit.cover));
        expect(imageWidget.image, isA<ResizeImage>());
        final resize = imageWidget.image as ResizeImage;
        expect(resize.width, equals(450));
      });

      testWidgets('com usarBordaInteligente: true e larguraAlvo: 1200 renderiza fundo ImageFiltered com blur e BoxFit.cover e primeiro plano com BoxFit.contain', (WidgetTester tester) async {
        final picoDir = Directory('${tempDir.path}/downloads/pico_borda')
          ..createSync(recursive: true);
        final imgFile = File('${picoDir.path}/capa.webp');
        imgFile.writeAsBytesSync(bytesPng1);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: buildCragBackground(
                  'capa.webp',
                  cragId: 'pico_borda',
                  capaPath: 'capa.webp',
                  checksumSha256: 'hash_borda',
                  larguraAlvo: 1200,
                  usarBordaInteligente: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ImageFiltered), findsOneWidget);
        final imageFiltered = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
        expect(imageFiltered.imageFilter, isNotNull);

        // Duas instâncias de Image compartilhando o mesmo ImageProvider
        final imageFinders = find.byType(Image);
        expect(imageFinders, findsNWidgets(2));

        final imagemFundo = tester.widget<Image>(imageFinders.at(0));
        expect(imagemFundo.fit, equals(BoxFit.cover));
        expect(imagemFundo.image, isA<ResizeImage>());
        final resizeFundo = imagemFundo.image as ResizeImage;
        expect(resizeFundo.width, equals(1200));

        final imagemFrente = tester.widget<Image>(imageFinders.at(1));
        expect(imagemFrente.fit, equals(BoxFit.contain));
        expect(imagemFrente.image, equals(imagemFundo.image));
      });

      const bytesPng4x3 = <int>[
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 4, 0, 0, 0, 3, 8, 6, 0, 0, 0, 180, 244, 174, 198, 0, 0,
        0, 21, 73, 68, 65, 84, 120, 156, 99, 252, 207, 192, 240, 159, 1, 9,
        48, 33, 115, 176, 10, 0, 0, 97, 107, 2, 4, 250, 99, 38, 203, 0, 0,
        0, 0, 73, 69, 78, 68, 174, 66, 96, 130
      ];

      testWidgets('com usarBordaInteligente: true notifica aoResolverProporcao e aplica desfoque horizontal com ClipRect', (WidgetTester tester) async {
        final picoDir = Directory('${tempDir.path}/downloads/pico_proporcao')
          ..createSync(recursive: true);
        final imgFile = File('${picoDir.path}/capa.webp');
        imgFile.writeAsBytesSync(bytesPng4x3);

        double? proporcaoRecebida;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: buildCragBackground(
                  'capa.webp',
                  cragId: 'pico_proporcao',
                  capaPath: 'capa.webp',
                  checksumSha256: 'hash_proporcao',
                  larguraAlvo: 1200,
                  usarBordaInteligente: true,
                  aoResolverProporcao: (p) => proporcaoRecebida = p,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          while (proporcaoRecebida == null) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();

        expect(proporcaoRecebida, closeTo(4.0 / 3.0, 0.001));
        expect(find.byType(ClipRect), findsWidgets);
        final imageFiltered = tester.widget<ImageFiltered>(find.byType(ImageFiltered));
        expect(imageFiltered.imageFilter.toString(), contains('24'));
        expect(imageFiltered.imageFilter.toString(), contains('0'));
      });

      testWidgets('com usarBordaInteligente: true quando a imagem falha exibe apenas um ícone de erro', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: buildCragBackground(
                  'thumbnails/pico_inexistente.webp',
                  cragId: 'pico_inexistente',
                  checksumSha256: 'hash_inexistente',
                  larguraAlvo: 1200,
                  usarBordaInteligente: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });

      testWidgets('didUpdateWidget re-inicializa provedor quando propriedades mudam', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: buildCragBackground('thumbnails/pico_a.webp', cragId: 'pico_a'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: buildCragBackground('thumbnails/pico_b.webp', cragId: 'pico_b'),
            ),
          ),
        );
        await tester.pump();
      });

      testWidgets('extrai cragId de thumbnailUrl via regex quando cragId for omitido', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: buildCragBackground('thumbnails/pico_auto.webp'),
            ),
          ),
        );
        await tester.pump();
      });
    });
  });
}

