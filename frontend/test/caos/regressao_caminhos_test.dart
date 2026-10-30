// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'fabrica_dataset_caos.dart';
import 'receita_crash_robo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Suíte de Regressão de Caminhos do Robô Caótico', () {
    late AmbienteAppCaos ambiente;

    setUp(() async {
      ambiente = await AmbienteAppCaos.inicializar();
    });

    tearDown(() async {
      await ambiente.limpar();
    });

    final diretorioReceitas = Directory('test/caos/caminhos_regressao');
    final arquivosReceita = diretorioReceitas.existsSync()
        ? (diretorioReceitas
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];

    test('Possui ao menos uma receita de regressão versionada', () {
      expect(
        arquivosReceita,
        isNotEmpty,
        reason:
            'O diretório test/caos/caminhos_regressao/ deve conter as receitas JSON de regressão.',
      );
    });

    for (final arquivo in arquivosReceita) {
      final nomeArquivo = arquivo.uri.pathSegments.last;
      testWidgets(
        'Reproduz receita $nomeArquivo sem falhas ou regressões',
        (tester) async {
          final receita = ReceitaCrashRobo.carregarDeArquivo(arquivo);
          final motor = ambiente.criarMotor(
            tester: tester,
            reportarAoSentry: false,
          );

          final assinaturaFalha = await motor.reproduzirCaminho(
            dataset: receita.dataset,
            passos: receita.passosMinimos,
          );

          expect(
            assinaturaFalha,
            isNull,
            reason:
                'A receita de regressão "$nomeArquivo" (seed: ${receita.seed}, '
                'dataset: ${receita.dataset.name}) voltou a falhar com: $assinaturaFalha',
          );
        },
      );
    }
  });
}
