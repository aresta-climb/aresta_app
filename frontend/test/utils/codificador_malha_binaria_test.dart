// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/data/modelos/modelos_relevo_topografico.dart';
import 'package:frontend/utils/codificador_malha_binaria.dart';

void main() {
  group('CodificadorMalhaBinaria', () {
    test('codifica e decodifica malha completa do globo e rodovias com fidelidade binária', () {
      final bytes = CodificadorMalhaBinaria.codificarMalhaGlobo(
        versaoMalhaViaria: 'osm-bin-v4',
        continentes: const [
          PoligonoGeografico(
            id: 'america_sul',
            verticesLonLat: [Offset(-50.0, -25.0), Offset(-38.0, -15.0)],
          ),
        ],
        brasil: const [Offset(-48.0, -23.0), Offset(-41.0, -18.0)],
        estados: const [
          PoligonoGeografico(
            id: 'MG',
            verticesLonLat: [Offset(-44.5, -20.5), Offset(-43.2, -19.1)],
          ),
        ],
        localidades: const [
          LocalidadeRegionalMapa(
            nome: 'Belo Horizonte',
            ehCidade: true,
            nivel: 1,
            longitude: -43.9386,
            latitude: -19.9191,
          ),
          LocalidadeRegionalMapa(
            nome: '',
            ehCidade: false,
            nivel: 3,
            longitude: -43.6135,
            latitude: -19.3156,
          ),
        ],
        rodovias: [
          RodoviaRegionalMapa.comLimites(
            ehPrincipal: true,
            nivelViario: 1,
            codigo: 'BR-040',
            verticesLonLat: const [
              Offset(-43.9386, -19.9191),
              Offset(-43.8200, -20.2500),
            ],
          ),
          RodoviaRegionalMapa.comLimites(
            ehPrincipal: false,
            nivelViario: 2,
            codigo: '',
            verticesLonLat: const [
              Offset(-43.9386, -19.9191),
              Offset(-43.6135, -19.3156),
            ],
          ),
        ],
      );

      final lido = CodificadorMalhaBinaria.decodificarMalhaGlobo(bytes);
      expect(lido.versaoMalhaViaria, equals('osm-bin-v4'));
      expect(lido.continentes.single.id, equals('america_sul'));
      expect(lido.brasil.length, equals(2));
      expect(lido.estados.single.id, equals('MG'));
      expect(lido.localidades.first.nome, equals('Belo Horizonte'));
      expect(lido.localidades.first.ehCidade, isTrue);
      expect(lido.localidades.last.nome, isEmpty);
      expect(lido.localidades.last.ehCidade, isFalse);
      expect(lido.rodovias.first.codigo, equals('BR-040'));
      expect(lido.rodovias.first.ehPrincipal, isTrue);
      expect(lido.rodovias.last.nivelViario, equals(2));

      expect(
        () => CodificadorMalhaBinaria.decodificarMalhaGlobo(
          Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        ),
        throwsFormatException,
      );
      expect(
        () => CodificadorMalhaBinaria.decodificarMalhaGlobo(
          Uint8List.sublistView(bytes, 0, 10),
        ),
        throwsFormatException,
      );
    });

    test('codifica e decodifica snapshot viário offline e rejeita cabeçalho ou conteúdo vazio', () {
      final snap = SnapshotMalhaViariaOffline(
        geradoEm: DateTime.utc(2026, 11, 27, 16, 30),
        versaoHash: 'osm-snap-1',
        rodovias: [
          RodoviaRegionalMapa.comLimites(
            ehPrincipal: true,
            nivelViario: 1,
            codigo: 'MG-010',
            verticesLonLat: const [
              Offset(-43.9386, -19.9191),
              Offset(-43.6135, -19.3156),
            ],
          ),
        ],
      );

      final bytes = CodificadorMalhaBinaria.codificarSnapshotViario(snap);
      final decodificado = CodificadorMalhaBinaria.decodificarSnapshotViario(bytes);
      expect(decodificado.versaoHash, equals('osm-snap-1'));
      expect(decodificado.geradoEm, equals(DateTime.utc(2026, 11, 27, 16, 30)));
      expect(decodificado.rodovias.single.codigo, equals('MG-010'));

      expect(
        () => CodificadorMalhaBinaria.decodificarSnapshotViario(
          Uint8List.fromList([0, 0, 0, 0, 1, 0]),
        ),
        throwsFormatException,
      );

      final bytesVazio = CodificadorMalhaBinaria.codificarSnapshotViario(
        SnapshotMalhaViariaOffline(
          geradoEm: DateTime.utc(2026, 11, 27),
          versaoHash: '',
          rodovias: const [],
        ),
      );
      expect(
        () => CodificadorMalhaBinaria.decodificarSnapshotViario(bytesVazio),
        throwsFormatException,
      );
    });

    test('codifica e decodifica altimetria inicial com e sem grade regional SRTM', () {
      final grade = GradeElevacaoRegionalOffline(
        latMin: -21.0,
        lonMin: -45.0,
        passoGraus: 0.05,
        linhas: 2,
        colunas: 2,
        cotasMetros: Int16List.fromList([780, 840, 920, 1150]),
      );

      final bytesComGrade = CodificadorMalhaBinaria.codificarAltimetriaInicial(
        cotasPorPico: const {
          'cipo': CotaAltimetricaPico(
            altitudeBaseMetros: 810,
            altitudePicoMetros: 1320,
            altitudePontoMetros: 995,
            dimensaoGradeDem: 2,
            raioGradeDemGraus: 0.024,
            gradeDemMetros: [810, 920, 1100, 1320],
          ),
          'urca': CotaAltimetricaPico(
            altitudeBaseMetros: 12,
            altitudePicoMetros: 396,
          ),
        },
        gradeRegional: grade,
      );

      final lido = CodificadorMalhaBinaria.decodificarAltimetriaInicial(bytesComGrade);
      expect(lido.cotasPorPico['cipo']?.altitudePicoMetros, equals(1320));
      expect(lido.cotasPorPico['cipo']?.altitudePontoMetros, equals(995));
      expect(lido.cotasPorPico['cipo']?.gradeDemMetros, equals([810, 920, 1100, 1320]));
      expect(lido.cotasPorPico['urca']?.altitudePontoMetros, isNull);
      expect(lido.gradeRegional?.linhas, equals(2));
      expect(lido.gradeRegional?.cotasMetros, equals([780, 840, 920, 1150]));

      final bytesSemGrade = CodificadorMalhaBinaria.codificarAltimetriaInicial(
        cotasPorPico: const {},
      );
      final semGrade = CodificadorMalhaBinaria.decodificarAltimetriaInicial(bytesSemGrade);
      expect(semGrade.cotasPorPico, isEmpty);
      expect(semGrade.gradeRegional, isNull);

      expect(
        () => CodificadorMalhaBinaria.decodificarAltimetriaInicial(
          Uint8List.fromList([9, 9, 9, 9, 1, 0]),
        ),
        throwsFormatException,
      );
    });
  });
}
