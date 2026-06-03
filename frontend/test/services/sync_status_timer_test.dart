import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';

void main() {
  group('SyncStatus Timer Tests', () {
    testWidgets('Deve mudar para justUpdated e depois para updated após 3 segundos', (WidgetTester tester) async {
      // Usamos um mock manual do repositório
      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      final syncService = SyncService(repo);

      // Garante que o estado inicial não seja nenhum dos dois
      repo.syncStatus.value = SyncStatus.updating;

      // Dispara o status temporário
      syncService.setUpdatedStatus();

      // Verifica se mudou para justUpdated imediatamente
      expect(repo.syncStatus.value, SyncStatus.justUpdated);

      // Avança 1 segundo (ainda deve ser justUpdated)
      await tester.pump(const Duration(seconds: 1));
      expect(repo.syncStatus.value, SyncStatus.justUpdated);

      // Avança mais 2.1 segundos (total > 3s)
      await tester.pump(const Duration(milliseconds: 2100));
      
      // Agora deve ter voltado para updated
      expect(repo.syncStatus.value, SyncStatus.updated);
    });

    testWidgets('Não deve sobrescrever se o status mudar para outra coisa (ex: erro)', (WidgetTester tester) async {
      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      final syncService = SyncService(repo);

      syncService.setUpdatedStatus();
      expect(repo.syncStatus.value, SyncStatus.justUpdated);

      // Simulamos que ocorreu um erro logo em seguida
      repo.syncStatus.value = SyncStatus.error;

      // Avança o tempo
      await tester.pump(const Duration(seconds: 4));

      // Não deve ter voltado para updated, deve ter mantido o erro
      expect(repo.syncStatus.value, SyncStatus.error);
    });
  });
}
