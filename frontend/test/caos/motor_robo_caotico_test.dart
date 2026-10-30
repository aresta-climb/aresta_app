// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../mocks/mock_app_logger.dart';
import 'motor_robo_caotico.dart';
import 'receita_crash_robo.dart';

/// Aplicativo de bancada controlado para validar determinismo, ações e shrinking do MotorRoboCaotico.
class _AppBancadaTesteCaos extends StatefulWidget {
  final bool habilitarArmadilhaCrash;

  const _AppBancadaTesteCaos({this.habilitarArmadilhaCrash = false});

  @override
  State<_AppBancadaTesteCaos> createState() => _AppBancadaTesteCaosState();
}

class _AppBancadaTesteCaosState extends State<_AppBancadaTesteCaos> {
  int _contadorPassosArmadilha = 0;
  String _ultimoTexto = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bancada Caos'),
          leading: BackButton(
            onPressed: () {
              // Botão voltar visível
            },
          ),
        ),
        body: ListView(
          children: [
            TextField(
              key: const ValueKey<String>('campo_busca_caos'),
              onChanged: (v) => setState(() => _ultimoTexto = v),
            ),
            Text('Texto atual: $_ultimoTexto'),
            FilledButton(
              key: const ValueKey<String>('botao_armar'),
              onPressed: () {
                setState(() {
                  _contadorPassosArmadilha = 1;
                });
              },
              child: const Text('Armar Armadilha'),
            ),
            TextButton(
              onPressed: () {
                if (widget.habilitarArmadilhaCrash &&
                    _contadorPassosArmadilha == 1) {
                  throw StateError('Crash determinístico na armadilha!');
                }
              },
              child: const Text('Disparar Armadilha'),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('motor_robo_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MotorRoboCaotico', () {
    testWidgets(
      'Produz caminhada 100% determinística para a mesma seed e executa replay fiel de passos',
      (tester) async {
        final motor = MotorRoboCaotico(
          tester: tester,
          montarCenario: (_) async {
            await tester.pumpWidget(const _AppBancadaTesteCaos());
            await tester.pump();
          },
        );

        final resultado1 = await motor.executarSessao(
          seed: 42,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 12,
        );
        final resultado2 = await motor.executarSessao(
          seed: 42,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 12,
        );

        expect(resultado1.teveFalha, isFalse);
        expect(resultado1.passosExecutados.length, 12);
        expect(
          resultado1.passosExecutados,
          equals(resultado2.passosExecutados),
        );

        // Executa replay explícito dos passos gravados
        final falhaReplay = await motor.reproduzirCaminho(
          dataset: TipoDatasetCaos.normal,
          passos: resultado1.passosExecutados,
        );
        expect(falhaReplay, isNull);
      },
    );

    testWidgets(
      'Captura crash, encolhe caminho por busca binária (shrinking), salva receita JSON e reporta ao AppLogger.logCrash',
      (tester) async {
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final motor = MotorRoboCaotico(
          tester: tester,
          diretorioSaidaReceitas: tempDir,
          reportarAoSentry: true,
          montarCenario: (_) async {
            await tester.pumpWidget(
              const _AppBancadaTesteCaos(habilitarArmadilhaCrash: true),
            );
            await tester.pump();
          },
        );

        // Caminho com ruído antes dos 2 passos que causam o crash
        const caminhoComRuido = <PassoRobo>[
          PassoRobo(acao: TipoAcaoRobo.alternarConectividade),
          PassoRobo(acao: TipoAcaoRobo.dispararEventoSync),
          PassoRobo(
            acao: TipoAcaoRobo.digitarTexto,
            alvo: SeletorAlvoRobo.porKey('campo_busca_caos'),
            textoDigitado: 'ruído inicial',
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porKey('botao_armar'),
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porTipoEIcone(
              tipoWidget: 'IconButton',
              iconeCodePoint: 0xe872,
            ),
          ),
          PassoRobo(
            acao: TipoAcaoRobo.tap,
            alvo: SeletorAlvoRobo.porTipoETexto(
              tipoWidget: 'TextButton',
              texto: 'Disparar Armadilha',
            ),
          ),
        ];

        final receita = await motor.processarFalhaComShrinking(
          seed: 777,
          dataset: TipoDatasetCaos.toxico,
          passosAteFalha: caminhoComRuido,
          excecao: StateError('Crash determinístico na armadilha!'),
          stackTrace: StackTrace.current,
        );

        // O shrinking deve ter podado os 4 passos de ruído e deixado apenas os 2 passos essenciais!
        expect(receita.passosOriginais.length, 6);
        expect(receita.passosMinimos.length, 2);
        expect(
          receita.passosMinimos.first.alvo,
          const SeletorAlvoRobo.porKey('botao_armar'),
        );

        // Deve ter salvo o arquivo JSON no diretório de receitas
        final arquivos = tempDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();
        expect(arquivos, isNotEmpty);

        // Deve ter reportado ao AppLogger.logCrash com receita_robo_caotico
        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(mockLogger.recordedErrors.last['fatal'], isTrue);
        expect(
          mockLogger.recordedErrors.last['contextosExtras'],
          contains('receita_robo_caotico'),
        );
      },
    );

    testWidgets(
      'executarCampanhaPorTempo roda até esgotar o orçamento de tempo, deduplica falhas repetidas e consolida relatório final',
      (tester) async {
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        int sessoesIniciadas = 0;
        final motor = MotorRoboCaotico(
          tester: tester,
          diretorioSaidaReceitas: tempDir,
          reportarAoSentry: true,
          montarCenario: (_) async {
            sessoesIniciadas++;
            await tester.pumpWidget(
              const _AppBancadaTesteCaos(habilitarArmadilhaCrash: true),
            );
            await tester.pump();
          },
        );

        final relatorio = await motor.executarCampanhaPorTempo(
          duracaoMaxima: const Duration(milliseconds: 150),
          maxPassosPorSessao: 15,
          seedInicial: 100,
        );

        expect(sessoesIniciadas, greaterThanOrEqualTo(2));
        expect(relatorio.totalSessoesExecutadas, greaterThanOrEqualTo(2));
        // Mesmo que múltiplas seeds encontrem a mesma armadilha, deve deduplicar por assinatura!
        if (relatorio.falhasUnicas.isNotEmpty) {
          expect(relatorio.falhasUnicas.length, 1);
          expect(relatorio.formatarResumoConsolidado(), contains('StateError'));
        }
      },
    );
  });
}
