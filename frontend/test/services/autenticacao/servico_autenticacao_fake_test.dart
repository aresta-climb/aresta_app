// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'servico_autenticacao_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;
  });

  group('ServicoAutenticacaoFake', () {
    test('cumpre contrato completo de OTP 6 dígitos, Google, Apple, atualização de perfil e encerramento de sessão', () async {
      final fake = ServicoAutenticacaoFake(repositorio: repositorio);
      expect(fake.estaAutenticado, isFalse);
      expect(fake.obterPerfil().estaAutenticado, isFalse);
      expect(fake.perfilListenable.value.estaAutenticado, isFalse);

      // Valida e-mail e código OTP
      await expectLater(
        () => fake.solicitarCodigoOtpEmail(email: 'invalido'),
        throwsA(isA<ExcecaoAutenticacao>()),
      );
      await fake.solicitarCodigoOtpEmail(email: 'clara@aresta.com');
      expect(fake.ultimoEmailOtpSolicitado, equals('clara@aresta.com'));

      await expectLater(
        () => fake.verificarCodigoOtpEmail(
          email: 'clara@aresta.com',
          codigo: '000000',
        ),
        throwsA(isA<ExcecaoAutenticacao>()),
      );

      final perfilOtp = await fake.verificarCodigoOtpEmail(
        email: 'clara@aresta.com',
        codigo: '123456',
      );
      expect(fake.estaAutenticado, isTrue);
      expect(perfilOtp.autorNomePublico, equals('clara'));

      await fake.encerrarSessao();
      expect(fake.estaAutenticado, isFalse);

      final perfilGoogle = await fake.entrarComGoogle();
      expect(perfilGoogle.userId, equals('usr_fake_google'));

      await fake.encerrarSessao();
      final perfilApple = await fake.entrarComApple();
      expect(perfilApple.userId, equals('usr_fake_apple'));

      final atualizado = await fake.atualizarPerfilRemoto(
        novoNome: 'Clara Escaladora',
        novaFotoUrl: 'https://exemplo.com/clara.webp',
      );
      expect(atualizado.autorNomePublico, equals('Clara Escaladora'));
      expect(atualizado.fotoUrl, equals('https://exemplo.com/clara.webp'));

      // Reconciliação e renovação de sessão no Fake
      fake.autorIdPublicoRemotoReconciliado = 'z9Yx8Wv7Ut6Sr5';
      final reconciliado = await fake.garantirSessaoEPerfilSincronizados(
        forcarRenovacaoToken: true,
      );
      expect(reconciliado.autorIdPublico, equals('z9Yx8Wv7Ut6Sr5'));
      expect(reconciliado.accessToken, equals('jwt_renovado_1'));
      expect(fake.totalRenovacoesToken, equals(1));

      fake.erroAoGarantirSessao = StateError('Falha ao renovar');
      await expectLater(
        () => fake.garantirSessaoEPerfilSincronizados(),
        throwsStateError,
      );

      await fake.encerrarSessao();
      fake.erroAoGarantirSessao = null;
      final anonimo = await fake.garantirSessaoEPerfilSincronizados();
      expect(anonimo.estaAutenticado, isFalse);

      await expectLater(
        fake.excluirConta,
        throwsA(isA<ExcecaoAutenticacao>()),
      );

      await fake.entrarComGoogle();
      fake.erroAoExcluirConta = StateError('Offline na exclusão');
      await expectLater(fake.excluirConta, throwsStateError);

      fake.erroAoExcluirConta = null;
      await fake.excluirConta();
      expect(fake.estaAutenticado, isFalse);
      expect(fake.totalContasExcluidas, 1);
    });

    test('permite simular cancelamento voluntário e exceções determinísticas em cada operação', () async {
      final fake = ServicoAutenticacaoFake(
        repositorio: repositorio,
        cancelarProximoLoginSocial: true,
        erroAoSolicitarOtp: Exception('Sem conexão com a internet'),
        erroAoVerificarOtp: const ExcecaoAutenticacao(
          'Falha interna',
          codigoStatusHttp: 500,
          ehErroUsuario: false,
        ),
      );

      await expectLater(
        () => fake.solicitarCodigoOtpEmail(email: 'a@b.com'),
        throwsException,
      );
      await expectLater(
        () => fake.verificarCodigoOtpEmail(email: 'a@b.com', codigo: '123456'),
        throwsA(isA<ExcecaoAutenticacao>()),
      );
      await expectLater(
        fake.entrarComGoogle,
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );
      await expectLater(
        fake.entrarComApple,
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );

      fake.cancelarProximoLoginSocial = false;
      fake.erroNoLoginSocial = StateError('Erro inesperado');
      await expectLater(fake.entrarComGoogle, throwsStateError);
      await expectLater(fake.entrarComApple, throwsStateError);
    });

    test('permite configurar cancelamento único silencioso sem bloquear tentativas seguintes', () async {
      final fake = ServicoAutenticacaoFake(
        repositorio: repositorio,
        cancelarProximoLoginSocial: true,
        cancelarApenasUmaVez: true,
      );

      await expectLater(
        fake.entrarComGoogle,
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );
      expect(fake.estaAutenticado, isFalse);

      final perfil = await fake.entrarComGoogle();
      expect(perfil.estaAutenticado, isTrue);
    });
  });
}
