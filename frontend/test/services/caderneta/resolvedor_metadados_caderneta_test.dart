// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/caderneta/resolvedor_metadados_caderneta.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _PathProviderTemporarioFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderTemporarioFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;

  @override
  Future<String?> getTemporaryPath() async => '$caminho/temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dirTemp;
  late RepositorioCadernetaLocal repoCaderneta;
  late RepositorioCatalogo repoCatalogo;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp(
      'resolvedor_metadados_caderneta_test_',
    );
    PathProviderPlatform.instance = _PathProviderTemporarioFake(dirTemp.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();

    repoCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repoCatalogo.fechar();
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('ResolvedorMetadadosCaderneta', () {
    test('retorna zero picos distintos e metadados nulos quando a caderneta está vazia', () async {
      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      expect(resolvedor.obterTotalPicosDistintos(), equals(0));
      expect(resolvedor.obterNomeDaVia('uidInexistente'), isNull);
      expect(resolvedor.obterGrauDaVia('uidInexistente'), isNull);

      resolvedor.dispose();
    });

    test('hidrata nomes, graus normalizados e picos distintos a partir do catalogo.db SQLite real', () async {
      await repoCatalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v1',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'croquiPedraR14',
                idSlug: 'br_mg_sabara_pedra_rachada',
                nome: 'Pedra Rachada',
              ),
              CatalogoCroqui(
                croquiUid: 'croquiSerraC14',
                idSlug: 'br_mg_serra_do_cipo',
                nome: 'Serra do Cipó',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'viaPedra1NanoX',
                tipo: 'escalada',
                croquiUid: 'croquiPedraR14',
                nome: 'Via Deslize',
                escaladaGrau: '6sup',
                escaladaTipo: 'esportiva',
              ),
              CatalogoEntidade(
                uid: 'blocoPedra2Nan',
                tipo: 'escalada',
                croquiUid: 'croquiPedraR14',
                nome: 'Bloco da Gruta',
                escaladaGrau: 'v4',
                escaladaTipo: 'boulder',
              ),
              CatalogoEntidade(
                uid: 'viaCipo1NanoXY',
                tipo: 'escalada',
                croquiUid: 'croquiSerraC14',
                nome: 'Fenda do Cipó',
                escaladaGrau: '7b',
                escaladaTipo: 'tradicional',
              ),
              CatalogoEntidade(
                uid: 'highlineCipo1X',
                tipo: 'escalada',
                croquiUid: 'croquiSerraC14',
                nome: 'Fita Aérea',
                escaladaGrau: '45m',
                escaladaTipo: 'highline',
              ),
            ],
          ),
        ),
      );

      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaPedra1NanoX',
          dataAscensao: DateTime(2026, 10, 1),
          tipoAscensao: TipoAscensao.aVista,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'blocoPedra2Nan',
          dataAscensao: DateTime(2026, 10, 2),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.boulder,
        ),
      );

      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      // Duas escaladas no mesmo croqui contam como 1 pico distinto
      expect(resolvedor.obterTotalPicosDistintos(), equals(1));
      expect(resolvedor.obterNomeDaVia('viaPedra1NanoX'), equals('Via Deslize'));
      // Normaliza '6sup' do catálogo para '6ºsup' compatível com a pirâmide de graus
      expect(resolvedor.obterGrauDaVia('viaPedra1NanoX'), equals('6ºsup'));
      expect(resolvedor.obterNomeDaVia('blocoPedra2Nan'), equals('Bloco da Gruta'));
      expect(resolvedor.obterGrauDaVia('blocoPedra2Nan'), equals('V4'));

      // Ao salvar cadena em um segundo pico e em highline, reage automaticamente
      var notificou = false;
      resolvedor.addListener(() => notificou = true);

      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaCipo1NanoXY',
          dataAscensao: DateTime(2026, 10, 3),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'highlineCipo1X',
          dataAscensao: DateTime(2026, 10, 4),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await resolvedor.atualizar();

      expect(notificou, isTrue);
      expect(resolvedor.obterTotalPicosDistintos(), equals(2));
      expect(resolvedor.obterNomeDaVia('viaCipo1NanoXY'), equals('Fenda do Cipó'));
      expect(resolvedor.obterGrauDaVia('viaCipo1NanoXY'), equals('7b'));
      // Highline não possui grau esportivo de escalada para a pirâmide
      expect(resolvedor.obterNomeDaVia('highlineCipo1X'), equals('Fita Aérea'));
      expect(resolvedor.obterGrauDaVia('highlineCipo1X'), isNull);

      resolvedor.dispose();
    });

    test('recarrega metadados reativamente quando o catalogo.db recebe um delta sync', () async {
      await repoCatalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v1',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'croquiDelta001',
                idSlug: 'br_rj_urca',
                nome: 'Morro da Urca',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'viaMutavel0001',
                tipo: 'escalada',
                croquiUid: 'croquiDelta001',
                nome: 'Nome Antigo',
                escaladaGrau: '5',
                escaladaTipo: 'tradicional',
              ),
            ],
          ),
        ),
      );

      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaMutavel0001',
          dataAscensao: DateTime(2026, 10, 5),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );

      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      expect(resolvedor.obterNomeDaVia('viaMutavel0001'), equals('Nome Antigo'));
      expect(resolvedor.obterGrauDaVia('viaMutavel0001'), equals('5º'));

      await repoCatalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v2',
          upserts: UpsertsSyncCatalogo(
            croquis: [],
            entidades: [
              CatalogoEntidade(
                uid: 'viaMutavel0001',
                tipo: 'escalada',
                croquiUid: 'croquiDelta001',
                nome: 'Via K2',
                escaladaGrau: '5sup/6a',
                escaladaTipo: 'tradicional',
              ),
            ],
          ),
        ),
      );
      await resolvedor.atualizar();

      expect(resolvedor.obterNomeDaVia('viaMutavel0001'), equals('Via K2'));
      expect(resolvedor.obterGrauDaVia('viaMutavel0001'), equals('5ºsup/6a'));

      resolvedor.dispose();
    });

    test('utiliza croquis carregados no DatasetRepository como fallback síncrono imediato e contabiliza mínimo de 1 pico para UID desconhecido', () async {
      final datasetRepo = DatasetRepository(
        editorDeCroqui: EditorDeCroqui(),
        repositorioCatalogo: repoCatalogo,
      );

      final viaDireta = Escalada(
        uid: 'viaOffline0001',
        viaEsportiva: ViaEsportiva(
          nome: 'Via da Sessão Offline',
          dificuldade: GrauVia_GrauVia.BR_7C,
        ),
      );
      final blocoEmGrupo = Escalada(
        uid: 'blocoOnline001',
        boulder: Boulder(
          nome: 'Boulder do Grupo Online',
          dificuldade: GrauBoulder_GrauBoulder.VB_BARRA_V0,
        ),
      );

      final croquiBaixado = Croqui(
        id: 'br_sp_sao_bento',
        uid: 'croquiBaixado1',
        nome: 'Pedra do Baú',
        picos: [
          Pico(
            nome: 'Baú',
            setoresOuGrupos: [
              SetorOuGrupo(
                setor: ArquivoSetor(
                  conteudo: Setor(
                    uid: 'setorBaixado01',
                    nome: 'Face Sul',
                    escaladas: [viaDireta],
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final croquiOnline = Croqui(
        id: 'br_mg_ouro_preto',
        nome: 'Ouro Preto',
        picos: [
          Pico(
            nome: 'Ouro Preto',
            setoresOuGrupos: [
              SetorOuGrupo(
                grupo: ArquivoGrupo(
                  conteudo: Grupo(
                    uid: 'grupoOnline001',
                    nome: 'Grupo Central',
                    setores: [
                      ArquivoSetor(
                        conteudo: Setor(
                          uid: 'setorOnline001',
                          nome: 'Setor Blocos',
                          escaladas: [blocoEmGrupo],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      datasetRepo.activeDataset.value = ConjuntoDadosCroqui(
        picosBaixados: [
          ResumoPico(
            id: 'br_sp_sao_bento',
            nome: 'Pedra do Baú',
            local: 'SP',
            isDownloaded: true,
            croqui: croquiBaixado,
          ),
        ],
        picosDisponiveis: const [],
        croquisBaixados: [croquiBaixado],
      );
      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_ouro_preto',
        croquiOnline,
      );

      // 1) Primeiro testa UID totalmente desconhecido: garante mínimo seguro de 1 pico quando há cadena
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'uidSemCatalogo',
          dataAscensao: DateTime(2026, 10, 1),
          tipoAscensao: TipoAscensao.tentativa,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );

      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        datasetRepo: datasetRepo,
      );
      await resolvedor.atualizar();
      expect(resolvedor.obterTotalPicosDistintos(), equals(1));

      // 2) Agora adiciona cadenas das escaladas presentes nos croquis em memória (sem estarem no catalogo.db)
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaOffline0001',
          dataAscensao: DateTime(2026, 10, 2),
          tipoAscensao: TipoAscensao.aVista,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'blocoOnline001',
          dataAscensao: DateTime(2026, 10, 3),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.boulder,
        ),
      );

      expect(
        resolvedor.obterNomeDaVia('viaOffline0001'),
        equals('Via da Sessão Offline'),
      );
      expect(resolvedor.obterGrauDaVia('viaOffline0001'), equals('7c'));
      expect(
        resolvedor.obterNomeDaVia('blocoOnline001'),
        equals('Boulder do Grupo Online'),
      );
      expect(resolvedor.obterGrauDaVia('blocoOnline001'), equals('VB/V0'));
      expect(resolvedor.obterTotalPicosDistintos(), equals(2));

      resolvedor.dispose();
    });
  });
}
