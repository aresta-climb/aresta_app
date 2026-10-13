// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Testes de widget para a tela principal do Mapa Global.
///
/// Assegura que a página [MapaGlobalPage] seja capaz de instanciar o mapa
/// e renderizar a barra de navegação corretamente sem quebrar a árvore
/// de widgets, utilizando uma carga simulada de picos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapa_global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view/view_models/mapa_global_view_model.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../mocks/mock_geolocator_platform.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository(EditorDeCroqui editor) : super(editorDeCroqui: editor);
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
}

void main() {
  setUp(() {
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });
  testWidgets('MapaGlobalPage renders correctly with crags', (
    WidgetTester tester,
  ) async {
    final mockEditor = EditorDeCroqui();
    final mockRepo = FakeDatasetRepository(mockEditor);
    final mockSync = FakeSyncService(mockRepo);

    final crags = [
      {
        'id': 'crag1',
        'nome': 'Pico 1',
        'local': 'Local 1',
        'latitude': -20.0,
        'longitude': -40.0,
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MapaGlobalPage(
          viewModel: MapaGlobalViewModel(
            datasetRepo: mockRepo,
            syncService: mockSync,
            picosIniciais: crags,
          ),
        ),
      ),
    );

    // Verifica AppBar
    expect(find.text('Mapa Global'), findsOneWidget);

    // Verifica se o GoogleMap é renderizado
    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('MapaGlobalPage atualiza marcadores ao cruzar faixas de zoom no onCameraMove', (
    WidgetTester tester,
  ) async {
    final mockEditor = EditorDeCroqui();
    final mockRepo = FakeDatasetRepository(mockEditor);
    final mockSync = FakeSyncService(mockRepo);

    final crags = [
      {
        'id': 'crag1',
        'nome': 'Pico 1',
        'local': 'Local 1',
        'latitude': -20.0,
        'longitude': -40.0,
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MapaGlobalPage(
          viewModel: MapaGlobalViewModel(
            datasetRepo: mockRepo,
            syncService: mockSync,
            picosIniciais: crags,
          ),
        ),
      ),
    );

    final googleMapFinder = find.byType(GoogleMap);
    expect(googleMapFinder, findsOneWidget);

    GoogleMap mapWidget = tester.widget<GoogleMap>(googleMapFinder);
    expect(mapWidget.markers.length, equals(1));

    // Movimentação mantendo na mesma faixa (macro 4.0 -> 5.5): não deve alterar a faixa
    mapWidget.onCameraMove?.call(const CameraPosition(target: LatLng(-20, -40), zoom: 5.5));
    await tester.pump();

    // Cruzando para a faixa regional (8.0): deve acionar rebuild para a nova faixa
    mapWidget.onCameraMove?.call(const CameraPosition(target: LatLng(-20, -40), zoom: 8.0));
    await tester.pump();

    mapWidget = tester.widget<GoogleMap>(googleMapFinder);
    expect(mapWidget.markers.length, equals(1));

    // Cruzando para a faixa local (12.0): deve acionar rebuild para faixa local
    mapWidget.onCameraMove?.call(const CameraPosition(target: LatLng(-20, -40), zoom: 12.0));
    await tester.pump();

    mapWidget = tester.widget<GoogleMap>(googleMapFinder);
    expect(mapWidget.markers.length, equals(1));
  });

  testWidgets('MapaGlobalPage exibe exatamente um botão de feedback na AppBar', (
    WidgetTester tester,
  ) async {
    final mockEditor = EditorDeCroqui();
    final mockRepo = FakeDatasetRepository(mockEditor);
    final mockSync = FakeSyncService(mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: MapaGlobalPage(
          viewModel: MapaGlobalViewModel(
            datasetRepo: mockRepo,
            syncService: mockSync,
          ),
        ),
      ),
    );

    // Deve conter exatamente 1 botão de alerta/feedback na AppBar
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('MapaGlobalPage renderiza marcadores ao receber CardCroquiViewModel com resolução via dataset', (
    WidgetTester tester,
  ) async {
    final mockEditor = EditorDeCroqui();
    final mockRepo = FakeDatasetRepository(mockEditor);
    final mockSync = FakeSyncService(mockRepo);

    final picosIndice = [
      ResumoCroqui(
        id: 'cipo',
        nome: 'Serra do Cipó',
        localizacao: Coordenada(
          latitude: -193333330,
          longitude: -436000000,
        ),
      ),
    ];

    mockRepo.activeDataset.value = ConjuntoDadosCroqui(
      metadadosDisponiveis: picosIndice,
    );

    final card = CardCroquiViewModel.deValores(
      id: 'cipo',
      titulo: 'SERRA DO CIPÓ',
      textoEstatisticas: '10 setores',
      caminhoMiniatura: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaGlobalPage(
          viewModel: MapaGlobalViewModel(
            datasetRepo: mockRepo,
            syncService: mockSync,
            picosIniciais: [card],
          ),
        ),
      ),
    );

    final googleMapFinder = find.byType(GoogleMap);
    expect(googleMapFinder, findsOneWidget);

    final GoogleMap mapWidget = tester.widget<GoogleMap>(googleMapFinder);
    expect(mapWidget.markers.length, equals(1));
  });
}

