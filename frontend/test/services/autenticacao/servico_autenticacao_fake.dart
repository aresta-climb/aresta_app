// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [ServicoAutenticacao].
///
/// Substitui chamadas de rede/canais nativos em testes de UI, navegação e Robô Caótico
/// sem exigir fallbacks sintéticos no código de produção.
class ServicoAutenticacaoFake implements ServicoAutenticacao {
  final RepositorioCaderneta _repositorio;

  /// Código OTP numérico de 6 dígitos aceito como válido neste Fake.
  String codigoOtpEsperado;

  /// Quando `true`, lança [ExcecaoAutenticacaoCancelada] na próxima chamada a Google ou Apple.
  bool cancelarProximoLoginSocial;

  /// Exceção determinística opcional lançada em [solicitarCodigoOtpEmail].
  Object? erroAoSolicitarOtp;

  /// Exceção determinística opcional lançada em [verificarCodigoOtpEmail].
  Object? erroAoVerificarOtp;

  /// Exceção determinística opcional lançada em [entrarComGoogle] e [entrarComApple].
  Object? erroNoLoginSocial;

  /// Último e-mail validado com sucesso em [solicitarCodigoOtpEmail].
  String? ultimoEmailOtpSolicitado;

  /// Contador de envios de código OTP realizados com sucesso.
  int totalEnviosOtp = 0;

  /// Cria uma instância configurável de [ServicoAutenticacaoFake].
  ServicoAutenticacaoFake({
    RepositorioCaderneta? repositorio,
    this.codigoOtpEsperado = '123456',
    this.cancelarProximoLoginSocial = false,
    this.erroAoSolicitarOtp,
    this.erroAoVerificarOtp,
    this.erroNoLoginSocial,
  }) : _repositorio = repositorio ?? RepositorioCadernetaLocal.instancia;

  @override
  ValueListenable<PerfilEscalador> get perfilListenable =>
      _repositorio.perfilNotifier;

  @override
  PerfilEscalador obterPerfil() => _repositorio.obterPerfil();

  @override
  bool get estaAutenticado => _repositorio.obterPerfil().estaAutenticado;

  @override
  Future<void> solicitarCodigoOtpEmail({required String email}) async {
    final emailLimpo = ServicoAutenticacaoLocal.validarFormatoEmail(email);
    if (erroAoSolicitarOtp != null) {
      Error.throwWithStackTrace(erroAoSolicitarOtp!, StackTrace.current);
    }
    ultimoEmailOtpSolicitado = emailLimpo;
    totalEnviosOtp++;
  }

  @override
  Future<PerfilEscalador> verificarCodigoOtpEmail({
    required String email,
    required String codigo,
  }) async {
    final emailLimpo = ServicoAutenticacaoLocal.validarFormatoEmail(email);
    final codigoLimpo = ServicoAutenticacaoLocal.validarFormatoCodigoOtp(codigo);
    if (erroAoVerificarOtp != null) {
      Error.throwWithStackTrace(erroAoVerificarOtp!, StackTrace.current);
    }
    if (codigoLimpo != codigoOtpEsperado) {
      throw const ExcecaoAutenticacao(
        'O código de acesso expirou ou é inválido.',
        ehErroUsuario: true,
      );
    }
    final atual = _repositorio.obterPerfil();
    final nomeFinal = atual.autorNomePublico == PerfilEscalador.apelidoPadrao
        ? emailLimpo.split('@').first
        : atual.autorNomePublico;
    await _repositorio.salvarPerfil(
      atual.copyWith(
        userId: 'usr_fake_otp',
        autorNomePublico: nomeFinal,
        accessToken: 'jwt_fake_otp',
      ),
    );
    return _repositorio.obterPerfil();
  }

  @override
  Future<PerfilEscalador> entrarComGoogle() => _entrarSocial(
        userId: 'usr_fake_google',
        nomePadrao: 'Escalador Google',
      );

  @override
  Future<PerfilEscalador> entrarComApple() => _entrarSocial(
        userId: 'usr_fake_apple',
        nomePadrao: 'Escalador Apple',
      );

  Future<PerfilEscalador> _entrarSocial({
    required String userId,
    required String nomePadrao,
  }) async {
    if (cancelarProximoLoginSocial) {
      throw const ExcecaoAutenticacaoCancelada();
    }
    if (erroNoLoginSocial != null) {
      Error.throwWithStackTrace(erroNoLoginSocial!, StackTrace.current);
    }
    final atual = _repositorio.obterPerfil();
    final nomeFinal = atual.autorNomePublico == PerfilEscalador.apelidoPadrao
        ? nomePadrao
        : atual.autorNomePublico;
    await _repositorio.salvarPerfil(
      atual.copyWith(
        userId: userId,
        autorNomePublico: nomeFinal,
        accessToken: 'jwt_$userId',
      ),
    );
    return _repositorio.obterPerfil();
  }

  @override
  Future<PerfilEscalador> atualizarPerfilRemoto({
    String? novoNome,
    String? novaFotoUrl,
  }) async {
    final atual = _repositorio.obterPerfil();
    await _repositorio.salvarPerfil(
      atual.copyWith(
        autorNomePublico: (novoNome != null && novoNome.trim().isNotEmpty)
            ? novoNome.trim()
            : atual.autorNomePublico,
        fotoUrl: (novaFotoUrl != null && novaFotoUrl.trim().isNotEmpty)
            ? novaFotoUrl.trim()
            : atual.fotoUrl,
      ),
    );
    return _repositorio.obterPerfil();
  }

  @override
  Future<void> encerrarSessao() async {
    final atual = _repositorio.obterPerfil();
    if (!atual.estaAutenticado) return;
    await _repositorio.salvarPerfil(atual.copyWith(limparUserId: true));
  }
}
