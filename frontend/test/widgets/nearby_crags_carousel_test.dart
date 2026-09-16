// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/widgets/nearby_crags_carousel.dart';
import 'package:frontend/widgets/crag_card.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_geolocator_platform.dart';
import '../mocks/mock_telemetry_service.dart';

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
}

class FakeSyncService extends Fake implements SyncService {
  bool isNetworkDisabledResult = false;
  bool downloadSuccess = true;
  ResumoCroqui? downloadedResumo;
  final ValueNotifier<Map<String, double>> _downloadingCrags = ValueNotifier({});

  @override
  ValueNotifier<Map<String, double>> get downloadingCrags => _downloadingCrags;

  @override
  Future<bool> isNetworkDisabled() async => isNetworkDisabledResult;

  @override
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    downloadedResumo = resumo;
    return downloadSuccess;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NearbyCragsCarousel Widget Tests', () {
    late MockGeolocatorPlatform mockGeolocator;
    late FakeSyncService fakeSyncService;
    late Directory tempDir;
    late Map<String, dynamic> picoA;
    late Map<String, dynamic> picoB;

    setUp(() async {
      TelemetryService.instance = MockTelemetryService();
      tempDir = await Directory.systemTemp.createTemp('nearby_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      SharedPreferences.setMockInitialValues({});
      mockGeolocator = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocator;
      fakeSyncService = FakeSyncService();

      final editorDeCroqui = EditorDeCroqui();
      final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      
      picoA = <String, dynamic>{
        'id': 'pico_a',
        'nome': 'Pico A',
        'caminhoRelativo': 'picos/pico_a/pico_a.binarypb',
        'latitude': -20.01,
        'longitude': -44.01,
        'isDownloaded': false,
        'thumbnailUrl': '',
      };
      picoB = <String, dynamic>{
        'id': 'pico_b',
        'nome': 'Pico B',
        'caminhoRelativo': 'picos/pico_b/pico_b.binarypb',
        'latitude': -22.0,
        'longitude': -45.0,
        'isDownloaded': true,
        'thumbnailUrl': '',
      };

      datasetRepo.activeDataset.value = TopoDataset(
        availablePicos: [picoA, picoB],
        downloadedPicos: [picoB],
      );

      final indice = Indice();
      indice.croquis.add(
        ResumoCroqui()
          ..id = 'pico_a'
          ..nome = 'Pico A'
          ..caminhoRelativo = 'picos/pico_a/pico_a.binarypb',
      );
      indice.croquis.add(
        ResumoCroqui()
          ..id = 'pico_b'
          ..nome = 'Pico B'
          ..caminhoRelativo = 'picos/pico_b/pico_b.binarypb',
      );
      datasetRepo.indiceData.value = indice;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets(
      'Deve obter localização do GPS, salvar no SharedPreferences e exibir picos ordenados',
      (WidgetTester tester) async {
        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('MAIS PRÓXIMOS DE VOCÊ'), findsOneWidget);
        expect(find.text('PICO A'), findsWidgets);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('last_known_latitude'), -20.0);
        expect(prefs.getDouble('last_known_longitude'), -44.0);
      },
    );

    testWidgets(
      'Quando GPS falhar, deve utilizar coordenadas salvas no SharedPreferences como fallback',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'last_known_latitude': -20.0,
          'last_known_longitude': -44.0,
        });

