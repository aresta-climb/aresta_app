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

    test('encontra até 6 nós mais próximos ordenados por distância dentro do raio padrão de 25 km', () {
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
          latitude: -20.0800, // ~9.1 km ao sul
          longitude: -43.9800,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 20000},
        ),
        const NoEstrada(
          noOsmId: 105,
          latitude: -20.1200, // ~13.3 km ao sul
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 22000},
        ),
        const NoEstrada(
          noOsmId: 106,
          latitude: -20.1700, // ~18.9 km ao sul (dentro do novo raio de 25 km!)
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 25000},
        ),
        const NoEstrada(
          noOsmId: 107,
          latitude: -20.2000, // ~22.2 km ao sul (7º mais próximo, deve ficar de fora do top 6)
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 27000},
        ),
        const NoEstrada(
          noOsmId: 108,
          latitude: -20.3000, // ~33 km ao sul (fora do raio de 25 km)
          longitude: -44.3000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 5000},
        ),
      ];

      final arvore = ArvoreKdNosEstrada(nos);

      expect(arvore.estaVazia, isFalse);
      expect(arvore.tamanho, 8);

      final vizinhos = arvore.buscarMaisProximos(
        latitude: -20.0000,
        longitude: -44.0000,
      );

      expect(
        vizinhos.map((n) => n.noOsmId).toList(),
        <int>[102, 101, 103, 104, 105, 106],
      );
    });

    test('ignora nós além do raio de captura de 25 km mesmo quando há menos de 6 nós próximos', () {
      final nos = <NoEstrada>[
        const NoEstrada(
          noOsmId: 201,
          latitude: -20.1700, // ~18.9 km (<= 25 km)
          longitude: -44.0000,
          distanciasPorCroquiMetros: <String, int>{'pico_a': 8000},
        ),
        const NoEstrada(
          noOsmId: 202,
          latitude: -20.2600, // ~28.8 km (> 25 km)
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
        limite: 3,
      );

      expect(vizinhos.map((n) => n.noOsmId).toList(), <int>[5, 6, 7]);
    });
  });

  group('EstimativaViagemPico', () {
    test('arredonda durações abaixo de 60 min em múltiplos de 5 min (mínimo 5 min) e >= 60 min em múltiplos de 10 min', () {
      expect(EstimativaViagemPico.arredondarMinutos(2), 5);
      expect(EstimativaViagemPico.arredondarMinutos(38), 40);
      expect(EstimativaViagemPico.arredondarMinutos(58), 60);
      expect(EstimativaViagemPico.arredondarMinutos(74), 70);
      expect(EstimativaViagemPico.arredondarMinutos(75), 80);
      expect(EstimativaViagemPico.arredondarMinutos(120), 120);
    });

    test('formata badge e tooltip com tempo arredondado quando possui duracaoMinutos e apenas km quando não possui', () {
      const comMenosDeUmaHora = EstimativaViagemPico(
        distanciaMetros: 51400,
        duracaoMinutos: 38,
      );
      expect(comMenosDeUmaHora.possuiEstimativaTempo, isTrue);
      expect(comMenosDeUmaHora.formatarBadge(), '~40 min');
      expect(
        comMenosDeUmaHora.formatarTooltip(),
        'Estimativa sem trânsito: ~40 min (51.4 km)',
      );

      const comMaisDeUmaHora = EstimativaViagemPico(
        distanciaMetros: 88200,
        duracaoMinutos: 74,
      );
      expect(comMaisDeUmaHora.formatarBadge(), '~1h 10min');
      expect(
        comMaisDeUmaHora.formatarTooltip(),
        'Estimativa sem trânsito: ~1h 10min (88.2 km)',
      );

      const comHoraExata = EstimativaViagemPico(
        distanciaMetros: 150000,
        duracaoMinutos: 118,
      );
      expect(comHoraExata.formatarBadge(), '~2h');
      expect(
        comHoraExata.formatarTooltip(),
        'Estimativa sem trânsito: ~2h (150.0 km)',
      );

      const apenasDistancia = EstimativaViagemPico(
        distanciaMetros: 245600,
      );
      expect(apenasDistancia.possuiEstimativaTempo, isFalse);
      expect(apenasDistancia.formatarBadge(), '245.6 km');
      expect(apenasDistancia.formatarTooltip(), isNull);
    });
  });

  group('CalculadoraDistanciaEstrada', () {
    test('calcula tempo de acesso U -> K (30 km/h até 3 km e 50 km/h acima de 3 km) e escolhe o nó que minimiza o tempo total', () {
      // Testa diretamente o cálculo de tempo de acesso:
      // 8000 m de estrada (3 km a 30 km/h = 6 min + 5 km a 50 km/h = 6 min -> 12 min)
      expect(
        CalculadoraDistanciaEstrada.calcularTempoAcessoMinutos(8000.0),
        closeTo(12.0, 1e-6),
      );
      // 1500 m de estrada (1.5 km a 30 km/h = 3 min)
      expect(
        CalculadoraDistanciaEstrada.calcularTempoAcessoMinutos(1500.0),
        closeTo(3.0, 1e-6),
      );

      // Usuário em (-20.0000, -44.0000).
      // Nó 10 (estrada secundária lenta): mais curto em distância (32 km), porém leva 58 min.
      // Nó 20 (rodovia rápida): mais longo em distância (44 km), porém leva 33 min!
      const noSecundarioCurtoLento = NoEstrada(
        noOsmId: 10,
        latitude: -20.0050,
        longitude: -44.0000,
        distanciasPorCroquiMetros: <String, int>{'serra_cipo': 32000},
        duracoesPorCroquiMinutos: <String, int>{'serra_cipo': 58},
      );
      const noRodoviaLongoRapido = NoEstrada(
        noOsmId: 20,
        latitude: -20.0100,
        longitude: -44.0000,
        distanciasPorCroquiMetros: <String, int>{'serra_cipo': 44000},
        duracoesPorCroquiMinutos: <String, int>{'serra_cipo': 33},
      );

      final calculadora = CalculadoraDistanciaEstrada(
        nos: const <NoEstrada>[noSecundarioCurtoLento, noRodoviaLongoRapido],
      );

      final estimativa = calculadora.calcularEstimativaViagem(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'serra_cipo',
        latitudePico: -19.3500,
        longitudePico: -43.6000,
      );

      final distRetaNo20 = Geolocator.distanceBetween(
        -20.0000,
        -44.0000,
        noRodoviaLongoRapido.latitude,
        noRodoviaLongoRapido.longitude,
      );
      final distAcessoNo20 = distRetaNo20 * 1.25;
      final tempoAcessoNo20 =
          CalculadoraDistanciaEstrada.calcularTempoAcessoMinutos(distAcessoNo20);

      expect(estimativa.possuiEstimativaTempo, isTrue);
      expect(estimativa.duracaoMinutos, (tempoAcessoNo20 + 33).round());
      expect(estimativa.distanciaMetros, closeTo(distAcessoNo20 + 44000, 0.01));
    });

    test('escolhe o nó vizinho que minimiza a distância quando duracoesPorCroquiMinutos não está preenchido', () {
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

    test('calcula apenas o trecho inicial e duração mínima quando o usuário está próximo ao nó do próprio estacionamento', () {
      const noEstacionamento = NoEstrada(
        noOsmId: 99,
        latitude: -20.0030,
        longitude: -44.0030,
        distanciasPorCroquiMetros: <String, int>{'pedra_grande': 0},
        duracoesPorCroquiMinutos: <String, int>{'pedra_grande': 0},
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

      final estimativa = calculadora.calcularEstimativaViagem(
        latitudeUsuario: -20.0000,
        longitudeUsuario: -44.0000,
        identificadorCroqui: 'pedra_grande',
        latitudePico: -20.0030,
        longitudePico: -44.0030,
      );

      expect(
        estimativa.distanciaMetros,
        closeTo(distRetaEstacionamento * 1.25, 0.01),
      );
      expect(estimativa.duracaoMinutos, 1);
      expect(estimativa.formatarBadge(), '~5 min');
    });

    test('utiliza portais de borda (sem estimativa de tempo) quando o usuário está a mais de 180 km do pico fora da malha local', () {
      const noLocalSp = NoEstrada(
        noOsmId: 500,
        latitude: -23.5510,
        longitude: -46.6310,
        distanciasPorCroquiMetros: <String, int>{'pedra_bau': 140000},
        duracoesPorCroquiMinutos: <String, int>{'pedra_bau': 125},
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

      final estimativa = calculadora.calcularEstimativaViagem(
        latitudeUsuario: -23.5500,
        longitudeUsuario: -46.6300,
        identificadorCroqui: 'serra_cipo',
        latitudePico: -19.3500,
        longitudePico: -43.6000,
      );

      expect(estimativa.distanciaMetros, closeTo(esperado, 0.01));
      expect(estimativa.duracaoMinutos, isNull);
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

      expect(calculadora.possuiMalha, isTrue);
      expect(resultado, closeTo(distRetaPico * 1.25, 0.01));
    });

    test('retorna distância geodésica direta quando a calculadora está vazia sem malha carregada', () {
      const calculadora = CalculadoraDistanciaEstrada.vazia();

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
        duracoesPorCroquiMinutos: <String, int>{
          'pico_perto_estrada': 15,
          'pico_atras_serra': 75,
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
        latitudePico: -20.0500,
        longitudePico: -44.0500,
        nosProximosPrecalculados: nosProximos,
      );

      expect(distPicoPertoEstrada, lessThan(distPicoAtrasSerra));
    });
  });
}
