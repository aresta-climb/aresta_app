// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Testes do DatasetRepository: lógica de estado público, busca recursiva de
/// arquivos (testada via sistema de arquivos), e extração de capa markdown
/// (testada indiretamente via regex local equivalente).
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:fixnum/fixnum.dart';
import '../mocks/mock_telemetry_service.dart';
import '../mocks/mock_app_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/utils/construtor_caminho_trajeto.dart';

class MockAssetBundle extends Mock implements AssetBundle {}
class MockServicoCroquiOnline extends Mock implements ServicoCroquiOnline {}

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => '$tempPath/temp_cache';
}

void main() {
  late EditorDeCroqui editor;
  late DatasetRepository repo;
  late Directory tempDir;
  late MockTelemetryService mockTelemetry;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('dataset_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Estado público do DatasetRepository
  // ---------------------------------------------------------------------------

  group('Estado do DatasetRepository', () {
    test('loadEmpty deve criar dataset com listas vazias', () {
      repo.loadEmpty();
      expect(repo.activeDataset.value, isNotNull);
      expect(repo.activeDataset.value!.availablePicos, isEmpty);
      expect(repo.activeDataset.value!.downloadedPicos, isEmpty);
    });

    test('loadEmpty deve invalidar cache de traçados de ConstrutorCaminhoTrajeto', () {
      final p1 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'mapa#1',
        caminhoSvg: 'M 0 0 L 10 10',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );
      repo.loadEmpty();
      final p2 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'mapa#1',
        caminhoSvg: 'M 0 0 L 10 10',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );
      expect(identical(p1, p2), isFalse);
    });

    test('triggerHomeReset deve incrementar homeResetTrigger', () {
      final before = repo.homeResetTrigger.value;
      repo.triggerHomeReset();
      expect(repo.homeResetTrigger.value, before + 1);
    });

    test('triggerHomeReset múltiplo incrementa corretamente', () {
      final before = repo.homeResetTrigger.value;
      repo.triggerHomeReset();
      repo.triggerHomeReset();
      repo.triggerHomeReset();
      expect(repo.homeResetTrigger.value, before + 3);
    });

    test('activeDataset começa como null', () {
      final freshEditor = EditorDeCroqui();
      final freshRepo = DatasetRepository(editorDeCroqui: freshEditor);
      expect(freshRepo.activeDataset.value, isNull);
    });

    test('activeDataset notifica ouvintes ao ser atualizado', () {
      bool notified = false;
      repo.activeDataset.addListener(() => notified = true);
      repo.loadEmpty();
      expect(notified, isTrue);
    });

    test(
      'init deve descompactar indice.binarypb e thumbnails do preload quando o indice local nao existe',
      () async {
        final mockBundle = MockAssetBundle();

        final fakeIndice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'crag1',
              caminhoRelativo: 'crag1/compilado.binarypb',
            ),
          ],
        );
        final indiceBytes = fakeIndice.writeToBuffer();

        // Mock para indice.binarypb
        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        // Mock para thumbnail
        when(
          () => mockBundle.load('assets/preload/thumbnails/crag1.webp'),
        ).thenAnswer(
          (_) async => ByteData.view(Uint8List.fromList([1, 2, 3]).buffer),
        );

        // Injeta o mockBundle (adicionaremos no DatasetRepository depois)
        repo.assetBundle = mockBundle;
        SharedPreferences.setMockInitialValues({});
        await repo.init();

        final docsPath = tempDir.path;
        final localIndiceFile = File(editor.indicePath(docsPath));
        expect(localIndiceFile.existsSync(), isTrue);

        final thumbFile = File('$docsPath/thumbnails/crag1.webp');
        expect(thumbFile.existsSync(), isTrue);

        // Deve ter carregado na memoria
        expect(repo.activeDataset.value!.availablePicos.length, 1);
      },
    );

    test(
      'updateDatasetAfterDownload deve atualizar isDownloaded flag no availablePicos e preencher data',
      () async {
        repo.activeDataset.value = TopoDataset(
          availablePicos: [
            {'id': 'pico_1', 'isDownloaded': false},
          ],
          downloadedPicos: [],
        );

        final picoDir = Directory(
          '${editor.downloadsPath(tempDir.path)}/pico_1',
        );
        await picoDir.create(recursive: true);
        final picoFile = File('${picoDir.path}/pico_1.binarypb');

        final dummyPico = Pico()..nome = 'Pico Teste';
        final dummyCroqui = Croqui()..picos.add(dummyPico);
        await picoFile.writeAsBytes(dummyCroqui.writeToBuffer());

        final p1 = ConstrutorCaminhoTrajeto.obterCaminho(
          chaveCache: 'mapa#download',
          caminhoSvg: 'M 0 0 L 10 10',
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
        );

        await repo.updateDatasetAfterDownload('pico_1');

        final p2 = ConstrutorCaminhoTrajeto.obterCaminho(
          chaveCache: 'mapa#download',
          caminhoSvg: 'M 0 0 L 10 10',
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
        );
        expect(identical(p1, p2), isFalse);

        final updatedAvailable = repo.activeDataset.value!.availablePicos;
        expect(updatedAvailable.first['isDownloaded'], isTrue);

        final downloaded = repo.activeDataset.value!.downloadedPicos;
        expect(downloaded.length, 1);
        expect(downloaded.first['data'], isNotNull);
        expect((downloaded.first['data'] as Map)['pico'], isA<Pico>());
        expect((downloaded.first['data'] as Map)['croqui'], isA<Croqui>());
      },
    );

    test(
      'loadIndiceToMemory mapeia o campo descricao do ResumoCroqui',
      () async {
        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_desc',
              nome: 'Nome',
              descricao: 'Uma descrição curta muito legal',
              caminhoRelativo: 'pico_desc.zip',
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        expect(available.first['descricao'], 'Uma descrição curta muito legal');
      },
    );

    test(
      'loadIndiceToMemory mapeia estatísticas pré-computadas',
      () async {
        final precomputados = PrecomputadosResumoCroqui(
          totalEscaladas: 50,
          totalSetores: 5,
          totalEsportivas: 30,
          totalBoulders: 20,
        );

        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_stats',
              nome: 'Nome Stats',
              caminhoRelativo: 'pico_stats.zip',
              precomputados: precomputados,
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        final stats = available.first['estatisticas'];
        expect(stats, isNotNull);
        expect(stats['totalVias'], 50);
        expect(stats['totalSetores'], 5);
        expect(stats['totalEsportivas'], 30);
        expect(stats['totalBoulders'], 20);
        expect(stats['totalMoveis'], 0);
      },
    );

    test(
      'loadIndiceToMemory mapeia thumbnailUrl com a rota canônica thumbnails/<picoId>.webp',
      () async {
        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'br_mg_caete_pedra_filha',
              nome: 'Pedra da Filha',
              caminhoRelativo: 'picos/br_mg_caete_pedra_filha/br_mg_caete_pedra_filha.binarypb',
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        final pico = available.first;
        final baseUrl = repo.editorDeCroqui.activeBaseUrl;
        expect(pico['thumbnailUrl'], equals('$baseUrl/thumbnails/br_mg_caete_pedra_filha.webp'));
      },
    );

    test(
      'loadIndiceToMemory constrói url com parâmetro mandatório de versão ?v=<checksumSha256Croqui>',
      () async {
        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_versao',
              nome: 'Pico Versão',
              caminhoRelativo: 'picos/pico_versao/compilado.binarypb',
              checksumSha256Croqui: 'hash_abc123',
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        final pico = available.first;
        final baseUrl = repo.editorDeCroqui.activeBaseUrl;
        expect(
          pico['url'],
          equals('$baseUrl/picos/pico_versao/compilado.binarypb?v=hash_abc123'),
        );
        expect(pico['checksum'], equals('hash_abc123'));
      },
    );

    test(
      'loadIndiceToMemory mapeia tamanho_download_bytes e tamanhoFormatado corretamente',
      () async {
        final precomputados = PrecomputadosResumoCroqui(
          totalEscaladas: 10,
          totalSetores: 2,
          tamanhoDownloadBytes: Int64(19293798),
        );

        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_com_tamanho',
              nome: 'Pico Com Tamanho',
              caminhoRelativo: 'pico_com_tamanho.zip',
              precomputados: precomputados,
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        final item = available.first;
        expect(item['tamanhoBytes'], 19293798);
        expect(item['tamanhoFormatado'], '18.4 MB');
        expect(item['estatisticas']['tamanhoDownloadBytes'], 19293798);
      },
    );

    test(
      'loadIndiceToMemory deve preencher a chave [data] na inicializacao se o pico ja estiver baixado',
      () async {
        // Simula um pico já baixado no disco antes de carregar o índice
        final picoDir = Directory(
          '${editor.downloadsPath(tempDir.path)}/pico_boot',
        );
        await picoDir.create(recursive: true);
        final picoFile = File('${picoDir.path}/pico_boot.binarypb');

        final dummyPico = Pico()..nome = 'Pico de Boot Teste';
        final dummyCroqui = Croqui()..picos.add(dummyPico);
        await picoFile.writeAsBytes(dummyCroqui.writeToBuffer());

        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_boot',
              nome: 'Nome',
              caminhoRelativo: 'pico_boot.zip',
            ),
          ],
        );

        await repo.loadIndiceToMemory(indice);

        final downloaded = repo.activeDataset.value!.downloadedPicos;
        expect(downloaded.length, 1);
        expect(downloaded.first['isDownloaded'], isTrue);
        expect(downloaded.first['data'], isNotNull);
        expect((downloaded.first['data'] as Map)['pico'], isA<Pico>());
        expect((downloaded.first['data'] as Map)['croqui'], isA<Croqui>());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Operações de Deleção
  // ---------------------------------------------------------------------------
  group('Deleção de Crag', () {
    test('deleteCrag remove o diretório do pico corretamente', () async {
      final picoId = 'pico_para_deletar';
      final picoDir = Directory(
        '${editor.downloadsPath(tempDir.path)}/$picoId',
      );
      await picoDir.create(recursive: true);

      // Cria arquivo de teste dentro
      final testFile = File('${picoDir.path}/test_file.txt');
      await testFile.writeAsString('conteudo_teste');

      expect(picoDir.existsSync(), isTrue);

      final result = await repo.deleteCrag(picoId);

      expect(result, isTrue);
      expect(picoDir.existsSync(), isFalse);
    });

    test('deleteCrag preserva croqui no GerenciadorSessaoOnline ao excluir do disco permanente', () async {
      final picoId = 'pico_para_preservar';
      final picoDir = Directory(
        '${editor.downloadsPath(tempDir.path)}/$picoId',
      );
      await picoDir.create(recursive: true);

      final croqui = Croqui(id: picoId, nome: 'Pico Preservado');
      final croquiFile = File('${picoDir.path}/$picoId.binarypb');
      await croquiFile.writeAsBytes(croqui.writeToBuffer());

      final result = await repo.deleteCrag(picoId);

      expect(result, isTrue);
      expect(picoDir.existsSync(), isFalse);
      expect(
        repo.gerenciadorSessaoOnline.obterCroquiOnline(picoId)?.nome,
        equals('Pico Preservado'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Consulta de Croqui (Hierarquia Estrita de 4 Etapas: RAM -> Downloads -> Temp Cache -> Rede)
  // ---------------------------------------------------------------------------
  group('getCroqui (Hierarquia Estrita de 4 Etapas)', () {
    late MockServicoCroquiOnline mockServicoOnline;
    late DatasetRepository repoHierarquico;

    setUp(() {
      mockServicoOnline = MockServicoCroquiOnline();
      when(() => mockServicoOnline.caminhoCacheVolatil).thenReturn(null);
      when(() => mockServicoOnline.obterDiretorioCache())
          .thenAnswer((_) async => '${tempDir.path}/temp_cache');
      repoHierarquico = DatasetRepository(
        editorDeCroqui: editor,
        servicoCroquiOnline: mockServicoOnline,
      );
    });

    test('Etapa 1: Retorna croqui da RAM mesmo se houver versões em /downloads e temp_cache', () async {
      final picoId = 'pico_etapa1';
      final croquiRam = Croqui(id: picoId, nome: 'Croqui da RAM');
      repoHierarquico.gerenciadorSessaoOnline.registrarCroquiOnline(picoId, croquiRam);

      // Cria também no downloads com nome diferente para provar prioridade da RAM
      final picoDir = Directory('${editor.downloadsPath(tempDir.path)}/$picoId')..createSync(recursive: true);
      final croquiDownloads = Croqui(id: picoId, nome: 'Croqui de Downloads');
      File('${picoDir.path}/compilado.binarypb').writeAsBytesSync(croquiDownloads.writeToBuffer());

      final resultado = await repoHierarquico.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Croqui da RAM'));
      verifyZeroInteractions(mockServicoOnline);
    });

    test('Etapa 2: Retorna croqui de /downloads se não estiver na RAM, sem consultar rede', () async {
      final picoId = 'pico_etapa2';
      final picoDir = Directory('${editor.downloadsPath(tempDir.path)}/$picoId')..createSync(recursive: true);
      final croquiDownloads = Croqui(id: picoId, nome: 'Croqui de Downloads');
      File('${picoDir.path}/compilado.binarypb').writeAsBytesSync(croquiDownloads.writeToBuffer());

      final resultado = await repoHierarquico.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Croqui de Downloads'));
      verifyZeroInteractions(mockServicoOnline);
    });

    test('Etapa 3: Retorna croqui do temp_cache se não estiver na RAM nem em /downloads, sem chamar rede', () async {
      final picoId = 'pico_etapa3';
      final checksum = 'sha256_etapa3';

      // Configura índice com o checksum
      repoHierarquico.indiceData.value = Indice(
        croquis: [
          ResumoCroqui(
            id: picoId,
            nome: 'Pico Etapa 3',
            caminhoRelativo: 'picos/$picoId/compilado.binarypb',
            checksumSha256Croqui: checksum,
          ),
        ],
      );

      // Cria o arquivo no temp_cache
      final tempCacheDir = Directory('${tempDir.path}/temp_cache/$picoId')..createSync(recursive: true);
      final croquiTemp = Croqui(id: picoId, nome: 'Croqui do Temp Cache');
      File('${tempCacheDir.path}/compilado.binarypb.$checksum').writeAsBytesSync(croquiTemp.writeToBuffer());

      final resultado = await repoHierarquico.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Croqui do Temp Cache'));
      expect(repoHierarquico.gerenciadorSessaoOnline.obterCroquiOnline(picoId)?.nome, equals('Croqui do Temp Cache'));
      verifyNever(() => mockServicoOnline.carregarCroquiRemoto(
            any(),
            picoId: any(named: 'picoId'),
            checksumSha256: any(named: 'checksumSha256'),
          ));
    });

    test('Etapa 4: Busca via ServicoCroquiOnline com ?v=<checksum> quando não estiver em RAM, downloads nem temp_cache', () async {
      final picoId = 'pico_etapa4';
      final checksum = 'sha256_etapa4';

      repoHierarquico.indiceData.value = Indice(
        croquis: [
          ResumoCroqui(
            id: picoId,
            nome: 'Pico Etapa 4',
            caminhoRelativo: 'picos/$picoId/compilado.binarypb',
            checksumSha256Croqui: checksum,
          ),
        ],
      );

      final croquiRede = Croqui(id: picoId, nome: 'Croqui da Rede');
      final expectedUrl = '${editor.activeBaseUrl}/picos/$picoId/compilado.binarypb?v=$checksum';

      when(() => mockServicoOnline.carregarCroquiRemoto(
            expectedUrl,
            picoId: picoId,
            checksumSha256: checksum,
          )).thenAnswer((_) async => croquiRede);

      final resultado = await repoHierarquico.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Croqui da Rede'));
      expect(
        repoHierarquico.gerenciadorSessaoOnline.obterCroquiOnline(picoId)?.nome,
        equals('Croqui da Rede'),
      );
      verify(() => mockServicoOnline.carregarCroquiRemoto(
            expectedUrl,
            picoId: picoId,
            checksumSha256: checksum,
          )).called(1);
    });

    test('Construtor padrão compartilha a mesma instância de GerenciadorSessaoOnline com ServicoCroquiOnline', () {
      final repoPadrao = DatasetRepository(editorDeCroqui: editor);
      expect(
        identical(
          repoPadrao.gerenciadorSessaoOnline,
          repoPadrao.servicoCroquiOnline.sessaoOnline,
        ),
        isTrue,
        reason: 'ServicoCroquiOnline deve compartilhar a mesma sessão online do repositório',
      );
    });

    test('Retorna null se o croqui não for encontrado em nenhuma etapa e rede falhar', () async {
      final picoId = 'pico_inexistente';

      when(() => mockServicoOnline.carregarCroquiRemoto(
            any(),
            picoId: any(named: 'picoId'),
            checksumSha256: any(named: 'checksumSha256'),
          )).thenAnswer((_) async => null);

      final resultado = await repoHierarquico.getCroqui(picoId);

      expect(resultado, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Pré-bundling (Unpack Assets)
  // ---------------------------------------------------------------------------
  group('_unpackPreloadedAssets', () {
    late MockAppLogger mockLogger;

    setUp(() {
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
    });

    test(
      'deve logar erro se falhar ao carregar o indice do bundle (ex: pasta não existe)',
      () async {
        final mockBundle = MockAssetBundle();
        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenThrow(Exception('Bundle não encontrado'));

        repo.assetBundle = mockBundle;

        // Chamamos init que por sua vez chama _unpackPreloadedAssets na ausência de diretórios
        await repo.init();

        expect(mockLogger.recordedErrors.isNotEmpty, isTrue);
        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage'].contains('Preload de indice.binarypb'),
          ),
          isTrue,
        );
      },
    );

    test(
      'deve logar erro se falhar ao carregar uma thumbnail específica',
      () async {
        final mockBundle = MockAssetBundle();

        final mockIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico_sem_thumb'
              ..caminhoRelativo = 'picos/pico_sem_thumb.binarypb',
          );
        final indiceBytes = mockIndice.writeToBuffer();

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        when(
          () =>
              mockBundle.load('assets/preload/thumbnails/pico_sem_thumb.webp'),
        ).thenThrow(Exception('Thumbnail missing in bundle'));

        repo.assetBundle = mockBundle;

        await repo.init();

        // O índice foi carregado com sucesso, mas a thumbnail falhou
        expect(mockLogger.recordedErrors.isNotEmpty, isTrue);
        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage'].contains(
              'Erro ao carregar thumbnail pico_sem_thumb',
            ),
          ),
          isTrue,
        );
      },
    );

    test(
      'deve definir a cached_data_version para evitar tela de migração na primeira instalação',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockBundle = MockAssetBundle();
        final mockIndice = Indice();
        final indiceBytes = mockIndice.writeToBuffer();

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        repo.assetBundle = mockBundle;

        await repo.init();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt('cached_data_version'),
          equals(NetworkConstants.kDataVersion),
        );
      },
    );
  });

  group('Tabela de Dispersão de Hashes de Mídia', () {
    test('obterSha256DaMidia resolve thumbnail indexada do Indice', () async {
      final indice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'pico_ouro_preto'
            ..checksumSha256Thumbnail = 'hash_thumb_123',
        );

      await repo.loadIndiceToMemory(indice);

      expect(
        repo.obterSha256DaMidia('pico_ouro_preto', 'thumbnails/pico_ouro_preto.webp'),
        equals('hash_thumb_123'),
      );
      expect(
        repo.obterSha256DaMidia('pico_ouro_preto', 'pico_ouro_preto.webp'),
        equals('hash_thumb_123'),
      );
    });

    test('obterSha256DaMidia resolve arquivo externo indexado do Croqui', () {
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'setores/principal/mapa.webp',
            checksumSha256: 'sha_mapa_xyz',
          ),
        );

      repo.indexarMidiasDoCroqui('pico_ouro_preto', croqui);

      expect(
        repo.obterSha256DaMidia('pico_ouro_preto', 'setores/principal/mapa.webp'),
        equals('sha_mapa_xyz'),
      );
      expect(
        repo.obterSha256DaMidia('pico_ouro_preto', '/setores/principal/mapa.webp'),
        equals('sha_mapa_xyz'),
      );
    });

    test('obterSha256DaMidia retorna null para pico ou mídia inexistente', () {
      expect(repo.obterSha256DaMidia('pico_fantasma', 'mapa.webp'), isNull);
      expect(repo.obterSha256DaMidia('pico_ouro_preto', 'arquivo_inexistente.jpg'), isNull);
    });

    test('obterSha256DaMidia resolve mídia a partir do GerenciadorSessaoOnline se não indexada previamente', () {
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'croqui_online.webp',
            checksumSha256: 'sha_online_999',
          ),
        );
      repo.gerenciadorSessaoOnline.registrarCroquiOnline('pico_online_1', croqui);

      expect(
        repo.obterSha256DaMidia('pico_online_1', 'croqui_online.webp'),
        equals('sha_online_999'),
      );
    });

    test('TDD 1.3: obterSha256DaMidia deve resolver mídia de croqui online mesmo quando índice já indexou thumbnail do pico', () async {
      final indice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'pico_com_thumb'
            ..checksumSha256Thumbnail = 'hash_thumb_123',
        );
      await repo.loadIndiceToMemory(indice);

      expect(
        repo.obterSha256DaMidia('pico_com_thumb', 'thumbnails/pico_com_thumb.webp'),
        equals('hash_thumb_123'),
      );

      final croquiOnline = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'imagens/mapa_setor.webp',
            checksumSha256: 'hash_mapa_456',
          ),
        );
      repo.gerenciadorSessaoOnline.registrarCroquiOnline('pico_com_thumb', croquiOnline);

      expect(
        repo.obterSha256DaMidia('pico_com_thumb', 'imagens/mapa_setor.webp'),
        equals('hash_mapa_456'),
      );
    });

    test('TDD 1.3: obterSha256DaMidia e indexarMidiasDoCroqui devem normalizar caminhos com ./ e barras invertidas', () {
      final croqui = Croqui()
        ..arquivosExternos.addAll([
          ArquivoExterno(
            caminho: r'.\imagens\setor_1.webp',
            checksumSha256: 'hash_normalizado_1',
          ),
          ArquivoExterno(
            caminho: './mapas/geral.webp',
            checksumSha256: 'hash_normalizado_2',
          ),
        ]);

      repo.indexarMidiasDoCroqui('pico_normalizacao', croqui);

      expect(repo.obterSha256DaMidia('pico_normalizacao', 'imagens/setor_1.webp'), equals('hash_normalizado_1'));
      expect(repo.obterSha256DaMidia('pico_normalizacao', r'.\imagens\setor_1.webp'), equals('hash_normalizado_1'));
      expect(repo.obterSha256DaMidia('pico_normalizacao', r'imagens\setor_1.webp'), equals('hash_normalizado_1'));
      expect(repo.obterSha256DaMidia('pico_normalizacao', './imagens/setor_1.webp'), equals('hash_normalizado_1'));
      expect(repo.obterSha256DaMidia('pico_normalizacao', 'mapas/geral.webp'), equals('hash_normalizado_2'));
      expect(repo.obterSha256DaMidia('pico_normalizacao', r'.\mapas\geral.webp'), equals('hash_normalizado_2'));
    });

    test('isPicoDownloaded retorna true apenas para picos presentes em picosBaixados', () {
      expect(repo.isPicoDownloaded('pico_qualquer'), isFalse);

      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: [
          {'id': 'pico_1', 'nome': 'Pico 1'},
          {'id': 'pico_2', 'nome': 'Pico 2'},
        ],
        picosBaixados: [
          {'id': 'pico_1', 'nome': 'Pico 1'},
        ],
      );

      expect(repo.isPicoDownloaded('pico_1'), isTrue);
      expect(repo.isPicoDownloaded('pico_2'), isFalse);
    });

    test('updateDatasetAfterDownload remove a sessão do pico no GerenciadorSessaoOnline', () async {
      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: [
          {'id': 'pico_1', 'nome': 'Pico 1'},
        ],
        picosBaixados: [],
      );

      repo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1'),
        etag: 'etag_123',
      );
      expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_1'), isNotNull);

      await repo.updateDatasetAfterDownload('pico_1');

      expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_1'), isNull);
      expect(repo.gerenciadorSessaoOnline.obterEtag('pico_1'), isNull);
    });

    test('notificarAtualizacaoSessaoOnline re-indexa mídias e atualiza activeDataset', () {
      final croqui = Croqui(id: 'pico_online_1')
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'mapa_novo.webp',
            checksumSha256: 'sha_novo_123',
          ),
        );
      repo.gerenciadorSessaoOnline.registrarCroquiOnline('pico_online_1', croqui);
      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: [
          {'id': 'pico_online_1', 'nome': 'Pico Online 1'},
        ],
        picosBaixados: [],
      );

      bool activeDatasetNotificou = false;
      repo.activeDataset.addListener(() {
        activeDatasetNotificou = true;
      });

      repo.notificarAtualizacaoSessaoOnline('pico_online_1');

      expect(activeDatasetNotificou, isTrue);
      expect(
        repo.obterSha256DaMidia('pico_online_1', 'mapa_novo.webp'),
        equals('sha_novo_123'),
      );
    });

    test('notificarCroquiOnlineAtualizadoNaUI notifica notificadorCroquiAtualizado', () {
      String? nomeNotificado;
      repo.notificadorCroquiAtualizado.addListener(() {
        nomeNotificado = repo.notificadorCroquiAtualizado.value;
      });

      repo.notificarCroquiOnlineAtualizadoNaUI('Pedra do Baú');

      expect(nomeNotificado, equals('Pedra do Baú'));
    });

    group('DatasetRepository - Invalidação de Croquis e Trajetos Obsoletos', () {
      test('deve limpar o cache estático de caminhos em ConstrutorCaminhoTrajeto', () {
        const chave = 'mapa_teste#linha_1';
        final caminho1 = ConstrutorCaminhoTrajeto.obterCaminho(
          chaveCache: chave,
          caminhoSvg: 'M 0 0 L 100 100',
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
        );

        // Confirma que estava no cache
        final mesmoCaminho = ConstrutorCaminhoTrajeto.obterCaminho(
          chaveCache: chave,
          caminhoSvg: 'M 0 0 L 100 100',
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
        );
        expect(identical(caminho1, mesmoCaminho), isTrue);

        repo.invalidarCroquisObsoletos();

        // Após invalidar, o cache deve ter sido limpo
        final caminhoAposLimpeza = ConstrutorCaminhoTrajeto.obterCaminho(
          chaveCache: chave,
          caminhoSvg: 'M 0 0 L 100 100',
          estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
        );
        expect(identical(caminho1, caminhoAposLimpeza), isFalse);
      });

      test('deve remover da sessão online os picos com checksum divergente no novo índice quando fechados', () {
        final croquiDesatualizado = Croqui(id: 'pico_desatualizado');
        final croquiInalterado = Croqui(id: 'pico_inalterado');

        repo.gerenciadorSessaoOnline.registrarCroquiOnline(
          'pico_desatualizado',
          croquiDesatualizado,
          checksumSha256: 'sha_antigo_123',
        );
        repo.gerenciadorSessaoOnline.registrarCroquiOnline(
          'pico_inalterado',
          croquiInalterado,
          checksumSha256: 'sha_constante_456',
        );

        final novoIndice = Indice()
          ..croquis.addAll([
            ResumoCroqui(
              id: 'pico_desatualizado',
              checksumSha256Croqui: 'sha_novo_999',
            ),
            ResumoCroqui(
              id: 'pico_inalterado',
              checksumSha256Croqui: 'sha_constante_456',
            ),
          ]);

        repo.invalidarCroquisObsoletos(novoIndice: novoIndice);

        expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_desatualizado'), isNull);
        expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_inalterado'), isNotNull);
      });

      test('deve remover da sessão online os picos listados em picosAtualizados', () {
        final croqui = Croqui(id: 'pico_disco');
        repo.gerenciadorSessaoOnline.registrarCroquiOnline('pico_disco', croqui);

        repo.invalidarCroquisObsoletos(picosAtualizados: ['pico_disco']);

        expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_disco'), isNull);
      });

      test('não deve remover da sessão online o pico que estiver atualmente aberto (picoAbertoId)', () {
        final croqui = Croqui(id: 'pico_em_uso');
        repo.gerenciadorSessaoOnline.registrarCroquiOnline(
          'pico_em_uso',
          croqui,
          checksumSha256: 'sha_antigo',
        );

        final novoIndice = Indice()
          ..croquis.add(
            ResumoCroqui(
              id: 'pico_em_uso',
              checksumSha256Croqui: 'sha_novo',
            ),
          );

        repo.invalidarCroquisObsoletos(
          novoIndice: novoIndice,
          picosAtualizados: ['pico_em_uso'],
          picoAbertoId: 'pico_em_uso',
        );

        expect(repo.gerenciadorSessaoOnline.obterCroquiOnline('pico_em_uso'), isNotNull);
      });
    });

    group('obterDataAtualizacaoCroqui', () {
      test('retorna DateTime a partir do resumo em indiceData', () {
        final timestampProto = Timestamp.fromDateTime(DateTime.utc(2026, 9, 18, 1, 54, 49));
        final indice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico_18_set'
              ..timestampUpdate = timestampProto,
          );
        repo.indiceData.value = indice;

        final data = repo.obterDataAtualizacaoCroqui('pico_18_set');
        expect(data, isNotNull);
        expect(data?.toUtc().year, 2026);
        expect(data?.toUtc().month, 9);
        expect(data?.toUtc().day, 18);
      });

      test('retorna DateTime a partir de activeDataset (picosDisponiveis)', () {
        repo.indiceData.value = null;
        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosDisponiveis: [
            {
              'id': 'pico_ativo',
              'dataUpdate': '2026-09-18T01:54:49.000Z',
            },
          ],
          picosBaixados: [],
        );

        final data = repo.obterDataAtualizacaoCroqui('pico_ativo');
        expect(data, isNotNull);
        expect(data?.toUtc().year, 2026);
        expect(data?.toUtc().month, 9);
        expect(data?.toUtc().day, 18);
      });

      test('retorna null se o pico não for encontrado', () {
        repo.indiceData.value = Indice();
        repo.activeDataset.value = ConjuntoDadosCroqui.vazio();

        expect(repo.obterDataAtualizacaoCroqui('pico_inexistente'), isNull);
      });
    });
  });
}




