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

        expect(await servico.sincronizarSeNecessario(forcar: true), isTrue);

        relogio = relogio.add(const Duration(hours: 2));
        fake.erroSimulado = const SocketException('Sem rede na rocha');
        expect(await servico.sincronizarSeNecessario(), isFalse);

        servico.dispose();

        // Verifica tolerancia caso assetBundle falhe e construtor com relogio padrao
        final servicoAssetFalho = ServicoClimaAltimetria(
          armazenamento: armazenamento,
          fonteRemota: fake,
          assetBundle: _AssetBundleFalho(),
        );
        await servicoAssetFalho.inicializar();
        expect(
          servicoAssetFalho.obterUmidadePico('inexistente').nivel,
          NivelUmidadePico.seco,
        );
        servicoAssetFalho.dispose();
        final servicoPadrao = ServicoClimaAltimetria();
        expect(servicoPadrao.bolhasAtivas, isEmpty);
        servicoPadrao.dispose();
      },
    );

    test(
      'ClienteClimaAltimetriaSupabase deve lidar com chave JWT, recorrer a copia_seguranca e falhar em HTTP 500 ou ambos vazios',
      () async {
        var modoServidor = 'fallback_seguranca';
        String? authRecebido;
        final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => servidor.close(force: true));

        var requisicoesAltimetria = 0;
        servidor.listen((HttpRequest req) async {
          authRecebido = req.headers.value('authorization');
          req.response.headers.contentType = ContentType.json;
          final slot = req.uri.queryParameters['slot'] ?? '';
          if (req.uri.path.endsWith('/snapshots_altimetria_picos')) {
            requisicoesAltimetria++;
          }

          if (modoServidor == 'erro_500') {
            req.response.statusCode = 503;
            req.response.write('Unavailable');
            await req.response.close();
            return;
          }
          if (modoServidor == 'ambos_vazios') {
            req.response.write('[]');
            await req.response.close();
            return;
          }

          if (req.uri.path.endsWith('/estado_clima_picos')) {
            if (slot == 'eq.atual' && modoServidor == 'fallback_seguranca') {
              req.response.write('[]');
            } else {
              req.response.write(jsonEncode([
                {
                  'slot': slot.replaceFirst('eq.', ''),
                  'gerado_em': '2026-11-25T12:00:00Z',
                  'bolhas_chuva': [
                    {
                      'id': 'frente_cipo',
                      'lat': -19.34,
                      'lon': -43.62,
                      'intensidade_mm_h': 3.2,
                      'vento_rumo_graus': 40.0,
                      'vento_kmh': 19.0,
                      'contorno_externo': [
                        [-44.0, -19.8],
                        [-43.1, -19.7],
                        [-43.5, -18.9],
                      ],
                    },
                  ],
                  'chuva_por_pico': {
                    'cipo': [
                      {
                        'data': '2026-11-24',
                        'mm': 9.4,
                        'bolha_id': 'frente_cipo',
                      },
                    ],
                  },
                },
              ]));
            }
          } else if (req.uri.path.endsWith('/snapshots_altimetria_picos')) {
            if (slot == 'eq.atual' && modoServidor == 'fallback_seguranca') {
              req.response.write('[]');
            } else {
              req.response.write(jsonEncode([
                {
                  'slot': slot.replaceFirst('eq.', ''),
                  'gerado_em': '2026-11-25T12:00:00Z',
                  'altimetria_por_pico': {
                    'cipo': {
                      'altitude_base_m': 810,
                      'altitude_pico_m': 1120,
                    },
                  },
                },
              ]));
            }
          }
          await req.response.close();
        });

        final cliente = ClienteClimaAltimetriaSupabase(
          urlBaseSupabase: 'http://127.0.0.1:${servidor.port}/',
          chaveAnonima: 'eyJhbGciOiJIUzI1NiJ9.teste',
          clienteHttp: ClienteHttpAresta.instancia,
        );

        // Por padrao nao consulta snapshots_altimetria_picos (economia de banda)
        final snapApenasClima = await cliente.buscarSnapshotRemoto();
        expect(authRecebido, equals('Bearer eyJhbGciOiJIUzI1NiJ9.teste'));
        expect(snapApenasClima.bolhasChuva.single.id, equals('frente_cipo'));
        expect(snapApenasClima.altimetriaPorPico, isEmpty);
        expect(requisicoesAltimetria, equals(0));

        final snapSeg = await cliente.buscarSnapshotRemoto(
          incluirAltimetria: true,
        );
        expect(requisicoesAltimetria, greaterThan(0));
        expect(
          snapSeg.altimetriaPorPico['cipo']!.altitudePicoMetros,
          equals(1120),
        );

        modoServidor = 'direto_atual';
        final snapAtual = await cliente.buscarSnapshotRemoto(
          incluirAltimetria: true,
        );
        expect(
          snapAtual.altimetriaPorPico['cipo']!.altitudePicoMetros,
          equals(1120),
        );

        modoServidor = 'ambos_vazios';
        await expectLater(
          cliente.buscarSnapshotRemoto(),
          throwsA(isA<HttpException>()),
        );

        modoServidor = 'erro_500';
        await expectLater(
          cliente.buscarSnapshotRemoto(),
          throwsA(isA<HttpException>()),
        );
        final servicoPadrao = ServicoClimaAltimetria();
        expect(servicoPadrao.bolhasAtivas, isEmpty);
        servicoPadrao.dispose();
      },
    );

    test(
      'obterUmidadePico respeita a data civil local do dispositivo sem adiantar para o dia seguinte após 21h BRT (00h UTC)',
      () async {
        // 25/11 às 22:30 BRT corresponde a 26/11 às 01:30 UTC: o usuário ainda está no dia 25!
        final fake = ClienteClimaAltimetriaFake(
          snapshotInicial: SnapshotClimaAltimetria(
            geradoEm: DateTime.utc(2026, 11, 26, 1, 15),
            bolhasChuva: const [],
            chuvaPorPico: {
              'pico_com_evento_utc_adiantado': [
                EventoChuvaPico(
                  data: DateTime.utc(2026, 11, 26),
                  milimetros: 18.0,
                ),
              ],
              'pico_chuva_hoje_25': [
                EventoChuvaPico(
                  data: DateTime.utc(2026, 11, 25),
                  milimetros: 12.0,
                ),
              ],
            },
            altimetriaPorPico: const {
              'pico_com_evento_utc_adiantado': CotaAltimetricaPico(
                altitudeBaseMetros: 800,
                altitudePicoMetros: 1100,
              ),
              'pico_chuva_hoje_25': CotaAltimetricaPico(
                altitudeBaseMetros: 800,
                altitudePicoMetros: 1100,
              ),
            },
          ),
        );

        final servico = ServicoClimaAltimetria(
          armazenamento: armazenamento,
          fonteRemota: fake,
          relogioUtc: () => DateTime.utc(2026, 11, 26, 1, 30),
          relogioLocal: () => DateTime(2026, 11, 25, 22, 30),
        );
        addTearDown(servico.dispose);

        await servico.inicializar();
        await servico.sincronizarSeNecessario(forcar: true);

        // Evento datado de 26/11 não pode aparecer enquanto o calendário local ainda é 25/11
        expect(
          servico.obterUmidadePico('pico_com_evento_utc_adiantado').nivel,
          equals(NivelUmidadePico.seco),
        );

        // Evento de 25/11 permanece no dia 0 da janela de 4 dias com data formatada 25/11
        final estado25 = servico.obterUmidadePico('pico_chuva_hoje_25');
        expect(estado25.nivel, equals(NivelUmidadePico.possivelmenteUmido));
        expect(estado25.dataChuvaFormatadaCurta, equals('25/11'));
        expect(estado25.diasParaSecar, equals(4));
        expect(
          servico.obterCotaAltimetrica('pico_chuva_hoje_25')?.altitudeBaseMetros,
          equals(800),
        );

        // Exercita singleton compartilhado, redefinirParaTestes e relógios padrão (UTC + local)
        expect(ServicoClimaAltimetria.instancia, isNotNull);
        ServicoClimaAltimetria.redefinirParaTestes();

        final servicoRelogiosPadrao = ServicoClimaAltimetria(
          armazenamento: armazenamento,
          fonteRemota: fake,
        );
        addTearDown(servicoRelogiosPadrao.dispose);
        await servicoRelogiosPadrao.sincronizarSeNecessario(forcar: true);
        expect(servicoRelogiosPadrao.temSnapshotClima, isTrue);
      },
    );
  });
}
