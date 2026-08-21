package com.example.frontend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import dev.fluttercommunity.workmanager.BackgroundWorker

/**
 * Receiver acionado automaticamente pelo Android quando o pacote do aplicativo
 * é atualizado pela Google Play Store (ACTION_MY_PACKAGE_REPLACED).
 *
 * Enfileira a tarefa de migração em segundo plano no WorkManager com restrição de rede conectada.
 */
class PackageReplacedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val workData = workDataOf(
                BackgroundWorker.DART_TASK_KEY to "tarefa_migracao_pos_atualizacao"
            )

            val workRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
                .setConstraints(constraints)
                .setInputData(workData)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                "migracao_pos_update",
                ExistingWorkPolicy.REPLACE,
                workRequest
            )
        }
    }
}
