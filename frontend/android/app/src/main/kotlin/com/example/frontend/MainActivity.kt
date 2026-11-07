// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

package com.example.frontend

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.ColorDrawable
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.auth.api.signin.GoogleSignInStatusCodes
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.min

class MainActivity : FlutterActivity() {
    companion object {
        private const val CANAL_CICLO_VIDA = "app.escalada.croquis/ciclo_vida"
        private const val CANAL_SELETOR_MIDIA = "app.escalada.croquis/seletor_midia"
        private const val CANAL_AUTENTICACAO_NATIVA = "app.escalada.croquis/autenticacao_nativa"
        private const val CODIGO_SELECIONAR_FOTO = 9401
        private const val CODIGO_LOGIN_GOOGLE = 9402
        private const val TAMANHO_AVATAR_PX = 256
    }

    private var resultadoPendenteFoto: MethodChannel.Result? = null
    private var resultadoPendenteAuthGoogle: MethodChannel.Result? = null

    /**
     * Registra o canal nativo de ciclo de vida para permitir que o Flutter mova
     * a tarefa para segundo plano (`moveTaskToBack`) ao pressionar Voltar na raiz
     * da tela inicial (`HomeNode`), preservando a `MainActivity` e a `FlutterEngine`
     * vivas em memória em vez de destruí-las com `Activity.finish()`.
     * Também registra o canal nativo de seleção e compressão de foto de perfil.
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL_SELETOR_MIDIA
        ).setMethodCallHandler { call, result ->
            if (call.method == "selecionarFotoPerfil") {
                resultadoPendenteFoto?.success(null)
                resultadoPendenteFoto = result
                try {
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "image/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(
                        Intent.createChooser(intent, "Selecionar foto de perfil"),
                        CODIGO_SELECIONAR_FOTO
                    )
                } catch (_: Exception) {
                    resultadoPendenteFoto = null
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL_AUTENTICACAO_NATIVA
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "solicitarIdTokenGoogle" -> {
                    val webClientId = call.argument<String>("webClientId")?.trim().orEmpty()
                    if (webClientId.isEmpty()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    resultadoPendenteAuthGoogle?.success(null)
                    resultadoPendenteAuthGoogle = result
                    try {
                        val opcoes = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestEmail()
                            .requestProfile()
                            .requestIdToken(webClientId)
                            .build()
                        val cliente = GoogleSignIn.getClient(this, opcoes)
                        cliente.signOut().addOnCompleteListener {
                            try {
                                startActivityForResult(cliente.signInIntent, CODIGO_LOGIN_GOOGLE)
                            } catch (_: Exception) {
                                val pendente = resultadoPendenteAuthGoogle
                                resultadoPendenteAuthGoogle = null
                                pendente?.success(null)
                            }
                        }
                    } catch (_: Exception) {
                        resultadoPendenteAuthGoogle = null
                        result.success(null)
                    }
                }
                "solicitarIdTokenApple" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CODIGO_SELECIONAR_FOTO) {
            val callback = resultadoPendenteFoto
            resultadoPendenteFoto = null
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                callback?.success(null)
                return
            }
            try {
                val uri = data.data!!
                val bitmapOriginal = contentResolver.openInputStream(uri)?.use { stream ->
                    BitmapFactory.decodeStream(stream)
                }
                if (bitmapOriginal == null) {
                    callback?.success(null)
                    return
                }
                val lado = min(bitmapOriginal.width, bitmapOriginal.height)
                val x = (bitmapOriginal.width - lado) / 2
                val y = (bitmapOriginal.height - lado) / 2
                val quadrado = Bitmap.createBitmap(bitmapOriginal, x, y, lado, lado)
                val redimensionado = Bitmap.createScaledBitmap(
                    quadrado,
                    TAMANHO_AVATAR_PX,
                    TAMANHO_AVATAR_PX,
                    true
                )
                val saida = ByteArrayOutputStream()
                redimensionado.compress(Bitmap.CompressFormat.JPEG, 82, saida)
                callback?.success(saida.toByteArray())
            } catch (_: Exception) {
                callback?.success(null)
            }
        } else if (requestCode == CODIGO_LOGIN_GOOGLE) {
            val callback = resultadoPendenteAuthGoogle
            resultadoPendenteAuthGoogle = null
            val tarefa = GoogleSignIn.getSignedInAccountFromIntent(data)
            try {
                val conta = tarefa.getResult(ApiException::class.java)
                val token = conta.idToken
                if (token.isNullOrBlank()) {
                    callback?.success(null)
                } else {
                    callback?.success(
                        mapOf(
                            "idToken" to token,
                            "nomeExibicao" to conta.displayName,
                            "fotoUrl" to conta.photoUrl?.toString(),
                            "cancelado" to false
                        )
                    )
                }
            } catch (e: ApiException) {
                if (e.statusCode == GoogleSignInStatusCodes.SIGN_IN_CANCELLED ||
                    resultCode == Activity.RESULT_CANCELED
                ) {
                    callback?.success(mapOf("cancelado" to true))
                } else {
                    callback?.success(null)
                }
            } catch (_: Exception) {
                callback?.success(null)
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
