// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/gerenciador_semver.dart';

void main() {
  group('GerenciadorSemver - Validação de SemVer', () {
    test('deve validar versões semânticas válidas', () {
      expect(() => GerenciadorSemver.validarSemver('0.1.0'), returnsNormally);
      expect(() => GerenciadorSemver.validarSemver('1.2.3'), returnsNormally);
      expect(
        () => GerenciadorSemver.validarSemver('0.1.4-dev'),
        returnsNormally,
      );
      expect(
        () => GerenciadorSemver.validarSemver('0.2.4-dev+67'),
        returnsNormally,
      );
      expect(
        () => GerenciadorSemver.validarSemver('1.0.0+10'),
        returnsNormally,
      );
    });

    test('deve lançar exceção para versões semânticas inválidas', () {
      expect(
        () => GerenciadorSemver.validarSemver(''),
        throwsA(isA<SemverInvalidoException>()),
      );
      expect(
        () => GerenciadorSemver.validarSemver('1.0'),
        throwsA(isA<SemverInvalidoException>()),
      );
      expect(
        () => GerenciadorSemver.validarSemver('v1.0.0'),
        throwsA(isA<SemverInvalidoException>()),
      );
      expect(
        () => GerenciadorSemver.validarSemver('invalido'),
        throwsA(isA<SemverInvalidoException>()),
      );
    });
  });

  group('GerenciadorSemver - Comparação SemVer', () {
    test('deve comparar corretamente versões estáveis distintas', () {
      expect(GerenciadorSemver.compararSemver('0.1.3', '0.1.4'), isNegative);
      expect(GerenciadorSemver.compararSemver('0.1.4', '0.1.3'), isPositive);
      expect(GerenciadorSemver.compararSemver('0.1.4', '0.1.4'), equals(0));
      expect(GerenciadorSemver.compararSemver('0.2.0', '0.1.9'), isPositive);
      expect(GerenciadorSemver.compararSemver('1.0.0', '0.9.9'), isPositive);
    });

    test('deve considerar pré-release inferior à versão estável equivalente', () {
      expect(
        GerenciadorSemver.compararSemver('0.1.4-dev', '0.1.4'),
        isNegative,
      );
      expect(
        GerenciadorSemver.compararSemver('0.1.4', '0.1.4-dev'),
        isPositive,
      );
      expect(
        GerenciadorSemver.compararSemver('0.1.4-dev', '0.1.4-dev'),
        equals(0),
      );
    });

    test('deve ignorar metadados de build na comparação semântica', () {
      expect(
        GerenciadorSemver.compararSemver('0.1.4+10', '0.1.4+20'),
        equals(0),
      );
    });
  });

  group('GerenciadorSemver - Cálculo de Versão de Release', () {
    test('modo patch com versão em ciclo de desenvolvimento ativo', () {
      final resultado = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4-dev+10',
        tipo: 'patch',
      );
      expect(resultado, equals('0.1.4'));
    });

    test('modo patch com versão estável prévia', () {
      final resultado = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.3+10',
        tipo: 'patch',
      );
      expect(resultado, equals('0.1.4'));
    });

    test('modo minor incrementa minor e zera patch', () {
      final aPartirDeDev = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4-dev+10',
        tipo: 'minor',
      );
      expect(aPartirDeDev, equals('0.2.0'));

      final aPartirDeEstavel = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4+10',
        tipo: 'minor',
      );
      expect(aPartirDeEstavel, equals('0.2.0'));
    });

    test('modo major incrementa major e zera minor e patch', () {
      final aPartirDeDev = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4-dev+10',
        tipo: 'major',
      );
      expect(aPartirDeDev, equals('1.0.0'));

      final aPartirDeEstavel = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4+10',
        tipo: 'major',
      );
      expect(aPartirDeEstavel, equals('1.0.0'));
    });

    test('modo custom com versão customizada válida e estritamente maior', () {
      final resultado = GerenciadorSemver.calcularVersaoRelease(
        versaoAtual: '0.1.4-dev+10',
        tipo: 'custom',
        custom: '0.3.0',
      );
      expect(resultado, equals('0.3.0'));
    });

    test('modo custom deve falhar se versão for nula, vazia ou inválida', () {
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.1.4-dev',
          tipo: 'custom',
          custom: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.1.4-dev',
          tipo: 'custom',
          custom: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.1.4-dev',
          tipo: 'custom',
          custom: 'invalido',
        ),
        throwsA(isA<SemverInvalidoException>()),
      );
    });

    test('modo custom deve falhar se versão for menor ou igual à atual', () {
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.2.0+10',
          tipo: 'custom',
          custom: '0.1.9',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.2.0+10',
          tipo: 'custom',
          custom: '0.2.0',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deve lançar exceção para tipo de incremento desconhecido', () {
      expect(
        () => GerenciadorSemver.calcularVersaoRelease(
          versaoAtual: '0.1.4-dev',
          tipo: 'desconhecido',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GerenciadorSemver - Cálculo do Próximo Ciclo Dev', () {
    test('deve calcular patch + 1 e adicionar sufixo -dev', () {
      expect(GerenciadorSemver.calcularProximoDev('0.1.4'), equals('0.1.5-dev'));
      expect(GerenciadorSemver.calcularProximoDev('0.2.0'), equals('0.2.1-dev'));
      expect(GerenciadorSemver.calcularProximoDev('1.0.0'), equals('1.0.1-dev'));
    });

    test('deve suportar versão com metadados de build', () {
      expect(
        GerenciadorSemver.calcularProximoDev('0.1.4+11'),
        equals('0.1.5-dev'),
      );
    });

    test('deve falhar se versão informada for inválida', () {
      expect(
        () => GerenciadorSemver.calcularProximoDev('invalida'),
        throwsA(isA<SemverInvalidoException>()),
      );
    });
  });

  group('GerenciadorSemver - Decomposição SemVer', () {
    test('deve decompor partes corretamente', () {
      final info = GerenciadorSemver.decompor('0.2.4-dev+67');
      expect(info.maior, equals(0));
      expect(info.menor, equals(2));
      expect(info.correcao, equals(4));
      expect(info.preRelease, equals('dev'));
      expect(info.build, equals(67));
      expect(info.ehDev, isTrue);
      expect(info.semverBase, equals('0.2.4'));
    });
  });
}
