// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
  group('resolveRouteLabels e RotulosVia', () {
    test('retorna rótulos vazios quando não há mapas no setor', () {
      final rotulos = resolveRouteLabels(Escalada(), Setor());
      expect(rotulos.mapIndicator, isEmpty);
      expect(rotulos.resolvedLabel, isEmpty);
    });

    test('instancia RotulosVia corretamente com valores tipados', () {
      const rotulos = RotulosVia(
        mapIndicator: 'M1',
        resolvedLabel: '1-A',
      );
      expect(rotulos.mapIndicator, 'M1');
      expect(rotulos.resolvedLabel, '1-A');
    });

    test('resolve rótulos e indicador do mapa quando há mapas e pontos', () {
      final mapa1 = Mapa(
        referencias: [
          Mapa_Referencia(
            escalada: 'Via dos Sonhos',
            ids: ['p1', 'p2'],
          ),
        ],
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(id: 'p1', label: '1'),
          Mapa_PontoDeInteresse(id: 'p2', label: 'A'),
        ],
      );
      final mapa2 = Mapa();
      final setor = Setor(mapas: [mapa1, mapa2]);
      final escalada = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via dos Sonhos',
          indiceMapaPadrao: 0,
        ),
      );

      final rotulos = resolveRouteLabels(escalada, setor);
      expect(rotulos.mapIndicator, 'M1');
      expect(rotulos.resolvedLabel, '1-A');
    });
  });

  group('buildEscaladaSortGrid', () {
    testWidgets('renderiza botões e chama onSortChanged', (WidgetTester tester) async {
      EscaladaSortMode? selectedMode;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildEscaladaSortGrid(
              context,
              EscaladaSortMode.original,
              (mode) {
                selectedMode = mode;
              },
            ),
          ),
        ),
      ));

      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('ALFABÉTICO'), findsOneWidget);
      expect(find.text('DIFICULDADE'), findsOneWidget);

      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.alphaAsc);
      
      await tester.tap(find.text('DIFICULDADE'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.gradeAsc);
    });
  });

  group('buildSetorBody', () {
    testWidgets('renderiza vias e destaca via alvo', (WidgetTester tester) async {
      final via = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via Teste',
          destaque: true,
        ),
      );
      final setor = Setor(nome: 'Setor Principal');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildSetorBody(
              context,
              setor,
              'crag_1',
              [via],
              via,
              GlobalKey(),
            ),
          ),
        ),
      ));

      expect(find.text('Via Teste'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('resolveRouteLabels', () {
    test('retorna codenome correto para via com caminho vetorial de múltiplos segmentos', () {
      final via = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Polydance'),
      );
      final setor = Setor(
        mapas: [
          Mapa(
            pontosDeInteresse: [
              Mapa_PontoDeInteresse(
                id: 'linha_12',
                linha: LinhaTrajeto(
                  compilado: DadosCompiladosLinha(
                    marcadores: [
                      MarcadorCompilado(
                        tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                        rotulo: '5',
                      ),
                    ],
                  ),
                ),
              ),
              Mapa_PontoDeInteresse(
                id: 'linha_16',
                linha: LinhaTrajeto(
                  compilado: DadosCompiladosLinha(
                    marcadores: [
                      MarcadorCompilado(
                        tipo: NoTrajeto_TipoNo.PASSAGEM,
                        rotulo: '',
                      ),
                    ],
                  ),
                ),
              ),
              Mapa_PontoDeInteresse(
                id: 'linha_21',
                linha: LinhaTrajeto(
                  compilado: DadosCompiladosLinha(
                    marcadores: [
                      MarcadorCompilado(
                        tipo: NoTrajeto_TipoNo.FIM_TOP,
                        rotulo: 'C',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            referencias: [
              Mapa_Referencia(
                escalada: 'Polydance',
                ids: ['linha_12', 'linha_16', 'linha_21'],
              ),
            ],
          ),
        ],
      );

      final result = resolveRouteLabels(via, setor);
      expect(result.resolvedLabel, '5-C');
      expect(result['resolvedLabel'], '5-C');
    });

    test('retorna vazio e sem IDs técnicos para linhas sem nós de círculo identificador', () {
      final via = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Via Sem Circulo'),
      );
      final setor = Setor(
        mapas: [
          Mapa(
            pontosDeInteresse: [
              Mapa_PontoDeInteresse(
                id: 'linha_curva',
                linha: LinhaTrajeto(
                  compilado: DadosCompiladosLinha(
                    marcadores: [
                      MarcadorCompilado(
                        tipo: NoTrajeto_TipoNo.PASSAGEM,
                        rotulo: '',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            referencias: [
              Mapa_Referencia(
                escalada: 'Via Sem Circulo',
                ids: ['linha_curva'],
              ),
            ],
          ),
        ],
      );

      final result = resolveRouteLabels(via, setor);
      expect(result.resolvedLabel, '');
      expect(result['resolvedLabel'], '');
    });

    test('retorna rótulo de POI convencional', () {
      final via = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Via Tradicional'),
      );
      final setor = Setor(
        mapas: [
          Mapa(
            pontosDeInteresse: [
              Mapa_PontoDeInteresse(
                id: 'p1',
                label: '12',
                circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
              ),
            ],
            referencias: [
              Mapa_Referencia(
                escalada: 'Via Tradicional',
                ids: ['p1'],
              ),
            ],
          ),
        ],
      );

      final result = resolveRouteLabels(via, setor);
      expect(result.resolvedLabel, '12');
      expect(result['resolvedLabel'], '12');
    });
  });

  group('buildSetorBody e modalidades de escalada', () {
    testWidgets('renderiza corretamente modalidades Mista, Móvel e Esportiva nos cards do setor', (
      WidgetTester tester,
    ) async {
      final viaEsportiva = Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via Esportiva Teste',
          dificuldade: GrauVia_GrauVia.BR_7A,
        ),
      );
      final viaMovelPura = Escalada(
        viaMovel: ViaMovel(
          nome: 'Fenda Pura',
          dificuldade: GrauVia_GrauVia.BR_5SUP,
          quantidadeProtecoesIntermediarias: 0,
        ),
      );
      final viaMovelMista = Escalada(
        viaMovel: ViaMovel(
          nome: 'Fenda com Grampo',
          dificuldade: GrauVia_GrauVia.BR_6SUP,
          quantidadeProtecoesIntermediarias: 2,
        ),
      );
      final viaMultipitchMista = Escalada(
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
          nome: 'Paredão Misto',
          dificuldadeMaxima: GrauVia_GrauVia.BR_7A,
          tipoViaMultiplasEnfiadas:
              ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.MISTA,
        ),
      );

      final setor = Setor(nome: 'Setor Central');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildSetorBody(
                context,
                setor,
                'crag_teste',
                [viaEsportiva, viaMovelPura, viaMovelMista, viaMultipitchMista],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Via Esportiva Teste'), findsOneWidget);
      expect(find.text('Esportiva | 7a'), findsOneWidget);

      expect(find.text('Fenda Pura'), findsOneWidget);
      expect(find.text('Móvel | 5ºsup'), findsOneWidget);

      expect(find.text('Fenda com Grampo'), findsOneWidget);
      expect(find.text('Mista | 6ºsup'), findsOneWidget);

      expect(find.text('Paredão Misto'), findsOneWidget);
      expect(find.text('Mista | 7a'), findsOneWidget);
    });

    testWidgets(
      'não exibe "indefinido" e omite separador quando a via tiver grau indefinido',
      (WidgetTester tester) async {
        final viaSemGrau = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Via Sem Grau',
            dificuldade: GrauVia_GrauVia.INDEFINIDO,
          ),
        );
        final setor = Setor(nome: 'Setor Teste');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => buildSetorBody(
                  context,
                  setor,
                  'crag_teste',
                  [viaSemGrau],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Via Sem Grau'), findsOneWidget);
        expect(find.text('Esportiva'), findsOneWidget);
        expect(find.textContaining(RegExp(r'indefinido', caseSensitive: false)), findsNothing);
        expect(find.textContaining('Esportiva |'), findsNothing);
      },
    );
  });
}

