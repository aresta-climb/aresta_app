// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view/function_library/funcoes_explorar.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/widgets/imagem_arquivo_aresta.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CragCard exibe estatísticas resumidas por padrão e detalhadas quando solicitado', (
    WidgetTester tester,
  ) async {
    final crag = MetadadosIndice(
      id: 'crag1',
      nome: 'Pico Teste',
      precomputados: PrecomputadosResumoCroqui(
        totalSetores: 3,
        totalEscaladas: 15,
        totalBoulders: 10,
        totalEsportivas: 5,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CragCard.deMetadados(
            metadados: crag,
            isDownloaded: false,
            downloadingCrags: ValueNotifier({}),
            onDownload: () {},
          ),
        ),
      ),
    );

    expect(find.text('3 setores • 15 escaladas'), findsOneWidget);
    expect(find.textContaining('boulders'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CragCard.deMetadados(
            metadados: crag,
            isDownloaded: false,
            downloadingCrags: ValueNotifier({}),
            showDetailedStats: true,
            onDownload: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('3 setores • 15 escaladas (10 boulders, 5 esportivas)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'buildCragListItem aceita CardCroquiViewModel e Map sincronizando estado salvoOffline',
    (WidgetTester tester) async {
      var abriu = false;
      const card = CardCroquiViewModel.deValores(
        id: 'c1',
        titulo: 'PICO CARD',
        textoEstatisticas: '1 setor • 5 vias',
        caminhoMiniatura: '',
        salvoOffline: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(
              card,
              ValueNotifier<Map<String, double>>({}),
              () {},
              onOpen: () => abriu = true,
              isDownloaded: true,
            ),
          ),
        ),
      );

      expect(find.text('SALVO OFFLINE'), findsOneWidget);
      await tester.tap(find.text('PICO CARD'));
      expect(abriu, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragListItem(
              const {'id': 'm1', 'nome': 'PICO MAPA'},
              ValueNotifier<Map<String, double>>({}),
              () {},
            ),
          ),
        ),
      );
      expect(find.text('PICO MAPA'), findsOneWidget);
    },
  );

  group('CragBackground Downsampling Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('thumb_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      EditorDeCroqui();
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    final bytesPng1 = <int>[
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
      0, 13, 73, 68, 65, 84, 120, 156, 99, 100, 248, 207, 80, 15, 0, 3,
      134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, 174,
      66, 96, 130
    ];

    testWidgets('buildCragBackground aplica cacheWidth na imagem remota e resolve miniatura local', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragBackground('https://cdn.arestaclimb.com/thumb.webp'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final Image remoteImg = tester.widget(find.byType(Image));
      expect((remoteImg.image as ResizeImage).width, equals(450));

      final thumbDir = Directory('${tempDir.path}/downloads/thumbnails')
        ..createSync(recursive: true);
      File('${thumbDir.path}/crag_local.webp').writeAsBytesSync(bytesPng1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCragBackground(
              'https://serving.arestaclimb.com/v4/thumbnails/crag_local.webp',
              cragId: 'crag_local',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final Image localImg = tester.widget(find.byType(Image));
      final resize = localImg.image as ResizeImage;
      expect(resize.width, equals(450));
      expect(resize.imageProvider, isA<ImagemArquivoAresta>());
    });
  });

  test(
    'extrairSiglaUfPico resolve sigla pelo id, caminhoRelativo e faixas geograficas',
    () {
      expect(
        extrairSiglaUfPico(
          id: 'br_mg_serra_cipo',
          caminhoRelativo: '',
          latitude: 0,
          longitude: 0,
        ),
        equals('MG'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'custom_1',
          caminhoRelativo: 'croquis/br_rj_urca/compilado.binarypb',
          latitude: 0,
          longitude: 0,
        ),
        equals('RJ'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c1',
          caminhoRelativo: '',
          latitude: -22.9,
          longitude: -43.2,
        ),
        equals('RJ'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c2',
          caminhoRelativo: '',
          latitude: -20.3,
          longitude: -40.3,
        ),
        equals('ES'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c3',
          caminhoRelativo: '',
          latitude: -23.5,
          longitude: -46.6,
        ),
        equals('SP'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c4',
          caminhoRelativo: '',
          latitude: -19.5,
          longitude: -44.0,
        ),
        equals('MG'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c5',
          caminhoRelativo: '',
          latitude: -29.0,
          longitude: -51.0,
        ),
        equals('RS'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c6',
          caminhoRelativo: '',
          latitude: -12.5,
          longitude: -41.5,
        ),
        equals('BA'),
      );
      expect(
        extrairSiglaUfPico(
          id: 'c7',
          caminhoRelativo: '',
          latitude: -16.0,
          longitude: -56.0,
        ),
        equals('BR'),
      );
    },
  );

  test(
    'construirMarcadorGloboPico e resolverAlvoDownloadExplorar normalizam marcadores e alvos de download',
    () {
      final marcadorPadrao = construirMarcadorGloboPico(
        id: 'br_mg_cipo',
        nome: '',
        caminhoRelativo: '',
        latitude: -19.3,
        longitude: -43.6,
        cota: null,
        umidade: const EstadoUmidadePico.seco(),
      );
      expect(marcadorPadrao.uf, equals('MG'));
      expect(marcadorPadrao.nome, isNotEmpty);
      expect(marcadorPadrao.altitudePicoMetros, equals(920));
      expect(marcadorPadrao.altitudeBaseMetros, equals(640));

      final marcadorComCota = construirMarcadorGloboPico(
        id: 'br_mg_igarape',
        nome: 'Pedra Grande',
        caminhoRelativo: '',
        latitude: -20.07,
        longitude: -44.30,
        cota: const CotaAltimetricaPico(
          altitudeBaseMetros: 960,
          altitudePicoMetros: 1430,
          dimensaoGradeDem: 2,
          raioGradeDemGraus: 0.02,
          gradeDemMetros: [960, 1100, 1250, 1430],
        ),
        umidade: const EstadoUmidadePico.seco(),
      );
      expect(marcadorComCota.altitudeBaseMetros, equals(960));
      expect(marcadorComCota.dimensaoGradeDem, equals(2));

      expect(
        resolverAlvoDownloadExplorar(
          const CardCroquiViewModel.deValores(
            id: 'card_id',
            titulo: 'Serra do Cipó',
            textoEstatisticas: '',
            caminhoMiniatura: '',
            salvoOffline: false,
          ),
        ),
        equals((id: 'card_id', nome: 'Serra do Cipó')),
      );
      expect(
        resolverAlvoDownloadExplorar({'id': 'map_id', 'nome': 'Pico Mapa'}),
        equals((id: 'map_id', nome: 'Pico Mapa')),
      );
      expect(resolverAlvoDownloadExplorar('str_id').id, equals('str_id'));

      expect(
        calcularOpacidadeFundoBarraTopo(
          alturaGavetaPx: 300.0,
          alturaTelaPx: 800.0,
        ),
        equals(0.0),
      );
      expect(
        calcularOpacidadeFundoBarraTopo(
          alturaGavetaPx: 640.0,
          alturaTelaPx: 800.0,
        ),
        closeTo(0.50, 1e-4),
      );
      expect(
        calcularOpacidadeFundoBarraTopo(
          alturaGavetaPx: 760.0,
          alturaTelaPx: 800.0,
        ),
        equals(1.0),
      );

      expect(calcularLodFocoLocalizacaoUsuario(0.40), closeTo(1.58, 1e-4));
      expect(calcularLodFocoLocalizacaoUsuario(2.40), closeTo(2.40, 1e-4));
    },
  );
}
