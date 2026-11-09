// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/sql/generated/dart/catalogo_sql.dart';
import 'package:frontend/services/catalogo/repositorio_catalogo.dart';

class _PathProviderFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;
}

void main() {
  sqfliteFfiInit();

  late Directory dirTemp;
  late String caminhoBanco;
  late RepositorioCatalogo repositorio;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp('repo_catalogo_test_');
    caminhoBanco = '${dirTemp.path}/catalogo.db';
    repositorio = RepositorioCatalogo(
      provedorCaminhoBanco: () async => caminhoBanco,
      fabricaBanco: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repositorio.fechar();
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('RepositorioCatalogo', () {
    test(
      'deve retornar versao vazia e listas vazias quando o arquivo catalogo.db ainda nao existir no disco',
      () async {
        expect(await repositorio.obterVersaoCatalogo(), isEmpty);
        expect(await repositorio.listarCroquis(), isEmpty);
        expect(await repositorio.listarEntidadesDetalhadas(), isEmpty);
        expect(await repositorio.obterIdSlugPorUid('uid_qualquer'), isNull);
        expect(await repositorio.obterItemPorUid('uid_qualquer'), isNull);
        final calculadoraVazia = await repositorio.carregarMalhaEstrada();
        expect(calculadoraVazia.possuiMalha, isFalse);
      },
    );

    test(
      'deve aplicar delta (upserts e deletes) atomicamente e atualizar versao_catalogo em catalogo_meta',
      () async {
        var notificacoes = 0;
        repositorio.versaoNotificador.addListener(() {
          notificacoes++;
        });

        // 1. Primeiro delta inicial (inserção de 2 croquis, 1 grupo, 1 setor e 2 escaladas)
        const deltaInicial = RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoAtual: '1111222233334444',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'croqui_uid_1',
                idSlug: 'br_mg_igarape_pedra_grande',
                nome: 'Pedra Grande de Igarapé',
                cidade: 'Igarapé',
                estado: 'MG',
              ),
              CatalogoCroqui(
                croquiUid: 'croqui_uid_2',
                idSlug: 'br_rj_rio_urca',
                nome: 'Morro da Urca',
                cidade: 'Rio de Janeiro',
                estado: 'RJ',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'grupo_uid_1',
                tipo: 'grupo',
                croquiUid: 'croqui_uid_1',
                nome: 'Grupo Sherpa',
              ),
              CatalogoEntidade(
                uid: 'setor_uid_1',
                tipo: 'setor',
                croquiUid: 'croqui_uid_1',
                nome: 'Setor Principal',
                grupoUid: 'grupo_uid_1',
              ),
              CatalogoEntidade(
                uid: 'via_uid_1',
                tipo: 'escalada',
                croquiUid: 'croqui_uid_1',
                nome: 'Fissura da Direita',
                escaladaGrau: '6sup',
                escaladaTipo: 'tradicional',
                setorUid: 'setor_uid_1',
                grupoUid: 'grupo_uid_1',
              ),
              CatalogoEntidade(
                uid: 'via_uid_2',
                tipo: 'escalada',
                croquiUid: 'croqui_uid_2',
                nome: 'Italianos',
                escaladaGrau: '5sup',
                escaladaTipo: 'tradicional',
              ),
            ],
          ),
          deletes: DeletesSyncCatalogo(croquis: [], entidades: []),
        );

        await repositorio.aplicarDelta(deltaInicial);

        expect(notificacoes, equals(1));
        expect(
          await repositorio.obterVersaoCatalogo(),
          equals('1111222233334444'),
        );

        final croquis = await repositorio.listarCroquis();
        expect(croquis.length, equals(2));
        expect(croquis.first.nome, equals('Morro da Urca'));
        expect(croquis.last.nome, equals('Pedra Grande de Igarapé'));

        // Verifica resolução de id_slug tanto por croqui_uid quanto por uid de entidade
        expect(
          await repositorio.obterIdSlugPorUid('croqui_uid_1'),
          equals('br_mg_igarape_pedra_grande'),
        );
        expect(
          await repositorio.obterIdSlugPorUid('br_mg_igarape_pedra_grande'),
          equals('br_mg_igarape_pedra_grande'),
        );
        expect(
          await repositorio.obterIdSlugPorUid('via_uid_1'),
          equals('br_mg_igarape_pedra_grande'),
        );
        expect(
          await repositorio.obterIdSlugPorUid('inexistente'),
          isNull,
        );

        // Verifica resolução enriquecida via obterItemPorUid para escalada, setor, grupo e croqui
        final itemVia = await repositorio.obterItemPorUid('via_uid_1');
        expect(itemVia, isNotNull);
        expect(itemVia!.tipo, equals('escalada'));
        expect(itemVia.nome, equals('Fissura da Direita'));
        expect(itemVia.escaladaGrau, equals('6sup'));
        expect(itemVia.escaladaTipo, equals('tradicional'));
        expect(itemVia.setorNome, equals('Setor Principal'));
        expect(itemVia.grupoNome, equals('Grupo Sherpa'));
        expect(itemVia.picoNome, equals('Pedra Grande de Igarapé'));
        expect(itemVia.idSlug, equals('br_mg_igarape_pedra_grande'));
        expect(itemVia.cidade, equals('Igarapé'));
        expect(itemVia.estado, equals('MG'));

        final itemCroquiPorUid = await repositorio.obterItemPorUid('croqui_uid_1');
        expect(itemCroquiPorUid, isNotNull);
        expect(itemCroquiPorUid!.tipo, equals('pico'));
        expect(itemCroquiPorUid.uid, equals('croqui_uid_1'));
        expect(itemCroquiPorUid.croquiUid, equals('croqui_uid_1'));
        expect(itemCroquiPorUid.idSlug, equals('br_mg_igarape_pedra_grande'));
        expect(itemCroquiPorUid.nome, equals('Pedra Grande de Igarapé'));
        expect(itemCroquiPorUid.picoNome, equals('Pedra Grande de Igarapé'));
        expect(itemCroquiPorUid.cidade, equals('Igarapé'));
        expect(itemCroquiPorUid.estado, equals('MG'));

        final itemCroquiPorSlug = await repositorio.obterItemPorUid(
          'br_mg_igarape_pedra_grande',
        );
        expect(itemCroquiPorSlug, isNotNull);
        expect(itemCroquiPorSlug!.tipo, equals('pico'));
        expect(itemCroquiPorSlug.idSlug, equals('br_mg_igarape_pedra_grande'));

        expect(await repositorio.obterItemPorUid('inexistente'), isNull);

        // Verifica listagem detalhada com LEFT JOIN
        final entidades = await repositorio.listarEntidadesDetalhadas();
        expect(entidades.length, equals(4));
        final via1 = entidades.firstWhere((e) => e.uid == 'via_uid_1');
        expect(via1.nome, equals('Fissura da Direita'));
        expect(via1.escaladaGrau, equals('6sup'));
        expect(via1.escaladaTipo, equals('tradicional'));
        expect(via1.setorNome, equals('Setor Principal'));
        expect(via1.grupoNome, equals('Grupo Sherpa'));
        expect(via1.picoNome, equals('Pedra Grande de Igarapé'));
        expect(via1.cidade, equals('Igarapé'));
        expect(via1.estado, equals('MG'));
        expect(via1.idSlug, equals('br_mg_igarape_pedra_grande'));

        // 2. Segundo delta (atualizando via_uid_1 e removendo croqui_uid_2 e via_uid_2)
        const deltaIncremental = RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoAtual: '5555666677778888',
          upserts: UpsertsSyncCatalogo(
            croquis: [],
            entidades: [
              CatalogoEntidade(
                uid: 'via_uid_1',
                tipo: 'escalada',
                croquiUid: 'croqui_uid_1',
                nome: 'Fissura da Direita Renovada',
                escaladaGrau: '7a',
                escaladaTipo: 'esportiva',
                setorUid: 'setor_uid_1',
                grupoUid: 'grupo_uid_1',
              ),
            ],
          ),
          deletes: DeletesSyncCatalogo(
            croquis: ['croqui_uid_2'],
            entidades: ['via_uid_2'],
          ),
        );

        await repositorio.aplicarDelta(deltaIncremental);

        expect(notificacoes, equals(2));
        expect(
          await repositorio.obterVersaoCatalogo(),
          equals('5555666677778888'),
        );
        expect((await repositorio.listarCroquis()).length, equals(1));
        expect(await repositorio.obterIdSlugPorUid('via_uid_2'), isNull);

        final entidadesApos = await repositorio.listarEntidadesDetalhadas();
        final via1Atualizada =
            entidadesApos.firstWhere((e) => e.uid == 'via_uid_1');
        expect(via1Atualizada.nome, equals('Fissura da Direita Renovada'));
        expect(via1Atualizada.escaladaGrau, equals('7a'));
        expect(via1Atualizada.escaladaTipo, equals('esportiva'));
      },
    );

    test(
      'deve substituir banco completo atomicamente em full_download e ler nova versao',
      () async {
        // Cria um banco inicial na versão antiga
        await repositorio.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'versao_antiga_00',
          ),
        );
        expect(
          await repositorio.obterVersaoCatalogo(),
          equals('versao_antiga_00'),
        );

        // Prepara outro arquivo SQLite representando o catalogo.db baixado do R2
        final caminhoRemoto = '${dirTemp.path}/remoto_r2.db';
        final dbRemoto = await databaseFactoryFfi.openDatabase(caminhoRemoto);
        for (final ddl in comandosDdlCatalogo) {
          await dbRemoto.execute(ddl);
        }
        await dbRemoto.insert(
          'catalogo_meta',
          const LinhaCatalogoMeta(
            chave: 'versao_catalogo',
            valor: 'versao_r2_999999',
          ).toMap(),
        );
        await dbRemoto.insert(
          'catalogo_croquis',
          const LinhaCatalogoCroquis(
            croquiUid: 'c_r2',
            idSlug: 'br_sp_sao_bento_bau',
            nome: 'Pedra do Baú',
            cidade: 'São Bento do Sapucaí',
            estado: 'SP',
          ).toMap(),
        );
        await dbRemoto.close();

        // Cria arquivos residuais simulando estado WAL/SHM/Journal anterior
        File('$caminhoBanco-wal').writeAsStringSync('residuo-wal');
        File('$caminhoBanco-shm').writeAsStringSync('residuo-shm');
        File('$caminhoBanco-journal').writeAsStringSync('residuo-journal');

        final bytesRemoto = await File(caminhoRemoto).readAsBytes();
        await repositorio.substituirBancoCompleto(
          Uint8List.fromList(bytesRemoto),
        );

        expect(File('$caminhoBanco-wal').existsSync(), isFalse);
        expect(File('$caminhoBanco-shm').existsSync(), isFalse);
        expect(File('$caminhoBanco-journal').existsSync(), isFalse);

        expect(
          await repositorio.obterVersaoCatalogo(),
          equals('versao_r2_999999'),
        );
        expect(
          await repositorio.obterIdSlugPorUid('c_r2'),
          equals('br_sp_sao_bento_bau'),
        );
      },
    );

    test(
      'deve serializar operacoes concorrentes evitando race conditions entre substituicao, consultas e fechamento',
      () async {
        final caminhoRemoto = '${dirTemp.path}/remoto_concorrente.db';
        final dbRemoto = await databaseFactoryFfi.openDatabase(caminhoRemoto);
        for (final ddl in comandosDdlCatalogo) {
          await dbRemoto.execute(ddl);
        }
        await dbRemoto.insert(
          'catalogo_meta',
          const LinhaCatalogoMeta(
            chave: 'versao_catalogo',
            valor: 'versao_concorrente_1',
          ).toMap(),
        );
        await dbRemoto.insert(
          'catalogo_croquis',
          const LinhaCatalogoCroquis(
            croquiUid: 'c_conc',
            idSlug: 'br_mg_ferros_pico',
            nome: 'Pico dos Ferros',
            cidade: 'Ferros',
            estado: 'MG',
          ).toMap(),
        );
        await dbRemoto.insert(
          'catalogo_aresta',
          const LinhaCatalogoAresta(
            uid: 'e_conc',
            tipo: 'escalada',
            croquiUid: 'c_conc',
            nome: 'Via Concorrente',
          ).toMap(),
        );
        await dbRemoto.close();

        final bytesRemoto =
            Uint8List.fromList(await File(caminhoRemoto).readAsBytes());

        final repoConcorrente = RepositorioCatalogo(
          provedorCaminhoBanco: () async {
            await Future<void>.delayed(const Duration(milliseconds: 15));
            return caminhoBanco;
          },
          fabricaBanco: databaseFactoryFfi,
        );

        // Dispara substituição, leituras e fechamento em paralelo sem aguardar individualmente
        final futuroSubstituicao =
            repoConcorrente.substituirBancoCompleto(bytesRemoto);
        final futuroVersao = repoConcorrente.obterVersaoCatalogo();
        final futuroEntidades = repoConcorrente.listarEntidadesDetalhadas();
        final futuroSlug = repoConcorrente.obterIdSlugPorUid('e_conc');
        final futuroFechar = repoConcorrente.fechar();

        await Future.wait([
          futuroSubstituicao,
          futuroVersao,
          futuroEntidades,
          futuroSlug,
          futuroFechar,
        ]);

        expect(await futuroVersao, equals('versao_concorrente_1'));
        expect((await futuroEntidades).single.nome, equals('Via Concorrente'));
        expect(await futuroSlug, equals('br_mg_ferros_pico'));
      },
    );

    test(
      'deve usar caminho padrao via getApplicationDocumentsDirectory, criar diretorios pais ausentes e retornar vazio se catalogo_meta nao tiver versao',
      () async {
        databaseFactory = databaseFactoryFfi;
        final subPastaInexistente = '${dirTemp.path}/aninhado/profundo';
        final repoSub = RepositorioCatalogo(
          provedorCaminhoBanco: () async => '$subPastaInexistente/catalogo.db',
        );

        // Aplica delta sem versaoAtual para testar tabela catalogo_meta sem chave versao_catalogo
        await repoSub.aplicarDelta(
          const RespostaSyncCatalogo(acao: 'apply_delta'),
        );
        expect(await repoSub.obterVersaoCatalogo(), isEmpty);
        await repoSub.fechar();

        // Testa substituirBancoCompleto criando diretório pai inexistente
        final outraSubPasta = '${dirTemp.path}/outro_aninhado/sub';
        final repoSubst = RepositorioCatalogo(
          provedorCaminhoBanco: () async => '$outraSubPasta/catalogo.db',
        );
        final bytesAtuais =
            await File('$subPastaInexistente/catalogo.db').readAsBytes();
        await repoSubst.substituirBancoCompleto(
          Uint8List.fromList(bytesAtuais),
        );
        expect(File('$outraSubPasta/catalogo.db').existsSync(), isTrue);
        await repoSubst.fechar();

        PathProviderPlatform.instance = _PathProviderFake(dirTemp.path);
        final repoPadrao = RepositorioCatalogo();
        expect(await repoPadrao.obterVersaoCatalogo(), isEmpty);
        await repoPadrao.fechar();
      },
    );

    test(
      'deve migrar automaticamente coluna legada uf para estado e remover atualizado_em ao abrir catalogo.db antigo',
      () async {
        final caminhoLegado = '${dirTemp.path}/catalogo_legado_uf.db';
        final dbLegado = await databaseFactoryFfi.openDatabase(caminhoLegado);
        await dbLegado.execute('''
          CREATE TABLE catalogo_croquis (
            croqui_uid TEXT PRIMARY KEY,
            id_slug TEXT NOT NULL,
            nome TEXT NOT NULL,
            cidade TEXT,
            uf TEXT,
            atualizado_em INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await dbLegado.execute('''
          CREATE TABLE catalogo_aresta (
            uid TEXT PRIMARY KEY,
            tipo TEXT NOT NULL,
            croqui_uid TEXT NOT NULL,
            nome TEXT NOT NULL,
            escalada_grau TEXT,
            escalada_tipo TEXT,
            setor_uid TEXT,
            grupo_uid TEXT
          )
        ''');
        await dbLegado.insert('catalogo_croquis', {
          'croqui_uid': 'uid_c_legado',
          'id_slug': 'br_mg_igarape_pedra_grande',
          'nome': 'Pedra Grande',
          'cidade': 'Igarapé',
          'uf': 'MG',
          'atualizado_em': 100,
        });
        await dbLegado.insert('catalogo_aresta', {
          'uid': 'uid_via_legada',
          'tipo': 'escalada',
          'croqui_uid': 'uid_c_legado',
          'nome': 'Via Legada',
          'escalada_grau': '6sup',
          'escalada_tipo': 'esportiva',
        });
        await dbLegado.close();

        final repoMigrado = RepositorioCatalogo(
          provedorCaminhoBanco: () async => caminhoLegado,
          fabricaBanco: databaseFactoryFfi,
        );

        final croquis = await repoMigrado.listarCroquis();
        expect(croquis, hasLength(1));
        expect(croquis.single.estado, equals('MG'));

        final entidades = await repoMigrado.listarEntidadesDetalhadas();
        expect(entidades, hasLength(1));
        expect(entidades.single.nome, equals('Via Legada'));
        expect(entidades.single.estado, equals('MG'));

        await repoMigrado.fechar();

        final dbInspecao = await databaseFactoryFfi.openDatabase(caminhoLegado);
        final colunas =
            await dbInspecao.rawQuery('PRAGMA table_info(catalogo_croquis)');
        final nomesColunas = colunas.map((c) => c['name'] as String?).toSet();
        expect(nomesColunas.contains('atualizado_em'), isFalse);
        await dbInspecao.close();
      },
    );

    test(
      'deve persistir malha rodoviaria em aplicarDelta, carregar CalculadoraDistanciaEstrada por croqui_uid e id_slug, e limpar em cascata nos deletes',
      () async {
        // 1. Banco existe mas ainda sem nós rodoviários -> possuiMalha == false
        await repositorio.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v_sem_malha',
          ),
        );
        final calcInicial = await repositorio.carregarMalhaEstrada();
        expect(calcInicial.possuiMalha, isFalse);

        // 2. Insere 2 croquis, 2 nós rodoviários (1 próximo do usuário e 1 portal de borda) e distâncias
        await repositorio.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v_com_malha_1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'uid_cipo',
                  idSlug: 'br_mg_santana_serra_cipo',
                  nome: 'Serra do Cipó',
                  cidade: 'Santana do Riacho',
                  estado: 'MG',
                ),
                CatalogoCroqui(
                  croquiUid: 'uid_lapinha',
                  idSlug: 'br_mg_santana_lapinha',
                  nome: 'Lapinha da Serra',
                  cidade: 'Santana do Riacho',
                  estado: 'MG',
                ),
              ],
              entidades: [],
              nosEstrada: [
                CatalogoNoEstrada(
                  noOsmId: 1001,
                  latitudeE7: -200010000, // -20.0010
                  longitudeE7: -440010000, // -44.0010
                ),
                CatalogoNoEstrada(
                  noOsmId: 2002,
                  latitudeE7: -215000000, // -21.5000 (portal de borda)
                  longitudeE7: -445000000, // -44.5000
                ),
              ],
              distanciasEstrada: [
                CatalogoDistanciaEstrada(
                  croquiUid: 'uid_cipo',
                  noOsmId: 1001,
                  distanciaMetros: 95000,
                  naBorda: 0,
                ),
                CatalogoDistanciaEstrada(
                  croquiUid: 'uid_cipo',
                  noOsmId: 2002,
                  distanciaMetros: 175000,
                  naBorda: 1,
                ),
                CatalogoDistanciaEstrada(
                  croquiUid: 'uid_lapinha',
                  noOsmId: 1001,
                  distanciaMetros: 132000,
                ),
              ],
            ),
            deletes: DeletesSyncCatalogo(croquis: [], entidades: []),
          ),
        );

        final calculadora = await repositorio.carregarMalhaEstrada();
        expect(calculadora.possuiMalha, isTrue);

        // Deve resolver distância tanto pelo croqui_uid quanto pelo id_slug
        final distPorUid = calculadora.calcularDistanciaMetros(
          latitudeUsuario: -20.0000,
          longitudeUsuario: -44.0000,
          identificadorCroqui: 'uid_cipo',
          latitudePico: -19.3500,
          longitudePico: -43.6000,
        );
        final distPorSlug = calculadora.calcularDistanciaMetros(
          latitudeUsuario: -20.0000,
          longitudeUsuario: -44.0000,
          identificadorCroqui: 'br_mg_santana_serra_cipo',
          latitudePico: -19.3500,
          longitudePico: -43.6000,
        );
        expect(distPorUid, closeTo(distPorSlug, 0.001));
        expect(distPorSlug, greaterThan(95000));
        expect(distPorSlug, lessThan(96000));

        // Usuário longe (> 180 km, sem nós num raio de 15 km) utiliza o portal de borda 2002
        final distViaPortal = calculadora.calcularDistanciaMetros(
          latitudeUsuario: -22.0000,
          longitudeUsuario: -44.5000,
          identificadorCroqui: 'br_mg_santana_serra_cipo',
          latitudePico: -19.3500,
          longitudePico: -43.6000,
        );
        expect(distViaPortal, greaterThan(175000));

        // 3. Remove uid_lapinha e o nó 2002 via deletes
        await repositorio.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoAtual: 'v_com_malha_2',
            deletes: DeletesSyncCatalogo(
              croquis: ['uid_lapinha'],
              entidades: [],
              nosEstrada: [2002],
            ),
          ),
        );

        final calcAposDelete = await repositorio.carregarMalhaEstrada();
        final nosProximos = calcAposDelete.buscarNosProximos(
          latitudeUsuario: -20.0000,
          longitudeUsuario: -44.0000,
        );
        expect(nosProximos.single.noOsmId, equals(1001));
        expect(
          nosProximos.single.distanciasPorCroquiMetros
              .containsKey('uid_lapinha'),
          isFalse,
        );
      },
    );
  });
}
