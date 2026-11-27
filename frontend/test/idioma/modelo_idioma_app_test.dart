// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  group('IdiomaApp', () {
    test(
      'mapeia metadados ISO, regiões, nomes nativos e locales completos para os cinco idiomas suportados',
      () {
        expect(IdiomaApp.values, hasLength(5));

        expect(IdiomaApp.portugues.codigoIso, 'pt');
        expect(IdiomaApp.portugues.regiaoIso, 'BR');
        expect(IdiomaApp.portugues.nomeNativo, 'Português');
        expect(IdiomaApp.portugues.subtituloRegiao, 'Brasil');
        expect(IdiomaApp.portugues.locale, const Locale('pt', 'BR'));

        expect(IdiomaApp.ingles.codigoIso, 'en');
        expect(IdiomaApp.ingles.regiaoIso, 'US');
        expect(IdiomaApp.ingles.nomeNativo, 'English');
        expect(IdiomaApp.ingles.locale, const Locale('en', 'US'));

        expect(IdiomaApp.espanhol.codigoIso, 'es');
        expect(IdiomaApp.espanhol.regiaoIso, 'ES');
        expect(IdiomaApp.espanhol.nomeNativo, 'Español');
        expect(IdiomaApp.espanhol.locale, const Locale('es', 'ES'));

        expect(IdiomaApp.alemao.codigoIso, 'de');
        expect(IdiomaApp.alemao.regiaoIso, 'DE');
        expect(IdiomaApp.alemao.nomeNativo, 'Deutsch');
        expect(IdiomaApp.alemao.locale, const Locale('de', 'DE'));

        expect(IdiomaApp.holandes.codigoIso, 'nl');
        expect(IdiomaApp.holandes.regiaoIso, 'NL');
        expect(IdiomaApp.holandes.nomeNativo, 'Nederlands');
        expect(IdiomaApp.holandes.subtituloRegiao, 'Nederland / België');
        expect(IdiomaApp.holandes.locale, const Locale('nl', 'NL'));
      },
    );

    test(
      'retorna locale compatível com o pacote de feedback para todos os idiomas suportados',
      () {
        expect(
          IdiomaApp.portugues.localeFeedbackCompativel,
          const Locale('pt', 'BR'),
        );
        expect(
          IdiomaApp.alemao.localeFeedbackCompativel,
          const Locale('de'),
        );
        expect(
          IdiomaApp.espanhol.localeFeedbackCompativel,
          const Locale('es'),
        );
        expect(
          IdiomaApp.ingles.localeFeedbackCompativel,
          const Locale('en'),
        );
        expect(
          IdiomaApp.holandes.localeFeedbackCompativel,
          const Locale('en'),
        );
      },
    );

    test(
      'resolve IdiomaApp a partir de código ISO ignorando caixa e espaços e recorre ao português para nulos ou desconhecidos',
      () {
        expect(IdiomaApp.deCodigoIso(null), IdiomaApp.portugues);
        expect(IdiomaApp.deCodigoIso(''), IdiomaApp.portugues);
        expect(IdiomaApp.deCodigoIso('xx'), IdiomaApp.portugues);
        expect(IdiomaApp.deCodigoIso('pt'), IdiomaApp.portugues);
        expect(IdiomaApp.deCodigoIso(' EN '), IdiomaApp.ingles);
        expect(IdiomaApp.deCodigoIso('Es'), IdiomaApp.espanhol);
        expect(IdiomaApp.deCodigoIso('DE'), IdiomaApp.alemao);
        expect(IdiomaApp.deCodigoIso('  nl '), IdiomaApp.holandes);
      },
    );

    test(
      'rotaciona ciclicamente pelos cinco idiomas na ordem PT, EN, ES, DE, NL e retorna ao PT',
      () {
        expect(IdiomaApp.portugues.proximoNaRotacao, IdiomaApp.ingles);
        expect(IdiomaApp.ingles.proximoNaRotacao, IdiomaApp.espanhol);
        expect(IdiomaApp.espanhol.proximoNaRotacao, IdiomaApp.alemao);
        expect(IdiomaApp.alemao.proximoNaRotacao, IdiomaApp.holandes);
        expect(IdiomaApp.holandes.proximoNaRotacao, IdiomaApp.portugues);
      },
    );
  });
}
