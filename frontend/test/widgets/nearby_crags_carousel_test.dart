// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/widgets/nearby_crags_carousel.dart';
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
      
      final picoA = <String, dynamic>{
        'id': 'pico_a',
        'nome': 'Pico A',
        'caminhoRelativo': 'picos/pico_a/pico_a.binarypb',
        'latitude': -20.01,
        'longitude': -44.01,
        'isDownloaded': false,
        'thumbnailUrl': '',
      };
      final picoB = <String, dynamic>{
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
        expect(find.text('PICO A'), findsOneWidget);

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

        expect(find.text('PICO A'), findsOneWidget);
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

        expect(find.text('PICO A'), findsOneWidget);
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

        expect(find.text('PICO A'), findsOneWidget);
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

        // Toca no card do Pico A para abrir o bottom sheet
        await tester.tap(find.text('PICO A'));
        await tester.pumpAndSettle();

        // No bottom sheet, clica em BAIXAR CROQUI
        expect(find.text('BAIXAR CROQUI'), findsOneWidget);
        await tester.tap(find.text('BAIXAR CROQUI'));
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
        expect(find.text('PICO B'), findsOneWidget);
        await tester.tap(find.text('PICO B'));
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

        await tester.tap(find.text('PICO A'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('BAIXAR CROQUI'));
        await tester.pump();

        expect(
          find.text('Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.'),
          findsOneWidget,
        );
      },
    );
  });
}
