import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Widget de controle mestre (Wrapper) de versão do aplicativo.
///
/// Este widget deve englobar a raiz da aplicação (geralmente abaixo de `MaterialApp`).
/// Sua função é consultar a versão atual do build via `PackageInfo` e checar contra os
/// requisitos do Firebase `RemoteConfigService`.
///
/// Baseado na versão atual, ele pode:
/// - Bloquear toda a UI exibindo uma tela crítica de interrupção (Hard Block) se
///   a versão for menor que a `hard_min_version`.
/// - Mostrar um banner permanente laranja (Soft Block UI) recomendando fortemente
///   a atualização, se a versão for menor que a `soft_min_version` (sendo que as lógicas
///   de background também bloquearão os downloads na camada de rede).
/// - Mostrar um banner permanente azul sugerindo atualização caso exista uma
///   `recommended_version`.
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
  static String getStoreUrl(RemoteConfigService remoteConfig, {required bool isIOS}) {
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
  bool _isLoading = true;
  bool _isRecommendedBannerClosed = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  /// Carrega as informações do pacote do aplicativo instaladas localmente para
  /// descobrir o número de versão/build real do usuário. Se falhar, assume build 0.
  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final remoteConfig =
          widget.remoteConfigService ?? RemoteConfigService.instance;
      await remoteConfig.initialize();

      final hardMinVersion = remoteConfig.hardMinVersion;
      final softMinVersion = remoteConfig.softMinVersion;
      final recommendedVersion = remoteConfig.recommendedVersion;

      if (hardMinVersion > 0 && buildNumber < hardMinVersion) {
        TelemetryService.instance.logAppVersionHardBlock();
      } else if (softMinVersion > 0 && buildNumber < softMinVersion) {
        TelemetryService.instance.logAppVersionSoftBlock();
      } else if (recommendedVersion > 0 && buildNumber < recommendedVersion) {
        TelemetryService.instance.logAppVersionRecommendedUpdate();
      }

      if (mounted) {
        setState(() {
          _currentBuildNumber = buildNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  /// Abre a loja de aplicativos correta baseado no sistema operacional do dispositivo.
  /// Usuário é redirecionado para a App Store no iOS ou Play Store no Android.
  void _launchStore() {
    final remoteConfig = widget.remoteConfigService ?? RemoteConfigService.instance;
    final url = AppVersionChecker.getStoreUrl(remoteConfig, isIOS: Platform.isIOS);
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ColoredBox(color: Colors.black);
    }

    final remoteConfig =
        widget.remoteConfigService ?? RemoteConfigService.instance;
    final hardMinVersion = remoteConfig.hardMinVersion;
    final softMinVersion = remoteConfig.softMinVersion;
    final recommendedVersion = remoteConfig.recommendedVersion;

    if (hardMinVersion > 0 && _currentBuildNumber < hardMinVersion) {
      return Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Atualização Necessária',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sua versão do aplicativo é muito antiga e não é mais suportada. Por favor, atualize para continuar.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _launchStore,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Atualizar Agora'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    bool showSoftBanner =
        softMinVersion > 0 && _currentBuildNumber < softMinVersion;
    bool showRecBanner =
        !showSoftBanner &&
        recommendedVersion > 0 &&
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
