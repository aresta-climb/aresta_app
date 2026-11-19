// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/autenticacao/servico_autenticacao.dart';
import '../../services/firebase/app_logger.dart';

/// ViewModel responsável pelo estado e regras de negócio da tela de Login sem senha (MVVM).
///
/// Orquestra o fluxo em duas etapas de Magic Code (OTP numérico de 6 dígitos por e-mail)
/// com controle de frequência por janela deslizante (6 envios a cada 60s), autenticação
/// in-app com Google e Apple, tratamento silencioso de cancelamento voluntário, roteamento
/// de falhas reais para o [AppLogger] e proteção contra uso após [dispose].
class LoginViewModel extends ChangeNotifier {
  /// Quantidade máxima de solicitações de código OTP permitidas por janela móvel.
  static const int limiteEnviosPorJanela = 6;

  /// Duração da janela móvel de controle de frequência para reenvio de código OTP.
  static const Duration duracaoJanelaOtp = Duration(seconds: 60);

  /// Serviço de autenticação subjacente.
  final ServicoAutenticacao servicoAutenticacao;

  /// Callback opcional invocado após autenticação bem-sucedida.
  final VoidCallback? aoAutenticarComSucesso;

  /// Callback opcional invocado quando o escalador opta por continuar sem conta (offline).
  final VoidCallback? aoContinuarSemConta;

  final DateTime Function() _obterAgora;
  final List<DateTime> _historicoEnviosOtp = <DateTime>[];
  Timer? _timerContagemRegressiva;

  bool _descartado = false;
  String _email = '';
  String _codigoOtp = '';
  bool _aguardandoCodigoOtp = false;
  bool _carregando = false;
  String? _mensagemErro;
  String? _mensagemInfoOtp;

  /// Cria uma instância de [LoginViewModel].
  LoginViewModel({
    ServicoAutenticacao? servicoAutenticacao,
    this.aoAutenticarComSucesso,
    this.aoContinuarSemConta,
    DateTime Function()? obterAgora,
  }) : servicoAutenticacao =
           servicoAutenticacao ?? ServicoAutenticacaoLocal.instancia,
       _obterAgora = obterAgora ?? DateTime.now;

  /// Endereço de e-mail informado pelo escalador.
  String get email => _email;

  /// Código OTP numérico de 6 dígitos digitado pelo escalador.
  String get codigoOtp => _codigoOtp;

  /// Indica se a interface está na Etapa 2 aguardando a digitação do código de 6 dígitos.
  bool get aguardandoCodigoOtp => _aguardandoCodigoOtp;

  /// Indica se uma operação de rede/autenticação está em andamento.
  bool get carregando => _carregando;

  /// Mensagem de erro amigável a ser exibida na interface, quando presente.
  String? get mensagemErro => _mensagemErro;

  /// Mensagem informativa indicando o envio do código de 6 dígitos para o e-mail.
  String? get mensagemInfoOtp => _mensagemInfoOtp;

  /// Título principal exibido no cabeçalho da tela de login.
  String get tituloCabecalho => 'Entrar na sua conta';

  /// Subtítulo explicativo exibido abaixo do título principal.
  String get subtituloCabecalho =>
      'Entre sem senha usando sua conta social ou um código de 6 dígitos enviado por e-mail para sincronizar sua caderneta.';

  /// Segundos restantes até liberar um novo envio de código OTP quando o limite de
  /// [limiteEnviosPorJanela] em [duracaoJanelaOtp] foi atingido (`0` quando liberado).
  int get segundosRestantesReenvio {
    final agora = _obterAgora();
    _podarHistoricoJanelaOtp(agora);
    if (_historicoEnviosOtp.length < limiteEnviosPorJanela) {
      return 0;
    }
    final liberacao = _historicoEnviosOtp.first.add(duracaoJanelaOtp);
    final restanteMs = liberacao.difference(agora).inMilliseconds;
    if (restanteMs <= 0) {
      return 0;
    }
    return (restanteMs / 1000).ceil();
  }

  /// Indica se o escalador pode disparar uma nova solicitação de código OTP neste instante.
  bool get podeSolicitarCodigoOtp =>
      !_carregando && segundosRestantesReenvio == 0;

  void _podarHistoricoJanelaOtp(DateTime agora) {
    final limiteAntigo = agora.subtract(duracaoJanelaOtp);
    _historicoEnviosOtp.removeWhere((instante) => !instante.isAfter(limiteAntigo));
  }

