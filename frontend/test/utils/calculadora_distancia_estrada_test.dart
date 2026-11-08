// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:frontend/utils/calculadora_distancia_estrada.dart';

void main() {
  group('ArvoreKdNosEstrada', () {
    test('retorna lista vazia quando a árvore é construída sem nós', () {
      final arvore = ArvoreKdNosEstrada(const <NoEstrada>[]);

      expect(arvore.estaVazia, isTrue);
      expect(arvore.tamanho, 0);
      expect(
        arvore.buscarMaisProximos(latitude: -20.0, longitude: -44.0),
        isEmpty,
      );
    });

    test('encontra até 3 nós mais próximos ordenados por distância dentro do raio de 15 km', () {
      final nos = <NoEstrada>[
        const NoEstrada(
          noOsmId: 101,
          latitude: -20.0100, // ~1.1 km ao sul
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 10000},
        ),
        const NoEstrada(
          noOsmId: 102,
          latitude: -20.0020, // ~220 m ao sul (mais próximo)
          longitude: -44.0010,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 11000},
        ),
        const NoEstrada(
          noOsmId: 103,
          latitude: -19.9500, // ~5.5 km ao norte
          longitude: -44.0200,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 15000},
        ),
        const NoEstrada(
          noOsmId: 104,
          latitude: -20.0800, // ~8.9 km ao sul (4º mais próximo, deve ficar de fora do top 3)
          longitude: -43.9800,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 20000},
        ),
        const NoEstrada(
          noOsmId: 105,
          latitude: -20.3000, // ~33 km ao sul (fora do raio de 15 km)
          longitude: -44.3000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 5000},
        ),
        const NoEstrada(
          noOsmId: 106,
          latitude: -19.7000, // ~33 km ao norte (fora do raio de 15 km)
          longitude: -43.7000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 5000},
        ),
      ];

      final arvore = ArvoreKdNosEstrada(nos);

      expect(arvore.estaVazia, isFalse);
      expect(arvore.tamanho, 6);

      final vizinhos = arvore.buscarMaisProximos(
        latitude: -20.0000,
        longitude: -44.0000,
      );

      expect(vizinhos.map((n) => n.noOsmId).toList(), <int>[102, 101, 103]);
    });

    test('ignora nós além do raio de captura de 15 km mesmo quando há menos de 3 nós próximos', () {
      final nos = <NoEstrada>[
        const NoEstrada(
          noOsmId: 201,
          latitude: -20.0100, // ~1.1 km
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 8000},
        ),
        const NoEstrada(
          noOsmId: 202,
          latitude: -20.2000, // ~22 km (> 15 km)
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 4000},
        ),
      ];

      final arvore = ArvoreKdNosEstrada(nos);
      final vizinhos = arvore.buscarMaisProximos(
        latitude: -20.0000,
        longitude: -44.0000,
      );

      expect(vizinhos.map((n) => n.noOsmId).toList(), <int>[201]);
    });

    test('explora ambos os ramos da árvore quando a linha divisória está próxima do ponto de consulta', () {
      // Malha distribuída nos 4 quadrantes ao redor de (-20.0, -44.0) para exercitar
      // cortes alternados em latitude e longitude e poda/inspeção do ramo oposto.
      final nos = <NoEstrada>[
        const NoEstrada(
          noOsmId: 1,
          latitude: -20.050,
          longitude: -44.050,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 2,
          latitude: -20.040,
          longitude: -43.950,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 3,
          latitude: -19.960,
          longitude: -44.040,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 4,
          latitude: -19.950,
          longitude: -43.960,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 5,
          latitude: -20.005,
          longitude: -43.995,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 6,
          latitude: -19.995,
          longitude: -44.005,
          distanciasPorCroquiMetros: <String, int>{},
        ),
        const NoEstrada(
          noOsmId: 7,
          latitude: -20.008,
          longitude: -44.008,
          distanciasPorCroquiMetros: <String, int>{},
        ),
      ];

      final arvore = ArvoreKdNosEstrada(nos);
      final vizinhos = arvore.buscarMaisProximos(
        latitude: -20.001,
        longitude: -43.999,
      );

      expect(vizinhos.map((n) => n.noOsmId).toList(), <int>[5, 6, 7]);
    });
  });

  group('CalculadoraDistanciaEstrada', () {
    test('escolhe o nó vizinho na direção favorável que minimiza a distância total até o pico', () {
      // Usuário em (-20.000, -44.000).
      // Nó 1 está muito perto (500m ao norte), mas antes de um retorno rodoviário (distância ao pico = 28 km).
      // Nó 2 está a 2 km ao sul, já na direção do pico (distância ao pico = 23 km).
      const noAntesDoRetorno = NoEstrada(
        noOsmId: 10,
        latitude: -19.9955,
        longitude: -44.0000,
        distanciasPorCroquiMetros: <String, int>{'serra_cipo': 28000},
      );
      const noDirecaoPico = NoEstrada(
        noOsmId: 20,
        latitude: -20.0180,
        longitude: -44.0000,
        distanciasPorCroquiMetros: <String, int>{'serra_cipo': 23000},
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noAntesDoRetorno, noDirecaoPico],
      );

      final distRetaNo2 = Geolocator.distanceBetween(
        -20.0000,
        -44.0000,
        noDirecaoPico.latitude,
        noDirecaoPico.longitude,
      );
      final esperado = distRetaNo2 * 1.25 + 23000;

      final resultado = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'serra_cipo',
        latitudePico: -20.1500,
        longitudePico: -43.9000,
      );

      expect(resultado, closeTo(esperado, 0.01));
    });

    test('calcula apenas o trecho inicial quando o usuário está próximo ao nó do próprio estacionamento', () {
      // Nó do estacionamento possui distancia_metros = 0 para o pico.
      const noEstacionamento = NoEstrada(
        noOsmId: 99,
        latitude: -20.0030,
        longitude: -44.0030,
        distanciasPorCroquiMetros: <String, int>{'pedra_grande': 0},
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noEstacionamento],
      );

      final distRetaEstacionamento = Geolocator.distanceBetween(
        -20.0000,
        -44.0000,
        noEstacionamento.latitude,
        noEstacionamento.longitude,
      );

      final resultado = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'pedra_grande',
        latitudePico: -20.0030,
        longitudePico: -44.0030,
      );

      expect(resultado, closeTo(distRetaEstacionamento * 1.25, 0.01));
    });

    test('utiliza portais de borda quando o usuário está a mais de 180 km do pico fora da malha local', () {
      // Usuário em São Paulo (-23.55, -46.63), longe da malha local de Minas Gerais.
      // Há um nó local em SP que só conhece picos de SP ('pedra_bau').
      // O pico de MG ('serra_cipo') possui 2 portais de borda:
      // - Portal Sul (Fernão Dias / BR-381), na direção de SP, a 160 km de estrada do pico.
      // - Portal Norte (BR-040), na direção oposta, a 175 km de estrada do pico.
      const noLocalSp = NoEstrada(
        noOsmId: 500,
        latitude: -23.5510,
        longitude: -46.6310,
        distanciasPorCroquiMetros: <String, int>{'pedra_bau': 140000},
      );
      const portalSulBr381 = PortalBordaPico(
        noOsmId: 601,
        latitude: -20.8000,
        longitude: -44.6000,
        distanciaEstradaAtePicoMetros: 160000,
      );
      const portalNorteBr040 = PortalBordaPico(
        noOsmId: 602,
        latitude: -18.5000,
        longitude: -44.2000,
        distanciaEstradaAtePicoMetros: 175000,
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noLocalSp],
        portaisPorCroqui: const <String, List<PortalBordaPico>>{
          'serra_cipo': <PortalBordaPico>[portalNorteBr040, portalSulBr381],
        },
      );

      final distRetaPortalSul = Geolocator.distanceBetween(
        -23.5500,
        -46.6300,
        portalSulBr381.latitude,
        portalSulBr381.longitude,
      );
      final esperado = distRetaPortalSul * 1.25 + 160000;

      final resultado = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -23.5500,
        longitudeUsuario: -46.6300,
        identificadorCroqui: 'serra_cipo',
        latitudePico: -19.3500,
        longitudePico: -43.6000,
      );

      expect(resultado, closeTo(esperado, 0.01));
    });

    test('aplica fallback geodésico com fator 1.25 quando a malha está ativa mas o croqui não possui nós nem portais', () {
      const noOutroPico = NoEstrada(
        noOsmId: 700,
        latitude: -20.0010,
        longitude: -44.0010,
        distanciasPorCroquiMetros: <String, int>{'pico_existente': 12000},
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noOutroPico],
      );

      final distRetaPico = Geolocator.distanceBetween(
        -20.0000,
        -44.0000,
        -20.1000,
        -44.1000,
      );

      final resultado = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'croqui_novo_editor',
        latitudePico: -20.1000,
        longitudePico: -44.1000,
      );

      expect( calculadora.possuiMalha, isTrue);
      expect(resultado, closeTo(distRetaPico * 1.25, 0.01));
    });

    test('retorna distância geodésica direta quando a calculadora está vazia sem malha carregada', () {
      final calculadora = CalculadoraDistanciaEstrada.vazia();

      final distRetaPico = Geolocator.distanceBetween(
        -20.0000,
        -44.0000,
        -20.1000,
        -44.1000,
      );

      final resultado = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'qualquer_pico',
        latitudePico: -20.1000,
        longitudePico: -44.1000,
      );

      expect(calculadora.possuiMalha, isFalse);
      expect(resultado, closeTo(distRetaPico, 0.01));
    });

    test('reutiliza a lista de nós próximos pré-calculados para avaliar múltiplos picos em lote', () {
      const noCompartilhado = NoEstrada(
        noOsmId: 800,
        latitude: -20.0050,
        longitude: -44.0050,
        distanciasPorCroquiMetros: <String, int>{
          'pico_perto_estrada': 14000,
          'pico_atras_serra': 62000,
        },
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noCompartilhado],
      );

      final nosProximos = calculadora.buscarNosProximos(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
      );

      final distPicoPertoEstrada = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'pico_perto_estrada',
        latitudePico: -20.1200,
        longitudePico: -44.1200,
        nosProximosPrecalculados: nosProximos,
      );

      final distPicoAtrasSerra = calculadora.calcularDistanciaMetros(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'pico_atras_serra',
        latitudePico: -20.0500, // Mais perto em linha reta, mas muito mais longe por estrada!
        longitudePico: -44.0500,
        nosProximosPrecalculados: nosProximos,
      );

      expect(distPicoPertoEstrada, lessThan(distPicoAtrasSerra));
    });
  });
}
