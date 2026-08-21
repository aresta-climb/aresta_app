import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Widget de controle mestre e não-bloqueante de versão do aplicativo.
///
/// Este widget engloba a raiz da aplicação (abaixo de `MaterialApp`).
/// Sua função é consultar a versão local instalada via `PackageInfo` e checar contra os
/// requisitos do Firebase `RemoteConfigService` de forma totalmente assíncrona e reativa.
///
/// Seguindo os princípios de engenharia *offline-first*:
/// - A interface gráfica (`child`) é renderizada imediatamente no primeiro frame sem bloqueio de rede.
/// - O `RemoteConfigService` é ouvido de forma reativa (`ChangeNotifier`); quando novas regras chegam em
///   segundo plano, o widget atualiza a UI sem travar o aplicativo.
///
/// Baseado na versão atual, ele pode:
/// - Bloquear a UI exibindo uma tela crítica de interrupção (Hard Block) se a versão for menor que a `hard_min_version`.
/// - Mostrar um banner permanente laranja (Soft Block UI) recomendando a atualização se a versão for menor que `soft_min_version`.
/// - Mostrar um banner azul sugerindo atualização caso exista uma `recommended_version`.
class AppVersionChecker extends StatefulWidget {
  final Widget child;
  final RemoteConfigService? remoteConfigService;

  const AppVersionChecker({
    super.key,
    required this.child,
    this.remoteConfigService,
  });

  @override
  State<AppVersionChecker> createState() => _AppVersionCheckerState();

  @visibleForTesting
  static String getStoreUrl(
    RemoteConfigService remoteConfig, {
    required bool isIOS,
  }) {
    if (isIOS) {
      return remoteConfig.storeUrlIos.isNotEmpty
          ? remoteConfig.storeUrlIos
          : 'https://apps.apple.com/app/idXXXXXXXXX';
    } else {
      return 'market://details?id=app.escalada.croquis';
    }
  }
}

class _AppVersionCheckerState extends State<AppVersionChecker> {
  int _currentBuildNumber = 0;
  bool _isRecommendedBannerClosed = false;
  RemoteConfigService? _effectiveRemoteConfig;

  @override
  void initState() {
    super.initState();
    _effectiveRemoteConfig =
        widget.remoteConfigService ?? RemoteConfigService.instance;
    _effectiveRemoteConfig?.addListener(_onRemoteConfigChanged);

    // Dispara a inicialização/fetch em segundo plano sem travar a interface
    _effectiveRemoteConfig?.initialize();

    // Carrega o build number local de forma assíncrona
    _loadPackageInfo();
  }

  @override
  void didUpdateWidget(covariant AppVersionChecker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRemoteConfig =
        widget.remoteConfigService ?? RemoteConfigService.instance;
    if (_effectiveRemoteConfig != newRemoteConfig) {
      _effectiveRemoteConfig?.removeListener(_onRemoteConfigChanged);
      _effectiveRemoteConfig = newRemoteConfig;
      _effectiveRemoteConfig?.addListener(_onRemoteConfigChanged);
    }
  }

  @override
  void dispose() {
    _effectiveRemoteConfig?.removeListener(_onRemoteConfigChanged);
    super.dispose();
  }

  void _onRemoteConfigChanged() {
    if (mounted) {
      _checkAndLogTelemetry();
      setState(() {});
    }
  }

  /// Carrega as informações do pacote instaladas localmente no SO.
  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (mounted) {
        setState(() {
          _currentBuildNumber = buildNumber;
        });
        _checkAndLogTelemetry();
      }
    } catch (_) {
      // Falhas ao ler PackageInfo mantêm buildNumber como 0 de forma segura
    }
  }

  void _checkAndLogTelemetry() {
    if (_currentBuildNumber <= 0) return;

    final remoteConfig =
        _effectiveRemoteConfig ?? RemoteConfigService.instance;
    final hardMinVersion = remoteConfig.hardMinVersion;
    final softMinVersion = remoteConfig.softMinVersion;
    final recommendedVersion = remoteConfig.recommendedVersion;

    if (hardMinVersion > 0 && _currentBuildNumber < hardMinVersion) {
      TelemetryService.instance.logAppVersionHardBlock();
    } else if (softMinVersion > 0 && _currentBuildNumber < softMinVersion) {
      TelemetryService.instance.logAppVersionSoftBlock();
    } else if (recommendedVersion > 0 && _currentBuildNumber < recommendedVersion) {
      TelemetryService.instance.logAppVersionRecommendedUpdate();
    }
  }

  /// Abre a loja de aplicativos correta baseado no sistema operacional do dispositivo.
  void _launchStore() {
    final remoteConfig =
        _effectiveRemoteConfig ?? RemoteConfigService.instance;
    final url = AppVersionChecker.getStoreUrl(
      remoteConfig,
      isIOS: Platform.isIOS,
    );
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig =
        _effectiveRemoteConfig ?? RemoteConfigService.instance;
    final hardMinVersion = remoteConfig.hardMinVersion;
    final softMinVersion = remoteConfig.softMinVersion;
    final recommendedVersion = remoteConfig.recommendedVersion;

    // Se for exigida atualização crítica (Hard Block), substitui a visualização pelo bloqueio total
    if (hardMinVersion > 0 &&
        _currentBuildNumber > 0 &&
        _currentBuildNumber < hardMinVersion) {
      return AppVersionHardBlockScreen(onUpdatePressed: _launchStore);
    }

    final bool showSoftBanner =
        softMinVersion > 0 &&
        _currentBuildNumber > 0 &&
        _currentBuildNumber < softMinVersion;

    final bool showRecBanner =
        !showSoftBanner &&
        recommendedVersion > 0 &&
        _currentBuildNumber > 0 &&
        _currentBuildNumber < recommendedVersion &&
        !_isRecommendedBannerClosed;

    Widget content = widget.child;

    if (showSoftBanner || showRecBanner) {
      content = Column(
        children: [
          Material(
            color: showSoftBanner
                ? Colors.orange.shade800
                : Colors.blue.shade800,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    if (showSoftBanner)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRecommendedBannerClosed = true;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        showSoftBanner
                            ? 'Atualize o Aresta para voltar a baixar e sincronizar croquis.'
                            : 'Atualização Recomendada: uma nova versão está disponível.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _launchStore,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('ATUALIZAR'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}

/// Widget standalone da tela de bloqueio duro, extraído para permitir testes manuais e modularidade.
class AppVersionHardBlockScreen extends StatelessWidget {
  final VoidCallback onUpdatePressed;

  const AppVersionHardBlockScreen({super.key, required this.onUpdatePressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ATUALIZAÇÃO\nNECESSÁRIA',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sua versão do Aresta é muito antiga e não é mais suportada. Para continuar usando o app e explorando croquis, por favor, atualize-o na loja.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: onUpdatePressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ATUALIZAR AGORA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
