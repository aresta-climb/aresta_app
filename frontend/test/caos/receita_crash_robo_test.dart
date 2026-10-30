// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'receita_crash_robo.dart';

void main() {
  group('SeletorAlvoRobo e PassoRobo', () {
    test(
      'Serializa e desserializa todos os tipos de SeletorAlvoRobo e PassoRobo preservando metadados temporais',
      () {
        const seletores = <SeletorAlvoRobo>[
          SeletorAlvoRobo.porKey('botao_excluir_croqui'),
          SeletorAlvoRobo.porTipoETexto(
            tipoWidget: 'TextButton',
            texto: 'Sair sem Salvar',
            ocorrencia: 0,
          ),
          SeletorAlvoRobo.porTipoEIcone(
            tipoWidget: 'IconButton',
            iconeCodePoint: 0xe872,
            ocorrencia: 1,
          ),
          SeletorAlvoRobo.porTipoEIndice(
            tipoWidget: 'BackButton',
            ocorrencia: 0,
          ),
        ];

        for (final seletor in seletores) {
          final restaurado = SeletorAlvoRobo.fromJson(seletor.toJson());
          expect(restaurado, equals(seletor));
          expect(restaurado.descricaoLegivel, isNotEmpty);
        }

        final passos = <PassoRobo>[
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: seletores[0],
            pumpAndSettle: true,
          ),
          PassoRobo(
            acao: TipoAcaoRobo.scroll,
            alvo: seletores[1],
            deslocamentoDx: 0.0,
            deslocamentoDy: -300.0,
            pumpAndSettle: false,
            pumpMs: 150,
          ),
          PassoRobo(
            acao: TipoAcaoRobo.digitarTexto,
            alvo: seletores[2],
            textoDigitado: 'Via 🧗‍♂️ <small>12c</small>',
            pumpAndSettle: true,
          ),
          const PassoRobo(
            acao: TipoAcaoRobo.voltarAppNav,
            pumpAndSettle: false,
            pumpMs: 350,
          ),
          const PassoRobo(
            acao: TipoAcaoRobo.voltarSistema,
            pumpAndSettle: true,
          ),
          const PassoRobo(
            acao: TipoAcaoRobo.dispararEventoSync,
            pumpAndSettle: false,
            pumpMs: 100,
          ),
          const PassoRobo(
            acao: TipoAcaoRobo.alternarConectividade,
            pumpAndSettle: true,
          ),
        ];

        for (final passo in passos) {
          final restaurado = PassoRobo.fromJson(passo.toJson());
          expect(restaurado, equals(passo));
          expect(restaurado.descricaoLegivel, isNotEmpty);
        }
      },
    );
  });

  group('ReceitaCrashRobo', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('receita_crash_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'Salva e carrega ReceitaCrashRobo em arquivo JSON com instruções de regressão e assinatura de falha',
      () {
        const passo1 = PassoRobo(
          acao: TipoAcaoRobo.voltarAppNav,
          pumpAndSettle: false,
          pumpMs: 350,
        );
        const passo2 = PassoRobo(
          acao: TipoAcaoRobo.tap,
          alvo: SeletorAlvoRobo.porTipoETexto(
            tipoWidget: 'TextButton',
            texto: 'Sair sem Salvar',
          ),
          pumpAndSettle: true,
        );

        final receita = ReceitaCrashRobo.criar(
          seed: 849201,
          dataset: TipoDatasetCaos.toxico,
          excecao: StateError('Elemento desmontado (_element!)'),
          stackTrace: StackTrace.fromString(
            '#0 _PicoDetailsPageState._setupBackInterceptor (package:frontend/pages/pico.dart:186:12)\n'
            '#1 main (file:///test.dart:10:5)',
          ),
          passosMinimos: const [passo1, passo2],
          passosOriginais: const [
            PassoRobo(acao: TipoAcaoRobo.alternarConectividade),
            passo1,
            passo2,
          ],
        );

        expect(receita.seed, 849201);
        expect(receita.dataset, TipoDatasetCaos.toxico);
        expect(receita.assinaturaFalha, contains('StateError'));
        expect(receita.assinaturaFalha, contains('pico.dart:186'));
        expect(receita.instrucoesRegressao, contains('regressao_caminhos_test.dart'));

        final arquivo = File('${tempDir.path}/crash_849201.json');
        receita.salvarEmArquivo(arquivo);
        expect(arquivo.existsSync(), isTrue);

        final carregada = ReceitaCrashRobo.carregarDeArquivo(arquivo);
        expect(carregada.seed, receita.seed);
        expect(carregada.dataset, receita.dataset);
        expect(carregada.assinaturaFalha, receita.assinaturaFalha);
        expect(carregada.resumoErro, receita.resumoErro);
        expect(carregada.passosMinimos, equals(receita.passosMinimos));
        expect(carregada.passosOriginais, equals(receita.passosOriginais));
      },
    );
  });
}
