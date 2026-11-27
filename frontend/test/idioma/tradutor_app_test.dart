// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
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

  group('TradutorApp', () {
    test(
      'resolve textos estáticos e interpola parâmetros nomeados e valores nulos nos cinco idiomas',
      () async {
        expect(
          TradutorApp.dicionarioDe(IdiomaApp.portugues)[ChaveTexto.navExplorar],
          'EXPLORAR',
        );
        expect(
          TradutorApp.dicionarioDe(IdiomaApp.ingles)[ChaveTexto.navExplorar],
          'EXPLORE',
        );
        expect(
          TradutorApp.dicionarioDe(IdiomaApp.espanhol)[ChaveTexto.navExplorar],
          'EXPLORAR',
        );
        expect(
          TradutorApp.dicionarioDe(IdiomaApp.alemao)[ChaveTexto.navExplorar],
          'ENTDECKEN',
        );
        expect(
          TradutorApp.dicionarioDe(IdiomaApp.holandes)[ChaveTexto.navExplorar],
          'ONTDEKKEN',
        );

        expect(tr(ChaveTexto.homeBoasVindas), 'BEM VINDO!');
        await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.holandes);
        expect(tr(ChaveTexto.homeBoasVindas), 'WELKOM!');

        expect(
          TradutorApp.texto(
            ChaveTexto.shareConfiraGrupo,
            idioma: IdiomaApp.ingles,
            parametros: {'grupo': 'Sherpa', 'pico': 'Cipó', 'url': null},
          ),
          'Check out Sherpa at Cipó on Aresta:\n',
        );
      },
    );

    test(
      'formata datas legais ISO por extenso em português, inglês, espanhol, alemão e neerlandês',
      () async {
        expect(
          TradutorApp.formatarDataExtensoLegal('2026-11-25'),
          '25 de Novembro de 2026',
        );
        expect(
          TradutorApp.formatarDataExtensoLegal(
            '2026-11-25',
            idioma: IdiomaApp.ingles,
          ),
          'November 25, 2026',
        );
        expect(
          TradutorApp.formatarDataExtensoLegal(
            '2026-11-25',
            idioma: IdiomaApp.espanhol,
          ),
          '25 de noviembre de 2026',
        );
        expect(
          TradutorApp.formatarDataExtensoLegal(
            '2026-11-25',
            idioma: IdiomaApp.alemao,
          ),
          '25. November 2026',
        );
        expect(
          TradutorApp.formatarDataExtensoLegal(
            '2026-11-25',
            idioma: IdiomaApp.holandes,
          ),
          '25 november 2026',
        );

        // Fallback seguro para entradas malformadas ou não numéricas
        expect(
          TradutorApp.formatarDataExtensoLegal('data-invalida'),
          'data-invalida',
        );
        expect(
          TradutorApp.formatarDataExtensoLegal(
            '2026-xx-yy',
            idioma: IdiomaApp.ingles,
          ),
          'January yy, 2026',
        );
      },
    );

    testWidgets(
      'extensão em BuildContext expõe idiomaApp e traduz chaves reativamente ao alternar o idioma na árvore',
      (tester) async {
        final controlador = ControladorIdiomaApp.criarIsolado();

        await tester.pumpWidget(
          EscopoIdiomaApp(
            notificador: controlador.notificadorIdioma,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Text(context.idiomaApp.nomeNativo),
                      Text(
                        context.tr(
                          ChaveTexto.explorarContagemPicos,
                          {'n': 12},
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Português'), findsOneWidget);
        expect(find.text('12 PICOS'), findsOneWidget);

        await controlador.definirIdioma(IdiomaApp.ingles);
        await tester.pump();
        expect(find.text('English'), findsOneWidget);
        expect(find.text('12 CRAGS'), findsOneWidget);

        await controlador.definirIdioma(IdiomaApp.alemao);
        await tester.pump();
        expect(find.text('Deutsch'), findsOneWidget);
        expect(find.text('12 GEBIETE'), findsOneWidget);
      },
    );
  });
}
