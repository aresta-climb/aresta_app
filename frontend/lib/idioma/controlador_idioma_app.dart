// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modelo_idioma_app.dart';

/// Gerenciador reativo global do idioma selecionado pelo usuário no Aresta Climb.
///
/// Mantém o [IdiomaApp] ativo em memória ([notificadorIdioma]), notifica instantaneamente
/// toda a árvore de interface gráfica via [EscopoIdiomaApp] / [ValueListenable] e persiste
/// a escolha localmente em [SharedPreferences] para funcionamento 100% offline.
class ControladorIdiomaApp {
  /// Chave de armazenamento local em [SharedPreferences].
  static const String chavePreferenciaIdioma = 'idioma_app_selecionado';

  static final ControladorIdiomaApp instancia = ControladorIdiomaApp._interno();

  ControladorIdiomaApp._interno()
    : notificadorIdioma = ValueNotifier<IdiomaApp>(IdiomaApp.portugues);

  /// Construtor isolado para testes determinísticos de persistência e reatividade.
  @visibleForTesting
  ControladorIdiomaApp.criarIsolado({
    IdiomaApp idiomaInicial = IdiomaApp.portugues,
  }) : notificadorIdioma = ValueNotifier<IdiomaApp>(idiomaInicial);

  /// Notificador reativo observado pelas telas, abas, modais e ViewModels.
  final ValueNotifier<IdiomaApp> notificadorIdioma;

  /// Idioma atualmente ativo em todo o aplicativo.
  IdiomaApp get idiomaAtual => notificadorIdioma.value;

  /// Carrega o idioma salvo no dispositivo durante o Cold Start.
  Future<void> carregarDoDisco({SharedPreferences? prefsInjetado}) async {
    final prefs = prefsInjetado ?? await SharedPreferences.getInstance();
    final codigoSalvo = prefs.getString(chavePreferenciaIdioma);
    final resolvido = IdiomaApp.deCodigoIso(codigoSalvo);
    if (notificadorIdioma.value != resolvido) {
      notificadorIdioma.value = resolvido;
    }
  }

  /// Altera imediatamente o idioma ativo em toda a interface e persiste a preferência.
  Future<void> definirIdioma(
    IdiomaApp novoIdioma, {
    SharedPreferences? prefsInjetado,
  }) async {
    if (notificadorIdioma.value != novoIdioma) {
      notificadorIdioma.value = novoIdioma;
    }
    final prefs = prefsInjetado ?? await SharedPreferences.getInstance();
    await prefs.setString(chavePreferenciaIdioma, novoIdioma.codigoIso);
  }

  /// Alterna ciclicamente para o próximo idioma (`PT -> EN -> ES -> DE -> NL -> PT`).
  Future<IdiomaApp> ciclarProximoIdioma({
    SharedPreferences? prefsInjetado,
  }) async {
    final proximo = idiomaAtual.proximoNaRotacao;
    await definirIdioma(proximo, prefsInjetado: prefsInjetado);
    return proximo;
  }

  /// Restaura sincronamente para Português em tearDown de testes sem exigir I/O assíncrono.
  void restaurarPadraoEmMemoria() {
    if (notificadorIdioma.value != IdiomaApp.portugues) {
      notificadorIdioma.value = IdiomaApp.portugues;
    }
  }
}

/// Provedor reativo de árvore ([InheritedNotifier]) que reconstrói automaticamente qualquer
/// widget consumidor sempre que o idioma do aplicativo for alterado.
class EscopoIdiomaApp extends InheritedNotifier<ValueListenable<IdiomaApp>> {
  const EscopoIdiomaApp({
    super.key,
    required ValueListenable<IdiomaApp> notificador,
    required super.child,
  }) : super(notifier: notificador);

  /// Inscreve [context] nas mudanças de idioma quando presente na árvore, recorrendo
  /// de forma transparente à instância global em testes unitários de widgets isolados.
  static IdiomaApp observar(BuildContext context) {
    final escopo =
        context.dependOnInheritedWidgetOfExactType<EscopoIdiomaApp>();
    return escopo?.notifier?.value ?? ControladorIdiomaApp.instancia.idiomaAtual;
  }
}
