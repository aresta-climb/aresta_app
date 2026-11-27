// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/idioma/botao_bolha_idioma.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  tearDown(() {
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  Widget montarApp(Widget filho) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Scaffold(body: Center(child: filho)),
    );
  }

  group('BotaoBolhaIdioma', () {
    testWidgets(
      'renderiza bandeira do país do idioma ativo sem abreviações textuais tanto em superfície padrão quanto sobre fundo fotográfico',
      (tester) async {
        await tester.pumpWidget(
          montarApp(const BotaoBolhaIdioma(key: Key('bolha_padrao'))),
        );
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_pt')),
          findsOneWidget,
        );
        expect(find.text('PT'), findsNothing);

        final ctrl = ControladorIdiomaApp.criarIsolado(
          idiomaInicial: IdiomaApp.alemao,
        );
        await tester.pumpWidget(
          montarApp(
            BotaoBolhaIdioma(
              key: const Key('bolha_foto'),
              controlador: ctrl,
              sobreFundoFotografico: true,
            ),
          ),
        );
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_de')),
          findsOneWidget,
        );
        expect(find.text('DE'), findsNothing);
      },
    );

    testWidgets(
      'abre painel flutuante com bandeiras ao tocar e aplica o idioma selecionado fechando o diálogo',
      (tester) async {
        await tester.pumpWidget(
          montarApp(
            Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BotaoBolhaIdioma(key: Key('bolha_interativa')),
                  TextButton(
                    key: const Key('abrir_direto'),
                    onPressed: () => exibirSeletorBolhasIdioma(context),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('bolha_interativa')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('painel_seletor_bolhas_idioma')),
          findsOneWidget,
        );
        for (final idioma in IdiomaApp.values) {
          expect(
            find.byKey(Key('opcao_bolha_idioma_${idioma.codigoIso}')),
            findsOneWidget,
          );
          expect(
            find.byKey(Key('bandeira_opcao_idioma_${idioma.codigoIso}')),
            findsOneWidget,
          );
          expect(find.text(idioma.nomeNativo), findsOneWidget);
        }
        for (final siglaRemovida in ['PT', 'EN', 'ES', 'DE', 'NL']) {
          expect(find.text(siglaRemovida), findsNothing);
        }

        await tester.tap(find.byKey(const Key('opcao_bolha_idioma_nl')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('painel_seletor_bolhas_idioma')),
          findsNothing,
        );
        expect(ControladorIdiomaApp.instancia.idiomaAtual, IdiomaApp.holandes);
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_nl')),
          findsOneWidget,
        );

        // Abertura direta sem controlador explícito também usa a instância global
        await tester.tap(find.byKey(const Key('abrir_direto')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('painel_seletor_bolhas_idioma')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('opcao_bolha_idioma_en')));
        await tester.pumpAndSettle();
        expect(ControladorIdiomaApp.instancia.idiomaAtual, IdiomaApp.ingles);
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_en')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'rotaciona instantaneamente pelas cinco bandeiras ao manter a bolha pressionada',
      (tester) async {
        final ctrl = ControladorIdiomaApp.criarIsolado();
        await tester.pumpWidget(
          montarApp(
            BotaoBolhaIdioma(
              key: const Key('bolha_ciclica'),
              controlador: ctrl,
            ),
          ),
        );

        expect(
          find.byKey(const Key('bandeira_bolha_ativa_pt')),
          findsOneWidget,
        );

        const sequenciaEsperada = ['en', 'es', 'de', 'nl', 'pt'];
        for (final codigo in sequenciaEsperada) {
          await tester.longPress(find.byKey(const Key('bolha_ciclica')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(Key('bandeira_bolha_ativa_$codigo')),
            findsOneWidget,
          );
        }
      },
    );
  });
}
