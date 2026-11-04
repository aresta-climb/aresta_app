// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ServicoAutenticacaoLocal servicoAutenticacao;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;
    servicoAutenticacao = ServicoAutenticacaoLocal(repositorio: repositorio);
    ServicoAutenticacaoLocal.instancia = servicoAutenticacao;
  });

  tearDown(() {
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  group('LoginViewModel', () {
    test('inicia no modo Entrar com textos correspondentes e alterna modos e visibilidade de senha', () {
      final vm = LoginViewModel();

      expect(vm.modoCriarConta, isFalse);
      expect(vm.ocultarSenha, isTrue);
      expect(vm.carregando, isFalse);
      expect(vm.mensagemErro, isNull);
      expect(vm.tituloCabecalho, equals('Entrar na sua conta'));
      expect(
        vm.subtituloCabecalho,
        contains('Entre com sua conta Google ou e-mail'),
      );
      expect(vm.rotuloBotaoPrincipal, equals('Entrar'));
      expect(vm.rotuloAlternarModo, equals('Não tem conta? Criar agora'));

      vm.alternarModoConta();
      expect(vm.modoCriarConta, isTrue);
      expect(vm.tituloCabecalho, equals('Criar conta Aresta'));
      expect(
        vm.subtituloCabecalho,
        contains('Sincronize sua caderneta esportiva na nuvem'),
      );
      expect(vm.rotuloBotaoPrincipal, equals('Criar conta'));
      expect(vm.rotuloAlternarModo, equals('Já tem uma conta? Entrar'));

      vm.alternarVisibilidadeSenha();
      expect(vm.ocultarSenha, isFalse);

      vm.dispose();
    });

    test('submeterEmailSenha no modo Entrar valida erros, limpa erro ao editar campos e autentica com sucesso', () async {
      var sucessoAcionado = 0;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoAutenticacao,
        aoAutenticarComSucesso: () => sucessoAcionado++,
      );

      vm.definirEmail('invalido');
      vm.definirSenha('123');

      final resultadoFalha = await vm.submeterEmailSenha();
      expect(resultadoFalha, isFalse);
      expect(vm.mensagemErro, equals('Informe um endereço de e-mail válido.'));
      expect(sucessoAcionado, equals(0));

      // Editar qualquer campo limpa a mensagem de erro automaticamente
      vm.definirEmail('pedro@gmail.com');
      expect(vm.mensagemErro, isNull);

      final resultadoSenhaCurta = await vm.submeterEmailSenha();
      expect(resultadoSenhaCurta, isFalse);
      expect(
        vm.mensagemErro,
        equals('A senha deve ter pelo menos 6 caracteres.'),
      );

      vm.definirSenha('senhaForte123');
      expect(vm.mensagemErro, isNull);

      final resultadoSucesso = await vm.submeterEmailSenha();
      expect(resultadoSucesso, isTrue);
      expect(vm.mensagemErro, isNull);
      expect(sucessoAcionado, equals(1));
      expect(servicoAutenticacao.estaAutenticado, isTrue);

      vm.dispose();
    });

    test('submeterEmailSenha no modo Criar Conta valida nome e cria conta autenticada', () async {
      var sucessoAcionado = 0;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoAutenticacao,
        aoAutenticarComSucesso: () => sucessoAcionado++,
      );

      vm.alternarModoConta();
      vm.definirEmail('clara@gmail.com');
      vm.definirSenha('123456');

      final semNome = await vm.submeterEmailSenha();
      expect(semNome, isFalse);
      expect(
        vm.mensagemErro,
        equals('Informe seu nome ou apelido de escalador.'),
      );

      vm.definirNome('Clara Escaladora');
      expect(vm.mensagemErro, isNull);

      final criado = await vm.submeterEmailSenha();
      expect(criado, isTrue);
      expect(sucessoAcionado, equals(1));
      expect(repositorio.obterPerfil().autorNomePublico, equals('Clara Escaladora'));
      expect(repositorio.obterPerfil().estaAutenticado, isTrue);

      vm.dispose();
    });

    test('entrarComGoogle e continuarSemConta acionam callbacks e tratam exceções', () async {
      var autenticado = 0;
      var continuouSemConta = 0;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoAutenticacao,
        aoAutenticarComSucesso: () => autenticado++,
        aoContinuarSemConta: () => continuouSemConta++,
      );

      final logouGoogle = await vm.entrarComGoogle();
      expect(logouGoogle, isTrue);
      expect(autenticado, equals(1));
      expect(servicoAutenticacao.estaAutenticado, isTrue);

      vm.continuarSemConta();
      expect(continuouSemConta, equals(1));

      vm.dispose();
    });

    test('captura ExcecaoAutenticacao e exceções inesperadas do provedor no e-mail e no Google', () async {
      final servicoComFalhaDominioGoogle = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        provedorGoogle: () async =>
            throw const ExcecaoAutenticacao('Login com Google cancelado.'),
        provedorEmailSenha: (email, senha) async =>
            throw Exception('Falha de rede'),
      );

      final vm1 = LoginViewModel(
        servicoAutenticacao: servicoComFalhaDominioGoogle,
      );
      vm1.definirEmail('teste@gmail.com');
      vm1.definirSenha('123456');

      expect(await vm1.submeterEmailSenha(), isFalse);
      expect(
        vm1.mensagemErro,
        equals('Não foi possível concluir a autenticação. Tente novamente.'),
      );

      expect(await vm1.entrarComGoogle(), isFalse);
      expect(vm1.mensagemErro, equals('Login com Google cancelado.'));
      vm1.dispose();

      final servicoComFalhaGenericaGoogle = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        provedorGoogle: () async => throw Exception('Erro OAuth'),
      );
      final vm2 = LoginViewModel(
        servicoAutenticacao: servicoComFalhaGenericaGoogle,
      );
      expect(await vm2.entrarComGoogle(), isFalse);
      expect(
        vm2.mensagemErro,
        equals('Não foi possível entrar com o Google. Tente novamente.'),
      );
      vm2.dispose();
    });
  });
}
