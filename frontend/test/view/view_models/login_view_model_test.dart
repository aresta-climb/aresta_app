// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/view/view_models/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mocks/mock_app_logger.dart';
import '../../services/autenticacao/servico_autenticacao_fake.dart';

class _ServicoAutenticacaoLento extends ServicoAutenticacaoFake {
  final Completer<void> liberador = Completer<void>();

  _ServicoAutenticacaoLento({required super.repositorio});

  @override
  Future<PerfilEscalador> entrarComApple() async {
    await liberador.future;
    return super.entrarComApple();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ServicoAutenticacaoFake servicoFake;
  late MockAppLogger mockLogger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;

    servicoFake = ServicoAutenticacaoFake(repositorio: repositorio);
    ServicoAutenticacaoLocal.instancia = servicoFake;

    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
  });

  tearDown(() {
    ServicoAutenticacaoLocal.redefinirParaTestes();
    AppLogger.resetForTesting();
  });

  group('LoginViewModel (Sem Senha / OTP 6 dígitos)', () {
    test('executa fluxo de Magic Code em 2 etapas, limpa avisos ao editar, permite alterar e-mail e autentica com sucesso', () async {
      var autenticado = 0;
      final vm = LoginViewModel(
        aoAutenticarComSucesso: () => autenticado++,
      );

      expect(vm.aguardandoCodigoOtp, isFalse);
      expect(vm.carregando, isFalse);
      expect(vm.mensagemErro, isNull);
      expect(vm.tituloCabecalho, equals('Entrar na sua conta'));
      expect(vm.subtituloCabecalho, contains('sem senha'));

      // 1. E-mail inválido gera mensagem amigável sem enviar erro ao Sentry
      vm.definirEmail('email-invalido');
      expect(await vm.solicitarCodigoEmail(), isFalse);
      expect(vm.mensagemErro, equals('Informe um endereço de e-mail válido.'));
      expect(mockLogger.recordedErrors, isEmpty);

      // Editar o e-mail limpa o erro automaticamente
      vm.definirEmail('escalador@aresta.com');
      expect(vm.mensagemErro, isNull);

      // 2. Solicitar OTP avança para a etapa de código de 6 dígitos
      expect(await vm.solicitarCodigoEmail(), isTrue);
      expect(vm.aguardandoCodigoOtp, isTrue);
      expect(vm.mensagemInfoOtp, contains('escalador@aresta.com'));
      expect(autenticado, equals(0));

      // 3. Código incorreto exibe erro amigável sem alertar Sentry e limpa ao digitar
      vm.definirCodigoOtp('000000');
      expect(await vm.confirmarCodigoEmail(), isFalse);
      expect(
        vm.mensagemErro,
        equals('O código de acesso expirou ou é inválido.'),
      );
      expect(mockLogger.recordedErrors, isEmpty);

      vm.definirCodigoOtp('123456');
      expect(vm.mensagemErro, isNull);

      // 4. Alterar e-mail retorna à etapa 1 limpando código e mensagens
      vm.alterarEmailOtp();
      expect(vm.aguardandoCodigoOtp, isFalse);
      expect(vm.codigoOtp, isEmpty);
      expect(vm.mensagemInfoOtp, isNull);

      // 5. Reenvia código e confirma 6 dígitos -> autentica com sucesso
      expect(await vm.solicitarCodigoEmail(), isTrue);
      vm.definirCodigoOtp('123456');
      expect(await vm.confirmarCodigoEmail(), isTrue);
      expect(autenticado, equals(1));
      expect(servicoFake.estaAutenticado, isTrue);
      expect(vm.aguardandoCodigoOtp, isFalse);

      vm.dispose();
    });

    test('aplica janela deslizante de 6 envios de código OTP por 60 segundos com contagem regressiva', () {
      fakeAsync((async) {
        var agora = DateTime.utc(2026, 11, 19, 12, 0, 0);
        final vm = LoginViewModel(
          servicoAutenticacao: servicoFake,
          obterAgora: () => agora,
        );
        vm.definirEmail('janela@aresta.com');

        for (var i = 0; i < 6; i++) {
          expect(vm.podeSolicitarCodigoOtp, isTrue);
          bool? enviado;
          vm.reenviarCodigoEmail().then((v) => enviado = v);
          async.flushMicrotasks();
          expect(enviado, isTrue);
          agora = agora.add(const Duration(seconds: 5));
        }

        // Após 6 envios em 30s, restam 30s até liberar a vaga mais antiga
        expect(vm.segundosRestantesReenvio, equals(30));
        expect(vm.podeSolicitarCodigoOtp, isFalse);

        // Avança 1s no Timer.periodic para validar atualização ao vivo e cancelamento automático ao zerar
        agora = agora.add(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        expect(vm.segundosRestantesReenvio, equals(29));

        // Tentativa durante o bloqueio informa contagem regressiva sem acionar rede nem Sentry
        bool? bloqueado;
        vm.reenviarCodigoEmail().then((v) => bloqueado = v);
        async.flushMicrotasks();
        expect(bloqueado, isFalse);
        expect(vm.mensagemErro, contains('29s'));
        expect(servicoFake.totalEnviosOtp, equals(6));
        expect(mockLogger.recordedErrors, isEmpty);

        // Avança o relógio além de 60s da primeira solicitação -> timer encerra e libera novo envio
        agora = agora.add(const Duration(seconds: 30));
        async.elapse(const Duration(seconds: 1));
        expect(vm.segundosRestantesReenvio, equals(0));
        expect(vm.podeSolicitarCodigoOtp, isTrue);

        bool? reenviadoAposJanela;
        vm.reenviarCodigoEmail().then((v) => reenviadoAposJanela = v);
        async.flushMicrotasks();
        expect(reenviadoAposJanela, isTrue);
        expect(servicoFake.totalEnviosOtp, equals(7));

        vm.dispose();
      });
    });

    test('trata ExcecaoAutenticacaoCancelada silenciosamente e diferencia offline (logAviso) de erro real (logError)', () async {
      var abriuConfiguracoes = 0;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoFake,
        aoAbrirConfiguracoes: () => abriuConfiguracoes++,
      );

      // 1. Cancelamento voluntário no Google/Apple: sem mensagemErro e sem logError
      servicoFake.cancelarProximoLoginSocial = true;
      expect(await vm.entrarComGoogle(), isFalse);
      expect(vm.mensagemErro, isNull);
      expect(mockLogger.recordedErrors, isEmpty);

      expect(await vm.entrarComApple(), isFalse);
      expect(vm.mensagemErro, isNull);
      expect(mockLogger.recordedErrors, isEmpty);

      // 2. Queda de conexão (SocketException): mensagem offline amigável + logAviso
      servicoFake.cancelarProximoLoginSocial = false;
      servicoFake.erroNoLoginSocial = const SocketException('Failed host lookup');
      expect(await vm.entrarComGoogle(), isFalse);
      expect(vm.mensagemErro, contains('Sem conexão com a internet'));
      expect(mockLogger.recordedWarnings, isNotEmpty);
      expect(mockLogger.recordedErrors, isEmpty);

      // 3. ExcecaoAutenticacao operacional (ex.: HTTP 400 provider_disabled): registra logError com StackTrace
      servicoFake.erroNoLoginSocial = const ExcecaoAutenticacao(
        'Provedor de autenticação não está habilitado no servidor.',
        codigoStatusHttp: 400,
        ehErroUsuario: false,
        causaTecnica: 'HTTP 400 provider_disabled',
      );
      expect(await vm.entrarComApple(), isFalse);
      expect(
        vm.mensagemErro,
        equals('Provedor de autenticação não está habilitado no servidor.'),
      );
      expect(mockLogger.recordedErrors.length, equals(1));
      expect(mockLogger.recordedErrors.single['stackTrace'], isNotNull);

      // 4. ExcecaoAutenticacao com status HTTP transitório 503: registra logAviso sem abrir erro no Sentry
      mockLogger.recordedWarnings.clear();
      servicoFake.erroNoLoginSocial = const ExcecaoAutenticacao(
        'Serviço temporariamente indisponível.',
        codigoStatusHttp: 503,
        ehErroUsuario: false,
      );
      expect(await vm.entrarComGoogle(), isFalse);
      expect(mockLogger.recordedWarnings, isNotEmpty);
      expect(mockLogger.recordedErrors.length, equals(1));

      // 5. Exceção inesperada genérica: registra logError com StackTrace e exibe mensagem genérica
      servicoFake.erroNoLoginSocial = StateError('Falha inesperada');
      expect(await vm.entrarComGoogle(), isFalse);
      expect(
        vm.mensagemErro,
        equals('Não foi possível entrar com o Google. Tente novamente.'),
      );
      expect(mockLogger.recordedErrors.length, equals(2));

      vm.abrirConfiguracoes();
      expect(abriuConfiguracoes, equals(1));
      expect(vm.mensagemErro, isNull);

      vm.dispose();
    });

    test('não lança FlutterError quando entrarComApple conclui após dispose do LoginViewModel (Fixes ARESTA-APP-G)', () async {
      final servicoLento = _ServicoAutenticacaoLento(repositorio: repositorio);
      final vm = LoginViewModel(servicoAutenticacao: servicoLento);
      var notificacoes = 0;
      vm.addListener(() => notificacoes++);

      final futuroApple = vm.entrarComApple();
      expect(notificacoes, equals(1));

      // Descarta o ViewModel enquanto o modal nativo da Apple ainda está aberto
      vm.dispose();

      // Conclui a operação assíncrona após o dispose -> NÃO deve chamar notifyListeners()
      servicoLento.liberador.complete();
      await expectLater(futuroApple, completes);
      expect(notificacoes, equals(1));
    });
  });
}
