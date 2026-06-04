import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Serviço responsável por gerenciar o Firebase Remote Config.
///
/// O Remote Config permite alterar o comportamento e a aparência do aplicativo
/// sem precisar publicar uma nova atualização nas lojas (App Store/Google Play).
/// É ideal para:
/// - Feature Flags (ativar/desativar novas funcionalidades).
/// - Testes A/B (entregar configurações diferentes para grupos de usuários).
/// - Mensagens de aviso globais.
///
/// ## Como adicionar uma nova flag (Nova Configuração):
/// 1. Adicione a chave e o valor padrão no mapa `setDefaults` dentro do método `initialize()`.
///    Exemplo: `"nova_funcionalidade": false`
/// 2. Crie um novo `getter` tipado no final desta classe para facilitar o acesso na UI.
///    Exemplo: `bool get novaFuncionalidade => getBool('nova_funcionalidade');`
/// 3. No painel do Firebase Console, vá em "Remote Config" e crie um parâmetro com a MESMA chave.
///
/// ## Como usar no código:
/// Acesse a instância global (singleton) do serviço em qualquer lugar:
/// ```dart
/// if (RemoteConfigService.instance.novaFuncionalidade) {
///   // Código da nova funcionalidade
/// }
/// ```
class RemoteConfigService {
  RemoteConfigService._privateConstructor();

  /// Instância singleton global mutável para facilitar injeção de mock nos testes.
  static RemoteConfigService instance =
      RemoteConfigService._privateConstructor();

  late final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Inicializa o serviço definindo os padrões (defaults) e tentando buscar configurações do servidor.
  Future<void> initialize() async {
    try {
      // 1. Definimos os defaults inquebráveis locais (fallback para offline)
      await _remoteConfig.setDefaults(const {
        "flag_de_demonstracao1": false,
        "flag_de_demonstracao2": false,
      });

      // 2. Configurações de timeout e TTL (cache)
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(
            seconds: 10,
          ), // Desiste rápido se internet ruim
          minimumFetchInterval: const Duration(
            hours: 12,
          ), // Usa cache por 12 horas
        ),
      );

      // 3. Tenta buscar no fundo sem travar a interface
      await _remoteConfig.fetchAndActivate();

      if (kDebugMode) {
        print('🔧 [RemoteConfig] Configuração atualizada com sucesso.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '🔧 [RemoteConfig] Falha ao atualizar (offline?). Usando cache/defaults. Erro: $e',
        );
      }
    }
  }

  /// Retorna um valor booleano do Remote Config.
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }

  // ===========================================================================
  // GETTERS TIPADOS (FEATURE FLAGS)
  // Adicione novas flags aqui seguindo o padrão abaixo.
  // ===========================================================================

  /// Indica se a flag de demonstração 1 deve ser ativada.
  bool get flagDeDemonstracao1 => getBool('flag_de_demonstracao1');

  /// Indica se a flag de demonstração 2 deve ser ativada.
  bool get flagDeDemonstracao2 => getBool('flag_de_demonstracao2');
}
