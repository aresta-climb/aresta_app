// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConstrutorRedeViariaAresta', () {
    test('classifica todas as cidades como referência quando não há rodovias válidas ou picos', () {
      const localidades = [
        LocalidadeRegionalMapa(
          nome: 'Vitória',
          ehCidade: true,
          nivel: 1,
          longitude: -40.3128,
          latitude: -20.3155,
        ),
      ];
      const picos = [
        PicoRelevoReferencia(
          id: 'p1',
          latitude: -20.0,
          longitude: -44.0,
          altitudeBaseMetros: 800,
          altitudePicoMetros: 1200,
        ),
      ];

      final semRodovias = ConstrutorRedeViariaAresta.construir(
        rodovias: const [],
        localidades: localidades,
        picos: picos,
      );
      expect(semRodovias.trechosCorredorAresta, isEmpty);
      expect(semRodovias.cidadesClassificadas.single.ehRelevanteAresta, isFalse);

      final apenasPolilinhaCurta = ConstrutorRedeViariaAresta.construir(
        rodovias: const [
          RodoviaRegionalMapa(
            ehPrincipal: true,
            codigo: 'CURTA',
            verticesLonLat: [Offset(-43.9386, -19.9191)],
          ),
        ],
        localidades: localidades,
        picos: picos,
      );
      expect(apenasPolilinhaCurta.trechosCorredorAresta, isEmpty);
      expect(
        apenasPolilinhaCurta.cidadesClassificadas.single.ehRelevanteAresta,
        isFalse,
      );
    });

    test('propaga caminhos mínimos pelas rodovias federais BR-xxx desde Belo Horizonte até cada pico e gera assinatura determinística', () async {
      final malhaReal = await MalhaGeograficaGlobo.carregarDoAssetBundle();
      const picosAresta = <PicoRelevoReferencia>[
        PicoRelevoReferencia(
          id: 'cipo',
          latitude: -19.3156,
          longitude: -43.6135,
          altitudeBaseMetros: 820,
          altitudePicoMetros: 1310,
        ),
        PicoRelevoReferencia(
          id: 'sumidouro',
          latitude: -19.5600,
          longitude: -43.9400,
          altitudeBaseMetros: 710,
          altitudePicoMetros: 920,
        ),
        PicoRelevoReferencia(
          id: 'ouro_preto',
          latitude: -20.3677,
          longitude: -43.5075,
          altitudeBaseMetros: 1120,
          altitudePicoMetros: 1560,
        ),
        PicoRelevoReferencia(
          id: 'araxa',
          latitude: -19.7151,
          longitude: -46.7975,
          altitudeBaseMetros: 940,
          altitudePicoMetros: 1280,
        ),
        PicoRelevoReferencia(
          id: 'januaria',
          latitude: -15.4711,
          longitude: -44.4449,
          altitudeBaseMetros: 480,
          altitudePicoMetros: 760,
        ),
        PicoRelevoReferencia(
          id: 'friburgo',
          latitude: -22.2286,
          longitude: -42.4250,
          altitudeBaseMetros: 860,
          altitudePicoMetros: 1410,
        ),
      ];

      final localidadesComNivel3 = <LocalidadeRegionalMapa>[
        ...malhaReal.localidadesProximas,
        const LocalidadeRegionalMapa(
          nome: 'Serra do Cipó Vila',
          ehCidade: false,
          nivel: 3,
          longitude: -43.6150,
          latitude: -19.3200,
        ),
      ];

      final rede = ConstrutorRedeViariaAresta.construir(
        rodovias: malhaReal.rodoviasProximas,
        localidades: localidadesComNivel3,
        picos: picosAresta,
      );

      expect(rede.trechosCorredorAresta, isNotEmpty);
      expect(rede.trechosCorredorAresta.first.tempoInicio, closeTo(0.0, 0.08));
      expect(
        rede.trechosCorredorAresta.any((t) => t.tempoFim >= 0.95),
        isTrue,
      );

      final bh = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'Belo Horizonte',
      );
      final seteLagoas = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'Sete Lagoas',
      );
      final lagoaSanta = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'Lagoa Santa',
      );
      final ouroPreto = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'Ouro Preto',
      );
      final vilaCipo = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'Serra do Cipó Vila',
      );
      final saoPaulo = rede.cidadesClassificadas.firstWhere(
        (c) => c.localidade.nome == 'São Paulo',
      );

      expect(bh.ehRelevanteAresta, isTrue);
      expect(bh.tempoAtivacao, equals(0.0));
      expect(seteLagoas.ehRelevanteAresta, isTrue);
      expect(lagoaSanta.ehRelevanteAresta, isTrue);
      expect(ouroPreto.ehRelevanteAresta, isTrue);
      expect(ouroPreto.tempoAtivacao, greaterThan(bh.tempoAtivacao));
      expect(vilaCipo.ehRelevanteAresta, isTrue);
      expect(saoPaulo.ehRelevanteAresta, isFalse);

      final assinatura1 =
          ConstrutorRedeViariaAresta.calcularAssinaturaPicos(picosAresta);
      final assinatura2 =
          ConstrutorRedeViariaAresta.calcularAssinaturaPicos(picosAresta);
      final assinaturaDiferente =
          ConstrutorRedeViariaAresta.calcularAssinaturaPicos(
            picosAresta.sublist(0, 2),
          );
      expect(assinatura1, equals(assinatura2));
      expect(assinatura1, isNot(equals(assinaturaDiferente)));

      // Malha sintética com ponte virtual em trevo desnivelado (<= 1,80 km), nível 2 e sigla genérica filtrada
      final redeTrevo = ConstrutorRedeViariaAresta.construir(
        rodovias: const [
          RodoviaRegionalMapa(
            ehPrincipal: true,
            codigo: 'BR',
            verticesLonLat: [
              Offset(-43.9386, -19.9191),
              Offset(-43.9386, -19.9191),
              Offset(-43.8200, -19.8300),
            ],
          ),
          RodoviaRegionalMapa(
            ehPrincipal: false,
            nivelViario: 2,
            codigo: 'BR-262',
            verticesLonLat: [
              Offset(-43.8130, -19.8250),
              Offset(-43.6500, -19.7000),
            ],
          ),
          RodoviaRegionalMapa(
            ehPrincipal: false,
            nivelViario: 3,
            codigo: '',
            verticesLonLat: [
              Offset(-43.6500, -19.7000),
              Offset(-43.6420, -19.6920),
            ],
          ),
        ],
        localidades: const [
          LocalidadeRegionalMapa(
            nome: 'Arraial da Pedra',
            ehCidade: false,
            nivel: 3,
            longitude: -43.6420,
            latitude: -19.6920,
          ),
        ],
        picos: const [
          PicoRelevoReferencia(
            id: 'destino',
            latitude: -19.6920,
            longitude: -43.6420,
            altitudeBaseMetros: 780,
            altitudePicoMetros: 1180,
          ),
        ],
      );
      expect(redeTrevo.trechosCorredorAresta.length, greaterThanOrEqualTo(2));
      expect(redeTrevo.rodoviasFundo.first.codigo, isEmpty);
      expect(redeTrevo.rodoviasFundo[1].codigo, equals('BR-262'));
      expect(redeTrevo.cidadesClassificadas.single.ehRelevanteAresta, isTrue);

      // Rota individual Usuário -> Pico: conecta quando próximo à malha BR e retorna null em outro estado distante
      final rotaPertoBh = ConstrutorRedeViariaAresta.construirRotaUsuarioNaRede(
        redeBase: rede,
        origemUsuarioLonLat: const Offset(-43.9500, -19.9300),
        destinoPicoLonLat: const Offset(-43.6135, -19.3156),
      );
      expect(rotaPertoBh, isNotNull);
      expect(rotaPertoBh, isNotEmpty);
      expect(rotaPertoBh!.first.tempoInicio, equals(0.0));
      expect(rotaPertoBh.last.tempoFim, equals(1.0));

      final rotaTrevoVirtual =
          ConstrutorRedeViariaAresta.construirRotaUsuarioNaRede(
        redeBase: redeTrevo,
        origemUsuarioLonLat: const Offset(-43.9386, -19.9191),
        destinoPicoLonLat: const Offset(-43.6420, -19.6920),
      );
      expect(rotaTrevoVirtual, isNotNull);
      expect(rotaTrevoVirtual!.length, equals(2));

      final rotaOutroEstadoLonge =
          ConstrutorRedeViariaAresta.construirRotaUsuarioNaRede(
        redeBase: rede,
        origemUsuarioLonLat: const Offset(-38.5014, -12.9714),
        destinoPicoLonLat: const Offset(-43.6135, -19.3156),
      );
      expect(rotaOutroEstadoLonge, isNull);

      expect(
        ConstrutorRedeViariaAresta.construirRotaUsuarioNaRede(
          redeBase: const RedeViariaArestaGlobo(
            rodoviasFundo: [],
            trechosCorredorAresta: [],
            cidadesClassificadas: [],
          ),
          origemUsuarioLonLat: const Offset(-43.9386, -19.9191),
          destinoPicoLonLat: const Offset(-43.6135, -19.3156),
        ),
        isNull,
      );
    });
  });
}