        mockGeolocator.currentPositionException = Exception('GPS Timeout');
        mockGeolocator.lastKnownPositionResult = null;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PICO A'), findsWidgets);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      },
    );

    testWidgets(
      'Quando GPS estiver desligado e não houver cache no SharedPreferences, deve finalizar sem travar',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        mockGeolocator.isLocationServiceEnabledResult = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Quando permissão for deniedForever no init, deve tentar fallback de cache',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'last_known_latitude': -20.0,
          'last_known_longitude': -44.0,
        });
        mockGeolocator.checkPermissionResult = LocationPermission.deniedForever;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PICO A'), findsWidgets);
      },
    );

    testWidgets(
      'Quando permissão for negada, deve exibir botão e permitir tentar autorização',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        mockGeolocator.checkPermissionResult = LocationPermission.denied;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Permitir Localização'), findsOneWidget);

        // Se ao clicar no botão for deniedForever, tenta fallback
        mockGeolocator.requestPermissionResult = LocationPermission.deniedForever;
        await tester.tap(find.text('Permitir Localização'));
        await tester.pumpAndSettle();

        // Se ao clicar conceder, obtém coordenadas
        mockGeolocator.requestPermissionResult = LocationPermission.always;
        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.tap(find.text('Permitir Localização'));
        await tester.pumpAndSettle();

        expect(find.text('PICO A'), findsWidgets);
      },
    );

    testWidgets(
      'Quando permissão for concedida mas GPS retornar null e cache vazio, não deve manter card de permissão',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        mockGeolocator.checkPermissionResult = LocationPermission.denied;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Permitir Localização'), findsOneWidget);

        // Usuário concede permissão, mas GPS dá erro/timeout e lastKnown é nulo
        mockGeolocator.requestPermissionResult = LocationPermission.whileInUse;
        mockGeolocator.currentPositionException = Exception('No GPS fix');
        mockGeolocator.lastKnownPositionResult = null;

        await tester.tap(find.text('Permitir Localização'));
        await tester.pumpAndSettle();

        // Não deve mais mostrar o botão nem o card de permissão negada
        expect(find.text('Permitir Localização'), findsNothing);
        expect(
          find.text(
            'Permita o acesso à localização para ver os picos mais próximos de você.',
          ),
          findsNothing,
        );
        expect(
          find.text('Aguardando sinal de GPS...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Quando activeDataset for populado após a resolução do GPS, deve recalcular distâncias e exibir picos automaticamente',
      (WidgetTester tester) async {
        final datasetRepo = DatasetRepository.instance!;
        // Simula startup: GPS já tem fix, mas o repositório ainda está carregando do disco
        datasetRepo.activeDataset.value = null;

        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        // Primeiro pump: activeDataset é null -> spinner de loading
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Repositório conclui a leitura em disco e notifica activeDataset
        datasetRepo.activeDataset.value = TopoDataset(
          availablePicos: [
            <String, dynamic>{
              'id': 'pico_a',
              'nome': 'Pico A',
              'caminhoRelativo': 'picos/pico_a/pico_a.binarypb',
              'latitude': -20.01,
              'longitude': -44.01,
              'isDownloaded': false,
              'thumbnailUrl': '',
            },
          ],
          downloadedPicos: [],
        );

        await tester.pumpAndSettle();

        // Deve ter recalculado as distâncias e exibido o Pico A!
        expect(find.text('PICO A'), findsWidgets);
      },
    );

    testWidgets(
      'Deve obter localização instantaneamente a partir de getLastKnownPosition do SO sem travar',
      (WidgetTester tester) async {
        mockGeolocator.lastKnownPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        mockGeolocator.currentPositionException = Exception('Slow active GPS');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PICO A'), findsWidgets);
      },
    );

    testWidgets(
      'Deve escutar getPositionStream e atualizar os picos em tempo real quando o emulador/GPS emitir uma nova posição',
      (WidgetTester tester) async {
        mockGeolocator.lastKnownPositionResult = null;
        mockGeolocator.currentPositionException = Exception('No fix initially');

        final streamController = StreamController<Position>.broadcast();
        mockGeolocator.positionStreamOverride = streamController.stream;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Aguardando sinal de GPS...'), findsOneWidget);

        // Emulador emite nova posição via stream
        streamController.add(
          Position(
            latitude: -20.0,
            longitude: -44.0,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 1000.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PICO A'), findsWidgets);
        expect(mockGeolocator.lastStreamSettings?.accuracy, equals(LocationAccuracy.high));
        await streamController.close();
      },
    );

    testWidgets(
      'getCurrentPosition deve ser chamado com LocationAccuracy.high para suportar emulador e satélites',
      (WidgetTester tester) async {
        mockGeolocator.lastKnownPositionResult = null;
        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(mockGeolocator.lastCurrentPositionSettings?.accuracy, equals(LocationAccuracy.high));
        expect(find.text('PICO A'), findsWidgets);
      },
    );

    testWidgets(
      'Quando permissão for deniedForever ao clicar no botão, deve chamar openAppSettings',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        mockGeolocator.checkPermissionResult = LocationPermission.denied;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );
        await tester.pumpAndSettle();

        mockGeolocator.requestPermissionResult = LocationPermission.deniedForever;
        await tester.tap(find.text('Permitir Localização'));
        await tester.pumpAndSettle();

        expect(mockGeolocator.openAppSettingsCalled, isTrue);
      },
    );

    testWidgets(
      'Deve disparar download do pico ao abrir modal e clicar em baixar',
      (WidgetTester tester) async {
        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Aciona o download do Pico A
        final carouselState = tester.state(find.byType(NearbyCragsCarousel)) as dynamic;
        carouselState.handleDownload(picoA);
        await tester.pumpAndSettle();

        expect(fakeSyncService.downloadedResumo?.id, 'pico_a');
      },
    );

    testWidgets(
      'Deve abrir pico baixado diretamente ao tocar no card salvo',
      (WidgetTester tester) async {
        mockGeolocator.currentPositionResult = Position(
          latitude: -22.0,
          longitude: -45.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Toca no Pico B (que está marcado como isDownloaded)
        expect(find.text('PICO B'), findsWidgets);
        await tester.tap(find.text('PICO B').first);
        await tester.pump();
      },
    );

    testWidgets(
      'Deve exibir snackbar de app descontinuado se isNetworkDisabled for true ao tentar baixar',
      (WidgetTester tester) async {
        fakeSyncService.isNetworkDisabledResult = true;
        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Aciona o download do Pico A quando rede estiver desabilitada
        final carouselState = tester.state(find.byType(NearbyCragsCarousel)) as dynamic;
        carouselState.handleDownload(picoA);
        await tester.pumpAndSettle();

        expect(
          find.text('Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Deve limitar a exibição a no máximo 6 picos mais próximos quando houver mais de 6 disponíveis',
      (WidgetTester tester) async {
        final datasetRepo = DatasetRepository.instance!;
        // Cria 8 picos com distâncias progressivas a partir de (-20.0, -44.0)
        final picosVariados = List.generate(8, (i) {
          return <String, dynamic>{
            'id': 'pico_$i',
            'nome': 'Pico $i',
            'caminhoRelativo': 'picos/pico_$i/pico_$i.binarypb',
            'latitude': -20.0 + (i * 0.1),
            'longitude': -44.0 + (i * 0.1),
            'isDownloaded': false,
            'thumbnailUrl': '',
          };
        });

        datasetRepo.activeDataset.value = TopoDataset(
          availablePicos: picosVariados,
          downloadedPicos: [],
        );

        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Deve conter os 6 primeiros picos mais próximos (Pico 0 a 5)
        // e NÃO deve conter o 7º e 8º (Pico 6 e 7)
        final carouselState = tester.state(find.byType(NearbyCragsCarousel)) as dynamic;
        final List<ResumoPico> picosExibidos = carouselState.closestCrags;
        expect(picosExibidos.length, equals(6));
        expect(picosExibidos.map((p) => p.id).toList(), equals([
          'pico_0',
          'pico_1',
          'pico_2',
          'pico_3',
          'pico_4',
          'pico_5',
        ]));
      },
    );

    testWidgets(
      'Deve fazer loop contínuo do carrossel ao rolar horizontalmente além do último pico',
      (WidgetTester tester) async {
        final datasetRepo = DatasetRepository.instance!;
        final picos = List.generate(6, (i) {
          return <String, dynamic>{
            'id': 'pico_loop_$i',
            'nome': 'Pico Loop $i',
            'caminhoRelativo': 'picos/pico_loop_$i/pico_loop_$i.binarypb',
            'latitude': -20.0 + (i * 0.05),
            'longitude': -44.0 + (i * 0.05),
            'isDownloaded': false,
            'thumbnailUrl': '',
          };
        });

        datasetRepo.activeDataset.value = TopoDataset(
          availablePicos: picos,
          downloadedPicos: [],
        );

        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NearbyCragsCarousel(syncService: fakeSyncService),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Inicialmente o Pico Loop 0 é visível
        expect(find.text('PICO LOOP 0'), findsOneWidget);

        // Rola horizontalmente por uma distância correspondente a mais de 6 cards (6 * 356px)
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        // Rola para a direita ultrapassando os 6 itens
        await tester.drag(listViewFinder, const Offset(-2500, 0));
        await tester.pumpAndSettle();

        // Após rolar além dos 6 itens, o carrossel reinicia o ciclo (looping) e exibe novamente os picos
        expect(find.byType(CragCard), findsWidgets);
      },
    );
  });
}
