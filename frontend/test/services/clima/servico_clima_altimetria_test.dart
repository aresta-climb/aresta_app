// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/servico_clima_altimetria.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';

import '../../fakes/cliente_clima_altimetria_fake.dart';

class _AssetBundleFalho extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('Asset ausente'));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(StateError('Asset corrompido'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late Directory dirTemp;
  late ArmazenamentoClimaLocal armazenamento;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp('srv_clima_alt_test_');
    armazenamento = ArmazenamentoClimaLocal(
      provedorDiretorioBase: () async => dirTemp.path,
    );
  });

  tearDown(() async {
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('ServicoClimaAltimetria e ClienteClimaAltimetriaSupabase', () {
    test(
      'deve carregar semente offline inicial, hidratar cache em disco, sincronizar com TTL de 30min e avaliar radar ao vivo + umidade de 5 dias',
      () async {
        // Pre-popula disco para exercitar hidratacao inicial
        await armazenamento.salvarSnapshot(
          SnapshotClimaAltimetria(
            geradoEm: DateTime.utc(2026, 11, 24),
            bolhasChuva: const [],
            chuvaPorPico: const {},
            altimetriaPorPico: const {
              'pico_cache_previo': CotaAltimetricaPico(
                altitudeBaseMetros: 500,
                altitudePicoMetros: 910,
              ),
            },
          ),
        );

        var relogio = DateTime.utc(2026, 11, 25, 14, 0);
        final fake = ClienteClimaAltimetriaFake(
          snapshotInicial: SnapshotClimaAltimetria(
            geradoEm: DateTime.utc(2026, 11, 25, 13, 30),
            bolhasChuva: const [
              BolhaChuvaRegional(
                id: 'frente_mg',
                latitude: -20.04,
                longitude: -44.24,
                intensidadeMmHora: 5.8,
                ventoRumoGraus: 52.0,
                ventoVelocidadeKmh: 24.0,
                contornoExterno: [
                  PontoContornoGeo(longitude: -45.0, latitude: -21.0),
                  PontoContornoGeo(longitude: -43.2, latitude: -20.8),
                  PontoContornoGeo(longitude: -43.6, latitude: -19.2),
                ],
              ),
            ],
            bolhasIncendio: const [
              BolhaIncendioRegional(
                id: 'fogo_cipo',
                latitude: -19.34,
                longitude: -43.62,
                potenciaFrpMw: 38.0,
                totalFocos: 4,
                ventoRumoGraus: 275.0,
                ventoVelocidadeKmh: 18.0,
                contornoExterno: [
                  PontoContornoGeo(longitude: -43.70, latitude: -19.40),
                  PontoContornoGeo(longitude: -43.54, latitude: -19.39),
                  PontoContornoGeo(longitude: -43.58, latitude: -19.28),
                ],
              ),
            ],
            chuvaPorPico: {
              'br_mg_igarape_pedra_grande': [
                EventoChuvaPico(
                  data: DateTime.utc(2026, 11, 25),
                  milimetros: 22.0,
                  bolhaId: 'frente_mg',
                ),
              ],
            },
            altimetriaPorPico: const {
              'br_mg_igarape_pedra_grande': CotaAltimetricaPico(
                altitudeBaseMetros: 982,
                altitudePicoMetros: 1432,
              ),
              'br_es_pancao_pico_novo': CotaAltimetricaPico(
                altitudeBaseMetros: 220,
                altitudePicoMetros: 680,
              ),
            },
          ),
        );

        final servico = ServicoClimaAltimetria(
          armazenamento: armazenamento,
          fonteRemota: fake,
          relogioUtc: () => relogio,
        );

        expect(servico.inicializado, isFalse);
        expect(servico.temSnapshotClima, isFalse);
        await servico.inicializar();
        expect(servico.inicializado, isTrue);
        expect(servico.temSnapshotClima, isTrue);
        // Chamada idempotente
        await servico.inicializar();
        expect(servico.obterAltitudePico('pico_cache_previo'), equals(910));

        // Quando todos os picos informados ja existem na semente local, busca APENAS estado_clima_picos
        expect(
          await servico.sincronizarSeNecessario(
            idsPicosCatalogo: const ['br_mg_igarape_pedra_grande'],
          ),
          isTrue,
        );
        expect(fake.totalChamadas, equals(1));
        expect(fake.totalChamadasComAltimetria, equals(0));
        expect(
          servico.obterUmidadePico('br_mg_igarape_pedra_grande').nivel,
          equals(NivelUmidadePico.possivelmenteUmido),
        );
        expect(
          servico.obterUmidadePico('pico_seco_sem_chuva').nivel,
          equals(NivelUmidadePico.seco),
        );
        expect(servico.bolhasAtivas.length, equals(1));
        expect(servico.bolhasAtivas.single.bolha.id, equals('frente_mg'));
        expect(servico.bolhasIncendioAtivas.length, equals(1));
        expect(
          servico.bolhasIncendioAtivas.single.incendio.id,
          equals('fogo_cipo'),
        );

        // Dentro do TTL de 30min sem pico novo -> nao refaz requisicao
        relogio = relogio.add(const Duration(minutes: 15));
        expect(
          await servico.sincronizarSeNecessario(
            idsPicosCatalogo: const ['br_mg_igarape_pedra_grande'],
          ),
          isFalse,
        );

        // Se surgir pico novo ausente da altimetria local, sincroniza imediatamente incluindo altimetria
        expect(
          await servico.sincronizarSeNecessario(
            idsPicosCatalogo: const [
              'br_mg_igarape_pedra_grande',
              'br_es_pancao_pico_novo',
            ],
          ),
          isTrue,
        );
        expect(fake.totalChamadasComAltimetria, equals(1));
        expect(
          servico.obterAltitudePico('br_es_pancao_pico_novo'),
          equals(680),
        );

