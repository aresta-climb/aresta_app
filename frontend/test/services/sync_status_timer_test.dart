import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';

void main() {
  group('SyncStatus Timer Tests', () {
    testWidgets(
      'Deve mudar para justUpdated e depois para updated após 4 segundos',
      (WidgetTester tester) async {
        // Usamos um mock manual do repositório
        final editor = EditorDeCroqui();
        final repo = DatasetRepository(editorDeCroqui: editor);
        final syncService = SyncService(datasetRepository: repo);

        // Garante que o estado inicial não seja nenhum dos dois
        syncService.syncStatus.value = SyncStatus.updating;

        // Dispara o status temporário
        syncService.setUpdatedStatus();

        // Verifica se mudou para justUpdated imediatamente
        expect(syncService.syncStatus.value, SyncStatus.justUpdated);

        // Avança 1 segundo (ainda deve ser justUpdated)
        await tester.pump(const Duration(seconds: 1));
        expect(syncService.syncStatus.value, SyncStatus.justUpdated);

        // Avança mais 3.1 segundos (total > 4s)
        await tester.pump(const Duration(milliseconds: 3100));

        // Agora deve ter voltado para updated
        expect(syncService.syncStatus.value, SyncStatus.updated);
      },
    );

    testWidgets(
      'Não deve sobrescrever se o status mudar para outra coisa (ex: erro)',
      (WidgetTester tester) async {
        final editor = EditorDeCroqui();
        final repo = DatasetRepository(editorDeCroqui: editor);
        final syncService = SyncService(datasetRepository: repo);

        syncService.setUpdatedStatus();
        expect(syncService.syncStatus.value, SyncStatus.justUpdated);

        // Simulamos que ocorreu um erro logo em seguida
        syncService.syncStatus.value = SyncStatus.error;

        // Avança o tempo
        await tester.pump(const Duration(seconds: 4));

        // Não deve ter voltado para updated, deve ter mantido o erro
        expect(syncService.syncStatus.value, SyncStatus.error);
      },
    );

    testWidgets(
      'Deve mudar para noNewUpdates e depois para updated após 4 segundos',
      (WidgetTester tester) async {
        final editor = EditorDeCroqui();
        final repo = DatasetRepository(editorDeCroqui: editor);
        final syncService = SyncService(datasetRepository: repo);

        syncService.syncStatus.value = SyncStatus.updating;

        // Dispara o status com noNewUpdates: true
        syncService.setUpdatedStatus(noNewUpdates: true);

        expect(syncService.syncStatus.value, SyncStatus.noNewUpdates);

        await tester.pump(const Duration(seconds: 1));
        expect(syncService.syncStatus.value, SyncStatus.noNewUpdates);

        await tester.pump(const Duration(milliseconds: 3100));
        expect(syncService.syncStatus.value, SyncStatus.updated);
      },
    );
  });
}
