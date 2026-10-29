// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

package com.example.frontend

import android.graphics.drawable.ColorDrawable
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
