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
import 'package:fixnum/fixnum.dart';
import '../mocks/mock_telemetry_service.dart';
import '../mocks/mock_app_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/firebase/app_logger.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

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

        await repo.updateDatasetAfterDownload('pico_1');

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
  // Consulta de Croqui (Híbrido: Local ou Sessão Online)
  // ---------------------------------------------------------------------------
  group('getCroqui (Híbrido Local e Sessão Online)', () {
    test('retorna croqui do disco permanente se existir em /downloads', () async {
      final picoId = 'pico_local';
      final picoDir = Directory(
        '${editor.downloadsPath(tempDir.path)}/$picoId',
      );
      await picoDir.create(recursive: true);

      final croquiLocal = Croqui(id: picoId, nome: 'Pico Local');
      final croquiFile = File('${picoDir.path}/$picoId.binarypb');
      await croquiFile.writeAsBytes(croquiLocal.writeToBuffer());

      final resultado = await repo.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Local'));
    });

    test('retorna croqui da sessão online se não estiver baixado localmente', () async {
      final picoId = 'pico_remoto';
      final croquiOnline = Croqui(id: picoId, nome: 'Pico Online em Memória');
      repo.gerenciadorSessaoOnline.registrarCroquiOnline(picoId, croquiOnline);

      final resultado = await repo.getCroqui(picoId);

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Online em Memória'));
    });

    test('retorna null se o croqui não estiver nem em disco nem na sessão online', () async {
      final resultado = await repo.getCroqui('pico_fantasma');
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
  });
}



