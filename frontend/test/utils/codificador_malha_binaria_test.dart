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

