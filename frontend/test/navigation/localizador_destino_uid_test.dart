// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/localizador_destino_uid.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String caminhoBase;
  _FakePathProvider(this.caminhoBase);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoBase;

  @override
  Future<String?> getTemporaryPath() async => '$caminhoBase/temp';
}

void main() {
  sqfliteFfiInit();

  late Directory dirTemp;
  late EditorDeCroqui editorDeCroqui;
  late RepositorioCatalogo repositorioCatalogo;
  late DatasetRepository datasetRepo;
  late LocalizadorDestinoUid localizador;

  late Pico picoTeste;
  late Croqui croquiTeste;
  late Setor setorDireto;
  late Grupo grupoTeste;
  late Setor setorNoGrupo;
  late Escalada viaNoSetorDireto;
  late Escalada viaNoSetorDoGrupo;
  late Botao botaoTeste;

  const String uidCroqui = 'pQ9mRt2Kx1Vw8L';
  const String uidGrupo = 'g8Rk2L1x9Y7zWq';
  const String uidSetorDireto = 's1Lk9P1x4Vw8Mn';
  const String uidSetorNoGrupo = 's2Lk9P1x4Vw8Mn';
  const String uidViaSetorDireto = 'v1siJek3FiG3aB';
  const String uidViaSetorDoGrupo = 'v2siJek3FiG3aB';
  const String uidBotao = 'b1siJek3FiG3aB';
  const String uidInexistente = 'z9zzZzZzZzZzZz';

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp('localizador_uid_test_');
    PathProviderPlatform.instance = _FakePathProvider(dirTemp.path);

    editorDeCroqui = EditorDeCroqui();
    repositorioCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
    datasetRepo = DatasetRepository(
      editorDeCroqui: editorDeCroqui,
      repositorioCatalogo: repositorioCatalogo,
    );
    localizador = LocalizadorDestinoUid(datasetRepo: datasetRepo);

    // 1. Constrói estrutura hierárquica completa com UIDs NanoID 14c
    croquiTeste = Croqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..uid = uidCroqui;

    picoTeste = Pico()..nome = 'Pedra Grande de Igarapé';

    // Via em setor direto
    viaNoSetorDireto = Escalada()
      ..uid = uidViaSetorDireto
      ..viaEsportiva = (ViaEsportiva()..nome = 'Teto da Savassinha');

    setorDireto = Setor()
      ..nome = 'Savassinha'
      ..uid = uidSetorDireto;
    setorDireto.escaladas.add(viaNoSetorDireto);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorDireto),
    );

    // Via em setor dentro de grupo
    viaNoSetorDoGrupo = Escalada()
      ..uid = uidViaSetorDoGrupo
      ..boulder = (Boulder()..nome = 'Bloco do Totem');

    setorNoGrupo = Setor()
      ..nome = 'Setor do Bloco'
      ..uid = uidSetorNoGrupo;
    setorNoGrupo.escaladas.add(viaNoSetorDoGrupo);

    grupoTeste = Grupo()
      ..nome = 'Grupo Estacionamento'
      ..uid = uidGrupo;
    grupoTeste.setores.add(ArquivoSetor()..conteudo = setorNoGrupo);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupoTeste),
    );

    botaoTeste = Botao()
      ..uid = uidBotao
      ..texto = 'Ver Mapa Geral';
    croquiTeste.botoes.add(botaoTeste);

    croquiTeste.picos.add(picoTeste);

    // 2. Configura dataset com metadados do índice e picos baixados
    final resumoIndice = ResumoCroqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..croquiUid = uidCroqui
      ..nome = 'Pedra Grande de Igarapé';

    datasetRepo.activeDataset.value = TopoDataset(
      picosBaixados: [
        {
          'id': 'br_mg_igarape_pedra_grande',
          'data': {'pico': picoTeste, 'croqui': croquiTeste},
        },
      ],
      picosDisponiveis: [resumoIndice.paraResumoPico()],
      metadadosDisponiveis: [resumoIndice],
    );
  });

  tearDown(() async {
    await repositorioCatalogo.fechar();
    if (dirTemp.existsSync()) {
      await dirTemp.delete(recursive: true);
    }
  });

  group('LocalizadorDestinoUid', () {
    test('localiza Croqui a partir de croquiUid do índice de metadados', () async {
      final destino = await localizador.localizar(uidCroqui);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('pico'));
      expect(destino.noNavegacao, isA<PicoNode>());
      expect(
        destino.toString(),
        contains('DestinoUidLocalizado(idCroqui: br_mg_igarape_pedra_grande'),
      );
      final picoNode = destino.noNavegacao as PicoNode;
      expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
    });

    test('localiza Croqui diretamente por croqui.uid nos picos baixados quando não está em metadadosDisponiveis', () async {
      datasetRepo.activeDataset.value = TopoDataset(
        picosBaixados: [
          {
            'id': 'br_mg_igarape_pedra_grande',
            'data': {'pico': picoTeste, 'croqui': croquiTeste},
          },
        ],
        picosDisponiveis: [],
        metadadosDisponiveis: [],
      );

      final destino = await localizador.localizar(uidCroqui);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('pico'));
      expect(destino.noNavegacao, isA<PicoNode>());
    });

    test('localiza Via em setor direto com linhagem correta da árvore', () async {
      final destino = await localizador.localizar(uidViaSetorDireto);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Teto da Savassinha'));
      expect(destino.noNavegacao, isA<ViaNode>());

      final viaNode = destino.noNavegacao as ViaNode;
      expect(viaNode.escaladaNome, equals('Teto da Savassinha'));
      expect(viaNode.setorNome, equals('Savassinha'));
      expect(viaNode.grupoNome, isNull);
      expect(viaNode.parent, isA<SetorNode>());

      final setorNode = viaNode.parent as SetorNode;
      expect(setorNode.setorNome, equals('Savassinha'));
      expect(setorNode.parent, isA<PicoNode>());
    });

    test('localiza Via dentro de setor pertencente a um Grupo', () async {
      final destino = await localizador.localizar(uidViaSetorDoGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Bloco do Totem'));
      expect(destino.noNavegacao, isA<ViaNode>());

      final viaNode = destino.noNavegacao as ViaNode;
      expect(viaNode.escaladaNome, equals('Bloco do Totem'));
      expect(viaNode.setorNome, equals('Setor do Bloco'));
      expect(viaNode.grupoNome, equals('Grupo Estacionamento'));
      expect(viaNode.parent, isA<SetorNode>());

      final setorNode = viaNode.parent as SetorNode;
      expect(setorNode.parent, isA<GrupoNode>());

      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
    });

    test('localiza Setor direto com linhagem até PicoNode', () async {
      final destino = await localizador.localizar(uidSetorDireto);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('setor'));
      expect(destino.nomeEntidade, equals('Savassinha'));
      expect(destino.noNavegacao, isA<SetorNode>());

      final setorNode = destino.noNavegacao as SetorNode;
      expect(setorNode.setorNome, equals('Savassinha'));
      expect(setorNode.parent, isA<PicoNode>());
    });

    test('localiza Setor dentro de Grupo com GrupoNode como pai', () async {
      final destino = await localizador.localizar(uidSetorNoGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('setor'));
      expect(destino.nomeEntidade, equals('Setor do Bloco'));
      expect(destino.noNavegacao, isA<SetorNode>());

      final setorNode = destino.noNavegacao as SetorNode;
      expect(setorNode.parent, isA<GrupoNode>());
      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
    });

    test('localiza Grupo diretamente com PicoNode como pai', () async {
      final destino = await localizador.localizar(uidGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('grupo'));
      expect(destino.nomeEntidade, equals('Grupo Estacionamento'));
      expect(destino.noNavegacao, isA<GrupoNode>());

      final grupoNode = destino.noNavegacao as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
    });

    test('localiza Botão interativo retornando PicoNode', () async {
      final destino = await localizador.localizar(uidBotao);

      expect(destino, isNotNull);
      expect(destino!.tipoDestino, equals('pico'));
      expect(destino.nomeEntidade, equals('Ver Mapa Geral'));
      expect(destino.noNavegacao, isA<PicoNode>());
    });

    test('localiza entidade presente na sessão online em memória', () async {
      const String uidViaRemota = 'vOnline1234567';
      final croquiOnline = Croqui()
        ..id = 'br_mg_cipo'
        ..uid = 'cOnline1234567';
      final picoOnline = Pico()..nome = 'Serra do Cipó';
      final setorOnline = Setor()..nome = 'Vale da Lapinha';
      final viaOnline = Escalada()
        ..uid = uidViaRemota
        ..viaEsportiva = (ViaEsportiva()..nome = 'Gafanhoto');
      setorOnline.escaladas.add(viaOnline);
      picoOnline.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorOnline),
      );
      croquiOnline.picos.add(picoOnline);

      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_cipo',
        croquiOnline,
      );

      final destino = await localizador.localizar(uidViaRemota);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_cipo'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Gafanhoto'));
      expect(destino.noNavegacao, isA<ViaNode>());
    });

    test('consulta RepositorioCatalogo e carrega croqui online sob demanda quando não está em memória', () async {
      const String uidViaCatalogo = 'vCatRemoto1234';
      const String uidCroquiCatalogo = 'cCatRemoto1234';
      const String idSlugRemoto = 'br_rj_urca';

      final croquiRemoto = Croqui()
        ..id = idSlugRemoto
        ..uid = uidCroquiCatalogo;
      final picoRemoto = Pico()..nome = 'Morro da Urca';
      final setorRemoto = Setor()
        ..uid = 'sCatRemoto1234'
        ..nome = 'Face Norte';
      final viaRemota = Escalada()
        ..uid = uidViaCatalogo
        ..viaEsportiva = (ViaEsportiva()..nome = 'Italianos');
      setorRemoto.escaladas.add(viaRemota);
      picoRemoto.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorRemoto),
      );
      croquiRemoto.picos.add(picoRemoto);

      // Popula o catalogo.db com o croqui e a via
      await repositorioCatalogo.aplicarDelta(
        RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoAtual: 'v1',
          versaoDestino: 'v1',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: uidCroquiCatalogo,
                idSlug: idSlugRemoto,
                nome: 'Morro da Urca',
                cidade: 'Rio de Janeiro',
                estado: 'RJ',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: uidViaCatalogo,
                tipo: 'escalada',
                croquiUid: uidCroquiCatalogo,
                nome: 'Italianos',
                setorUid: 'sCatRemoto1234',
              ),
            ],
          ),
        ),
      );

      // Inicia micro-servidor HTTP local para servir o compilado.binarypb do croqui remoto
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.add(croquiRemoto.writeToBuffer());
        request.response.close();
      });

      editorDeCroqui.isExperimentalMode.value = true;
      editorDeCroqui.editorUrl.value =
          'http://127.0.0.1:${server.port}/indice.binarypb';

      final resumoRemoto = ResumoCroqui()
        ..id = idSlugRemoto
        ..croquiUid = uidCroquiCatalogo
        ..nome = 'Morro da Urca'
        ..caminhoRelativo = '$idSlugRemoto/compilado.binarypb'
        ..checksumSha256Croqui = 'hash123';

      datasetRepo.indiceData.value = Indice()..croquis.add(resumoRemoto);

      final destino = await localizador.localizar(uidViaCatalogo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals(idSlugRemoto));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Italianos'));
      expect(destino.noNavegacao, isA<ViaNode>());
    });

    test('constrói MapasCarrosselNode com parent quando abrirMapa: true em Pico, Grupo, Setor e Via com mapas', () async {
      // Adiciona mapas válidos ao Pico, Grupo, Setor e Via
      final mapaGeral = Mapa()
        ..caminhoImagemMapa = 'mapas/geral.webp'
        ..larguraMapa = 1000
        ..alturaMapa = 800;
      picoTeste.mapasGerais = ArquivoMapas()
        ..conteudo = (ColecaoDeMapas()..mapas.add(mapaGeral));

      final mapaGrupo = Mapa()
        ..caminhoImagemMapa = 'mapas/grupo.webp'
        ..larguraMapa = 1200
        ..alturaMapa = 900;
      grupoTeste.mapas.add(mapaGrupo);

      final mapaSetor = Mapa()
        ..caminhoImagemMapa = 'mapas/savassinha.webp'
        ..larguraMapa = 1600
        ..alturaMapa = 1200
        ..referencias.add(
          Mapa_Referencia()
            ..alvoUid = uidViaSetorDireto
            ..pontosUids.add('pt_via_1'),
        );
      setorDireto.mapas.add(mapaSetor);

      // 1. Pico com abrirMapa: true
      final destinoPico = await localizador.localizar(
        uidCroqui,
        abrirMapa: true,
      );
      expect(destinoPico, isNotNull);
      expect(destinoPico!.noNavegacao, isA<MapasCarrosselNode>());
      final carrosselPico = destinoPico.noNavegacao as MapasCarrosselNode;
      expect(carrosselPico.parent, isA<PicoNode>());
      expect(carrosselPico.mapas.first.mapaCaminhoImagem, equals('mapas/geral.webp'));

      // 2. Grupo com abrirMapa: true
      final destinoGrupo = await localizador.localizar(
        uidGrupo,
        abrirMapa: true,
      );
      expect(destinoGrupo, isNotNull);
      expect(destinoGrupo!.noNavegacao, isA<MapasCarrosselNode>());
      final carrosselGrupo = destinoGrupo.noNavegacao as MapasCarrosselNode;
      expect(carrosselGrupo.parent, isA<GrupoNode>());
      expect(carrosselGrupo.mapas.first.mapaCaminhoImagem, equals('mapas/grupo.webp'));

      // 3. Setor com abrirMapa: true
      final destinoSetor = await localizador.localizar(
        uidSetorDireto,
        abrirMapa: true,
      );
      expect(destinoSetor, isNotNull);
      expect(destinoSetor!.noNavegacao, isA<MapasCarrosselNode>());
      final carrosselSetor = destinoSetor.noNavegacao as MapasCarrosselNode;
      expect(carrosselSetor.parent, isA<SetorNode>());
      expect(carrosselSetor.mapas.first.mapaCaminhoImagem, equals('mapas/savassinha.webp'));

      // 4. Via com abrirMapa: true (focado no ponto da referência)
      final destinoVia = await localizador.localizar(
        uidViaSetorDireto,
        abrirMapa: true,
      );
      expect(destinoVia, isNotNull);
      expect(destinoVia!.noNavegacao, isA<MapasCarrosselNode>());
      final carrosselVia = destinoVia.noNavegacao as MapasCarrosselNode;
      expect(carrosselVia.parent, isA<ViaNode>());
      expect(carrosselVia.mapas.first.initialSelectedId, equals('pt_via_1'));
    });

    test('faz fallback gracioso para o nó principal quando abrirMapa: true mas a entidade não possui mapas', () async {
      final destinoPico = await localizador.localizar(uidCroqui, abrirMapa: true);
      expect(destinoPico!.noNavegacao, isA<PicoNode>());

      final destinoGrupo = await localizador.localizar(uidGrupo, abrirMapa: true);
      expect(destinoGrupo!.noNavegacao, isA<GrupoNode>());

      final destinoSetor = await localizador.localizar(uidSetorDireto, abrirMapa: true);
      expect(destinoSetor!.noNavegacao, isA<SetorNode>());

      final destinoVia = await localizador.localizar(uidViaSetorDireto, abrirMapa: true);
      expect(destinoVia!.noNavegacao, isA<ViaNode>());
    });

    test('carrega croqui sob demanda na sessao online quando o UID pertence a um croqui de metadadosDisponiveis ainda nao baixado', () async {
      const String uidCroquiNaoBaixado = '4onIN9Ga05O9Kr';
      const String idSlugNaoBaixado =
          'br_mg_sabara_pedra_rachada_setor_horizonte';

      final croquiRemoto = Croqui()
        ..id = idSlugNaoBaixado
        ..uid = uidCroquiNaoBaixado
        ..picos.add(Pico()..nome = 'Pedra Rachada - Setor Horizonte');

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.add(croquiRemoto.writeToBuffer());
        request.response.close();
      });

      editorDeCroqui.isExperimentalMode.value = true;
      editorDeCroqui.editorUrl.value =
          'http://127.0.0.1:${server.port}/indice.binarypb';

      final resumoNaoBaixado = ResumoCroqui()
        ..id = idSlugNaoBaixado
        ..croquiUid = uidCroquiNaoBaixado
        ..nome = 'Pedra Rachada - Setor Horizonte'
        ..caminhoRelativo = '$idSlugNaoBaixado/compilado.binarypb'
        ..checksumSha256Croqui = 'hash_pedra_rachada';

      datasetRepo.indiceData.value = Indice()..croquis.add(resumoNaoBaixado);
      datasetRepo.activeDataset.value = TopoDataset(
        picosBaixados: [],
        picosDisponiveis: [resumoNaoBaixado.paraResumoPico()],
        metadadosDisponiveis: [resumoNaoBaixado],
      );

      final destino = await localizador.localizar(uidCroquiNaoBaixado);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals(idSlugNaoBaixado));
      expect(destino.tipoDestino, equals('pico'));
      expect(destino.noNavegacao, isA<PicoNode>());
      expect(
        datasetRepo.gerenciadorSessaoOnline.obterCroquiOnline(idSlugNaoBaixado),
        isNotNull,
      );
    });

    test('retorna null para UID inexistente no acervo', () async {
      final destino = await localizador.localizar(uidInexistente);
      expect(destino, isNull);
    });

    test(
      'isola resolução de UID entre <docs>/catalogo.db oficial e <docs>/editor/experimental/catalogo.db no Modo Experimental',
      () async {
        final repoDinamico = RepositorioCatalogo(
          provedorCaminhoBanco: () async =>
              editorDeCroqui.catalogoPath(dirTemp.path),
          fabricaBanco: databaseFactoryFfi,
        );
        final datasetDinamico = DatasetRepository(
          editorDeCroqui: editorDeCroqui,
          repositorioCatalogo: repoDinamico,
        );
        final localizadorDinamico = LocalizadorDestinoUid(
          datasetRepo: datasetDinamico,
        );

        // 1. Popula o catalogo.db oficial
        await repoDinamico.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_oficial',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'cUidOficialOnly',
                  idSlug: 'pico_oficial_only',
                  nome: 'Pico Oficial',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'vUidOficialOnly',
                  tipo: 'escalada',
                  croquiUid: 'cUidOficialOnly',
                  nome: 'Via Oficial',
                ),
              ],
            ),
          ),
        );

        // 2. Entra no modo experimental e popula <docs>/editor/experimental/catalogo.db
        final croquiExp = Croqui()
          ..id = 'pico_exp_only'
          ..uid = 'cUidExpOnly1234'
          ..picos.add(
            Pico()
              ..nome = 'Pico Experimental'
              ..setoresOuGrupos.add(
                SetorOuGrupo()
                  ..setor = (ArquivoSetor()
                    ..conteudo = (Setor()
                      ..uid = 'sUidExpOnly1234'
                      ..nome = 'Setor Experimental'
                      ..escaladas.add(
                        Escalada()
                          ..uid = 'vUidExpOnly1234'
                          ..viaEsportiva = (ViaEsportiva()
                            ..nome = 'Via Experimental'),
                      ))),
              ),
          );

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((request) {
          request.response.statusCode = 200;
          request.response.add(croquiExp.writeToBuffer());
          request.response.close();
        });

        editorDeCroqui.isExperimentalMode.value = true;
        editorDeCroqui.editorUrl.value =
            'http://127.0.0.1:${server.port}/indice.binarypb';

        await repoDinamico.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_exp',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'cUidExpOnly1234',
                  idSlug: 'pico_exp_only',
                  nome: 'Pico Experimental',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'vUidExpOnly1234',
                  tipo: 'escalada',
                  croquiUid: 'cUidExpOnly1234',
                  nome: 'Via Experimental',
                  setorUid: 'sUidExpOnly1234',
                ),
              ],
            ),
          ),
        );

        final resumoExp = ResumoCroqui()
          ..id = 'pico_exp_only'
          ..croquiUid = 'cUidExpOnly1234'
          ..nome = 'Pico Experimental'
          ..caminhoRelativo = 'pico_exp_only/compilado.binarypb';
        datasetDinamico.indiceData.value = Indice()..croquis.add(resumoExp);

        // No Modo Experimental: resolve UID experimental e ignora UID exclusivo do catálogo oficial
        expect(
          File('${dirTemp.path}/editor/experimental/catalogo.db').existsSync(),
          isTrue,
        );
        final destinoExp = await localizadorDinamico.localizar(
          'vUidExpOnly1234',
        );
        expect(destinoExp, isNotNull);
        expect(destinoExp!.idCroqui, equals('pico_exp_only'));
        expect(destinoExp.nomeEntidade, equals('Via Experimental'));

        final destinoOficialEmExp = await localizadorDinamico.localizar(
          'vUidOficialOnly',
        );
        expect(destinoOficialEmExp, isNull);

        // Ao executar nukeExperimentalData(), fecha e remove o catalogo.db experimental e restaura o oficial
        await editorDeCroqui.nukeExperimentalData();
        expect(
          File('${dirTemp.path}/editor/experimental/catalogo.db').existsSync(),
          isFalse,
        );
        expect(
          await repoDinamico.obterIdSlugPorUid('vUidOficialOnly'),
          equals('pico_oficial_only'),
        );
        await repoDinamico.fechar();
      },
    );
  });
}

