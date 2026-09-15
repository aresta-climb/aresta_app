// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
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
      expect(result['resolvedLabel'], '12');
    });
  });
}
