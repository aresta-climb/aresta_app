// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/calcular_versao_release.dart';

void main() {
  late Directory dirTemp;
  late File arquivoPubspecTemp;

  setUp(() {
    dirTemp = Directory.systemTemp.createTempSync('teste_calcular_versao_');
    arquivoPubspecTemp = File('${dirTemp.path}/pubspec.yaml');
    arquivoPubspecTemp.writeAsStringSync('''
name: frontend
description: "Aplicativo de escalada"
version: 0.2.4-dev+67

environment:
  sdk: ^3.11.3
''');
  });

  tearDown(() {
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('CalcularVersaoRelease CLI', () {
    test('deve calcular patch a partir de versao -dev com sucesso', () async {
      final bufferSaida = StringBuffer();
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'patch',
          '--pubspec',
          arquivoPubspecTemp.path,
          '--formato',
          'semver',
        ],
        saida: bufferSaida,
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('0.2.4'));
      expect(bufferErro.toString(), isEmpty);
    });

    test('deve calcular versao completa com build incrementado', () async {
      final bufferSaida = StringBuffer();
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'patch',
          '--pubspec',
          arquivoPubspecTemp.path,
          '--formato',
          'completo',
        ],
        saida: bufferSaida,
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('0.2.4+68'));
    });

    test('deve calcular tag com prefixo v', () async {
      final bufferSaida = StringBuffer();
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'patch',
          '--pubspec',
          arquivoPubspecTemp.path,
          '--formato',
          'tag',
        ],
        saida: bufferSaida,
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(0));
      expect(bufferSaida.toString().trim(), equals('v0.2.4+68'));
    });

    test('deve exportar variaveis para arquivo de ambiente do GitHub Actions', () async {
      final arquivoEnv = File('${dirTemp.path}/github_output.txt');
      final bufferSaida = StringBuffer();

      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'minor',
          '--pubspec',
          arquivoPubspecTemp.path,
          '--exportar-env',
          arquivoEnv.path,
        ],
        saida: bufferSaida,
      );

      expect(codigoRetorno, equals(0));
      expect(arquivoEnv.existsSync(), isTrue);

      final conteudoEnv = arquivoEnv.readAsStringSync();
      expect(conteudoEnv, contains('versao_release=0.3.0'));
      expect(conteudoEnv, contains('novo_build=68'));
      expect(conteudoEnv, contains('versao_completa=0.3.0+68'));
      expect(conteudoEnv, contains('tag_name=v0.3.0+68'));
    });

    test('deve falhar se arquivo pubspec nao existir', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'patch',
          '--pubspec',
          '${dirTemp.path}/inexistente.yaml',
        ],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Arquivo pubspec não encontrado'));
    });

    test('deve falhar se pubspec nao tiver chave version', () async {
      final pubspecInvalido = File('${dirTemp.path}/invalido.yaml');
      pubspecInvalido.writeAsStringSync('name: sem_versao\n');

      final bufferErro = StringBuffer();
      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'patch',
          '--pubspec',
          pubspecInvalido.path,
        ],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Padrão "version:" não encontrado'));
    });

    test('deve falhar no modo custom sem versão fornecida', () async {
      final bufferErro = StringBuffer();
      final codigoRetorno = await executarCalcularVersaoRelease(
        [
          '--tipo',
          'custom',
          '--pubspec',
          arquivoPubspecTemp.path,
        ],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('customizada é obrigatória'));
    });
  });
}
