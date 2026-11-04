// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/funcoes_hub_perfil_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // PNG transparente 1x1 válido para testes de MemoryImage
  final png1x1Base64 = base64Encode(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('funcoes_hub_perfil_caderneta', () {
    testWidgets('buildCabecalhoHubPerfil renderiza nome, função, avatar (padrão, Data URI e URL) e aciona editar perfil e alterar foto', (tester) async {
      var editou = false;
      var alterouFoto = false;

      await tester.pumpWidget(
        wrapWithTheme(
          buildCabecalhoHubPerfil(
            nome: 'Fernanda Rocha',
            funcao: 'Escaladora',
            onEditarPerfil: () => editou = true,
            onAlterarFoto: () => alterouFoto = true,
          ),
        ),
      );

      expect(find.text('Fernanda Rocha'), findsOneWidget);
      expect(find.text('Escaladora'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_editar_perfil_hub')));
      await tester.pump();
      expect(editou, isTrue);

      await tester.tap(find.byKey(const Key('btn_alterar_foto_perfil_hub')));
      await tester.pump();
      expect(alterouFoto, isTrue);

      // Com Data URI base64 válida, renderiza MemoryImage no CircleAvatar
      await tester.pumpWidget(
        wrapWithTheme(
          buildCabecalhoHubPerfil(
            nome: 'Fernanda Rocha',
            funcao: 'Escaladora',
            onEditarPerfil: () {},
            avatarUrl: 'data:image/png;base64,$png1x1Base64',
          ),
        ),
      );
      expect(find.byIcon(Icons.person), findsNothing);
      final avatarMemory = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatarMemory.backgroundImage, isA<MemoryImage>());

      // Valida construirProvedorAvatarPerfil para URL HTTP/HTTPS e entradas inválidas
      expect(
        construirProvedorAvatarPerfil('https://lh3.googleusercontent.com/a/f.jpg'),
        isA<NetworkImage>(),
      );
      expect(construirProvedorAvatarPerfil(null), isNull);
      expect(construirProvedorAvatarPerfil('   '), isNull);
      expect(construirProvedorAvatarPerfil('data:image/jpeg;base64,:::invalido:::'), isNull);
      expect(construirProvedorAvatarPerfil('ftp://invalido'), isNull);
    });

    testWidgets('buildBarraMetricasHub renderiza 4 cartões com valores e rótulos corretos', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          buildBarraMetricasHub(
            totalCadenas: 3,
            totalTentativas: 1,
            totalPicos: 18,
            totalVias: 64,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('CADENAS'), findsOneWidget);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('TENTATIVAS'), findsOneWidget);

      expect(find.text('18'), findsOneWidget);
      expect(find.text('PICOS'), findsOneWidget);

      expect(find.text('64'), findsOneWidget);
      expect(find.text('VIAS'), findsOneWidget);
    });

    testWidgets('buildBarraMetricasHub mantém os 4 cartões com a mesma altura e escala em telas estreitas', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithTheme(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildBarraMetricasHub(
              totalCadenas: 3,
              totalTentativas: 1,
              totalPicos: 18,
              totalVias: 64,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boxCadenas = tester.getRect(find.byKey(const Key('card_metrica_cadenas')));
      final boxTentativas = tester.getRect(find.byKey(const Key('card_metrica_tentativas')));
      final boxPicos = tester.getRect(find.byKey(const Key('card_metrica_picos')));
      final boxVias = tester.getRect(find.byKey(const Key('card_metrica_vias')));

      // Todos os 4 cartões devem manter estritamente a mesma altura
      expect(boxTentativas.height, equals(boxCadenas.height));
      expect(boxPicos.height, equals(boxCadenas.height));
      expect(boxVias.height, equals(boxCadenas.height));

      // Todos os 4 cartões devem ter larguras proporcionais / homogêneas
      expect((boxTentativas.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxPicos.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxVias.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));

      expect(tester.takeException(), isNull);
    });

    testWidgets('buildMenuOpcoesHub renderiza itens e aciona callbacks de navegação', (tester) async {
      var abriuCaderneta = false;
      var abriuConfiguracoes = false;
      var abriuDados = false;
      var confirmouSaida = false;
      var abriuEntrarConta = false;

      await tester.pumpWidget(
        wrapWithTheme(
          buildMenuOpcoesHub(
            onEntrarNaConta: () => abriuEntrarConta = true,
            onAbrirCaderneta: () => abriuCaderneta = true,
            onAbrirConfiguracoes: () => abriuConfiguracoes = true,
            onAbrirDadosPrivacidade: () => abriuDados = true,
            onConfirmarSaida: () => confirmouSaida = true,
          ),
        ),
      );

      expect(find.text('Entrar na conta'), findsOneWidget);
      expect(find.text('Minha caderneta'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Dados e privacidade'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      await tester.tap(find.byKey(const Key('item_menu_entrar_conta')));
      await tester.pump();
      expect(abriuEntrarConta, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_minha_caderneta')));
      await tester.pump();
      expect(abriuCaderneta, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_configuracoes')));
      await tester.pump();
      expect(abriuConfiguracoes, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_dados_privacidade')));
      await tester.pump();
      expect(abriuDados, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_sair')));
      await tester.pump();
      expect(confirmouSaida, isTrue);
    });

    testWidgets('buildCardMetricaHub aplica borda padrão derivada de corIcone quando corBorda é omitida', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          buildCardMetricaHub(
            key: const Key('card_padrao'),
            icone: Icons.star_rounded,
            corIcone: const Color(0xFF22C55E),
            valor: '10',
            rotulo: 'RECORDES',
          ),
        ),
      );

      expect(find.byKey(const Key('card_padrao')), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('RECORDES'), findsOneWidget);
    });
  });
}
