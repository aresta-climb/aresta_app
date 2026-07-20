import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/via_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('getGrauString', () {
    test('deve formatar grau de via esportiva', () {
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_7A);
      
      expect(getGrauString(escalada), '7A');
    });

    test('deve formatar grau de via móvel', () {
      final escalada = Escalada()
        ..viaMovel = (ViaMovel()..dificuldade = GrauVia_GrauVia.BR_5SUP);
      
      expect(getGrauString(escalada), '5SUP');
    });

    test('deve formatar grau de boulder', () {
      final escalada = Escalada()
        ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V4);
      
      expect(getGrauString(escalada), 'V4');
    });

    test('deve formatar grau de multipitch', () {
      final escalada = Escalada()
        ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()..dificuldadeMaxima = GrauVia_GrauVia.BR_6SUP_BARRA_7A);
      
      expect(getGrauString(escalada), '6SUP BARRA 7A');
    });

    test('deve retornar string vazia para tipos não suportados', () {
      final escalada = Escalada()..highline = Highline();
      expect(getGrauString(escalada), '');
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

    test('deve retornar 0 para tipos não suportados', () {
      final escalada = Escalada()..highline = Highline();
      expect(getGrauValue(escalada), 9999);
    });
  });

  group('buildViaBody', () {
    testWidgets('deve renderizar chip Ver no mapa se houver mapa em pico maps index', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final escalada = Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
      final mapa = Mapa()..caminhoImagemMapa = 'mapa1.png';
      mapa.referencias.add(Mapa_Referencia(escalada: 'Via Teste', ids: ['p1']));
      
      final setor = Setor()..nome = 'Setor Teste';
      setor.escaladas.add(escalada);
      setor.mapas.add(mapa);
      
      pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor));

      await tester.pumpWidget(MaterialApp(
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
      ));

      expect(find.text('VER NO CROQUI INTERATIVO'), findsOneWidget);
    });
  });
}
