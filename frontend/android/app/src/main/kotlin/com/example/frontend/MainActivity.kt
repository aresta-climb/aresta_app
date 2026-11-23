// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

package com.example.frontend

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.drawable.ColorDrawable
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.UUID
import kotlin.math.min

class MainActivity : FlutterActivity() {
    companion object {
        private const val CANAL_CICLO_VIDA = "app.escalada.croquis/ciclo_vida"
        private const val CANAL_SELETOR_MIDIA = "app.escalada.croquis/seletor_midia"
        private const val CANAL_AUTENTICACAO_NATIVA = "app.escalada.croquis/autenticacao_nativa"
        private const val CODIGO_SELECIONAR_FOTO = 9401
        private const val TAMANHO_AVATAR_PX = 256
    }

    private var resultadoPendenteFoto: MethodChannel.Result? = null
    private var resultadoPendenteOAuthPkce: MethodChannel.Result? = null
    private var esquemaCallbackOAuthPendente: String = "aresta"
    private var jaSaiuParaNavegadorOAuth: Boolean = false
    private val escopoPrincipal = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /**
     * Registra o canal nativo de ciclo de vida para permitir que o Flutter mova
     * a tarefa para segundo plano (`moveTaskToBack`) ao pressionar Voltar na raiz
     * da tela inicial (`HomeNode`), preservando a `MainActivity` e a `FlutterEngine`
     * vivas em memória em vez de destruí-las com `Activity.finish()`.
     * Também registra os canais nativos de seleção de foto e autenticação via CredentialManager.
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
                    val urlAutorizacaoPkce = call.argument<String>("urlAutorizacaoPkce")?.trim().orEmpty()
                    val esquemaCallback = call.argument<String>("esquemaCallback")?.trim()
                        ?.takeIf { it.isNotEmpty() } ?: "aresta"
                    if (webClientId.isEmpty() && urlAutorizacaoPkce.isEmpty()) {
                        result.success(mapOf("erro" to "webClientId ausente"))
                        return@setMethodCallHandler
                    }
                    if (BuildConfig.ARESTA_SMOKE_CI && ehEmuladorAndroid()) {
                        val cfgSmoke = extrairConfiguracaoSmokeValida()
                        if (cfgSmoke != null) {
                            solicitarIdTokenLoopbackSmoke(cfgSmoke.first, webClientId, result)
                            return@setMethodCallHandler
                        }
                    }
                    iniciarLoginNativoGoogle(
                        webClientId = webClientId,
                        urlAutorizacaoPkce = urlAutorizacaoPkce,
                        esquemaCallback = esquemaCallback,
                        result = result
                    )
                }
                "solicitarIdTokenApple" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        if (BuildConfig.ARESTA_SMOKE_CI && ehEmuladorAndroid()) {
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "app.escalada.croquis/smoke_ci"
            ).setMethodCallHandler { call, result ->
                if (call.method == "obterConfiguracaoSmoke") {
                    val cfg = extrairConfiguracaoSmokeValida()
                    if (cfg != null) {
                        result.success(
                            mapOf(
                                "ativo" to true,
                                "servidorUrl" to cfg.first,
                                "token" to cfg.second
                            )
                        )
                    } else {
                        result.success(mapOf("ativo" to false))
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        val uri = intent.data
        val callbackOAuth = resultadoPendenteOAuthPkce
        if (callbackOAuth != null &&
            uri != null &&
            uri.scheme.equals(esquemaCallbackOAuthPendente, ignoreCase = true)
        ) {
            limparEstadoOAuthPkce()
            callbackOAuth.success(
                mapOf(
                    "callbackUrl" to uri.toString(),
                    "cancelado" to false
                )
            )
            return
        }
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onPause() {
        super.onPause()
        if (resultadoPendenteOAuthPkce != null) {
            jaSaiuParaNavegadorOAuth = true
        }
    }

    override fun onResume() {
        super.onResume()
        if (resultadoPendenteOAuthPkce != null && jaSaiuParaNavegadorOAuth) {
            window.decorView.postDelayed({
                val pendente = resultadoPendenteOAuthPkce
                if (pendente != null && jaSaiuParaNavegadorOAuth) {
                    limparEstadoOAuthPkce()
                    pendente.success(mapOf("cancelado" to true))
                }
            }, 250L)
        }
    }

    private fun limparEstadoOAuthPkce() {
        resultadoPendenteOAuthPkce = null
        jaSaiuParaNavegadorOAuth = false
    }

    private fun ehEmuladorAndroid(): Boolean {
        return Build.FINGERPRINT.contains("generic", ignoreCase = true) ||
            Build.HARDWARE.contains("ranchu", ignoreCase = true) ||
            Build.HARDWARE.contains("goldfish", ignoreCase = true) ||
            Build.PRODUCT.contains("sdk_gphone", ignoreCase = true) ||
            Build.MODEL.contains("Emulator", ignoreCase = true) ||
            Build.MODEL.contains("Android SDK built for", ignoreCase = true)
    }

    private fun extrairConfiguracaoSmokeValida(): Pair<String, String>? {
        val srvBruto = intent?.getStringExtra("smoke_server")?.trim()?.trimEnd('/').orEmpty()
        val tokBruto = intent?.getStringExtra("smoke_token")?.trim().orEmpty()
        if (srvBruto.isEmpty() || tokBruto.isEmpty()) return null
        return try {
            val uri = URI(srvBruto)
            val host = uri.host?.lowercase().orEmpty()
            val hostsLoopback = setOf("10.0.2.2", "127.0.0.1", "localhost")
            if (uri.scheme == "http" && uri.port > 0 && hostsLoopback.contains(host)) {
                Pair("http://$host:${uri.port}", tokBruto)
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun solicitarIdTokenLoopbackSmoke(
        servidorUrl: String,
        webClientId: String,
        result: MethodChannel.Result
    ) {
        escopoPrincipal.launch {
            try {
                val mapa = withContext(Dispatchers.IO) {
                    val rawNonce = UUID.randomUUID().toString().replace("-", "")
                    val url = URL("$servidorUrl/__smoke__/oidc-token")
                    val conn = (url.openConnection() as HttpURLConnection).apply {
                        requestMethod = "POST"
                        connectTimeout = 5000
                        readTimeout = 5000
                        doOutput = true
                        setRequestProperty("Content-Type", "application/json")
                    }
                    val payloadReq = JSONObject().apply {
                        put("rawNonce", rawNonce)
                        put("webClientId", webClientId)
                    }.toString()
                    conn.outputStream.use { it.write(payloadReq.toByteArray(Charsets.UTF_8)) }
                    val codigo = conn.responseCode
                    val texto = (if (codigo in 200..299) conn.inputStream else conn.errorStream)
                        ?.bufferedReader(Charsets.UTF_8)
                        ?.use { it.readText() }
                        .orEmpty()
                    if (codigo !in 200..299) {
                        mapOf("erro" to "HTTP $codigo: $texto")
                    } else {
                        val json = JSONObject(texto)
                        mapOf(
                            "idToken" to json.optString("idToken"),
                            "nonce" to json.optString("nonce", rawNonce),
                            "nomeExibicao" to json.optString("nomeExibicao", "Escalador Smoke CI"),
                            "cancelado" to false
                        )
                    }
                }
                result.success(mapa)
            } catch (e: Exception) {
                result.success(mapOf("erro" to (e.message ?: e.javaClass.simpleName)))
            }
        }
    }

    private fun iniciarLoginNativoGoogle(
        webClientId: String,
        urlAutorizacaoPkce: String,
        esquemaCallback: String,
        result: MethodChannel.Result
    ) {
        val contexto = this
        escopoPrincipal.launch {
            try {
                if (webClientId.isEmpty()) {
                    throw IllegalStateException("webClientId ausente")
                }
                val opcaoGoogle = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(webClientId)
                    .setAutoSelectEnabled(false)
                    .build()
                val requisicao = GetCredentialRequest.Builder()
                    .addCredentialOption(opcaoGoogle)
                    .build()

                val gerenciador = CredentialManager.create(contexto)
                val resposta = gerenciador.getCredential(
                    request = requisicao,
                    context = contexto
                )

                val credencial = resposta.credential
                if (credencial is CustomCredential &&
                    credencial.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
                ) {
                    val tokenGoogle = GoogleIdTokenCredential.createFrom(credencial.data)
                    result.success(
                        mapOf(
                            "idToken" to tokenGoogle.idToken,
                            "nomeExibicao" to tokenGoogle.displayName,
                            "fotoUrl" to tokenGoogle.profilePictureUri?.toString(),
                            "cancelado" to false
                        )
                    )
                } else {
                    result.success(mapOf("erro" to "Credencial inesperada: ${credencial.type}"))
                }
            } catch (_: GetCredentialCancellationException) {
                result.success(mapOf("cancelado" to true))
            } catch (e: Exception) {
                // Em emuladores sem conta Google no SO, ROMs sem Play Services ou builds locais de debug
                // sem SHA-1 cadastrado no Google Cloud Console, realiza fluxo OAuth PKCE via Custom Tabs.
                if (urlAutorizacaoPkce.isNotEmpty()) {
                    iniciarSessaoWebGooglePkce(
                        urlAutorizacaoPkce = urlAutorizacaoPkce,
                        esquemaCallback = esquemaCallback,
                        erroAnterior = e,
                        result = result
                    )
                } else {
                    result.success(mapOf("erro" to (e.message ?: e.javaClass.simpleName)))
                }
            }
        }
    }

    private fun iniciarSessaoWebGooglePkce(
        urlAutorizacaoPkce: String,
        esquemaCallback: String,
        erroAnterior: Exception,
        result: MethodChannel.Result
    ) {
        try {
            resultadoPendenteOAuthPkce?.success(mapOf("cancelado" to true))
            resultadoPendenteOAuthPkce = result
            esquemaCallbackOAuthPendente = esquemaCallback
            jaSaiuParaNavegadorOAuth = false

            val uriAuth = Uri.parse(urlAutorizacaoPkce)
            val intentCustomTab = Intent(Intent.ACTION_VIEW, uriAuth).apply {
                val extras = Bundle()
                extras.putBinder("android.support.customtabs.extra.SESSION", null)
                putExtras(extras)
            }
            startActivity(intentCustomTab)
        } catch (_: Exception) {
            limparEstadoOAuthPkce()
            result.success(mapOf("erro" to (erroAnterior.message ?: erroAnterior.javaClass.simpleName)))
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
                val bytesOriginais = contentResolver.openInputStream(uri)?.use { stream ->
                    stream.readBytes()
                }
                if (bytesOriginais == null || bytesOriginais.isEmpty()) {
                    callback?.success(null)
                    return
                }
                val bitmapDecodificado = BitmapFactory.decodeByteArray(
                    bytesOriginais,
                    0,
                    bytesOriginais.size
                )
                if (bitmapDecodificado == null) {
                    callback?.success(null)
                    return
                }
                val bitmapOrientado = corrigirOrientacaoExif(bytesOriginais, bitmapDecodificado)
                val lado = min(bitmapOrientado.width, bitmapOrientado.height)
                val x = (bitmapOrientado.width - lado) / 2
                val y = (bitmapOrientado.height - lado) / 2
                val quadrado = Bitmap.createBitmap(bitmapOrientado, x, y, lado, lado)
                val redimensionado = Bitmap.createScaledBitmap(
                    quadrado,
                    TAMANHO_AVATAR_PX,
                    TAMANHO_AVATAR_PX,
                    true
                )
                val saida = ByteArrayOutputStream()
                val formatoWebp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    Bitmap.CompressFormat.WEBP_LOSSY
                } else {
                    @Suppress("DEPRECATION")
                    Bitmap.CompressFormat.WEBP
                }
                redimensionado.compress(formatoWebp, 82, saida)
                callback?.success(saida.toByteArray())
            } catch (_: Exception) {
                callback?.success(null)
            }
        }
    }

    /**
     * Lê o metadado EXIF `TAG_ORIENTATION` dos bytes originais da foto e aplica a matriz
     * de rotação/espelhamento correspondente para evitar que fotos da câmera em modo
     * retrato fiquem tombadas em 90 graus após `BitmapFactory.decodeByteArray`.
     */
    private fun corrigirOrientacaoExif(bytesOriginais: ByteArray, bitmap: Bitmap): Bitmap {
        return try {
            val exif = ExifInterface(ByteArrayInputStream(bytesOriginais))
            val orientacao = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
            val matriz = Matrix()
            when (orientacao) {
                ExifInterface.ORIENTATION_ROTATE_90 -> matriz.postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matriz.postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> matriz.postRotate(270f)
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matriz.postScale(-1f, 1f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> matriz.postScale(1f, -1f)
                ExifInterface.ORIENTATION_TRANSPOSE -> {
                    matriz.postRotate(90f)
                    matriz.postScale(-1f, 1f)
                }
                ExifInterface.ORIENTATION_TRANSVERSE -> {
                    matriz.postRotate(270f)
                    matriz.postScale(-1f, 1f)
                }
                else -> return bitmap
            }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matriz, true)
        } catch (_: Exception) {
            bitmap
        }
    }

    /**
     * Altera o fundo da janela nativa para a cor escura do tema (`#181312` deepBasalt)
     * assim que a atividade vai para segundo plano pela primeira vez.
     */
    override fun onStop() {
        super.onStop()
        window.setBackgroundDrawable(ColorDrawable(0xFF181312.toInt()))
    }

    override fun onDestroy() {
        escopoPrincipal.cancel()
        super.onDestroy()
    }
}
