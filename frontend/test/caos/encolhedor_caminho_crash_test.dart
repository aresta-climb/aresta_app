// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'encolhedor_caminho_crash.dart';
import 'receita_crash_robo.dart';

void main() {
  group('EncolhedorCaminhoCrash (ddmin por busca binária)', () {
    test(
      'Reduz uma sequência longa de 32 passos para exatamente os 3 passos causadores do crash',
      () async {
        const passoCritico1 = PassoRobo(
          acao: TipoAcaoRobo.tap,
          alvo: SeletorAlvoRobo.porKey('excluir_croqui'),
        );
        const passoCritico2 = PassoRobo(
          acao: TipoAcaoRobo.voltarAppNav,
          pumpAndSettle: false,
          pumpMs: 350,
        );
        const passoCritico3 = PassoRobo(
          acao: TipoAcaoRobo.tap,
          alvo: SeletorAlvoRobo.porTipoETexto(
            tipoWidget: 'TextButton',
            texto: 'Sair sem Salvar',
          ),
        );

        final caminhoLongo = <PassoRobo>[
          for (int i = 0; i < 12; i++)
            PassoRobo(
              acao: TipoAcaoRobo.tap,
              alvo: SeletorAlvoRobo.porKey('ruido_antes_$i'),
            ),
          passoCritico1,
          for (int i = 0; i < 8; i++)
            PassoRobo(
              acao: TipoAcaoRobo.scroll,
              alvo: SeletorAlvoRobo.porKey('ruido_meio_$i'),
              deslocamentoDy: -100,
            ),
          passoCritico2,
          for (int i = 0; i < 9; i++)
            PassoRobo(
              acao: TipoAcaoRobo.tap,
              alvo: SeletorAlvoRobo.porKey('ruido_fim_$i'),
            ),
          passoCritico3,
        ];

        expect(caminhoLongo.length, 32);

        final resultado = await EncolhedorCaminhoCrash.encolher(
          passosOriginais: caminhoLongo,
          assinaturaAlvo: 'StateError|pico.dart:186',
          maxTentativas: 30,
          testarSequencia: (candidato) async {
            final idx1 = candidato.indexOf(passoCritico1);
            final idx2 = candidato.indexOf(passoCritico2);
            final idx3 = candidato.indexOf(passoCritico3);
            if (idx1 != -1 && idx2 > idx1 && idx3 > idx2) {
              return 'StateError|pico.dart:186';
            }
            return null;
          },
        );

        expect(
          resultado,
          equals([passoCritico1, passoCritico2, passoCritico3]),
        );
      },
    );

    test(
      'Retorna a lista original sem alterações quando possui 1 único passo ou quando nenhum subconjunto reproduz a falha',
      () async {
        const passoUnico = PassoRobo(acao: TipoAcaoRobo.voltarAppNav);
        final resUnico = await EncolhedorCaminhoCrash.encolher(
          passosOriginais: const [passoUnico],
          assinaturaAlvo: 'ErroUnico',
          testarSequencia: (_) async => 'ErroUnico',
        );
        expect(resUnico, equals(const [passoUnico]));

        const doisPassos = [
          PassoRobo(acao: TipoAcaoRobo.alternarConectividade),
          PassoRobo(acao: TipoAcaoRobo.dispararEventoSync),
        ];
        final resIrredutivel = await EncolhedorCaminhoCrash.encolher(
          passosOriginais: doisPassos,
          assinaturaAlvo: 'ErroCombinado',
          maxTentativas: 5,
          testarSequencia: (c) async =>
              c.length == 2 ? 'ErroCombinado' : null,
        );
        expect(resIrredutivel, equals(doisPassos));
      },
    );
  });
}
