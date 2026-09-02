// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/formatador_creditos.dart';

void main() {
  group('FormatadorCreditos', () {
    group('isPlaceholder', () {
      test('identifica placeholders genéricos conhecidos', () {
        expect(FormatadorCreditos.isPlaceholder('Autores do Croqui Original'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('autores do croqui'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('Autor do Croqui'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('Autores'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('autor'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('Créditos'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('creditos'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('créditos do croqui'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('Desconhecido'), isTrue);
        expect(FormatadorCreditos.isPlaceholder('Sem Autor'), isTrue);
        expect(FormatadorCreditos.isPlaceholder(''), isTrue);
        expect(FormatadorCreditos.isPlaceholder('   '), isTrue);
      });

      test('identifica autores reais válidos', () {
        expect(FormatadorCreditos.isPlaceholder('Felipe Guimarães'), isFalse);
        expect(FormatadorCreditos.isPlaceholder('João Silva'), isFalse);
        expect(FormatadorCreditos.isPlaceholder('Equipe Aresta'), isFalse);
        expect(FormatadorCreditos.isPlaceholder('Pedro e Maria'), isFalse);
      });
    });

    group('extrairCreditosValidos', () {
      test('filtra placeholders e mantém apenas autores reais', () {
        final lista = [
          'Autores do Croqui Original',
          'João Silva',
          '  ',
          'Maria Santos',
          'Créditos',
        ];

        final resultado = FormatadorCreditos.extrairCreditosValidos(lista);
        expect(resultado, equals(['João Silva', 'Maria Santos']));
      });

      test('retorna lista vazia se todos forem placeholders', () {
        final lista = ['Autores do Croqui Original', 'Créditos'];
        expect(FormatadorCreditos.extrairCreditosValidos(lista), isEmpty);
      });
    });

    group('formatarLinhaCreditos', () {
      test('formata lista de autores prefixando com "Croqui por"', () {
        final creditos = ['João Silva', 'Maria Santos'];
        expect(
          FormatadorCreditos.formatarLinhaCreditos(creditos),
          equals('Croqui por João Silva, Maria Santos'),
        );
      });

      test('preserva texto quando já começar com prefixo de autoria', () {
        expect(
          FormatadorCreditos.formatarLinhaCreditos(['Croqui por Lucas']),
          equals('Croqui por Lucas'),
        );
        expect(
          FormatadorCreditos.formatarLinhaCreditos(['Autor: Carlos']),
          equals('Autor: Carlos'),
        );
        expect(
          FormatadorCreditos.formatarLinhaCreditos(['Crédito: Ana']),
          equals('Crédito: Ana'),
        );
      });

      test('retorna null se não houver autores válidos', () {
        expect(FormatadorCreditos.formatarLinhaCreditos([]), isNull);
        expect(
          FormatadorCreditos.formatarLinhaCreditos(['Autores do Croqui Original']),
          isNull,
        );
      });
    });
  });
}
