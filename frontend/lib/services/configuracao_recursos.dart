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
