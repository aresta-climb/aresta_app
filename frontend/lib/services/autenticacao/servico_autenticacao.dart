// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';
import 'cliente_supabase_autenticacao.dart';

/// Exceção lançada quando o escalador fecha ou cancela voluntariamente o modal de autenticação.
class ExcecaoAutenticacaoCancelada implements Exception {
  /// Cria uma instância constante de [ExcecaoAutenticacaoCancelada].
  const ExcecaoAutenticacaoCancelada();

  @override
  String toString() =>
      'ExcecaoAutenticacaoCancelada: Operação cancelada voluntariamente pelo escalador.';
}

/// Exceção de domínio lançada quando uma operação de autenticação ou validação falha.
class ExcecaoAutenticacao implements Exception, ExcecaoComStatusHttp {
  /// Mensagem descritiva amigável em português destinada à exibição ao escalador.
  final String mensagem;

  /// Código de status HTTP retornado pelo servidor, quando aplicável.
  @override
  final int? codigoStatusHttp;

  /// Indica se a falha decorre de entrada inválida do usuário (ex.: formato de e-mail,
  /// código OTP incorreto/expirado ou limite de frequência) e portanto não deve abrir erro no Sentry.
  final bool ehErroUsuario;

  /// Detalhe técnico interno para diagnóstico em observabilidade (nunca exibido cru na interface).
  final String? causaTecnica;

  /// Cria uma instância imutável de [ExcecaoAutenticacao].
  const ExcecaoAutenticacao(
    this.mensagem, {
    this.codigoStatusHttp,
    this.ehErroUsuario = true,
    this.causaTecnica,
  });

  @override
  String toString() => causaTecnica != null
      ? 'ExcecaoAutenticacao($causaTecnica): $mensagem'
      : 'ExcecaoAutenticacao: $mensagem';
}

/// Representa a resposta validada de um provedor de autenticação (OTP de e-mail, Google ou Apple).
class ResultadoProvedorAutenticacao {
  /// Identificador único do usuário retornado pelo Supabase Auth.
  final String userId;

  /// Nome de exibição retornado pelo provedor ou tabela `public.perfis`, quando disponível.
  final String? nomeExibicao;

  /// URL ou Data URI da foto de perfil retornada pelo provedor, quando disponível.
  final String? fotoUrl;

  /// Token JWT de sessão do Supabase Auth, quando disponível.
  final String? accessToken;

  /// Identificador público NanoID 14c recuperado do banco remoto, quando existente.
  final String? autorIdPublicoRemoto;

  /// Cria uma instância imutável de [ResultadoProvedorAutenticacao].
  const ResultadoProvedorAutenticacao({
    required this.userId,
    this.nomeExibicao,
    this.fotoUrl,
    this.accessToken,
    this.autorIdPublicoRemoto,
  });
}

/// Contrato da camada de serviço responsável pela autenticação sem senha e vínculo do [PerfilEscalador].
abstract class ServicoAutenticacao {
  /// Notificador reativo do perfil atual do escalador.
  ValueListenable<PerfilEscalador> get perfilListenable;

  /// Retorna o [PerfilEscalador] ativo no momento.
  PerfilEscalador obterPerfil();

  /// Indica se há um usuário autenticado vinculado ao perfil atual.
  bool get estaAutenticado;

  /// Solicita o envio de um código OTP numérico de 6 dígitos para o [email] informado.
  Future<void> solicitarCodigoOtpEmail({required String email});

  /// Valida o [codigo] OTP numérico de 6 dígitos enviado para [email] e vincula a sessão ao perfil local.
  Future<PerfilEscalador> verificarCodigoOtpEmail({
    required String email,
    required String codigo,
  });

  /// Autentica o escalador utilizando sua conta Google (Gmail) in-app via Supabase.
  Future<PerfilEscalador> entrarComGoogle();

  /// Autentica o escalador utilizando sua conta Apple (Apple ID) nativa via Supabase.
  Future<PerfilEscalador> entrarComApple();

  /// Atualiza o nome e/ou a foto de perfil localmente e sincroniza com o Supabase (Auth, Storage e `public.perfis`).
  Future<PerfilEscalador> atualizarPerfilRemoto({
    String? novoNome,
    String? novaFotoUrl,
  });

  /// Encerra a sessão autenticada, limpando o `userId` e preservando os dados offline locais.
  Future<void> encerrarSessao();
}

