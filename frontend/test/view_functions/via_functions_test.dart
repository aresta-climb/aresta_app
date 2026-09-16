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

  group('getModalidadeEscalada', () {
    test('deve retornar "Esportiva" para via esportiva', () {
      final escalada = Escalada()..viaEsportiva = ViaEsportiva(nome: 'Via A');
      expect(getModalidadeEscalada(escalada), 'Esportiva');
    });

    test('deve retornar "Móvel" para via móvel sem proteções fixas intermediárias', () {
      final escalada = Escalada()..viaMovel = ViaMovel(nome: 'Fenda Pura', quantidadeProtecoesIntermediarias: 0);
      expect(getModalidadeEscalada(escalada), 'Móvel');
    });

    test('deve retornar "Mista" para via móvel com proteções fixas intermediárias', () {
      final escalada = Escalada()..viaMovel = ViaMovel(nome: 'Vale Perdido', quantidadeProtecoesIntermediarias: 3);
      expect(getModalidadeEscalada(escalada), 'Mista');
    });

    test('deve retornar "Boulder" para boulder', () {
      final escalada = Escalada()..boulder = Boulder(nome: 'Bloco');
      expect(getModalidadeEscalada(escalada), 'Boulder');
    });

    test('deve retornar "Multipitch" para via de múltiplas enfiadas comum', () {
      final escalada = Escalada()
        ..viaMultiplasEnfiadas = ViaMultiplasEnfiadas(
          nome: 'Paredão',
          tipoViaMultiplasEnfiadas: ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.TODA_FIXA,
        );
      expect(getModalidadeEscalada(escalada), 'Multipitch');
    });

    test('deve retornar "Mista" para via de múltiplas enfiadas mista', () {
      final escalada = Escalada()
        ..viaMultiplasEnfiadas = ViaMultiplasEnfiadas(
          nome: 'Paredão Misto',
          tipoViaMultiplasEnfiadas: ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.MISTA,
        );
      expect(getModalidadeEscalada(escalada), 'Mista');
    });

    test('deve retornar "Highline" para highline', () {
      final escalada = Escalada()..highline = Highline(nome: 'Fita no Céu');
      expect(getModalidadeEscalada(escalada), 'Highline');
    });

    test('deve retornar string vazia para escalada não definida', () {
      final escalada = Escalada();
      expect(getModalidadeEscalada(escalada), '');
    });
  });

  group('getProtecoesString', () {
    test('deve formatar X+Y quando via esportiva tiver proteções intermediárias e na parada', () {
      final escalada = Escalada()
        ..viaEsportiva = ViaEsportiva(
          quantidadeProtecoesIntermediarias: 9,
          quantidadeProtecoesParada: 2,
        );
      expect(getProtecoesString(escalada), '9+2');
    });

    test('deve formatar X+0 quando via esportiva tiver apenas intermediárias', () {
      final escalada = Escalada()
        ..viaEsportiva = ViaEsportiva(
          quantidadeProtecoesIntermediarias: 5,
          quantidadeProtecoesParada: 0,
        );
      expect(getProtecoesString(escalada), '5+0');
    });

    test('deve formatar 0+Y quando via móvel tiver apenas parada', () {
      final escalada = Escalada()
        ..viaMovel = ViaMovel(
          quantidadeProtecoesIntermediarias: 0,
          quantidadeProtecoesParada: 2,
        );
      expect(getProtecoesString(escalada), '0+2');
    });

    test('deve retornar string vazia quando não houver proteções cadastradas', () {
      final escalada = Escalada()
        ..viaEsportiva = ViaEsportiva(
          quantidadeProtecoesIntermediarias: 0,
          quantidadeProtecoesParada: 0,
        );
      expect(getProtecoesString(escalada), '');
    });

    test('deve retornar string vazia para boulder', () {
      final escalada = Escalada()..boulder = Boulder();
      expect(getProtecoesString(escalada), '');
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
      expect(formatGradeString('BR_7B_BARRA_7C'), '7b/7c');
      expect(formatGradeString('BR_10A_BARRA_10B'), '10a/10b');
      expect(formatGradeString('VB_BARRA_V0'), 'vb/v0');
      expect(formatGradeString('V3_BARRA_V4'), 'v3/v4');
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

    testWidgets(
      'deve renderizar grau com barra formatado com "/" ao invés de "barra"',
      (tester) async {
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Zig Marley'
            ..dificuldade = GrauVia_GrauVia.BR_7B_BARRA_7C);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return buildViaBody(
                    context,
                    escalada,
                    'crag1',
                    pico: null,
                    setor: null,
                    grupo: null,
                    fromSetorPage: false,
                    fromMapaPage: false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('7b/7c'), findsOneWidget);
        expect(find.text('7b barra 7c'), findsNothing);
      },
    );
  });
}
