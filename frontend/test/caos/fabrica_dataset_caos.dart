// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/application_managers/feedback/orquestrador_feedback.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import '../mocks/mock_geolocator_platform.dart';
import 'motor_robo_caotico.dart';
import 'receita_crash_robo.dart';

/// Estrutura imutável com o estado inicial de catálogo e caderneta para uma sessão do robô caótico.
class EstadoDatasetCaos {
  /// Conjunto de dados de croquis (baixados e disponíveis online) injetado no `DatasetRepository`.
  final ConjuntoDadosCroqui conjuntoDados;

  /// Lista inicial de cadenas para popular o banco SQLite da Caderneta antes da exploração.
  final List<Cadena> cadenasIniciais;

  /// Constrói o estado inicial do dataset de caos.
  const EstadoDatasetCaos({
    required this.conjuntoDados,
    required this.cadenasIniciais,
  });
}

/// Fábrica determinística de datasets de teste para o Robô Caótico.
///
/// Disponibiliza dois perfis:
/// - [TipoDatasetCaos.normal]: Catálogo realista com picos baixados e online, setores, vias e cadenas coerentes.
/// - [TipoDatasetCaos.toxico]: Catálogo de estresse desenhado para expor falhas de layout (`RenderFlex overflow`),
///   acessos a listas vazias (`Bad state: No element`), markdown extremo e cadenas órfãs.
abstract final class FabricaDatasetCaos {
  /// Constrói o [EstadoDatasetCaos] correspondente ao [tipo] informado.
  static EstadoDatasetCaos construir(TipoDatasetCaos tipo) {
    switch (tipo) {
      case TipoDatasetCaos.normal:
        return _construirNormal();
      case TipoDatasetCaos.toxico:
        return _construirToxico();
    }
  }

