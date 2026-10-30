// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';

import '../../fakes/plugin_notificacoes_locais_fake.dart';
import '../../mocks/mock_app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PluginNotificacoesLocaisFake pluginFake;
  late GerenciadorNotificacaoDownload gerenciador;

  setUp(() {
    AppLogger.resetForTesting();
    GerenciadorNotificacaoDownload.instancia = null;
    pluginFake = PluginNotificacoesLocaisFake();
    gerenciador = GerenciadorNotificacaoDownload(plugin: pluginFake);
  });

  tearDown(() {
    GerenciadorNotificacaoDownload.instancia = null;
    AppLogger.resetForTesting();
  });

  group('GerenciadorNotificacaoDownload', () {
    test('instancia padrao cria e reutiliza singleton e permite substituicao para testes', () {
      final padrao1 = GerenciadorNotificacaoDownload.instancia;
      final padrao2 = GerenciadorNotificacaoDownload.instancia;
      expect(padrao1, same(padrao2));

      GerenciadorNotificacaoDownload.instancia = gerenciador;
      expect(GerenciadorNotificacaoDownload.instancia, same(gerenciador));
    });

    test('inicializar configura o plugin com icone @mipmap/ic_launcher e registra canais no Android', () async {
      final inicializado = await gerenciador.inicializar();

      expect(inicializado, isTrue);
      expect(
        pluginFake.configuracoesInicializadas?.android?.defaultIcon,
        equals('@mipmap/ic_launcher'),
      );
      final canais = pluginFake.androidFake!.canaisCriados;
      expect(canais.length, 2);
      expect(canais[0].id, equals('downloads_croquis'));
      expect(canais[1].id, equals('downloads_concluidos'));
    });

    test('inicializar retorna true quando initialize retorna null fora do Android', () async {
      final fakeSemAndroid = PluginNotificacoesLocaisFake(
        habilitarAndroidPorPadrao: false,
      )..resultadoInicializacao = null;
      final gerenciadorSemAndroid = GerenciadorNotificacaoDownload(
        plugin: fakeSemAndroid,
      );

      expect(await gerenciadorSemAndroid.inicializar(), isTrue);
    });

    test('solicitarPermissoes solicita no Android, no iOS e em plataforma generica', () async {
      expect(await gerenciador.solicitarPermissoes(), isTrue);
      expect(pluginFake.androidFake!.chamadasSolicitarPermissao, 1);

      pluginFake.androidFake!.resultadoPermissao = null;
      expect(await gerenciador.solicitarPermissoes(), isTrue);

      final fakeApenasIOS = PluginNotificacoesLocaisFake(
        habilitarAndroidPorPadrao: false,
        habilitarIOSPorPadrao: true,
      );
      final gerenciadorIOS = GerenciadorNotificacaoDownload(
        plugin: fakeApenasIOS,
      );
      expect(await gerenciadorIOS.solicitarPermissoes(), isTrue);
      expect(fakeApenasIOS.iosFake!.chamadasSolicitarPermissao, 1);
      expect(fakeApenasIOS.iosFake!.ultimoAlertaSolicitado, isTrue);
      expect(fakeApenasIOS.iosFake!.ultimoBadgeSolicitado, isTrue);
      expect(fakeApenasIOS.iosFake!.ultimoSomSolicitado, isFalse);

      fakeApenasIOS.iosFake!.resultadoPermissao = null;
      expect(await gerenciadorIOS.solicitarPermissoes(), isTrue);

      final fakeGenerico = PluginNotificacoesLocaisFake(
        habilitarAndroidPorPadrao: false,
        habilitarIOSPorPadrao: false,
      );
      final gerenciadorGenerico = GerenciadorNotificacaoDownload(
        plugin: fakeGenerico,
      );
      expect(await gerenciadorGenerico.solicitarPermissoes(), isTrue);
    });

    test('calcularIdNotificacao retorna id numerico estavel e positivo', () {
      final id1 = gerenciador.calcularIdNotificacao('br_mg_pedro_leopoldo');
      final id2 = gerenciador.calcularIdNotificacao('br_mg_pedro_leopoldo');
      final idOutro = gerenciador.calcularIdNotificacao('br_mg_cipoo');

      expect(id1, equals(id2));
      expect(id1, isPositive);
      expect(id1, isNot(equals(idOutro)));
    });

    test('atualizarProgresso ativa ForegroundService com icone @mipmap/ic_launcher e sem largeIcon', () async {
      await gerenciador.atualizarProgresso(
        'pico_1',
        'Pedra Grande',
        0.45,
      );

      expect(pluginFake.androidFake!.servicosIniciados.length, 1);
      final servico = pluginFake.androidFake!.servicosIniciados.first;
      expect(servico.id, equals(gerenciador.calcularIdNotificacao('pico_1')));
      expect(servico.titulo, equals('Pedra Grande'));
      expect(servico.corpo, equals('Baixando... 45%'));
      expect(
        servico.tiposServicoPrimeiroPlano,
        equals({AndroidServiceForegroundType.foregroundServiceTypeDataSync}),
      );

      final details = servico.detalhesAndroid!;
      expect(details.channelId, equals('downloads_croquis'));
      expect(details.ongoing, isTrue);
      expect(details.autoCancel, isFalse);
      expect(details.showProgress, isTrue);
      expect(details.progress, equals(45));
      expect(details.playSound, isFalse);
      expect(details.enableVibration, isFalse);
      expect(details.silent, isTrue);
      expect(details.subText, equals('Aresta Climb'));
      expect(details.icon, equals('@mipmap/ic_launcher'));
      expect(details.largeIcon, isNull);
    });

    test('atualizarProgresso subsequente atualiza via show() sem reiniciar ForegroundService e suporta iOS', () async {
      await gerenciador.atualizarProgresso('pico_1', 'Pedra Grande', 0.10);
      await gerenciador.atualizarProgresso('pico_1', 'Pedra Grande', 0.50);

      expect(pluginFake.androidFake!.servicosIniciados.length, 1);
      expect(pluginFake.notificacoesExibidas.length, 1);
      expect(pluginFake.notificacoesExibidas.first.titulo, 'Pedra Grande');
      expect(pluginFake.notificacoesExibidas.first.corpo, 'Baixando... 50%');
      expect(
        pluginFake.notificacoesExibidas.first.detalhes?.android?.largeIcon,
        isNull,
      );

      final fakeIOS = PluginNotificacoesLocaisFake(
        habilitarAndroidPorPadrao: false,
      );
      final gerenciadorIOS = GerenciadorNotificacaoDownload(plugin: fakeIOS);
      await gerenciadorIOS.atualizarProgresso('pico_1', 'Pedra Grande', 0.75);
      expect(fakeIOS.notificacoesExibidas.length, 1);
      expect(
        fakeIOS.notificacoesExibidas.first.detalhes?.iOS?.subtitle,
        'Baixando... 75%',
      );
    });

    test('notificarConclusao para ForegroundService, cancela notificacao sticky e exibe notificacao dispensavel sem largeIcon', () async {
      await gerenciador.atualizarProgresso('pico_1', 'Pedra Grande', 0.50);
      pluginFake.notificacoesExibidas.clear();

      await gerenciador.notificarConclusao('pico_1', 'Pedra Grande');

      final notifId = gerenciador.calcularIdNotificacao('pico_1');
      expect(pluginFake.androidFake!.chamadasPararServicoPrimeiroPlano, 1);
      expect(pluginFake.idsCancelados, [notifId]);
      expect(pluginFake.notificacoesExibidas.length, 1);

      final exibida = pluginFake.notificacoesExibidas.first;
      expect(exibida.id, equals(notifId));
      expect(exibida.titulo, equals('Pedra Grande'));
      expect(exibida.corpo, equals('✓ Croqui salvo para uso offline.'));

      final details = exibida.detalhes!;
      expect(details.android?.channelId, equals('downloads_concluidos'));
      expect(details.android?.ongoing, isFalse);
      expect(details.android?.autoCancel, isTrue);
      expect(details.android?.showProgress, isFalse);
      expect(details.android?.playSound, isFalse);
      expect(details.android?.enableVibration, isFalse);
      expect(details.android?.silent, isTrue);
      expect(details.android?.subText, equals('Aresta Climb'));
      expect(details.android?.icon, equals('@mipmap/ic_launcher'));
      expect(details.android?.largeIcon, isNull);
    });

    test('notificarFalha para ForegroundService, cancela sticky e exibe notificacao dispensavel de erro sem largeIcon', () async {
      await gerenciador.notificarFalha(
        'pico_1',
        'Pedra Grande',
        'Sem conexão com a internet',
      );

      final notifId = gerenciador.calcularIdNotificacao('pico_1');
      expect(pluginFake.androidFake!.chamadasPararServicoPrimeiroPlano, 1);
      expect(pluginFake.idsCancelados, [notifId]);
      expect(pluginFake.notificacoesExibidas.length, 1);

      final exibida = pluginFake.notificacoesExibidas.first;
      expect(exibida.corpo, equals('Sem conexão com a internet'));
      expect(exibida.detalhes?.android?.channelId, equals('downloads_concluidos'));
      expect(exibida.detalhes?.android?.ongoing, isFalse);
      expect(exibida.detalhes?.android?.autoCancel, isTrue);
      expect(exibida.detalhes?.android?.subText, equals('Aresta Climb'));
      expect(exibida.detalhes?.android?.icon, equals('@mipmap/ic_launcher'));
      expect(exibida.detalhes?.android?.largeIcon, isNull);

      await gerenciador.notificarFalha('pico_2', 'Pedra 2');
      expect(
        pluginFake.notificacoesExibidas.last.corpo,
        equals('Falha ao baixar croqui. Verifique sua conexão.'),
      );
    });

    test('cancelar remove a notificacao e para ForegroundService quando nao restam servicos ativos', () async {
      await gerenciador.cancelar('pico_1');

      expect(pluginFake.androidFake!.chamadasPararServicoPrimeiroPlano, 1);
      expect(
        pluginFake.idsCancelados,
        [gerenciador.calcularIdNotificacao('pico_1')],
      );
    });

    test('inicializar, solicitarPermissoes, atualizarProgresso, notificarConclusao, notificarFalha e cancelar tratam erros registrando via AppLogger', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      pluginFake.erroAoInicializar = Exception('Falha ao inicializar canais nativos');
      expect(await gerenciador.inicializar(), isFalse);

      pluginFake.androidFake!.erroAoSolicitarPermissao =
          Exception('Falha de permissão nativa');
      expect(await gerenciador.solicitarPermissoes(), isFalse);

      pluginFake.androidFake!.erroAoIniciarServicoPrimeiroPlano =
          Exception('Falha ao iniciar ForegroundService');
      await gerenciador.atualizarProgresso('pico_erro', 'Pedra Erro', 0.5);

      pluginFake.erroAoCancelar = Exception('Falha ao cancelar notificação');
      await gerenciador.notificarConclusao('pico_erro', 'Pedra Erro');
      await gerenciador.notificarFalha('pico_erro', 'Pedra Erro');
      await gerenciador.cancelar('pico_erro');

      expect(mockLogger.recordedErrors.length, 6);
      expect(
        mockLogger.recordedErrors[0]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao inicializar notificações'),
      );
      expect(
        mockLogger.recordedErrors[1]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao solicitar permissões'),
      );
      expect(
        mockLogger.recordedErrors[2]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao atualizar progresso'),
      );
      expect(
        mockLogger.recordedErrors[3]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao notificar conclusão'),
      );
      expect(
        mockLogger.recordedErrors[4]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao notificar falha'),
      );
      expect(
        mockLogger.recordedErrors[5]['contextMessage'],
        contains('[GerenciadorNotificacaoDownload] Erro ao cancelar notificação'),
      );
    });
  });
}
