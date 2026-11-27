// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/dados_cartao_compartilhamento.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/compartilhamento/cartao_compartilhamento_aresta.dart';

void main() {
  final pngMinimo = MemoryImage(
    Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]),
  );

  group('CartaoCompartilhamentoAresta', () {
    testWidgets('renderiza cartão completo de Escalada com imagem, pílula LINHA #N, clássica, selo de cadena e assinatura discreta sem QR Code', (tester) async {
      const dados = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.via,
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        titulo: 'Aresta Clássica',
        subtituloLocalizacao: 'Pedra Grande • Setor Principal',
        etiquetaCategoria: 'ESPORTIVA',
        grauDestaque: '6ºsup',
        ehClassica: true,
        chipsResumo: ['24m', '8+2', 'Argolas'],
        seloPessoal: SeloPessoalCompartilhamento(
          ehCadena: true,
          textoResumo: 'Encadenada em 14/09 (Flash)',
        ),
        caminhoImagemHeroi: 'mapas/topo.webp',
        rotuloLinhaNoMapa: '4',
        nomePico: 'Pedra Grande',
        nomeSetor: 'Setor Principal',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: const [AppColors.light]),
          home: Scaffold(
            body: Center(
              child: CartaoCompartilhamentoAresta(
                dados: dados,
                imageProviderOverride: pngMinimo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aresta Clássica'), findsOneWidget);
      expect(find.text('6ºsup'), findsOneWidget);
      expect(find.text('ESPORTIVA'), findsOneWidget);
      expect(find.text('CLÁSSICA'), findsOneWidget);
      expect(find.text('Pedra Grande • Setor Principal'), findsOneWidget);
      expect(find.text('Linha #4'), findsOneWidget);
      expect(find.text('Encadenada em 14/09 (Flash)'), findsOneWidget);
      expect(find.text('24m'), findsOneWidget);
      expect(find.text('8+2'), findsOneWidget);
      expect(find.textContaining('arestaclimb.com'), findsOneWidget);
      expect(find.textContaining('@arestaclimb'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code), findsNothing);
      expect(find.byIcon(Icons.qr_code_2), findsNothing);

      // Mantém estética escura editorial independente do tema claro da árvore
      final containerDecorado = tester.widget<Container>(
        find.byKey(const Key('cartao_compartilhamento_fundo')),
      );
      final decoracao = containerDecorado.decoration as BoxDecoration;
      expect(decoracao.gradient, isNotNull);
    });

    testWidgets('renderiza Pico, Grupo e Setor sem imagem heroica colapsando área da foto sem overflow', (tester) async {
      for (final dados in const [
        DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.pico,
          idCroqui: 'crag1',
          uid: 'uidP1',
          titulo: 'Pedra Grande',
          subtituloLocalizacao: 'Igarapé - MG',
          etiquetaCategoria: 'PICO DE ESCALADA',
          chipsResumo: ['4 setores', '32 escaladas'],
          nomePico: 'Pedra Grande',
        ),
        DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.grupo,
          idCroqui: 'crag1',
          uid: 'uidG1',
          titulo: 'Grupo Sherpa',
          subtituloLocalizacao: 'Pedra Grande',
          etiquetaCategoria: 'GRUPO DE SETORES',
          chipsResumo: ['2 setores', '12 escaladas'],
          nomePico: 'Pedra Grande',
        ),
        DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.setor,
          idCroqui: 'crag1',
          uid: 'uidS1',
          titulo: 'Setor Principal',
          subtituloLocalizacao: 'Pedra Grande • Grupo Sherpa',
          etiquetaCategoria: 'SETOR DE ESCALADA',
          chipsResumo: ['12 escaladas', 'Graus 4º – 7b'],
          seloPessoal: SeloPessoalCompartilhamento(
            ehCadena: false,
            textoResumo: 'Tentativa em 03/05',
          ),
          nomePico: 'Pedra Grande',
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: Center(
                child: CartaoCompartilhamentoAresta(dados: dados),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(dados.titulo), findsOneWidget);
        expect(find.text(dados.etiquetaCategoria), findsOneWidget);
        expect(find.textContaining('@arestaclimb'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('resolve imagem assíncrona via future, colapsa quando nula e atualiza em didUpdateWidget', (tester) async {
      const dadosComCaminho = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.pico,
        idCroqui: 'crag1',
        uid: 'uidP1',
        titulo: 'Pico Inicial',
        subtituloLocalizacao: 'MG',
        etiquetaCategoria: 'PICO DE ESCALADA',
        caminhoImagemHeroi: 'thumbnails/crag1.webp',
        nomePico: 'Pico Inicial',
      );
      const dadosAtualizados = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.pico,
        idCroqui: 'crag2',
        uid: 'uidP2',
        titulo: 'Pico Atualizado',
        subtituloLocalizacao: 'SP',
        etiquetaCategoria: 'PICO DE ESCALADA',
        caminhoImagemHeroi: 'thumbnails/crag2.webp',
        nomePico: 'Pico Atualizado',
      );

      // 1. Future resolve imagem válida -> exibe Image
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: CartaoCompartilhamentoAresta(
              dados: dadosComCaminho,
              imageProviderFutureOverride: Future.value(pngMinimo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2)); // herói + logo rodapé

      // 2. didUpdateWidget com future nula -> colapsa imagem heroica sem erro
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: CartaoCompartilhamentoAresta(
              dados: dadosAtualizados,
              imageProviderFutureOverride: Future.value(null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pico Atualizado'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // apenas logo do rodapé

      // 3. Caminho sem override aciona ProvedorImagemAresta.resolver normalmente
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: const Scaffold(
            body: CartaoCompartilhamentoAresta(
              dados: dadosAtualizados,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Pico Atualizado'), findsOneWidget);
    });
  });
}
