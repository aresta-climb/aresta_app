// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/via_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('getGrauString', () {
    test('deve formatar grau de via esportiva', () {
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_7A);

      expect(getGrauString(escalada), '7a');
    });

    test('deve formatar grau de via móvel', () {
      final escalada = Escalada()
        ..viaMovel = (ViaMovel()..dificuldade = GrauVia_GrauVia.BR_5SUP);

      expect(getGrauString(escalada), '5ºsup');
    });

    test('deve formatar grau de boulder', () {
      final escalada = Escalada()
        ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V4);

      expect(getGrauString(escalada), 'v4');
    });

    test('deve formatar grau de multipitch', () {
      final escalada = Escalada()
        ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()
          ..dificuldadeMaxima = GrauVia_GrauVia.BR_6SUP_BARRA_7A);

      expect(getGrauString(escalada), '6ºsup/7a');
    });

    test('deve retornar string vazia para tipos não suportados', () {
      final escalada = Escalada()..highline = Highline();
      expect(getGrauString(escalada), '');
    });
  });

  group('formatGradeString', () {
    test('deve formatar grau puro sem sufixo', () {
      expect(formatGradeString('BR_4'), '4º');
      expect(formatGradeString('BR_7a'), '7a'); // Letras não ganham 'º'
      expect(formatGradeString('BR_9c'), '9c');
    });

    test('deve formatar grau com sup', () {
      expect(formatGradeString('BR_5sup'), '5ºsup');
      expect(formatGradeString('BR_6_sup'), '6ºsup');
    });

    test('deve formatar graus com barra (divididos)', () {
      expect(formatGradeString('BR_4_BARRA_5'), '4º/5º');
      expect(formatGradeString('BR_5_BARRA_5sup'), '5º/5ºsup');
      expect(formatGradeString('BR_6sup_BARRA_7a'), '6ºsup/7a');
    });

    test('deve retornar string vazia ou inalterada se não fizer match (ex: strings puras)', () {
      expect(formatGradeString('lixo'), 'lixo');
    });
  });

  group('getGrauValue', () {
    test('deve retornar valores ordenáveis corretos para vias', () {
      final facil = Escalada()
        ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_3);

      final medio = Escalada()
        ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5);

      final dificil = Escalada()
        ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8C);

      final valFacil = getGrauValue(facil);
      final valMedio = getGrauValue(medio);
      final valDificil = getGrauValue(dificil);

      expect(valFacil < valMedio, isTrue);
      expect(valMedio < valDificil, isTrue);
    });

    test('deve retornar valores ordenáveis corretos para boulders', () {
      final facil = Escalada()
        ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V1);

      final medio = Escalada()
        ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V5);

      final dificil = Escalada()
        ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V12);

      final valFacil = getGrauValue(facil);
      final valMedio = getGrauValue(medio);
      final valDificil = getGrauValue(dificil);

      expect(valFacil < valMedio, isTrue);
      expect(valMedio < valDificil, isTrue);
    });

    test('deve retornar 9998 (INDEFINIDO) para tipos não suportados ou sem grau', () {
      final escalada = Escalada()..highline = Highline();
      expect(getGrauValue(escalada), 9998);
    });

    test('deve ordenar PROJETO como a dificuldade máxima absoluta (acima de INDEFINIDO)', () {
      final projetoVia = Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.PROJETO);
      final indefinidoVia = Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.INDEFINIDO);
      final normalVia = Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8C);

      final valProjeto = getGrauValue(projetoVia);
      final valIndefinido = getGrauValue(indefinidoVia);
      final valNormal = getGrauValue(normalVia);

      expect(valNormal < valIndefinido, isTrue, reason: "Normal deve ser menor que INDEFINIDO");
      expect(valIndefinido < valProjeto, isTrue, reason: "INDEFINIDO deve ser menor que PROJETO");
      
      expect(valProjeto, 9999);
      expect(valIndefinido, 9998);
    });
  });

  group('buildViaBody', () {
    testWidgets(
      'deve renderizar chip Ver no mapa se houver mapa em pico maps index',
      (tester) async {
        final pico = Pico()..nome = 'Pico Teste';
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
        final mapa = Mapa()..caminhoImagemMapa = 'mapa1.png';
        mapa.referencias.add(
          Mapa_Referencia(escalada: 'Via Teste', ids: ['p1']),
        );

        final setor = Setor()..nome = 'Setor Teste';
        setor.escaladas.add(escalada);
        setor.mapas.add(mapa);

        pico.setoresOuGrupos.add(
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return buildViaBody(
                    context,
                    escalada,
                    'crag1',
                    pico: pico,
                    setor: setor,
                    grupo: null,
                    fromSetorPage: false,
                    fromMapaPage: false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('VER NO CROQUI INTERATIVO'), findsOneWidget);
      },
    );
  });
}
