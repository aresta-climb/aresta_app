// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/atualizar_versao_pubspec.dart';

void main() {
  late Directory dirTemp;
  late File arquivoPubspecTemp;

  setUp(() {
    dirTemp = Directory.systemTemp.createTempSync('teste_atualizar_pubspec_');
    arquivoPubspecTemp = File('${dirTemp.path}/pubspec.yaml');
    arquivoPubspecTemp.writeAsStringSync('''
name: frontend
description: "Aplicativo de escalada"
publish_to: 'none'

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

  group('AtualizarVersaoPubspec CLI', () {
    test('deve atualizar versão no pubspec preservando o restante do arquivo', () async {
      final bufferSaida = StringBuffer();

      final codigoRetorno = await executarAtualizarVersaoPubspec(
        [arquivoPubspecTemp.path, '0.2.5+68'],
        saida: bufferSaida,
      );

      expect(codigoRetorno, equals(0));

      final conteudoAtualizado = arquivoPubspecTemp.readAsStringSync();
      expect(conteudoAtualizado, contains('version: 0.2.5+68'));
      expect(conteudoAtualizado, contains('name: frontend'));
      expect(conteudoAtualizado, contains('publish_to: \'none\''));
      expect(conteudoAtualizado, contains('sdk: ^3.11.3'));
    });

    test('deve suportar argumentos nomeados --pubspec e --versao', () async {
      final bufferSaida = StringBuffer();

      final codigoRetorno = await executarAtualizarVersaoPubspec(
        ['--pubspec', arquivoPubspecTemp.path, '--versao', '0.2.6-dev+69'],
        saida: bufferSaida,
      );

      expect(codigoRetorno, equals(0));

      final conteudoAtualizado = arquivoPubspecTemp.readAsStringSync();
      expect(conteudoAtualizado, contains('version: 0.2.6-dev+69'));
    });

    test('deve falhar se arquivo pubspec nao existir', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarAtualizarVersaoPubspec(
        ['${dirTemp.path}/inexistente.yaml', '0.2.5+68'],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Arquivo pubspec não encontrado'));
    });

    test('deve falhar se a nova versao for semver invalida', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarAtualizarVersaoPubspec(
        [arquivoPubspecTemp.path, 'versao_invalida'],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('não é uma versão SemVer válida'));
    });

    test('deve falhar se pubspec nao tiver chave version', () async {
      final pubspecSemVersao = File('${dirTemp.path}/sem_versao.yaml');
      pubspecSemVersao.writeAsStringSync('name: app\n');

      final bufferErro = StringBuffer();
      final codigoRetorno = await executarAtualizarVersaoPubspec(
        [pubspecSemVersao.path, '0.2.5+68'],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Padrão "version:" não encontrado'));
    });

    test('deve falhar se argumentos obrigatorios forem omitidos', () async {
      final bufferErro = StringBuffer();

      final codigoRetorno = await executarAtualizarVersaoPubspec(
        [],
        erro: bufferErro,
      );

      expect(codigoRetorno, equals(1));
      expect(bufferErro.toString(), contains('Uso:'));
    });
  });
}
