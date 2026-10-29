// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

package com.example.frontend

import android.graphics.drawable.ColorDrawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CANAL_CICLO_VIDA = "app.escalada.croquis/ciclo_vida"
    }

    /**
     * Registra o canal nativo de ciclo de vida para permitir que o Flutter mova
     * a tarefa para segundo plano (`moveTaskToBack`) ao pressionar Voltar na raiz
     * da tela inicial (`HomeNode`), preservando a `MainActivity` e a `FlutterEngine`
     * vivas em memória em vez de destruí-las com `Activity.finish()`.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL_CICLO_VIDA
        ).setMethodCallHandler { call, result ->
            if (call.method == "minimizarTarefa") {
                val movido = moveTaskToBack(true)
                result.success(movido)
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Altera o fundo da janela nativa para a cor escura do tema (`#181312` deepBasalt)
     * assim que a atividade vai para segundo plano pela primeira vez.
     *
     * Isso garante 0% de impacto na primeira abertura a frio (Cold Start continua `#FFFFFF`
     * alinhado à splash screen) e elimina qualquer flash branco ao restaurar a `SurfaceView`
     * do Flutter em retomadas de segundo plano (Warm Start / Hot Start).
     */
    override fun onStop() {
        super.onStop()
        window.setBackgroundDrawable(ColorDrawable(0xFF181312.toInt()))
    }
}