  static EstadoDatasetCaos _construirNormal() {
    final via1 = ViaEsportiva()
      ..nome = 'Aresta do Sol'
      ..dificuldade = GrauVia_GrauVia.BR_6SUP
      ..destaque = true
      ..extensao = 25
      ..descricao = 'Via clássica em diedro bem protegido.'
      ..conquistadores.add('Renato');

    final via2 = ViaEsportiva()
      ..nome = 'Fenda Invisível'
      ..dificuldade = GrauVia_GrauVia.BR_8A
      ..destaque = false
      ..extensao = 18
      ..descricao = 'Crux técnico na saída do teto.';

    final boulder1 = Boulder()
      ..nome = 'Bloco da Nascente'
      ..dificuldade = GrauBoulder_GrauBoulder.V4
      ..destaque = true
      ..descricao = 'Saída sentado em regletes.';

    final setorPrincipal = Setor()
      ..uid = 'set_norm_00001'
      ..nome = 'Setor Principal'
      ..descricao = 'Acesso por trilha de 10 minutos.'
      ..escaladas.addAll([
        Escalada()
          ..uid = 'via_norm_00001'
          ..viaEsportiva = via1,
        Escalada()
          ..uid = 'via_norm_00002'
          ..viaEsportiva = via2,
        Escalada()
          ..uid = 'bld_norm_00003'
          ..boulder = boulder1,
      ]);

    final picoBaixado = Pico()
      ..nome = 'Serra do Cipó'
      ..descricao = 'Calcário clássico com dezenas de setores.'
      ..estado = 'MG'
      ..cidade = 'Santana do Riacho'
      ..setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorPrincipal),
      );

    final croquiBaixado = Croqui()
      ..id = 'serra_do_cipo'
      ..uid = 'crq_norm_00001'
      ..picos.add(picoBaixado);

    final resumoBaixado = ResumoPico(
      id: 'serra_do_cipo',
      nome: 'Serra do Cipó',
      local: 'Santana do Riacho, MG',
      descricao: picoBaixado.descricao,
      isDownloaded: true,
      latitude: -19.3456,
      longitude: -43.6123,
      estatisticas: const EstatisticasPico(
        totalSetores: 1,
        totalVias: 3,
        totalEsportivas: 2,
        totalBoulders: 1,
      ),
      pico: picoBaixado,
      croqui: croquiBaixado,
    );

    final resumoOnline = const ResumoPico(
      id: 'pedra_bela',
      nome: 'Pedra Bela',
      local: 'Pedra Bela, SP',
      descricao: 'Granito tradicional do interior paulista.',
      isDownloaded: false,
      tamanhoBytes: 1048576,
      tamanhoFormatado: '1.0 MB',
      latitude: -22.7911,
      longitude: -46.4422,
      estatisticas: EstatisticasPico(
        totalSetores: 3,
        totalVias: 15,
        totalEsportivas: 15,
      ),
    );

    final cadenas = <Cadena>[
      Cadena(
        id: '11111111-1111-4111-8111-111111111111',
        escaladaUid: 'via_norm_00001',
        dataAscensao: DateTime.utc(2026, 5, 10),
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 1,
        notasPrivadas: 'Ótima aderência no calcário.',
      ),
    ];

    return EstadoDatasetCaos(
      conjuntoDados: ConjuntoDadosCroqui(
        picosBaixados: [resumoBaixado],
        picosDisponiveis: [resumoBaixado, resumoOnline],
      ),
      cadenasIniciais: cadenas,
    );
  }

  static EstadoDatasetCaos _construirToxico() {
    // 1. Pico completamente vazio (0 setores, 0 vias, sem coordenadas)
    final picoVazio = Pico()
      ..nome = 'Pico Vazio Degenerado'
      ..descricao = '';
    final croquiVazio = Croqui()
      ..id = 'pico_toxico_vazio'
      ..uid = 'crq_tox_vazio0'
      ..picos.add(picoVazio);
    final resumoVazio = ResumoPico(
      id: 'pico_toxico_vazio',
      nome: picoVazio.nome,
      local: '',
      descricao: '',
      isDownloaded: true,
      estatisticas: const EstatisticasPico(totalSetores: 0, totalVias: 0),
      pico: picoVazio,
      croqui: croquiVazio,
    );

    // 2. Pico com textos extremos (300+ caracteres sem espaços, emojis, Markdown e <small> aninhado)
    final nomeGigante =
        '🧗‍♂️🔥PicoSuperExtremoSemEspacosParaTestarOverflowDeLayoutNaAppBarECards_' *
        5;
    final descricaoMarkdownLimite =
        '# Título Gigante $nomeGigante\n\n'
        '<small>Nota pequena com **negrito** e tag incompleta <small> dentro</small>\n'
        '| Coluna A | Coluna B | Coluna C |\n'
        '|---|---|---|\n'
        '| Valor 1 | Valor 2 com texto enorme $nomeGigante | 🚀 |\n'
        '[Link quebrado](htp://url invalida com espacos)';

    final setorSemVias = Setor()
      ..uid = 'set_tox_vazio1'
      ..nome = 'Setor Fantasma Sem Escaladas'
      ..descricao = 'Setor sem nenhuma via nem imagem de croqui.';

    final viaTextoExtremo = ViaEsportiva()
      ..nome = 'Via_${'X' * 310}_🧗‍♀️'
      ..dificuldade = GrauVia_GrauVia.values.first
      ..extensao = 9999
      ..descricao = descricaoMarkdownLimite;

    final setorTextoExtremo = Setor()
      ..uid = 'set_tox_txt001'
      ..nome = 'Setor_${'Z' * 250}'
      ..descricao = descricaoMarkdownLimite
      ..escaladas.add(
        Escalada()
          ..uid = 'via_tox_txt001'
          ..viaEsportiva = viaTextoExtremo,
      );

    final picoTextoExtremo = Pico()
      ..nome = nomeGigante
      ..descricao = descricaoMarkdownLimite
      ..estado = 'UF_MUITO_LONGA_12345'
      ..cidade = 'Cidade_${'W' * 120}'
      ..setoresOuGrupos.addAll([
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorSemVias),
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorTextoExtremo),
      ]);

    final croquiTextoExtremo = Croqui()
      ..id = 'pico_toxico_texto_extremo'
      ..uid = 'crq_tox_txt001'
      ..picos.add(picoTextoExtremo);

    final resumoTextoExtremo = ResumoPico(
      id: 'pico_toxico_texto_extremo',
      nome: nomeGigante,
      local: '${picoTextoExtremo.cidade}, ${picoTextoExtremo.estado}',
      descricao: descricaoMarkdownLimite,
      isDownloaded: true,
      latitude: 0.0,
      longitude: 0.0,
      estatisticas: const EstatisticasPico(
        totalSetores: 2,
        totalVias: 1,
        totalEsportivas: 1,
      ),
      pico: picoTextoExtremo,
      croqui: croquiTextoExtremo,
    );

    // 3. Pico de alto volume (60 vias misturando todos os graus e modalidades)
    final escaladasVolume = <Escalada>[];
    final todosGrausVia = GrauVia_GrauVia.values;
    final todosGrausBoulder = GrauBoulder_GrauBoulder.values;

    for (var i = 0; i < 60; i++) {
      if (i % 3 == 0) {
        final grauBoulder = todosGrausBoulder[i % todosGrausBoulder.length];
        escaladasVolume.add(
          Escalada()
            ..uid = 'bld_tox_vol_${i.toString().padLeft(2, '0')}'
            ..boulder = (Boulder()
              ..nome = i == 0 ? '' : 'Boulder Caótico #$i'
              ..dificuldade = grauBoulder
              ..destaque = (i % 2 == 0)),
        );
      } else {
        final grauVia = todosGrausVia[i % todosGrausVia.length];
        escaladasVolume.add(
          Escalada()
            ..uid = 'via_tox_vol_${i.toString().padLeft(2, '0')}'
            ..viaEsportiva = (ViaEsportiva()
              ..nome = 'Via Volume #$i (${grauVia.name})'
              ..dificuldade = grauVia
              ..destaque = (i % 5 == 0)
              ..extensao = (i * 7) % 150),
        );
      }
    }

    final setorVolume = Setor()
      ..uid = 'set_tox_vol001'
      ..nome = 'Setor Maratona 60 Vias'
      ..escaladas.addAll(escaladasVolume);

    final picoVolume = Pico()
      ..nome = 'Pico Alto Volume'
      ..descricao = 'Pico para estressar listas, filtros e pirâmide de graus.'
      ..setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorVolume),
      );

    final croquiVolume = Croqui()
      ..id = 'pico_toxico_alto_volume'
      ..uid = 'crq_tox_vol001'
      ..picos.add(picoVolume);

    final resumoVolume = ResumoPico(
      id: 'pico_toxico_alto_volume',
      nome: picoVolume.nome,
      local: 'Serra Extrema, BR',
      descricao: picoVolume.descricao,
      isDownloaded: true,
      latitude: -23.5505,
      longitude: -46.6333,
      estatisticas: const EstatisticasPico(
        totalSetores: 1,
        totalVias: 60,
        totalEsportivas: 40,
        totalBoulders: 20,
      ),
      pico: picoVolume,
      croqui: croquiVolume,
    );

    // 4. Pico apenas online (não baixado) com tamanho zero
    final resumoOnlineToxico = const ResumoPico(
      id: 'pico_toxico_online_sem_cache',
      nome: 'Pico Online Sem Cache 🌩️',
      local: 'Remoto, AM',
      descricao: 'Pico nunca baixado localmente.',
      isDownloaded: false,
      tamanhoBytes: 0,
      tamanhoFormatado: '0 B',
    );

    // 5. Cadenas tóxicas (incluindo cadena órfã apontando para via inexistente e datas limites)
    final cadenasToxicas = <Cadena>[
      Cadena(
        id: '22222222-2222-4222-8222-222222222222',
        escaladaUid: 'uid_orfao_4040',
        dataAscensao: DateTime.utc(1970, 1, 1),
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.solo,
        tentativas: 999,
        notasPrivadas: 'Nota máxima ' * 25,
      ),
      Cadena(
        id: '33333333-3333-4333-8333-333333333333',
        escaladaUid: 'via_tox_txt001',
        dataAscensao: DateTime.utc(2099, 12, 31),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.boulder,
        tentativas: 1,
        notasPrivadas: '🧗‍♂️🔥',
      ),
    ];

    return EstadoDatasetCaos(
      conjuntoDados: ConjuntoDadosCroqui(
        picosBaixados: [resumoVazio, resumoTextoExtremo, resumoVolume],
        picosDisponiveis: [
          resumoVazio,
          resumoTextoExtremo,
          resumoVolume,
          resumoOnlineToxico,
        ],
      ),
      cadenasIniciais: cadenasToxicas,
    );
  }
}

