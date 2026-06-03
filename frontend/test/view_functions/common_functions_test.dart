/// Suíte de testes de funções utilitárias.
/// Cobre safeString e isBoulderArea.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  // ---------------------------------------------------------------------------
  // safeString
  // ---------------------------------------------------------------------------

  group('safeString', () {
    test('deve retornar a string do valor quando não nulo', () {
      expect(safeString('Pedra Bonita'), 'Pedra Bonita');
    });

    test('deve retornar string vazia para valores nulos por padrão', () {
      expect(safeString(null), '');
    });

    test('deve retornar o fallback especificado para valores nulos', () {
      expect(safeString(null, fallback: 'Desconhecido'), 'Desconhecido');
    });

    test('deve converter números para string corretamente', () {
      expect(safeString(42), '42');
    });

    test('deve converter booleans para string corretamente', () {
      expect(safeString(true), 'true');
    });
  });

  // ---------------------------------------------------------------------------
  // isBoulderArea
  // ---------------------------------------------------------------------------

  group('isBoulderArea', () {
    test('deve retornar false para lista vazia', () {
      expect(isBoulderArea([]), isFalse);
    });

    test('deve retornar true quando metade ou mais são boulders', () {
      // 2 boulders, 1 via esportiva → 66% boulder
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve retornar false quando menos da metade são boulders', () {
      // 1 boulder, 2 vias esportivas → 33% boulder
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isFalse);
    });

    test('deve retornar true quando todas são boulders', () {
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..boulder = Boulder(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve retornar false quando nenhuma é boulder', () {
      final escaladas = [
        Escalada()..viaEsportiva = ViaEsportiva(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isFalse);
    });

    test('caso de empate (50%) deve retornar true', () {
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve tratar viaMovel como não-boulder', () {
      final escaladas = [
        Escalada()..viaMovel = ViaMovel(),
        Escalada()..boulder = Boulder(),
      ];
      // 1 de 2 → 50% → retorna true
      expect(isBoulderArea(escaladas), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // normalizeSearchString
  // ---------------------------------------------------------------------------

  group('normalizeSearchString', () {
    test('deve converter string para letras minúsculas', () {
      expect(normalizeSearchString('PICO'), 'pico');
    });

    test('deve remover acentos e diacríticos corretamente', () {
      expect(normalizeSearchString('Píco'), 'pico');
      expect(normalizeSearchString('Coração'), 'coracao');
      expect(normalizeSearchString('Áéíóú Ãõ Âêîôû Àèìòù Çç Ññ'), 'aeiou ao aeiou aeiou cc nn');
    });

    test('deve retornar string vazia caso o input seja vazio', () {
      expect(normalizeSearchString(''), '');
    });

    test('não deve alterar caracteres especiais não mapeados e números', () {
      expect(normalizeSearchString('123@#%'), '123@#%');
    });
  });
}

