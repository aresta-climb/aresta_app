// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/calcular_proximo_dev.dart';

void main() {
  late Directory dirTemp;

  setUp(() {
    dirTemp = Directory.systemTemp.createTempSync('teste_calcular_proximo_dev_');
  });

  tearDown(() {
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('CalcularProximoDev CLI', () {
    test('deve calcular próximo patch dev no formato semver padrão', () async {
      final bufferSaida = StringBuffer();
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularProximoDev(
        ['0.1.4'],
        saida: bufferSaida,
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('0.1.5-dev'));
      expect(bufferErro.toString(), isEmpty);
    });

    test('deve calcular próximo patch dev com build incrementado no formato completo', () async {
      final bufferSaida = StringBuffer();
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularProximoDev(
        ['0.2.0', '--build', '68', '--formato', 'completo'],
        saida: bufferSaida,
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('0.2.1-dev+69'));
    });

    test('deve extrair build embutido se a versão de entrada contiver +build', () async {
      final bufferSaida = StringBuffer();

      final codigoRetorno = await executarCalcularProximoDev(
        ['1.0.0+50', '--formato', 'completo'],
        saida: bufferSaida,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('1.0.1-dev+51'));
    });

    test('deve exportar variáveis para arquivo de ambiente do GitHub Actions', () async {
      final arquivoEnv = File('${dirTemp.path}/github_output.txt');

      final codigoRetorno = await executarCalcularProximoDev(
        ['0.2.5', '--build', '68', '--exportar-env', arquivoEnv.path],
      );

      expect(codigoRetorno, equals(0));
      expect(arquivoEnv.existsSync(), isTrue);

      final conteudoEnv = arquivoEnv.readAsStringSync();
      expect(conteudoEnv, contains('versao_dev=0.2.6-dev'));
      expect(conteudoEnv, contains('build_dev=69'));
      expect(conteudoEnv, contains('versao_dev_completa=0.2.6-dev+69'));
    });

    test('deve falhar se nenhuma versão for informada', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularProximoDev(
        [],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Versão de lançamento é obrigatória'));
    });

    test('deve falhar se a versão informada for inválida', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularProximoDev(
        ['invalida'],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('não é uma versão SemVer válida'));
    });
  });
}