class _FakePathProviderCaos extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String caminhoTemporario;

  _FakePathProviderCaos(this.caminhoTemporario);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoTemporario;

  @override
  Future<String?> getApplicationSupportPath() async => caminhoTemporario;

  @override
  Future<String?> getLibraryPath() async => caminhoTemporario;

  @override
  Future<String?> getTemporaryPath() async => caminhoTemporario;
}

/// Ambiente que monta a árvore real de navegação do aplicativo (`TreeNavigationWrapper`)
/// alimentada pelos datasets da [FabricaDatasetCaos] para execução do [MotorRoboCaotico].
class AmbienteAppCaos {
  /// Diretório temporário isolado usado pelos serviços de armazenamento durante a sessão.
  final Directory diretorioTemporario;

  DatasetRepository? _repoAtual;
  SyncService? _syncAtual;

  AmbienteAppCaos._(this.diretorioTemporario);

  /// Inicializa os fakes de fronteira de plataforma (`PathProvider`, `Geolocator`, `SharedPreferences`).
  static Future<AmbienteAppCaos> inicializar() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FeedbackOrchestrator.debugIsConfiguredOverride = false;
    final tempDir = Directory.systemTemp.createTempSync('aresta_caos_app_');
    PathProviderPlatform.instance = _FakePathProviderCaos(tempDir.path);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    return AmbienteAppCaos._(tempDir);
  }

  /// Constrói um [MotorRoboCaotico] conectado à árvore real do aplicativo (`TreeNavigationWrapper`).
  MotorRoboCaotico criarMotor({
    required WidgetTester tester,
    Directory? diretorioSaidaReceitas,
    bool reportarAoSentry = false,
  }) {
    return MotorRoboCaotico(
      tester: tester,
      diretorioSaidaReceitas: diretorioSaidaReceitas,
      reportarAoSentry: reportarAoSentry,
      montarCenario: (dataset) async {
        final estado = FabricaDatasetCaos.construir(dataset);
        final editor = EditorDeCroqui();
        final repo = DatasetRepository(editorDeCroqui: editor);
        repo.activeDataset.value = estado.conjuntoDados;

        final syncService = SyncService(datasetRepository: repo);
        syncService.syncStatus.value = SyncStatus.updated;

        _repoAtual = repo;
        _syncAtual = syncService;

        await tester.pumpWidget(
          BetterFeedback(
            child: MaterialApp(
              home: TreeNavigationWrapper(
                key: TreeNavigationWrapper.navKey,
                datasetRepo: repo,
                syncService: syncService,
              ),
            ),
          ),
        );
        await tester.pump();
      },
      aoDispararEventoSync: () async {
        final sync = _syncAtual;
        final repo = _repoAtual;
        if (sync != null && repo != null) {
          sync.syncStatus.value = SyncStatus.updating;
          await tester.pump(const Duration(milliseconds: 16));
          repo.activeDataset.value = repo.activeDataset.value;
          sync.syncStatus.value = SyncStatus.justUpdated;
        }
      },
      aoAlternarConectividade: () async {
        final sync = _syncAtual;
        if (sync != null) {
          sync.syncStatus.value = sync.syncStatus.value == SyncStatus.offline
              ? SyncStatus.updated
              : SyncStatus.offline;
        }
      },
    );
  }

  /// Remove o diretório temporário criado para a sessão.
  Future<void> limpar() async {
    FeedbackOrchestrator.debugIsConfiguredOverride = null;
    if (diretorioTemporario.existsSync()) {
      diretorioTemporario.deleteSync(recursive: true);
    }
  }
}
