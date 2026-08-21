import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../services/dataset_repository.dart';
import '../../services/editor_croqui.dart';
import '../../services/http/sync_service.dart';
import '../../services/firebase/app_logger.dart';

/// Orquestrador de migração e sincronização executado em segundo plano (Background).
///
/// Responsável por coordenar o download silencioso do novo índice e de croquis
/// previamente salvos pelo usuário após uma atualização de aplicativo pela loja,
/// além de fornecer os métodos para agendamento e cancelamento de primeiro plano (Foreground Takeover).
class MigracaoBackgroundOrchestrator {
  /// Nome identificador da tarefa executada pelo WorkManager.
  static const String kNomeTarefaMigracao = 'tarefa_migracao_pos_atualizacao';

  /// Nome único de agendamento no WorkManager para evitar tarefas duplicadas.
  static const String kNomeUnicoMigracao = 'migracao_pos_update';

  /// Executa o fluxo de migração em segundo plano se houver necessidade detectada.
  ///
  /// 1. Verifica se há necessidade de migração estrutural (`checkNeedsMigration()`).
  /// 2. Se necessário, invoca `sync.executarMigracao()`.
  /// 3. Retorna [true] se nenhuma migração for necessária ou se for concluída com sucesso.
  static Future<bool> executarMigracaoPosAtualizacao({
    DatasetRepository? datasetRepo,
    SyncService? syncService,
    EditorDeCroqui? editorDeCroqui,
  }) async {
    try {
      debugPrint('[MigracaoBackground] Iniciando verificação de migração pós-atualização...');

      final editor = editorDeCroqui ?? EditorDeCroqui();
      final repo = datasetRepo ?? DatasetRepository(editorDeCroqui: editor);
      final sync = syncService ?? SyncService(datasetRepository: repo);

      final precisaMigrar = await sync.checkNeedsMigration();
      if (!precisaMigrar) {
        debugPrint('[MigracaoBackground] Nenhuma migração pendente detectada.');
        return true;
      }

      debugPrint('[MigracaoBackground] Migração necessária. Executando migração...');
      return await sync.executarMigracao();
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[MigracaoBackground] Erro inesperado ao executar migração em segundo plano',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Agenda a execução única da tarefa de migração no WorkManager com restrição de rede conectada.
  static Future<void> agendarMigracaoPosAtualizacao({
    Workmanager? workmanager,
  }) async {
    final wm = workmanager ?? Workmanager();
    await wm.registerOneOffTask(
      kNomeUnicoMigracao,
      kNomeTarefaMigracao,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancela qualquer tarefa de migração ativa em segundo plano para que a interface
  /// de primeiro plano assuma o controle com segurança (Estratégia Foreground Takeover).
  static Future<void> cancelarMigracaoSegundoPlano({
    Workmanager? workmanager,
  }) async {
    try {
      final wm = workmanager ?? Workmanager();
      await wm.cancelByUniqueName(kNomeUnicoMigracao);
      debugPrint('[MigracaoBackground] Tarefa em segundo plano cancelada para prioridade do primeiro plano.');
    } catch (e) {
      debugPrint('[MigracaoBackground] Erro ao cancelar tarefa de segundo plano: $e');
    }
  }
}
