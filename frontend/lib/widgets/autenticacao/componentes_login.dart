// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
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

/// Cabeçalho textual da tela de login exibindo título e subtítulo do modo atual.
class CabecalhoTelaLogin extends StatelessWidget {
  /// Título de destaque (ex.: entrar ou criar conta).
  final String titulo;

  /// Subtítulo explicativo sobre sincronização de cadenas e interações.
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

/// Divisor horizontal com rótulo centralizado entre login social e e-mail.
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

/// Banner informativo ou de erro exibido dentro do formulário de autenticação.
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

/// Cartão de formulário declarativo para autenticação ou cadastro por e-mail e senha.
class CartaoFormularioEmailLogin extends StatelessWidget {
  /// Indica se o formulário deve exibir o campo adicional de nome/apelido.
  final bool modoCriarConta;

  /// Indica se os caracteres da senha devem permanecer ocultos.
  final bool ocultarSenha;

  /// Indica se há uma operação de rede em andamento (desabilitando ações).
  final bool carregando;

  /// Rótulo do botão principal de submissão.
  final String rotuloBotaoPrincipal;

  /// Rótulo do botão secundário que alterna entre entrar e criar conta.
  final String rotuloAlternarModo;

  /// Mensagem de confirmação de e-mail pendente, quando existente.
  final String? mensagemConfirmacaoEmail;

  /// Mensagem de erro de validação ou autenticação, quando existente.
  final String? mensagemErro;

  /// Controlador do campo de nome ou apelido.
  final TextEditingController nomeController;

  /// Controlador do campo de e-mail.
  final TextEditingController emailController;

  /// Controlador do campo de senha.
  final TextEditingController senhaController;

  /// Callback acionado ao alterar o texto do nome.
  final ValueChanged<String> aoAlterarNome;

  /// Callback acionado ao alterar o texto do e-mail.
  final ValueChanged<String> aoAlterarEmail;

  /// Callback acionado ao alterar o texto da senha.
  final ValueChanged<String> aoAlterarSenha;

  /// Callback acionado ao alternar a visibilidade da senha.
  final VoidCallback aoAlternarVisibilidadeSenha;

  /// Callback acionado ao tocar no botão principal de submissão.
  final VoidCallback aoSubmeter;

  /// Callback acionado ao tocar no botão de alternância de modo da conta.
  final VoidCallback aoAlternarModoConta;

  /// Cria uma instância de [CartaoFormularioEmailLogin].
  const CartaoFormularioEmailLogin({
    super.key,
    required this.modoCriarConta,
    required this.ocultarSenha,
    required this.carregando,
    required this.rotuloBotaoPrincipal,
    required this.rotuloAlternarModo,
    this.mensagemConfirmacaoEmail,
    this.mensagemErro,
    required this.nomeController,
    required this.emailController,
    required this.senhaController,
    required this.aoAlterarNome,
    required this.aoAlterarEmail,
    required this.aoAlterarSenha,
    required this.aoAlternarVisibilidadeSenha,
    required this.aoSubmeter,
    required this.aoAlternarModoConta,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
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
          if (modoCriarConta) ...[
            TextField(
              key: const Key('campo_login_nome'),
              controller: nomeController,
              onChanged: aoAlterarNome,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: _decoracaoCampo(
                cores: cores,
                rotulo: 'Nome ou apelido',
                icone: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            key: const Key('campo_login_email'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: aoAlterarEmail,
            style: TextStyle(color: cores.chalkWhite, fontSize: 14),
            decoration: _decoracaoCampo(
              cores: cores,
              rotulo: 'E-mail',
              icone: Icons.alternate_email,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('campo_login_senha'),
            controller: senhaController,
            obscureText: ocultarSenha,
            onChanged: aoAlterarSenha,
            style: TextStyle(color: cores.chalkWhite, fontSize: 14),
            decoration: _decoracaoCampo(
              cores: cores,
              rotulo: 'Senha',
              icone: Icons.lock_outline,
              sufixo: IconButton(
                key: const Key('btn_alternar_visibilidade_senha'),
                icon: Icon(
                  ocultarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: cores.ashGrey,
                  size: 20,
                ),
                onPressed: aoAlternarVisibilidadeSenha,
              ),
            ),
          ),
          if (mensagemConfirmacaoEmail != null) ...[
            const SizedBox(height: 10),
            BannerAvisoLogin(
              key: const Key('banner_confirmacao_email_login'),
              mensagem: mensagemConfirmacaoEmail!,
              icone: Icons.mark_email_read_outlined,
              corDestaque: cores.dryMoss,
            ),
          ],
          if (mensagemErro != null) ...[
            const SizedBox(height: 10),
            BannerAvisoLogin(
              key: const Key('banner_erro_login'),
              mensagem: mensagemErro!,
              icone: Icons.error_outline,
              corDestaque: cores.rustIron,
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('btn_submeter_email_senha'),
            onPressed: carregando ? null : aoSubmeter,
            style: ElevatedButton.styleFrom(
              backgroundColor: cores.rustIron,
              foregroundColor: cores.chalkWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              rotuloBotaoPrincipal,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('btn_alternar_modo_conta'),
            onPressed: carregando ? null : aoAlternarModoConta,
            child: Text(
              rotuloAlternarModo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cores.chalkWhite.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required AppColors cores,
    required String rotulo,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: TextStyle(color: cores.ashGrey, fontSize: 13),
      prefixIcon: Icon(icone, color: cores.ashGrey, size: 20),
      suffixIcon: sufixo,
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

