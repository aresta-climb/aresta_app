// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase/app_logger.dart';

/// Gerencia o ciclo de vida das notificações nativas de download do sistema operacional,
/// suportando Foreground Services ininterruptos e sticky no Android,
/// transição atômica para notificações dispensáveis de conclusão e suporte a iOS.
class GerenciadorNotificacaoDownload {
  static const String canalProgressoId = 'downloads_croquis';
  static const String canalProgressoNome = 'Downloads de Croquis';
  static const String canalProgressoDescricao =
      'Notificações de progresso do download de croquis offline';

  static const String canalConclusaoId = 'downloads_concluidos';
  static const String canalConclusaoNome = 'Conclusão de Downloads';
  static const String canalConclusaoDescricao =
      'Notificações de conclusão ou falha de downloads de croquis';

  static const String iconePequeno = '@mipmap/ic_launcher';
  static const String iconeBitmapRaster = 'ic_launcher_foreground';
  static const String nomeApp = 'Aresta Climb';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Instância compartilhada do gerenciador de notificações.
  static GerenciadorNotificacaoDownload? _instancia;

  /// Retorna a instância padrão do gerenciador de notificações.
  static GerenciadorNotificacaoDownload get instancia {
    _instancia ??= GerenciadorNotificacaoDownload();
    return _instancia!;
  }

  /// Permite sobrescrever a instância padrão (útil para testes unitários).
  @visibleForTesting
  static set instancia(GerenciadorNotificacaoDownload? custom) {
    _instancia = custom;
  }

  GerenciadorNotificacaoDownload({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin de notificações nativas e registra os canais necessários.
  Future<bool> inicializar() async {
    try {
      const androidSettings = AndroidInitializationSettings(iconePequeno);
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      final inicializado = await _plugin.initialize(settings: settings);

      // Registra os canais no Android
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Canal de progresso: importância baixa para não emitir sons contínuos
        const canalProgresso = AndroidNotificationChannel(
          canalProgressoId,
          canalProgressoNome,
          description: canalProgressoDescricao,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(canalProgresso);

        // Canal de conclusão: totalmente silencioso sem som nem vibração
        const canalConclusao = AndroidNotificationChannel(
          canalConclusaoId,
          canalConclusaoNome,
          description: canalConclusaoDescricao,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(canalConclusao);
      }

      return inicializado ?? true;
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao inicializar notificações',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

  /// Solicita permissões de envio de notificação ao usuário nas plataformas suportadas.
  Future<bool> solicitarPermissoes() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final permitido = await androidPlugin.requestNotificationsPermission();
        return permitido ?? true;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final permitido = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        );
        return permitido ?? true;
      }

      return true;
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao solicitar permissões',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

  final Set<int> _servicosAtivos = {};

  /// Gera um identificador numérico estável e positivo de 32 bits a partir do [picoId].
  int calcularIdNotificacao(String picoId) {
    return (picoId.hashCode & 0x7FFFFFFF) % 100000;
  }

  /// Emite ou atualiza uma notificação contínua sticky (`ongoing: true`) com barra de progresso,
  /// ativando o Foreground Service no Android.
  Future<void> atualizarProgresso(
    String picoId,
    String nomePico,
    double progresso,
  ) async {
    try {
      final id = calcularIdNotificacao(picoId);
      final progressoInt = (progresso * 100).clamp(0, 100).toInt();

      final androidDetails = AndroidNotificationDetails(
        canalProgressoId,
        canalProgressoNome,
        channelDescription: canalProgressoDescricao,
        subText: nomeApp,
        icon: iconePequeno,
        largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster),
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Sticky
        showProgress: true,
        maxProgress: 100,
        progress: progressoInt,
        onlyAlertOnce: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        silent: true,
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        if (!_servicosAtivos.contains(id)) {
          _servicosAtivos.add(id);
          await androidPlugin.startForegroundService(
            id: id,
            title: nomePico,
            body: 'Baixando... $progressoInt%',
            notificationDetails: androidDetails,
            foregroundServiceTypes: {
              AndroidServiceForegroundType.foregroundServiceTypeDataSync,
            },
          );
        } else {
          // Atualiza a notificação existente sem reenviar intent de inicialização do serviço no background
          await _plugin.show(
            id: id,
            title: nomePico,
            body: 'Baixando... $progressoInt%',
            notificationDetails: NotificationDetails(android: androidDetails),
          );
        }
      } else {
        final darwinDetails = DarwinNotificationDetails(
          subtitle: 'Baixando... $progressoInt%',
          presentSound: false,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        );

        await _plugin.show(
            id: id,
            title: nomePico,
            body: 'Baixando... $progressoInt%',
            notificationDetails: notificationDetails);
      }
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao atualizar progresso',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Transita a notificação para o estado concluído de sucesso,
  /// finalizando o Foreground Service e exibindo uma notificação dispensável (`ongoing: false`).
  Future<void> notificarConclusao(
    String picoId,
    String nomePico,
  ) async {
    try {
      final id = calcularIdNotificacao(picoId);
      _servicosAtivos.remove(id);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null && _servicosAtivos.isEmpty) {
        await androidPlugin.stopForegroundService();
      }

      // Cancela a notificação sticky anterior
      await _plugin.cancel(id: id);

      final androidDetails = AndroidNotificationDetails(
        canalConclusaoId,
        canalConclusaoNome,
        channelDescription: canalConclusaoDescricao,
        subText: nomeApp,
        icon: iconePequeno,
        largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster),
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false, // Pode ser limpa (clearable)
        autoCancel: true, // Desaparece ao clicar
        showProgress: false, // Remove a barra de progresso
        playSound: false,
        enableVibration: false,
        silent: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentSound: false,
        presentAlert: true,
        presentBadge: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: id,
        title: nomePico,
        body: '✓ Croqui salvo para uso offline.',
        notificationDetails: notificationDetails,
      );
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao notificar conclusão',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Transita a notificação para estado de erro caso o download falhe,
  /// finalizando o Foreground Service.
  Future<void> notificarFalha(
    String picoId,
    String nomePico, [
    String? motivo,
  ]) async {
    try {
      final id = calcularIdNotificacao(picoId);
      _servicosAtivos.remove(id);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null && _servicosAtivos.isEmpty) {
        await androidPlugin.stopForegroundService();
      }

      // Cancela a notificação contínua sticky anterior
      await _plugin.cancel(id: id);

      final androidDetails = AndroidNotificationDetails(
        canalConclusaoId,
        canalConclusaoNome,
        channelDescription: canalConclusaoDescricao,
        subText: nomeApp,
        icon: iconePequeno,
        largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster),
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false,
        autoCancel: true,
        showProgress: false,
        playSound: false,
        enableVibration: false,
        silent: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentSound: false,
        presentAlert: true,
        presentBadge: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: id,
        title: nomePico,
        body: motivo ?? 'Falha ao baixar croqui. Verifique sua conexão.',
        notificationDetails: notificationDetails,
      );
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao notificar falha',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Cancela e remove a notificação da bandeja do sistema operacional e para o Foreground Service.
  Future<void> cancelar(String picoId) async {
    try {
      final id = calcularIdNotificacao(picoId);
      _servicosAtivos.remove(id);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null && _servicosAtivos.isEmpty) {
        await androidPlugin.stopForegroundService();
      }

      await _plugin.cancel(id: id);
    } catch (e, stackTrace) {
      if (!e.toString().contains('LateInitializationError')) {
        AppLogger.instance.logError(
          '[GerenciadorNotificacaoDownload] Erro ao cancelar notificação',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
