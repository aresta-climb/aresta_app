// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/autenticacao/componentes_login.dart';

void main() {
  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  group('Componentes declarativos da tela de Login (Dumb UI)', () {
    testWidgets('BarraTopoLogin, CabecalhoTelaLogin, DivisorSecaoLogin e BotaoContinuarSemContaLogin renderizam e acionam callbacks', (tester) async {
      var voltou = false;
      var continuouOffline = false;

      await tester.pumpWidget(
        envolverComTema(
          Column(
            children: [
              BarraTopoLogin(aoVoltar: () => voltou = true),
              const CabecalhoTelaLogin(
                titulo: 'Entrar na sua conta',
                subtitulo: 'Subtítulo de teste',
              ),
              const DivisorSecaoLogin(texto: 'ou use seu e-mail'),
              BotaoContinuarSemContaLogin(
                aoPressionar: () => continuouOffline = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('Subtítulo de teste'), findsOneWidget);
      expect(find.text('ou use seu e-mail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_voltar_login')));
      expect(voltou, isTrue);

      await tester.tap(find.byKey(const Key('btn_continuar_sem_conta')));
      expect(continuouOffline, isTrue);
    });

    testWidgets('BotaoProvedorOAuthLogin renderiza distintivo, rótulo e dispara callback quando habilitado', (tester) async {
      var acionado = 0;

      await tester.pumpWidget(
        envolverComTema(
          BotaoProvedorOAuthLogin(
            key: const Key('btn_oauth_teste'),
            rotulo: 'Continuar com Provedor',
            distintivo: const Text('P'),
            aoPressionar: () => acionado++,
          ),
        ),
      );

      expect(find.text('Continuar com Provedor'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_oauth_teste')));
      expect(acionado, equals(1));
    });

    testWidgets('CartaoFormularioEmailLogin renderiza campos, banners de confirmação e erro e aciona callbacks de edição e submissão', (tester) async {
      final nomeCtrl = TextEditingController();
      final emailCtrl = TextEditingController();
      final senhaCtrl = TextEditingController();
      addTearDown(() {
        nomeCtrl.dispose();
        emailCtrl.dispose();
        senhaCtrl.dispose();
      });

      String? nomeDigitado;
      String? emailDigitado;
      String? senhaDigitada;
      var alternouSenha = false;
      var submeteu = false;
      var alternouModo = false;

      await tester.pumpWidget(
        envolverComTema(
          CartaoFormularioEmailLogin(
            modoCriarConta: true,
            ocultarSenha: true,
            carregando: false,
            rotuloBotaoPrincipal: 'Criar conta',
            rotuloAlternarModo: 'Já tem uma conta? Entrar',
            mensagemConfirmacaoEmail: 'Confirme seu e-mail na caixa de entrada.',
            mensagemErro: 'Erro de validação.',
            nomeController: nomeCtrl,
            emailController: emailCtrl,
            senhaController: senhaCtrl,
            aoAlterarNome: (v) => nomeDigitado = v,
            aoAlterarEmail: (v) => emailDigitado = v,
            aoAlterarSenha: (v) => senhaDigitada = v,
            aoAlternarVisibilidadeSenha: () => alternouSenha = true,
            aoSubmeter: () => submeteu = true,
            aoAlternarModoConta: () => alternouModo = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('banner_confirmacao_email_login')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('banner_erro_login')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('campo_login_nome')),
        'Escalador',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'atleta@aresta.com',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_senha')),
        '123456',
      );
      expect(nomeDigitado, equals('Escalador'));
      expect(emailDigitado, equals('atleta@aresta.com'));
      expect(senhaDigitada, equals('123456'));

      await tester.tap(
        find.byKey(const Key('btn_alternar_visibilidade_senha')),
      );
      expect(alternouSenha, isTrue);

      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      expect(submeteu, isTrue);

      await tester.tap(find.byKey(const Key('btn_alternar_modo_conta')));
      expect(alternouModo, isTrue);
    });

    testWidgets('CartaoFormularioEmailLogin oculta campo de nome no modo Entrar, exibe ícone de senha visível e desabilita botões quando carregando', (tester) async {
      final nomeCtrl = TextEditingController();
      final emailCtrl = TextEditingController();
      final senhaCtrl = TextEditingController();
      addTearDown(() {
        nomeCtrl.dispose();
        emailCtrl.dispose();
        senhaCtrl.dispose();
      });

      var submeteu = false;
      var alternouModo = false;

      await tester.pumpWidget(
        envolverComTema(
          CartaoFormularioEmailLogin(
            modoCriarConta: false,
            ocultarSenha: false,
            carregando: true,
            rotuloBotaoPrincipal: 'Entrar',
            rotuloAlternarModo: 'Não tem conta? Criar agora',
            nomeController: nomeCtrl,
            emailController: emailCtrl,
            senhaController: senhaCtrl,
            aoAlterarNome: (_) {},
            aoAlterarEmail: (_) {},
            aoAlterarSenha: (_) {},
            aoAlternarVisibilidadeSenha: () {},
            aoSubmeter: () => submeteu = true,
            aoAlternarModoConta: () => alternouModo = true,
          ),
        ),
      );

      expect(find.byKey(const Key('campo_login_nome')), findsNothing);
      expect(
        find.byKey(const Key('banner_confirmacao_email_login')),
        findsNothing,
      );
      expect(find.byKey(const Key('banner_erro_login')), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      await tester.tap(find.byKey(const Key('btn_alternar_modo_conta')));
      expect(submeteu, isFalse);
      expect(alternouModo, isFalse);
    });
  });
}
