// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../mocks/mock_app_logger.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
  late MockIOSFlutterLocalNotificationsPlugin mockIOSPlugin;
  late GerenciadorNotificacaoDownload gerenciador;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const AndroidNotificationDetails('canal', 'nome'));
    registerFallbackValue(AndroidServiceStartType.startSticky);
    registerFallbackValue({AndroidServiceForegroundType.foregroundServiceTypeDataSync});
    registerFallbackValue(
      const AndroidNotificationChannel(
        'downloads_croquis',
        'Downloads de Croquis',
      ),
    );
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
    mockIOSPlugin = MockIOSFlutterLocalNotificationsPlugin();

    when(() => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((_) async => true);

    when(() => mockPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>())
        .thenReturn(mockAndroidPlugin);

    when(() => mockPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>())
        .thenReturn(mockIOSPlugin);

    when(() => mockAndroidPlugin.createNotificationChannel(any()))
        .thenAnswer((_) async {});

    when(() => mockAndroidPlugin.requestNotificationsPermission())
        .thenAnswer((_) async => true);

    when(() => mockAndroidPlugin.startForegroundService(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
          startType: any(named: 'startType'),
          foregroundServiceTypes: any(named: 'foregroundServiceTypes'),
        )).thenAnswer((_) async {});

    when(() => mockAndroidPlugin.stopForegroundService())
        .thenAnswer((_) async {});

    when(() => mockIOSPlugin.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        )).thenAnswer((_) async => true);

    when(() => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});

    when(() => mockPlugin.cancel(
          id: any(named: 'id'),
          tag: any(named: 'tag'),
        )).thenAnswer((_) async {});

    gerenciador = GerenciadorNotificacaoDownload(plugin: mockPlugin);
  });

  group('GerenciadorNotificacaoDownload', () {
    test('inicializar configura o plugin e registra canais de progresso e conclusao no Android', () async {
      final inicializado = await gerenciador.inicializar();

      expect(inicializado, isTrue);
      verify(() => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
      verify(() => mockAndroidPlugin.createNotificationChannel(any())).called(2);
    });

    test('solicitarPermissoes chama requisições de permissão nas plataformas', () async {
      final permitido = await gerenciador.solicitarPermissoes();

      expect(permitido, isTrue);
      verify(() => mockAndroidPlugin.requestNotificationsPermission()).called(1);
    });

    test('calcularIdNotificacao retorna id numérico estável e positivo', () {
      final id1 = gerenciador.calcularIdNotificacao('br_mg_pedro_leopoldo');
      final id2 = gerenciador.calcularIdNotificacao('br_mg_pedro_leopoldo');
      final idOutro = gerenciador.calcularIdNotificacao('br_mg_cipoo');

      expect(id1, equals(id2));
      expect(id1, isPositive);
      expect(id1, isNot(equals(idOutro)));
    });

    test('atualizarProgresso ativa ForegroundService com bitmap raster e barra de progresso', () async {
      await gerenciador.atualizarProgresso(
        'pico_1',
        'Pedra Grande',
        0.45,
      );

      final captured = verify(() => mockAndroidPlugin.startForegroundService(
            id: gerenciador.calcularIdNotificacao('pico_1'),
            title: 'Pedra Grande',
            body: 'Baixando... 45%',
            notificationDetails: captureAny(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeDataSync},
          )).captured;

      expect(captured.length, 1);
      final details = captured.first as AndroidNotificationDetails;
      expect(details.channelId, equals('downloads_croquis'));
      expect(details.ongoing, isTrue); // Sticky!
      expect(details.autoCancel, isFalse);
      expect(details.showProgress, isTrue);
      expect(details.progress, equals(45));
      expect(details.playSound, isFalse);
      expect(details.enableVibration, isFalse);
      expect(details.silent, isTrue);
      expect(details.subText, equals('Aresta Climb'));
      // Imagem raster PNG para evitar OpenGLRenderer 'unimplemented'
      expect(details.largeIcon, isA<DrawableResourceAndroidBitmap>());
      final largeIcon = details.largeIcon as DrawableResourceAndroidBitmap;
      expect(largeIcon.data, equals('ic_launcher_foreground'));
    });

    test('atualizarProgresso subsequente atualiza via show() sem reiniciar ForegroundService', () async {
      await gerenciador.atualizarProgresso('pico_1', 'Pedra Grande', 0.10);
      await gerenciador.atualizarProgresso('pico_1', 'Pedra Grande', 0.50);

      verify(() => mockAndroidPlugin.startForegroundService(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            foregroundServiceTypes: any(named: 'foregroundServiceTypes'),
          )).called(1);

      verify(() => mockPlugin.show(
            id: any(named: 'id'),
            title: 'Pedra Grande',
            body: 'Baixando... 50%',
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('notificarConclusao para ForegroundService, cancela notificação sticky e exibe notificação dispensável sem barra', () async {
      await gerenciador.notificarConclusao(
        'pico_1',
        'Pedra Grande',
      );

      final notifId = gerenciador.calcularIdNotificacao('pico_1');
      verify(() => mockAndroidPlugin.stopForegroundService()).called(1);
      verify(() => mockPlugin.cancel(id: notifId)).called(1);

      final captured = verify(() => mockPlugin.show(
            id: notifId,
            title: 'Pedra Grande',
            body: '✓ Croqui salvo para uso offline.',
            notificationDetails: captureAny(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          )).captured;

      expect(captured.length, 1);
      final details = captured.first as NotificationDetails;
      expect(details.android?.channelId, equals('downloads_concluidos'));
      expect(details.android?.ongoing, isFalse); // Clearable!
      expect(details.android?.autoCancel, isTrue);
      expect(details.android?.showProgress, isFalse);
      expect(details.android?.playSound, isFalse);
      expect(details.android?.enableVibration, isFalse);
      expect(details.android?.silent, isTrue);
      expect(details.android?.subText, equals('Aresta Climb'));
      expect(details.android?.largeIcon, isA<DrawableResourceAndroidBitmap>());
    });

    test('notificarFalha para ForegroundService, cancela sticky e exibe notificação dispensável de erro', () async {
      await gerenciador.notificarFalha(
        'pico_1',
        'Pedra Grande',
        'Sem conexão com a internet',
      );

      final notifId = gerenciador.calcularIdNotificacao('pico_1');
      verify(() => mockAndroidPlugin.stopForegroundService()).called(1);
      verify(() => mockPlugin.cancel(id: notifId)).called(1);

      final captured = verify(() => mockPlugin.show(
            id: notifId,
            title: 'Pedra Grande',
            body: 'Sem conexão com a internet',
            notificationDetails: captureAny(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          )).captured;

      final details = captured.first as NotificationDetails;
      expect(details.android?.channelId, equals('downloads_concluidos'));
      expect(details.android?.ongoing, isFalse);
      expect(details.android?.autoCancel, isTrue);
      expect(details.android?.subText, equals('Aresta Climb'));
    });

    test('cancelar remove a notificação e para ForegroundService', () async {
      await gerenciador.cancelar('pico_1');

      verify(() => mockAndroidPlugin.stopForegroundService()).called(1);
      verify(() => mockPlugin.cancel(id: gerenciador.calcularIdNotificacao('pico_1'))).called(1);
    });

    test('inicializar trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
          )).thenThrow(Exception('Falha ao inicializar canais nativos'));

      final res = await gerenciador.inicializar();
      expect(res, isFalse);

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao inicializar notificações'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('solicitarPermissoes trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockAndroidPlugin.requestNotificationsPermission())
          .thenThrow(Exception('Falha de permissão nativa'));

      final res = await gerenciador.solicitarPermissoes();
      expect(res, isFalse);

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao solicitar permissões'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('atualizarProgresso trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockAndroidPlugin.startForegroundService(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
            startType: any(named: 'startType'),
            foregroundServiceTypes: any(named: 'foregroundServiceTypes'),
          )).thenThrow(Exception('Falha ao iniciar ForegroundService'));

      await gerenciador.atualizarProgresso('pico_erro', 'Pedra Erro', 0.5);

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao atualizar progresso'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('notificarConclusao trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockPlugin.cancel(id: any(named: 'id')))
          .thenThrow(Exception('Falha ao cancelar notificação'));

      await gerenciador.notificarConclusao('pico_erro', 'Pedra Erro');

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao notificar conclusão'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('notificarFalha trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockPlugin.cancel(id: any(named: 'id')))
          .thenThrow(Exception('Falha ao cancelar notificação'));

      await gerenciador.notificarFalha('pico_erro', 'Pedra Erro');

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao notificar falha'));
      expect(erro['stackTrace'], isNotNull);
    });

    test('cancelar trata erro e registra via logError com stackTrace', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockPlugin.cancel(id: any(named: 'id')))
          .thenThrow(Exception('Falha ao cancelar notificação'));

      await gerenciador.cancelar('pico_erro');

      expect(mockLogger.recordedErrors.length, 1);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('[GerenciadorNotificacaoDownload] Erro ao cancelar notificação'));
      expect(erro['stackTrace'], isNotNull);
    });
  });
}
