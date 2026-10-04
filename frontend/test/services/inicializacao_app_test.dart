// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/inicializacao_app.dart';

class MockDatasetRepository extends Mock implements DatasetRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockWorkmanager extends Mock implements Workmanager {}

class MockImageCache extends Mock implements ImageCache {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gestão de Memória e Vitals (configurarGestaoMemoria)', () {
    test('define teto LRU do imageCache para 100 MB por padrão', () {
      configurarGestaoMemoria();
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(100 * 1024 * 1024),
      );
    });

    test('permite tamanho customizado', () {
      configurarGestaoMemoria(tamanhoMaximoBytes: 50 * 1024 * 1024);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(50 * 1024 * 1024),
      );
      configurarGestaoMemoria();
    });
  });

  group('Migração Silenciosa de Termos Legais (migrarTermosLegais)', () {
    test('migra de chave legada accepted_terms para accepted_legal_version = 1', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_terms': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, 1);
      expect(prefs.getInt('accepted_legal_version'), 1);
      expect(prefs.containsKey('accepted_terms'), isFalse);
    });

    test('remove accepted_terms residual se accepted_legal_version já existir', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_legal_version': 2,
        'accepted_terms': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, 2);
      expect(prefs.getInt('accepted_legal_version'), 2);
      expect(prefs.containsKey('accepted_terms'), isFalse);
    });

    test('retorna nulo se o usuário for novo e nunca aceitou nada', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, isNull);
    });
  });

  group('Serviços e Foreground Takeover (setupAppServices)', () {
    late MockDatasetRepository mockRepo;
    late MockSyncService mockSync;
    late MockWorkmanager mockWorkmanager;

    setUp(() {
      mockRepo = MockDatasetRepository();
      mockSync = MockSyncService();
      mockWorkmanager = MockWorkmanager();

      when(() => mockRepo.init()).thenAnswer((_) async {});
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});
    });

    test('cancela tarefa de segundo plano e sincroniza se não precisa de migração', () async {
      when(() => mockSync.checkNeedsMigration()).thenAnswer((_) async => false);
      when(() => mockSync.syncIndex()).thenAnswer((_) async => <String>[]);

      final result = await setupAppServices(
        mockRepo,
        mockSync,
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      verify(() => mockRepo.init()).called(1);
      verify(() => mockSync.checkNeedsMigration()).called(1);
      verify(() => mockSync.syncIndex()).called(1);
      expect(result, isFalse);
    });

    test('cancela tarefa de segundo plano e não sincroniza se precisa de migração', () async {
      when(() => mockSync.checkNeedsMigration()).thenAnswer((_) async => true);

      final result = await setupAppServices(
        mockRepo,
        mockSync,
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      verify(() => mockRepo.init()).called(1);
      verify(() => mockSync.checkNeedsMigration()).called(1);
      verifyNever(() => mockSync.syncIndex());
      expect(result, isTrue);
    });
  });

  group('Ouvintes LiveReload (registrarOuvintesLiveReload)', () {
    test('sincroniza índice e purga cache inativo ao receber evento', () async {
      final mockDataset = MockDatasetRepository();
      final mockSyncSvc = MockSyncService();
      final mockImageCache = MockImageCache();
      final editorLocal = EditorDeCroqui();

      when(() => mockSyncSvc.syncIndex()).thenAnswer((_) async => <String>[]);
      when(() => mockDataset.init()).thenAnswer((_) async {});
      when(() => mockDataset.gerenciadorSessaoOnline).thenReturn(GerenciadorSessaoOnline());

      registrarOuvintesLiveReload(
        editorLocal,
        mockDataset,
        mockSyncSvc,
        imageCache: mockImageCache,
      );

      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_1',
        timestamp: DateTime.now(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockSyncSvc.syncIndex()).called(1);
      verify(() => mockImageCache.clear()).called(1);
      verifyNever(() => mockDataset.init());
    });

    test('coalesce múltiplos eventos push de LiveReload em rápida sucessão', () async {
      final mockDataset = MockDatasetRepository();
      final mockSyncSvc = MockSyncService();
      final mockImageCache = MockImageCache();
      final editorLocal = EditorDeCroqui();

      when(() => mockSyncSvc.syncIndex()).thenAnswer((_) async => <String>[]);
      when(() => mockDataset.init()).thenAnswer((_) async {});
      when(() => mockDataset.gerenciadorSessaoOnline).thenReturn(GerenciadorSessaoOnline());

      registrarOuvintesLiveReload(
        editorLocal,
        mockDataset,
        mockSyncSvc,
        imageCache: mockImageCache,
        debounceDuration: const Duration(milliseconds: 40),
      );

      // Emite 3 eventos seguidos quase instantâneos
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_1',
        timestamp: DateTime.now(),
      );
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_2',
        timestamp: DateTime.now(),
      );
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_3',
        timestamp: DateTime.now(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Deve ter chamado syncIndex apenas 1 vez para o lote
      verify(() => mockSyncSvc.syncIndex()).called(1);
    });
  });
}
