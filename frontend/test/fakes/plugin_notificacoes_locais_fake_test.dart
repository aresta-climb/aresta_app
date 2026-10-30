// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plugin_notificacoes_locais_fake.dart';

void main() {
  group('PluginNotificacoesLocaisFake', () {
    test('inicializa e resolve implementações Android e iOS por padrão', () async {
      final fake = PluginNotificacoesLocaisFake();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      final resultado = await fake.initialize(settings: settings);

      expect(resultado, isTrue);
      expect(fake.configuracoesInicializadas, same(settings));
      expect(
        fake.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>(),
        same(fake.androidFake),
      );
      expect(
        fake.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>(),
        same(fake.iosFake),
      );
      expect(
        fake.resolvePlatformSpecificImplementation<
            FlutterLocalNotificationsPlatform>(),
        isNull,
      );
    });

    test('permite desabilitar implementações de plataforma e injetar instâncias customizadas', () {
      final fakeSemPlataformas = PluginNotificacoesLocaisFake(
        habilitarAndroidPorPadrao: false,
        habilitarIOSPorPadrao: false,
      );
      expect(fakeSemPlataformas.androidFake, isNull);
      expect(fakeSemPlataformas.iosFake, isNull);

      final androidCustom = ImplementacaoAndroidNotificacoesFake();
      final iosCustom = ImplementacaoIOSNotificacoesFake();
      final fakeCustom = PluginNotificacoesLocaisFake(
        android: androidCustom,
        ios: iosCustom,
      );
      expect(fakeCustom.androidFake, same(androidCustom));
      expect(fakeCustom.iosFake, same(iosCustom));
    });

    test('registra canais, permissões, ForegroundService, exibições e cancelamentos em memória', () async {
      final fake = PluginNotificacoesLocaisFake();
      const canal = AndroidNotificationChannel('id_canal', 'Nome Canal');
      const detalhesAndroid = AndroidNotificationDetails('id_canal', 'Nome Canal');
      const detalhes = NotificationDetails(android: detalhesAndroid);

      await fake.androidFake!.createNotificationChannel(canal);
      expect(fake.androidFake!.canaisCriados, [canal]);

      expect(await fake.androidFake!.requestNotificationsPermission(), isTrue);
      expect(fake.androidFake!.chamadasSolicitarPermissao, 1);

      expect(
        await fake.iosFake!.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        ),
        isTrue,
      );
      expect(fake.iosFake!.chamadasSolicitarPermissao, 1);
      expect(fake.iosFake!.ultimoAlertaSolicitado, isTrue);
      expect(fake.iosFake!.ultimoBadgeSolicitado, isTrue);
      expect(fake.iosFake!.ultimoSomSolicitado, isFalse);

      await fake.androidFake!.startForegroundService(
        id: 10,
        title: 'Pico',
        body: 'Baixando',
        notificationDetails: detalhesAndroid,
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeDataSync,
        },
      );
      expect(fake.androidFake!.servicosIniciados.length, 1);
      expect(fake.androidFake!.servicosIniciados.first.id, 10);
      expect(fake.androidFake!.servicosIniciados.first.titulo, 'Pico');
      expect(fake.androidFake!.servicosIniciados.first.corpo, 'Baixando');
      expect(
        fake.androidFake!.servicosIniciados.first.detalhesAndroid,
        same(detalhesAndroid),
      );
      expect(
        fake.androidFake!.servicosIniciados.first.tiposServicoPrimeiroPlano,
        {AndroidServiceForegroundType.foregroundServiceTypeDataSync},
      );

      await fake.androidFake!.stopForegroundService();
      expect(fake.androidFake!.chamadasPararServicoPrimeiroPlano, 1);

      await fake.show(
        id: 10,
        title: 'Pico',
        body: 'Concluído',
        notificationDetails: detalhes,
      );
      expect(fake.notificacoesExibidas.length, 1);
      expect(fake.notificacoesExibidas.first.id, 10);
      expect(fake.notificacoesExibidas.first.titulo, 'Pico');
      expect(fake.notificacoesExibidas.first.corpo, 'Concluído');
      expect(fake.notificacoesExibidas.first.detalhes, same(detalhes));

      await fake.cancel(id: 10);
      expect(fake.idsCancelados, [10]);
    });

    test('simula falhas determinísticas em todas as operações configuradas e noSuchMethod', () async {
      final fake = PluginNotificacoesLocaisFake();
      fake.erroAoInicializar = StateError('erro init');
      fake.erroAoExibir = StateError('erro show');
      fake.erroAoCancelar = StateError('erro cancel');
      fake.androidFake!.erroAoCriarCanal = StateError('erro canal');
      fake.androidFake!.erroAoSolicitarPermissao = StateError('erro perm android');
      fake.androidFake!.erroAoIniciarServicoPrimeiroPlano = StateError('erro start fg');
      fake.androidFake!.erroAoPararServicoPrimeiroPlano = StateError('erro stop fg');
      fake.iosFake!.erroAoSolicitarPermissao = StateError('erro perm ios');

      await expectLater(
        fake.initialize(settings: const InitializationSettings()),
        throwsStateError,
      );
      await expectLater(fake.show(id: 1), throwsStateError);
      await expectLater(fake.cancel(id: 1), throwsStateError);
      await expectLater(
        fake.androidFake!.createNotificationChannel(
          const AndroidNotificationChannel('id', 'nome'),
        ),
        throwsStateError,
      );
      await expectLater(
        fake.androidFake!.requestNotificationsPermission(),
        throwsStateError,
      );
      await expectLater(
        fake.androidFake!.startForegroundService(id: 1),
        throwsStateError,
      );
      await expectLater(
        fake.androidFake!.stopForegroundService(),
        throwsStateError,
      );
      await expectLater(
        fake.iosFake!.requestPermissions(),
        throwsStateError,
      );

      expect(() => fake.cancelAll(), throwsNoSuchMethodError);
      expect(() => fake.androidFake!.cancelAll(), throwsNoSuchMethodError);
      expect(() => fake.iosFake!.cancelAll(), throwsNoSuchMethodError);
    });
  });
}