/// Implementação de produção de [ServicoAutenticacao] integrada ao [RepositorioCaderneta] e ao Supabase.
///
/// Mantém o `autorIdPublico` (NanoID 14c) e as cadenas registradas offline intactos ao
/// vincular ou desvincular uma conta Google, Apple ou código OTP de e-mail, operando sob
/// filosofia *Fail-Fast* (sem contas fictícias de fallback em produção).
class ServicoAutenticacaoLocal implements ServicoAutenticacao {
  static final RegExp _regexCodigoSeisDigitos = RegExp(r'^\d{6}$');

  static ServicoAutenticacao? _instanciaCompartilhada;

  /// Instância compartilhada padrão do serviço de autenticação.
  static ServicoAutenticacao get instancia =>
      _instanciaCompartilhada ??= ServicoAutenticacaoLocal();

  /// Permite substituir a instância compartilhada em testes de integração.
  static set instancia(ServicoAutenticacao? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Redefine a instância compartilhada para o estado inicial em testes.
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  final RepositorioCaderneta _repositorio;
  final ClienteSupabaseAutenticacao _clienteSupabase;
  final String Function() _obterAnonKeySupabase;

  /// Cria uma instância de [ServicoAutenticacaoLocal].
  ServicoAutenticacaoLocal({
    RepositorioCaderneta? repositorio,
    ClienteSupabaseAutenticacao? clienteSupabase,
    ClienteHttpAresta? clienteHttp,
    String Function()? obterUrlSupabase,
    String Function()? obterAnonKeySupabase,
  }) : _repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _clienteSupabase =
           clienteSupabase ??
           ClienteSupabaseAutenticacao(
             clienteHttp: clienteHttp,
             obterUrlSupabase: obterUrlSupabase,
           ),
       _obterAnonKeySupabase =
           obterAnonKeySupabase ??
           (() => RemoteConfigService.instance.supabaseAnonKey);

  @override
  ValueListenable<PerfilEscalador> get perfilListenable =>
      _repositorio.perfilNotifier;

  @override
  PerfilEscalador obterPerfil() => _repositorio.obterPerfil();

  @override
  bool get estaAutenticado => _repositorio.obterPerfil().estaAutenticado;

  /// Valida sintaticamente um endereço de [email], lançando [ExcecaoAutenticacao] de entrada de usuário.
  static String validarFormatoEmail(String email) {
    final emailLimpo = email.trim();
    final partes = emailLimpo.split('@');
    if (partes.length != 2 ||
        partes[0].isEmpty ||
        !partes[1].contains('.') ||
        partes[1].startsWith('.') ||
        partes[1].endsWith('.')) {
      throw const ExcecaoAutenticacao(
        'Informe um endereço de e-mail válido.',
        ehErroUsuario: true,
      );
    }
    return emailLimpo;
  }

  /// Normaliza e valida um [codigo] OTP numérico de 6 dígitos.
  static String validarFormatoCodigoOtp(String codigo) {
    final normalizado = codigo.replaceAll(RegExp(r'\s+'), '');
    if (!_regexCodigoSeisDigitos.hasMatch(normalizado)) {
      throw const ExcecaoAutenticacao(
        'Informe o código numérico de 6 dígitos enviado por e-mail.',
        ehErroUsuario: true,
      );
    }
    return normalizado;
  }

  String _exigirAnonKey() {
    final anonKey = _obterAnonKeySupabase().trim();
    if (anonKey.isEmpty) {
      throw const ExcecaoAutenticacao(
        'Serviço de autenticação indisponível no momento.',
        ehErroUsuario: false,
        causaTecnica: 'supabaseAnonKey vazia em ServicoAutenticacaoLocal',
      );
    }
    return anonKey;
  }

  String _selecionarNomeExibicao({
    required PerfilEscalador perfilAtual,
    required String? nomeDoProvedor,
    required String? nomeFallbackGenerico,
  }) {
    if (nomeDoProvedor == null || nomeDoProvedor.trim().isEmpty) {
      return perfilAtual.autorNomePublico;
    }
    final ehApelidoPadraoLocal =
        perfilAtual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    final ehApenasFallbackGenerico =
        nomeFallbackGenerico != null && nomeDoProvedor == nomeFallbackGenerico;
    if (!ehApelidoPadraoLocal && ehApenasFallbackGenerico) {
      return perfilAtual.autorNomePublico;
    }
    return nomeDoProvedor;
  }

  Future<PerfilEscalador> _salvarPerfilAutenticado({
    required PerfilEscalador perfilAtual,
    required ResultadoProvedorAutenticacao resultado,
    required String? nomeFallbackGenerico,
  }) async {
    final nomeFinal = _selecionarNomeExibicao(
      perfilAtual: perfilAtual,
      nomeDoProvedor: resultado.nomeExibicao,
      nomeFallbackGenerico: nomeFallbackGenerico,
    );
    final novoPerfil = perfilAtual.copyWith(
      autorIdPublico:
          resultado.autorIdPublicoRemoto ?? perfilAtual.autorIdPublico,
      userId: resultado.userId,
      autorNomePublico: nomeFinal,
      fotoUrl: resultado.fotoUrl ?? perfilAtual.fotoUrl,
      accessToken: resultado.accessToken,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
  }

  @override
  Future<void> solicitarCodigoOtpEmail({required String email}) async {
    final emailLimpo = validarFormatoEmail(email);
    final anonKey = _exigirAnonKey();
    await _clienteSupabase.solicitarCodigoOtpEmail(
      email: emailLimpo,
      anonKey: anonKey,
    );
  }

  @override
  Future<PerfilEscalador> verificarCodigoOtpEmail({
    required String email,
    required String codigo,
  }) async {
    final emailLimpo = validarFormatoEmail(email);
    final codigoLimpo = validarFormatoCodigoOtp(codigo);
    final anonKey = _exigirAnonKey();
    final atual = _repositorio.obterPerfil();
    final prefixoEmail = emailLimpo.split('@').first;

    final resultado = await _clienteSupabase.verificarCodigoOtpEmail(
      email: emailLimpo,
      codigo: codigoLimpo,
      autorIdPublicoLocal: atual.autorIdPublico,
      anonKey: anonKey,
    );

    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFallbackGenerico: prefixoEmail,
    );
  }

  @override
  Future<PerfilEscalador> entrarComGoogle() async {
    final anonKey = _exigirAnonKey();
    final atual = _repositorio.obterPerfil();
    final resultado = await _clienteSupabase.autenticarGoogleOAuth(
      autorIdPublicoLocal: atual.autorIdPublico,
      anonKey: anonKey,
    );
    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFallbackGenerico: 'Escalador Google',
    );
  }

