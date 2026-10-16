// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';

/// Gerencia a ativação e bloqueio de funcionalidades e recursos em desenvolvimento
/// no aplicativo Aresta, permitindo ocultá-los por padrão em compilações de produção
/// e liberá-los exclusivamente mediante chaves de acesso ou flags de compilação.
///
/// ### Configuração em Linha de Comando:
/// É possível desbloquear o Perfil e a Caderneta Esportiva via `--dart-define`:
/// ```bash
/// flutter run --dart-define=API_KEY=my_secret_key --dart-define=APP_MODE=production
/// # ou alternativamente:
/// flutter run --dart-define=CHAVE_ACESSO_PERFIL=aresta_segredo_perfil_2026
/// # ou via flag booleana direta:
/// flutter run --dart-define=HABILITAR_PERFIL=true
/// ```
abstract final class ConfiguracaoRecursos {
  /// Nome da variável de ambiente com a chave de acesso do perfil.
  static const String nomeVariavelChavePerfil = 'CHAVE_ACESSO_PERFIL';

  /// Nome alternativo padrão da variável de chave de API / segredo.
  static const String nomeVariavelApiKey = 'API_KEY';

  /// Nome da variável de ambiente booleana para habilitação direta do perfil.
  static const String nomeVariavelHabilitarPerfil = 'HABILITAR_PERFIL';

  /// Nome da variável de ambiente com o modo de execução da aplicação.
  static const String nomeVariavelModoApp = 'APP_MODE';

  /// Conjunto de chaves de acesso secretas reconhecidas e autorizadas.
  static const Set<String> chavesSecretasAutorizadas = {
    'my_secret_key',
    'aresta_segredo_perfil_2026',
    'minha_chave_secreta',
    'aresta_dev_secret',
  };

  /// Chave de acesso extraída em tempo de compilação.
  static const String _chaveCompilada = String.fromEnvironment(
    nomeVariavelChavePerfil,
    defaultValue: String.fromEnvironment(
      nomeVariavelApiKey,
      defaultValue: '',
    ),
  );

  /// Flag booleana de ativação extraída em tempo de compilação.
  static const bool _flagHabilitarCompilada = bool.fromEnvironment(
    nomeVariavelHabilitarPerfil,
    defaultValue: false,
  );

  /// Modo da aplicação configurado em tempo de compilação (ex.: 'production', 'development').
  static const String _modoAppCompilado = String.fromEnvironment(
    nomeVariavelModoApp,
    defaultValue: '',
  );

  /// Modo da aplicação configurado via ambiente.
  static String get modoApp => _modoAppCompilado;

  /// Valor da chave de acesso provida via ambiente de compilação.
  static String get chaveAcessoDefinida => _chaveCompilada;

  /// Variável para sobrescrita em testes unitários e de widget.
  static bool? _sobrescritaPerfilParaTestes;

  /// Define um valor explícito de ativação do perfil durante a execução de testes.
  @visibleForTesting
  static void definirSobrescritaPerfilParaTestes(bool? habilitado) {
    _sobrescritaPerfilParaTestes = habilitado;
  }

  /// Restaura o estado original de configuração após a execução dos testes.
  @visibleForTesting
  static void redefinirParaTestes() {
    _sobrescritaPerfilParaTestes = null;
  }

  /// Verifica se uma determinada chave de acesso textual confere com os segredos autorizados.
  static bool validarChaveAcesso(String? chave) {
    if (chave == null) return false;
    final chaveTratada = chave.trim();
    if (chaveTratada.isEmpty) return false;
    return chavesSecretasAutorizadas.contains(chaveTratada);
  }

  /// Indica se os módulos de Perfil do Escalador e Caderneta Esportiva estão liberados para uso.
  ///
  /// Retorna `false` por padrão em compilações convencionais de produção.
  /// Retorna `true` se:
  /// 1. Uma chave secreta válida foi informada via `--dart-define=API_KEY=...` ou `CHAVE_ACESSO_PERFIL=...`.
  /// 2. A flag booleana `--dart-define=HABILITAR_PERFIL=true` foi definida.
  /// 3. Foi explicitamente habilitado em testes via [definirSobrescritaPerfilParaTestes].
  static bool get perfilHabilitado {
    if (_sobrescritaPerfilParaTestes != null) {
      return _sobrescritaPerfilParaTestes!;
    }
    if (_flagHabilitarCompilada) {
      return true;
    }
    return validarChaveAcesso(_chaveCompilada);
  }
}
