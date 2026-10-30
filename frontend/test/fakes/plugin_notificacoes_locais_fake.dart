// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Registro imutável de uma notificação exibida ou iniciada em primeiro plano pelo Fake.
class RegistroNotificacaoExibida {
  final int id;
  final String? titulo;
  final String? corpo;
  final NotificationDetails? detalhes;
  final AndroidNotificationDetails? detalhesAndroid;
  final Set<AndroidServiceForegroundType>? tiposServicoPrimeiroPlano;

  const RegistroNotificacaoExibida({
    required this.id,
    this.titulo,
    this.corpo,
    this.detalhes,
    this.detalhesAndroid,
    this.tiposServicoPrimeiroPlano,
  });
}

/// Implementação Fake determinística de [AndroidFlutterLocalNotificationsPlugin] para testes.
class ImplementacaoAndroidNotificacoesFake
    implements AndroidFlutterLocalNotificationsPlugin {
  final List<AndroidNotificationChannel> canaisCriados = [];
  final List<RegistroNotificacaoExibida> servicosIniciados = [];
  int chamadasPararServicoPrimeiroPlano = 0;
  int chamadasSolicitarPermissao = 0;

  bool? resultadoPermissao = true;
  Object? erroAoCriarCanal;
  Object? erroAoSolicitarPermissao;
  Object? erroAoIniciarServicoPrimeiroPlano;
  Object? erroAoPararServicoPrimeiroPlano;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    if (erroAoCriarCanal != null) {
      throw erroAoCriarCanal!;
    }
    canaisCriados.add(notificationChannel);
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    if (erroAoSolicitarPermissao != null) {
      throw erroAoSolicitarPermissao!;
    }
    chamadasSolicitarPermissao++;
    return resultadoPermissao;
  }

  @override
  Future<void> startForegroundService({
    required int id,
    String? title,
    String? body,
    AndroidNotificationDetails? notificationDetails,
    String? payload,
    AndroidServiceStartType startType = AndroidServiceStartType.startSticky,
    Set<AndroidServiceForegroundType>? foregroundServiceTypes,
  }) async {
    if (erroAoIniciarServicoPrimeiroPlano != null) {
      throw erroAoIniciarServicoPrimeiroPlano!;
    }
    servicosIniciados.add(
      RegistroNotificacaoExibida(
        id: id,
        titulo: title,
        corpo: body,
        detalhesAndroid: notificationDetails,
        tiposServicoPrimeiroPlano: foregroundServiceTypes,
      ),
    );
  }

  @override
  Future<void> stopForegroundService() async {
    if (erroAoPararServicoPrimeiroPlano != null) {
      throw erroAoPararServicoPrimeiroPlano!;
    }
    chamadasPararServicoPrimeiroPlano++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Implementação Fake determinística de [IOSFlutterLocalNotificationsPlugin] para testes.
class ImplementacaoIOSNotificacoesFake
    implements IOSFlutterLocalNotificationsPlugin {
  int chamadasSolicitarPermissao = 0;
  bool ultimoAlertaSolicitado = false;
  bool ultimoBadgeSolicitado = false;
  bool ultimoSomSolicitado = false;
  bool? resultadoPermissao = true;
  Object? erroAoSolicitarPermissao;

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    if (erroAoSolicitarPermissao != null) {
      throw erroAoSolicitarPermissao!;
    }
    chamadasSolicitarPermissao++;
    ultimoAlertaSolicitado = alert;
    ultimoBadgeSolicitado = badge;
    ultimoSomSolicitado = sound;
    return resultadoPermissao;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake determinístico em memória de [FlutterLocalNotificationsPlugin] para testes de comportamento.
///
/// Permite inspecionar notificações exibidas, canceladas, canais criados e simular
/// plataformas específicas (Android, iOS ou nenhuma) e falhas determinísticas de I/O.
class PluginNotificacoesLocaisFake implements FlutterLocalNotificationsPlugin {
  ImplementacaoAndroidNotificacoesFake? androidFake;
  ImplementacaoIOSNotificacoesFake? iosFake;

  InitializationSettings? configuracoesInicializadas;
  bool? resultadoInicializacao = true;
  Object? erroAoInicializar;
  Object? erroAoExibir;
  Object? erroAoCancelar;

  final List<RegistroNotificacaoExibida> notificacoesExibidas = [];
  final List<int> idsCancelados = [];

  PluginNotificacoesLocaisFake({
    ImplementacaoAndroidNotificacoesFake? android,
    ImplementacaoIOSNotificacoesFake? ios,
    bool habilitarAndroidPorPadrao = true,
    bool habilitarIOSPorPadrao = true,
  }) : androidFake =
           android ??
           (habilitarAndroidPorPadrao
               ? ImplementacaoAndroidNotificacoesFake()
               : null),
       iosFake =
           ios ??
           (habilitarIOSPorPadrao ? ImplementacaoIOSNotificacoesFake() : null);

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (erroAoInicializar != null) {
      throw erroAoInicializar!;
    }
    configuracoesInicializadas = settings;
    return resultadoInicializacao;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidFake as T?;
    }
    if (T == IOSFlutterLocalNotificationsPlugin) {
      return iosFake as T?;
    }
    return null;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    if (erroAoExibir != null) {
      throw erroAoExibir!;
    }
    notificacoesExibidas.add(
      RegistroNotificacaoExibida(
        id: id,
        titulo: title,
        corpo: body,
        detalhes: notificationDetails,
      ),
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    if (erroAoCancelar != null) {
      throw erroAoCancelar!;
    }
    idsCancelados.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
