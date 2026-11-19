// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/cores_app.dart';

/// Barra superior declarativa da tela de login com botão de retorno e marca.
class BarraTopoLogin extends StatelessWidget {
  /// Callback acionado ao tocar no botão de voltar.
  final VoidCallback aoVoltar;

  /// Cria uma instância de [BarraTopoLogin].
  const BarraTopoLogin({
    super.key,
    required this.aoVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 20, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('btn_voltar_login'),
            icon: Icon(Icons.arrow_back, color: cores.chalkWhite),
            tooltip: 'Voltar',
            onPressed: aoVoltar,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'ARESTA CLIMB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.dryMoss,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho textual da tela de login exibindo título e subtítulo explicativo.
class CabecalhoTelaLogin extends StatelessWidget {
  /// Título de destaque da tela de autenticação.
  final String titulo;

  /// Subtítulo explicativo sobre sincronização sem senha da caderneta.
  final String subtitulo;

  /// Cria uma instância de [CabecalhoTelaLogin].
  const CabecalhoTelaLogin({
    super.key,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Botão padronizado para provedores de login social OAuth (Google, Apple).
class BotaoProvedorOAuthLogin extends StatelessWidget {
  /// Rótulo exibido ao lado do distintivo do provedor.
  final String rotulo;

  /// Ícone ou letra estilizada que identifica o provedor OAuth.
  final Widget distintivo;

  /// Callback acionado ao pressionar o botão (`null` desabilita durante carregamento).
  final VoidCallback? aoPressionar;

  /// Cria uma instância de [BotaoProvedorOAuthLogin].
  const BotaoProvedorOAuthLogin({
    super.key,
    required this.rotulo,
    required this.distintivo,
    required this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return OutlinedButton(
      onPressed: aoPressionar,
      style: OutlinedButton.styleFrom(
        backgroundColor: cores.caveShadow,
        foregroundColor: cores.chalkWhite,
        side: BorderSide(color: cores.graniteEdge, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: distintivo,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divisor horizontal com rótulo centralizado entre login social e código por e-mail.
class DivisorSecaoLogin extends StatelessWidget {
  /// Texto exibido ao centro do divisor.
  final String texto;

  /// Cria uma instância de [DivisorSecaoLogin].
  const DivisorSecaoLogin({
    super.key,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: cores.graniteEdge, thickness: 1)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cores.ashGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: cores.graniteEdge, thickness: 1)),
      ],
    );
  }
}

/// Banner informativo ou de erro exibido na tela de autenticação.
class BannerAvisoLogin extends StatelessWidget {
  /// Texto da mensagem exibida ao escalador.
  final String mensagem;

  /// Ícone ilustrativo exibido à esquerda da mensagem.
  final IconData icone;

  /// Cor principal da borda, fundo translúcido e ícone.
  final Color corDestaque;

  /// Cria uma instância de [BannerAvisoLogin].
  const BannerAvisoLogin({
    super.key,
    required this.mensagem,
    required this.icone,
    required this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: corDestaque.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: corDestaque.withValues(alpha: 0.52),
        ),
      ),
      child: Row(
        children: [
          Icon(icone, color: corDestaque, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão declarativo para autenticação sem senha via código numérico de 6 dígitos (Magic Code OTP).
class CartaoCodigoEmailLogin extends StatelessWidget {
  /// Indica se o cartão está na Etapa 2 aguardando a digitação do código de 6 dígitos.
  final bool aguardandoCodigoOtp;

  /// Indica se há uma operação de rede em andamento (desabilitando botões).
  final bool carregando;

  /// Segundos restantes de bloqueio de reenvio na janela deslizante (`0` quando disponível).
  final int segundosRestantesReenvio;

  /// Mensagem informativa após o envio do código OTP, quando presente.
  final String? mensagemInfoOtp;

  /// Controlador do campo de e-mail.
  final TextEditingController emailController;

  /// Controlador do campo do código numérico de 6 dígitos.
  final TextEditingController codigoController;

  /// Callback acionado ao alterar o texto do e-mail.
  final ValueChanged<String> aoAlterarEmail;

  /// Callback acionado ao alterar o código OTP digitado.
  final ValueChanged<String> aoAlterarCodigo;

  /// Callback acionado para enviar o código de 6 dígitos na Etapa 1.
  final VoidCallback aoSolicitarCodigo;

  /// Callback acionado para validar o código de 6 dígitos na Etapa 2.
  final VoidCallback aoConfirmarCodigo;

  /// Callback acionado para solicitar o reenvio do código na Etapa 2.
  final VoidCallback aoReenviarCodigo;

  /// Callback acionado para retornar à Etapa 1 e alterar o endereço de e-mail.
  final VoidCallback aoAlterarEmailOtp;

  /// Cria uma instância de [CartaoCodigoEmailLogin].
  const CartaoCodigoEmailLogin({
    super.key,
    required this.aguardandoCodigoOtp,
    required this.carregando,
    required this.segundosRestantesReenvio,
    this.mensagemInfoOtp,
    required this.emailController,
    required this.codigoController,
    required this.aoAlterarEmail,
    required this.aoAlterarCodigo,
    required this.aoSolicitarCodigo,
    required this.aoConfirmarCodigo,
    required this.aoReenviarCodigo,
    required this.aoAlterarEmailOtp,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final bloqueadoReenvio = carregando || segundosRestantesReenvio > 0;
    final rotuloReenvio = segundosRestantesReenvio > 0
        ? 'Reenviar código (${segundosRestantesReenvio}s)'
        : 'Reenviar código';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!aguardandoCodigoOtp) ...[
            TextField(
              key: const Key('campo_login_email'),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              onChanged: aoAlterarEmail,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: _decoracaoCampo(
                cores: cores,
                rotulo: 'E-mail',
                icone: Icons.alternate_email,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('btn_enviar_codigo_otp'),
              onPressed: bloqueadoReenvio ? null : aoSolicitarCodigo,
              style: _estiloBotaoPrimario(cores),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  segundosRestantesReenvio > 0
                      ? 'Aguarde ${segundosRestantesReenvio}s'
                      : 'Receber código por e-mail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (mensagemInfoOtp != null) ...[
              BannerAvisoLogin(
                key: const Key('banner_info_otp_login'),
                mensagem: mensagemInfoOtp!,
                icone: Icons.mark_email_read_outlined,
                corDestaque: cores.dryMoss,
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const Key('campo_login_codigo_otp'),
              controller: codigoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: aoAlterarCodigo,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
              decoration: _decoracaoCampo(
                cores: cores,
                rotulo: 'Código de 6 dígitos',
                icone: Icons.pin_outlined,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('btn_confirmar_codigo_otp'),
              onPressed: carregando ? null : aoConfirmarCodigo,
              style: _estiloBotaoPrimario(cores),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Confirmar código',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('btn_reenviar_codigo_otp'),
                  onPressed: bloqueadoReenvio ? null : aoReenviarCodigo,
                  child: Text(
                    rotuloReenvio,
                    style: TextStyle(
                      color: bloqueadoReenvio
                          ? cores.ashGrey
                          : cores.chalkWhite.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('btn_alterar_email_otp'),
                  onPressed: carregando ? null : aoAlterarEmailOtp,
                  child: Text(
                    'Usar outro e-mail',
                    style: TextStyle(
                      color: cores.ashGrey,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle _estiloBotaoPrimario(AppColors cores) {
    return ElevatedButton.styleFrom(
      backgroundColor: cores.rustIron,
      foregroundColor: cores.chalkWhite,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    );
  }

  InputDecoration _decoracaoCampo({
    required AppColors cores,
    required String rotulo,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: TextStyle(color: cores.ashGrey, fontSize: 13),
      prefixIcon: Icon(icone, color: cores.ashGrey, size: 20),
      filled: true,
      fillColor: cores.deepBasalt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cores.graniteEdge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cores.rustIron, width: 1.4),
      ),
    );
  }
}

/// Botão declarativo para continuar usando o aplicativo sem conta (modo offline).
class BotaoContinuarSemContaLogin extends StatelessWidget {
  /// Callback acionado ao escolher continuar sem conta.
  final VoidCallback aoPressionar;

  /// Cria uma instância de [BotaoContinuarSemContaLogin].
  const BotaoContinuarSemContaLogin({
    super.key,
    required this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return TextButton(
      key: const Key('btn_continuar_sem_conta'),
      onPressed: aoPressionar,
      style: TextButton.styleFrom(
        foregroundColor: cores.ashGrey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cores.graniteEdge.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 18,
            color: cores.dryMoss,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Continuar sem conta / Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cores.chalkWhite.withValues(alpha: 0.9),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