  void _iniciarMonitoramentoContagemSeNecessario() {
    if (segundosRestantesReenvio <= 0) {
      _timerContagemRegressiva?.cancel();
      _timerContagemRegressiva = null;
      return;
    }
    _timerContagemRegressiva ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (segundosRestantesReenvio <= 0) {
          _timerContagemRegressiva?.cancel();
          _timerContagemRegressiva = null;
        }
        _notificarOuvintes();
      },
    );
  }

  void _notificarOuvintes() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  void _limparErroAoEditar() {
    if (_mensagemErro != null) {
      _mensagemErro = null;
      _notificarOuvintes();
    }
  }

  /// Atualiza o e-mail digitado e limpa alertas de erro anteriores.
  void definirEmail(String valor) {
    _email = valor;
    _limparErroAoEditar();
  }

  /// Atualiza o código OTP de 6 dígitos digitado e limpa alertas de erro anteriores.
  void definirCodigoOtp(String valor) {
    _codigoOtp = valor;
    _limparErroAoEditar();
  }

  /// Retorna à Etapa 1 permitindo corrigir ou trocar o endereço de e-mail informado.
  void alterarEmailOtp() {
    _aguardandoCodigoOtp = false;
    _codigoOtp = '';
    _mensagemErro = null;
    _mensagemInfoOtp = null;
    _notificarOuvintes();
  }

  /// Solicita o envio do código OTP de 6 dígitos para o [email] atual.
  ///
  /// Retorna `true` quando o código foi disparado e a tela avançou para a Etapa 2.
  Future<bool> solicitarCodigoEmail() async {
    final espera = segundosRestantesReenvio;
    if (espera > 0) {
      _mensagemErro =
          'Limite temporário atingido. Aguarde ${espera}s para solicitar outro código.';
      _notificarOuvintes();
      return false;
    }

    return _executarOperacaoAssincrona(
      acao: () async {
        await servicoAutenticacao.solicitarCodigoOtpEmail(email: _email);
        _historicoEnviosOtp.add(_obterAgora());
        _iniciarMonitoramentoContagemSeNecessario();
        _aguardandoCodigoOtp = true;
        _codigoOtp = '';
        _mensagemInfoOtp =
            'Enviamos um código de 6 dígitos para ${_email.trim()}. Verifique sua caixa de entrada e spam.';
        return true;
      },
      notificarAutenticacaoConcluida: false,
      contextoLogErro: 'Erro inesperado ao solicitar código OTP por e-mail',
      mensagemErroGenerico:
          'Não foi possível enviar o código de acesso. Tente novamente.',
    );
  }

  /// Reenvia um novo código OTP de 6 dígitos para o [email] atual respeitando a janela deslizante.
  Future<bool> reenviarCodigoEmail() => solicitarCodigoEmail();

  /// Valida o [codigoOtp] de 6 dígitos informado e conclui a sessão autenticada.
  Future<bool> confirmarCodigoEmail() {
    return _executarOperacaoAssincrona(
      acao: () async {
        await servicoAutenticacao.verificarCodigoOtpEmail(
          email: _email,
          codigo: _codigoOtp,
        );
        _aguardandoCodigoOtp = false;
        _codigoOtp = '';
        _mensagemInfoOtp = null;
        return true;
      },
      notificarAutenticacaoConcluida: true,
      contextoLogErro: 'Erro inesperado ao verificar código OTP por e-mail',
      mensagemErroGenerico:
          'Não foi possível validar o código de acesso. Tente novamente.',
    );
  }

  /// Inicia o fluxo de autenticação in-app via conta Google (Gmail).
  Future<bool> entrarComGoogle() {
    return _executarOperacaoAssincrona(
      acao: () async {
        await servicoAutenticacao.entrarComGoogle();
        return true;
      },
      notificarAutenticacaoConcluida: true,
      contextoLogErro: 'Erro inesperado no login com Google',
      mensagemErroGenerico:
          'Não foi possível entrar com o Google. Tente novamente.',
    );
  }

  /// Inicia o fluxo de autenticação nativa via conta Apple (Apple ID).
  Future<bool> entrarComApple() {
    return _executarOperacaoAssincrona(
      acao: () async {
        await servicoAutenticacao.entrarComApple();
        return true;
      },
      notificarAutenticacaoConcluida: true,
      contextoLogErro: 'Erro inesperado no login com Apple',
      mensagemErroGenerico:
          'Não foi possível entrar com a Apple. Tente novamente.',
    );
  }

  Future<bool> _executarOperacaoAssincrona({
    required Future<bool> Function() acao,
    required bool notificarAutenticacaoConcluida,
    required String contextoLogErro,
    required String mensagemErroGenerico,
  }) async {
    _carregando = true;
    _mensagemErro = null;
    _notificarOuvintes();

    try {
      final sucesso = await acao();
      _carregando = false;
      _notificarOuvintes();
      if (sucesso && notificarAutenticacaoConcluida && !_descartado) {
        aoAutenticarComSucesso?.call();
      }
      return sucesso;
    } on ExcecaoAutenticacaoCancelada {
      _carregando = false;
      _notificarOuvintes();
      return false;
    } on ExcecaoAutenticacao catch (e, stackTrace) {
      _carregando = false;
      _mensagemErro = e.mensagem;
      if (!e.ehErroUsuario) {
        if (AppLogger.isFalhaConexaoOuTimeout(e)) {
          AppLogger.instance.logAviso('$contextoLogErro ($e)');
        } else {
          AppLogger.instance.logError(
            contextoLogErro,
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      _notificarOuvintes();
      return false;
    } catch (e, stackTrace) {
      _carregando = false;
      if (AppLogger.isFalhaConexaoOuTimeout(e)) {
        AppLogger.instance.logAviso('$contextoLogErro ($e)');
        _mensagemErro =
            'Sem conexão com a internet. Verifique o sinal e tente novamente.';
      } else {
        AppLogger.instance.logError(
          contextoLogErro,
          error: e,
          stackTrace: stackTrace,
        );
        _mensagemErro = mensagemErroGenerico;
      }
      _notificarOuvintes();
      return false;
    }
  }

  /// Aciona o fluxo de navegação para continuar usando o aplicativo sem conta (modo offline).
  void continuarSemConta() {
    _mensagemErro = null;
    aoContinuarSemConta?.call();
  }

  @override
  void dispose() {
    _descartado = true;
    _timerContagemRegressiva?.cancel();
    _timerContagemRegressiva = null;
    super.dispose();
  }
}