  @override
  Future<PerfilEscalador> entrarComApple() async {
    final anonKey = _exigirAnonKey();
    final atual = _repositorio.obterPerfil();
    final resultado = await _clienteSupabase.autenticarAppleOAuth(
      autorIdPublicoLocal: atual.autorIdPublico,
      anonKey: anonKey,
    );
    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFallbackGenerico: 'Escalador Apple',
    );
  }

  @override
  Future<PerfilEscalador> atualizarPerfilRemoto({
    String? novoNome,
    String? novaFotoUrl,
  }) async {
    final atual = _repositorio.obterPerfil();
    final nomeFinal = (novoNome != null && novoNome.trim().isNotEmpty)
        ? novoNome.trim()
        : atual.autorNomePublico;
    var fotoFinal = (novaFotoUrl != null && novaFotoUrl.trim().isNotEmpty)
        ? novaFotoUrl.trim()
        : atual.fotoUrl;

    final anonKey = _obterAnonKeySupabase().trim();
    final accessToken = atual.accessToken;
    if (atual.estaAutenticado &&
        accessToken != null &&
        accessToken.isNotEmpty &&
        anonKey.isNotEmpty) {
      fotoFinal = await _clienteSupabase.sincronizarPerfilAtualizado(
        anonKey: anonKey,
        accessToken: accessToken,
        userId: atual.userId!,
        autorIdPublico: atual.autorIdPublico,
        nomeFinal: nomeFinal,
        fotoFinal: fotoFinal,
      );
    }

    final atualizado = atual.copyWith(
      autorNomePublico: nomeFinal,
      fotoUrl: fotoFinal,
    );
    await _repositorio.salvarPerfil(atualizado);
    return _repositorio.obterPerfil();
  }

  @override
  Future<void> encerrarSessao() async {
    final atual = _repositorio.obterPerfil();
    if (!atual.estaAutenticado) {
      return;
    }
    await _repositorio.salvarPerfil(atual.copyWith(limparUserId: true));
  }
}
