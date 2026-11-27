// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/camada_marcadores_globo_explorar.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  const malhaTeste = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          Offset(-50.0, -25.0),
          Offset(-38.0, -25.0),
          Offset(-38.0, -14.0),
          Offset(-50.0, -14.0),
        ],
      ),
    ],
    brasil: [
      Offset(-50.0, -25.0),
      Offset(-38.0, -25.0),
      Offset(-38.0, -14.0),
      Offset(-50.0, -14.0),
    ],
    estados: [],
    localidadesProximas: [
      LocalidadeRegionalMapa(
        nome: 'Belo Horizonte',
        ehCidade: true,
        nivel: 1,
        longitude: -44.08,
        latitude: -19.72,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lagoa Santa',
        ehCidade: true,
        nivel: 2,
        longitude: -43.89,
        latitude: -19.63,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lapinha da Serra',
        ehCidade: false,
        nivel: 3,
        longitude: -43.68,
        latitude: -19.12,
      ),
      LocalidadeRegionalMapa(
        nome: 'Polo Referência',
        ehCidade: true,
        nivel: 1,
        longitude: -44.00,
        latitude: -20.32,
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-381',
        verticesLonLat: [
          Offset(-44.08, -19.72),
          Offset(-44.20, -20.05),
        ],
      ),
    ],
  );

  const picosTeste = <MarcadorPicoGlobo>[
    MarcadorPicoGlobo(
      id: 'p_mg',
      nome: 'Pedra Grande',
      uf: 'MG',
      latitude: -20.05,
      longitude: -44.20,
      altitudeBaseMetros: 900,
      altitudePicoMetros: 1420,
    ),
    MarcadorPicoGlobo(
      id: 'p_rj',
      nome: 'Urca',
      uf: 'RJ',
      latitude: -20.12,
      longitude: -44.18,
      altitudeBaseMetros: 5,
      altitudePicoMetros: 396,
    ),
  ];

  final referenciasTeste =
      picosTeste.map((p) => p.paraReferenciaRelevo()).toList();
  final redeTeste = ConstrutorRedeViariaAresta.construir(
    rodovias: malhaTeste.rodoviasProximas,
    localidades: malhaTeste.localidadesProximas,
    picos: referenciasTeste,
  );

  group('CamadaMarcadoresGloboExplorar', () {
    testWidgets('agrupa picos por UF sem sobreposição em órbita distante e dispara seleção com LOD explícito', (
      tester,
    ) async {
      final ctrlOrbital = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 0.15,
      );
      addTearDown(ctrlOrbital.dispose);

      MarcadorPicoGlobo? clicado;
      double? lodRecebido;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => SizedBox(
                width: 400,
                height: 800,
                child: Stack(
                  children: CamadaMarcadoresGloboExplorar.construirCamadas(
                    context: ctx,
                    tamanho: const Size(400, 800),
                    controlador: ctrlOrbital,
                    redeViaria: redeTeste,
                    picos: picosTeste,
                    referenciasRelevo: referenciasTeste,
                    picoSelecionadoId: null,
                    localizacaoUsuario: null,
                    recuoSuperiorControles: 62.0,
                    aoSelecionarPico: (p, {lodExplicito}) {
                      clicado = p;
                      lodRecebido = lodExplicito;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cluster_uf_MG')), findsOneWidget);
      expect(find.byKey(const Key('cluster_uf_RJ')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cluster_uf_MG')));
      expect(clicado?.id, equals('p_mg'));
      expect(lodRecebido, closeTo(1.18, 1e-4));
    });

    testWidgets('projeta localidades IBGE sem colisão, ponto GPS do usuário e pílula expandida em zoom local', (
      tester,
    ) async {
      final ctrlLocal = ControladorCameraGlobo(
        latitudeInicial: -19.99,
        longitudeInicial: -44.08,
        lodInicial: 2.45,
      );
      addTearDown(ctrlLocal.dispose);

      var toquesPico = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => SizedBox(
                width: 420,
                height: 820,
                child: Stack(
                  children: CamadaMarcadoresGloboExplorar.construirCamadas(
                    context: ctx,
                    tamanho: const Size(420, 820),
                    controlador: ctrlLocal,
                    redeViaria: redeTeste,
                    picos: picosTeste,
                    referenciasRelevo: referenciasTeste,
                    picoSelecionadoId: 'p_mg',
                    localizacaoUsuario: (latitude: -19.99, longitude: -44.08),
                    recuoSuperiorControles: 62.0,
                    aoSelecionarPico: (_, {lodExplicito}) => toquesPico++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('marcador_localizacao_usuario')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pilula_lupa_p_mg')), findsOneWidget);
      expect(find.byKey(const Key('ponto_aresta_p_rj')), findsOneWidget);
      expect(find.text('Belo Horizonte'), findsOneWidget);
      expect(
        find.byKey(const Key('cidade_aresta_Belo Horizonte')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('cidade_referencia_Polo Referência')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('ponto_aresta_p_rj')));
      await tester.tap(find.byKey(const Key('pilula_lupa_p_mg')));
      expect(toquesPico, equals(2));
    });
  });
}
