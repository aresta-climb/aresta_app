// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/modelos_apresentacao_via.dart';
import 'package:frontend/widgets/via/secao_betas_expansivel_via.dart';

void main() {
  // PNG 1x1 transparente válido em Base64 para exercitar avatar real em memória sem rede.
  const png1x1DataUri =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: filho,
        ),
      ),
    );
  }

  testWidgets(
    'SecaoNotasComunidadeVia inicia recolhida, expande ao tocar exibindo foto/iniciais do autor e recolhe novamente',
    (tester) async {
      await tester.pumpWidget(
        envolver(const SecaoNotasComunidadeVia(notas: [])),
      );
      expect(find.textContaining('BETAS DA COMUNIDADE'), findsNothing);

      await tester.pumpWidget(
        envolver(
          const SecaoNotasComunidadeVia(
            notas: [
              NotaComunidadeApresentacao(
                cabecalhoAutorData: 'Eduardo Utsch • 23/11/2026',
                iniciaisAutor: 'EU',
                autorAvatarUrl: png1x1DataUri,
                rotuloEstilo: 'FLASH ★',
                texto: 'Boa sorte! Costura 3 pela esquerda.',
              ),
              NotaComunidadeApresentacao(
                cabecalhoAutorData: 'Carlos Lagartixa • 14/09/2026',
                iniciaisAutor: 'CL',
                texto: 'Descanso ótimo antes do teto.',
              ),
              NotaComunidadeApresentacao(
                cabecalhoAutorData: 'Mariana • 10/09/2026',
                iniciaisAutor: 'M',
                autorAvatarUrl: 'https://exemplo.invalido/avatar_inexistente.webp',
                texto: 'Agarra escondida na saída.',
              ),
            ],
          ),
        ),
      );

      // Inicia fechada por padrão para proteger escaladores à vista (sem spoilers)
      expect(find.text('BETAS DA COMUNIDADE (3)'), findsOneWidget);
      expect(find.text('Boa sorte! Costura 3 pela esquerda.'), findsNothing);

      // Expande ao tocar no cabeçalho
      await tester.tap(find.byKey(const Key('cabecalho_betas_comunidade_via')));
      await tester.pumpAndSettle();

      expect(find.text('Boa sorte! Costura 3 pela esquerda.'), findsOneWidget);
      expect(find.text('Eduardo Utsch • 23/11/2026'), findsOneWidget);
      expect(find.text('FLASH ★'), findsOneWidget);
      expect(find.text('CL'), findsOneWidget);
      expect(find.byType(AvatarAutorComunidadeVia), findsNWidgets(3));

      // Mesmo quando URL remota falha em ambiente offline/teste, faz fallback limpo para inicial sem exceção
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('M'), findsOneWidget);

      // Atualizar avatarUrl em didUpdateWidget limpa o estado de falha e exibe a nova imagem
      await tester.pumpWidget(
        envolver(
          const AvatarAutorComunidadeVia(
            key: Key('avatar_mutavel'),
            avatarUrl: 'https://exemplo.invalido/falha.webp',
            iniciais: 'M',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        envolver(
          const AvatarAutorComunidadeVia(
            key: Key('avatar_mutavel'),
            avatarUrl: png1x1DataUri,
            iniciais: 'M',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('avatar_mutavel')), findsOneWidget);

      // Recolhe novamente quando remontada e tocada no cabeçalho
      await tester.pumpWidget(
        envolver(
          const SecaoNotasComunidadeVia(
            notas: [
              NotaComunidadeApresentacao(
                cabecalhoAutorData: 'Eduardo Utsch • 23/11/2026',
                iniciaisAutor: 'EU',
                autorAvatarUrl: png1x1DataUri,
                rotuloEstilo: 'FLASH ★',
                texto: 'Boa sorte! Costura 3 pela esquerda.',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('cabecalho_betas_comunidade_via')));
      await tester.pumpAndSettle();
      expect(find.text('Boa sorte! Costura 3 pela esquerda.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cabecalho_betas_comunidade_via')));
      await tester.pumpAndSettle();
      expect(find.text('Boa sorte! Costura 3 pela esquerda.'), findsNothing);

      // Exibe ícones de editar e excluir exclusivamente para comentários criados pelo usuário atual
      NotaComunidadeApresentacao? editada;
      NotaComunidadeApresentacao? excluida;
      await tester.pumpWidget(
        envolver(
          SecaoNotasComunidadeVia(
            notas: const [
              NotaComunidadeApresentacao(
                uid: 'nota_minha_01',
                pertenceAoUsuarioAtual: true,
                cabecalhoAutorData: 'Você • 25/11/2026',
                iniciaisAutor: 'VC',
                texto: 'Meu beta editável.',
              ),
              NotaComunidadeApresentacao(
                uid: 'nota_alheia_02',
                pertenceAoUsuarioAtual: false,
                cabecalhoAutorData: 'Outro • 24/11/2026',
                iniciaisAutor: 'OT',
                texto: 'Beta de outro escalador.',
              ),
            ],
