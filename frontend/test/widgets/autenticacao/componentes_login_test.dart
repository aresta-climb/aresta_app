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

  group('Componentes declarativos da tela de Login Sem Senha (Dumb UI)', () {
    testWidgets('BarraTopoLogin, CabecalhoTelaLogin, DivisorSecaoLogin, BannerAvisoLogin e BotaoAbrirConfiguracoesLogin renderizam e acionam callbacks', (tester) async {
      var voltou = false;
      var foiParaInicio = false;
      var abriuConfiguracoes = false;

      await tester.pumpWidget(
        envolverComTema(
          Column(
            children: [
              BarraTopoLogin(
                aoVoltar: () => voltou = true,
                aoIrParaInicio: () => foiParaInicio = true,
              ),
              const CabecalhoTelaLogin(
                titulo: 'Entrar na sua conta',
                subtitulo: 'Subtítulo sem senha',
              ),
              const DivisorSecaoLogin(texto: 'ou receba um código por e-mail'),
              const BannerAvisoLogin(
                key: Key('banner_teste'),
                mensagem: 'Mensagem de alerta',
                icone: Icons.info_outline,
                corDestaque: Colors.orange,
              ),
              BotaoAbrirConfiguracoesLogin(
                aoPressionar: () => abriuConfiguracoes = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('Subtítulo sem senha'), findsOneWidget);
      expect(find.text('ou receba um código por e-mail'), findsOneWidget);
      expect(find.text('Mensagem de alerta'), findsOneWidget);
      expect(find.text('Abrir configurações do app'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_voltar_login')));
      expect(voltou, isTrue);
      expect(foiParaInicio, isFalse);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('btn_voltar_login'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await gesto.up();
      await tester.pumpAndSettle();
      expect(foiParaInicio, isTrue);

      await tester.tap(
        find.byKey(const Key('btn_abrir_configuracoes_login')),
      );
      expect(abriuConfiguracoes, isTrue);
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

    testWidgets('CartaoCodigoEmailLogin renderiza Etapa 1 (e-mail sem senha) e Etapa 2 (código OTP de 6 dígitos com reenvio e troca de e-mail)', (tester) async {
      final emailCtrl = TextEditingController();
      final codigoCtrl = TextEditingController();
      addTearDown(() {
        emailCtrl.dispose();
        codigoCtrl.dispose();
      });

      String? emailDigitado;
      String? codigoDigitado;
      var solicitouCodigo = false;
      var confirmouCodigo = false;
      var reenviouCodigo = false;
      var alterouEmail = false;

      // Etapa 1: solicitação do código por e-mail (zero campos de senha)
      await tester.pumpWidget(
        envolverComTema(
          CartaoCodigoEmailLogin(
            aguardandoCodigoOtp: false,
            carregando: false,
            segundosRestantesReenvio: 0,
            emailController: emailCtrl,
            codigoController: codigoCtrl,
            aoAlterarEmail: (v) => emailDigitado = v,
            aoAlterarCodigo: (v) => codigoDigitado = v,
            aoSolicitarCodigo: () => solicitouCodigo = true,
            aoConfirmarCodigo: () => confirmouCodigo = true,
            aoReenviarCodigo: () => reenviouCodigo = true,
            aoAlterarEmailOtp: () => alterouEmail = true,
          ),
        ),
      );

      expect(find.byKey(const Key('campo_login_email')), findsOneWidget);
      expect(find.byKey(const Key('campo_login_codigo_otp')), findsNothing);
      expect(find.textContaining('Senha'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'atleta@aresta.com',
      );
      expect(emailDigitado, equals('atleta@aresta.com'));

      await tester.tap(find.byKey(const Key('btn_enviar_codigo_otp')));
      expect(solicitouCodigo, isTrue);

      // Etapa 2: digitação do código de 6 dígitos com banner informativo
      await tester.pumpWidget(
        envolverComTema(
          CartaoCodigoEmailLogin(
            aguardandoCodigoOtp: true,
            carregando: false,
            segundosRestantesReenvio: 0,
            mensagemInfoOtp: 'Enviamos um código de 6 dígitos para atleta@aresta.com.',
            emailController: emailCtrl,
            codigoController: codigoCtrl,
            aoAlterarEmail: (v) => emailDigitado = v,
            aoAlterarCodigo: (v) => codigoDigitado = v,
            aoSolicitarCodigo: () => solicitouCodigo = true,
            aoConfirmarCodigo: () => confirmouCodigo = true,
            aoReenviarCodigo: () => reenviouCodigo = true,
            aoAlterarEmailOtp: () => alterouEmail = true,
          ),
        ),
      );

      expect(find.byKey(const Key('banner_info_otp_login')), findsOneWidget);
      expect(find.byKey(const Key('campo_login_codigo_otp')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('campo_login_codigo_otp')),
        '123456',
      );
      expect(codigoDigitado, equals('123456'));

      await tester.tap(find.byKey(const Key('btn_confirmar_codigo_otp')));
      expect(confirmouCodigo, isTrue);

      await tester.tap(find.byKey(const Key('btn_reenviar_codigo_otp')));
      expect(reenviouCodigo, isTrue);

      await tester.tap(find.byKey(const Key('btn_alterar_email_otp')));
      expect(alterouEmail, isTrue);
    });

    testWidgets('CartaoCodigoEmailLogin desabilita ações durante carregamento e exibe contagem regressiva de cooldown no reenvio', (tester) async {
      final emailCtrl = TextEditingController();
      final codigoCtrl = TextEditingController();
      addTearDown(() {
        emailCtrl.dispose();
        codigoCtrl.dispose();
      });

      var reenviou = false;
      await tester.pumpWidget(
        envolverComTema(
          CartaoCodigoEmailLogin(
            aguardandoCodigoOtp: true,
            carregando: false,
            segundosRestantesReenvio: 42,
            emailController: emailCtrl,
            codigoController: codigoCtrl,
            aoAlterarEmail: (_) {},
            aoAlterarCodigo: (_) {},
            aoSolicitarCodigo: () {},
            aoConfirmarCodigo: () {},
            aoReenviarCodigo: () => reenviou = true,
            aoAlterarEmailOtp: () {},
          ),
        ),
      );

      expect(find.text('Reenviar código (42s)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_reenviar_codigo_otp')));
      expect(reenviou, isFalse);

      // Etapa 1 durante cooldown exibe contagem regressiva no botão principal
      await tester.pumpWidget(
        envolverComTema(
          CartaoCodigoEmailLogin(
            aguardandoCodigoOtp: false,
            carregando: false,
            segundosRestantesReenvio: 15,
            emailController: emailCtrl,
            codigoController: codigoCtrl,
            aoAlterarEmail: (_) {},
            aoAlterarCodigo: (_) {},
            aoSolicitarCodigo: () {},
            aoConfirmarCodigo: () {},
            aoReenviarCodigo: () {},
            aoAlterarEmailOtp: () {},
          ),
        ),
      );
      expect(find.text('Aguarde 15s'), findsOneWidget);
    });
  });
}
