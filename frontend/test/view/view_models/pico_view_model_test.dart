// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_rede.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/pico_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mocks/mock_telemetria.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

class _ClienteHttpRastreavel extends http.BaseClient {
  bool foiFechado = false;
  final List<int> bytesResposta;
  final Map<String, String> headersResposta;

  _ClienteHttpRastreavel({
    this.bytesResposta = const [],
    this.headersResposta = const {},
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(bytesResposta),
      200,
      headers: headersResposta,
    );
  }

  @override
  void close() {
    foiFechado = true;
    super.close();
  }
}

class _ServicoCroquiOnlineComGatilho extends ServicoCroquiOnline {
  Future<bool> Function()? dispararTickPolling;

  _ServicoCroquiOnlineComGatilho({
    super.client,
    required super.sessaoOnline,
    super.verificarPicoBaixado,
  });

  @override
  void iniciarPollingEtag(
    String picoId,
    String url, {
    Duration intervalo = const Duration(seconds: 30),
    void Function(String picoId, Croqui croqui)? aoAtualizar,
  }) {
    super.iniciarPollingEtag(
      picoId,
      url,
      intervalo: intervalo,
      aoAtualizar: aoAtualizar,
    );
    dispararTickPolling = () => verificarAtualizacaoEtag(
          picoId,
          url,
          aoAtualizar: aoAtualizar,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repositorio;
  late Pico pico;
  late Croqui croqui;
  const cragId = 'crag_teste_1';

  setUp(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({
      'cached_data_version': NetworkConstants.kDataVersion,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.climb',
      version: '1.0.0',
      buildNumber: '100',
      buildSignature: '',
    );
    TelemetryService.instance = MockTelemetryService();

    tempDir = await Directory.systemTemp.createTemp('pico_view_model_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    repositorio = DatasetRepository(editorDeCroqui: EditorDeCroqui());
    pico = Pico()
      ..nome = 'Pedra do Baú'
      ..estado = 'SP';
    croqui = Croqui()
      ..id = cragId
      ..nome = 'Pedra do Baú'
      ..picos.add(pico);
  });

  tearDown(() async {
    SyncService.baseUrlOverride = null;
    SyncService.catalogoUrlOverride = null;
    GerenciadorNotificacaoDownload.instancia = null;
    await SyncService.instance?.tarefaMidiasEmSegundoPlano;
    await repositorio.repositorioCatalogo.fechar();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Inicia um micro-servidor HTTP local servindo o índice e o binário do croqui.
  Future<(HttpServer, SyncService, Indice)> iniciarServidorESyncReal({
    required Croqui croquiRemoto,
  }) async {
    final croquiBytes = croquiRemoto.writeToBuffer();
    final hashCroqui = sha256.convert(croquiBytes).toString();
    const caminhoRelativo = '$cragId/compilado.binarypb';

    final indice = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = cragId
          ..nome = croquiRemoto.nome.isNotEmpty ? croquiRemoto.nome : 'Pedra do Baú'
          ..caminhoRelativo = caminhoRelativo
          ..checksumSha256Croqui = hashCroqui
          ..timestampUpdate = Timestamp.fromDateTime(
            DateTime.utc(2026, 5, 20, 14, 30),
          ),
      );
    final indiceBytes = indice.writeToBuffer();

    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => await servidor.close(force: true));

    servidor.listen((HttpRequest req) async {
      if (req.uri.path.endsWith('/indice.binarypb')) {
        req.response.statusCode = 200;
        req.response.headers.set('etag', '"etag-indice-1"');
        req.response.add(indiceBytes);
      } else if (req.uri.path.endsWith('/$caminhoRelativo')) {
        req.response.statusCode = 200;
        req.response.headers.set('etag', '"etag-croqui-1"');
        req.response.add(croquiBytes);
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });

    final urlBase = 'http://127.0.0.1:${servidor.port}';
    SyncService.baseUrlOverride = urlBase;

    await repositorio.loadIndiceToMemory(indice);

    final clienteLocal = ClienteHttpAresta.paraTestes(http.Client());
    final syncService = SyncService(
      datasetRepository: repositorio,
      client: clienteLocal,
      network: SyncNetwork(clienteLocal, Duration.zero),
    );

    return (servidor, syncService, indice);
  }

  group('PicoViewModel - Estatísticas e Formatação de UI', () {
    test('calcula total de setores, modalidades e subtítulo corretamente', () {
      final setor1 = Setor(
        nome: 'Setor 1',
        escaladas: [
          Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Normal')),
          Escalada(boulder: Boulder(nome: 'Boulder Teste')),
        ],
      );

      final setor2 = Setor(
        nome: 'Setor 2',
        escaladas: [
          Escalada(viaMovel: ViaMovel(nome: 'Fissura Móvel')),
          Escalada(
            viaMultiplasEnfiadas: ViaMultiplasEnfiadas(nome: 'Parede Sul'),
          ),
          Escalada(highline: Highline(nome: 'Highline do Abismo')),
        ],
      );

      final grupo1 = Grupo(
        nome: 'Complexo Norte',
        setores: [ArquivoSetor(conteudo: setor2)],
      );

      pico.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo1)),
      ]);

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.categorias, isNotNull);
      expect(vm.regras, isEmpty);
      expect(vm.creditos, isEmpty);
      expect(vm.totalSetores, 2);
      expect(
        vm.subtitulo,
        'SP • 2 SETORES • 5 escaladas (1 esportivas, 1 boulders, 1 móveis, 1 múltiplas enfiadas, 1 highlines)',
      );
      expect(vm.tooltipBusca, 'Buscar via');
      vm.dispose();
    });

    test(
      'define tooltipBusca como boulder quando pico é focado em boulders',
      () {
        final setor = Setor(
          nome: 'Setor Boulder',
          escaladas: [Escalada(boulder: Boulder(nome: 'V3 dos Sonhos'))],
        );
        pico.setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        expect(vm.tooltipBusca, 'Buscar boulder');
        vm.dispose();
      },
    );

    test('obtém tamanhoFormatado e data de atualização do dataset', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': cragId,
            'nome': 'Pedra do Baú',
            'tamanho_bytes': 15 * 1024 * 1024,
            'tamanhoFormatado': '15.0 MB',
            'url': 'https://exemplo.com/bau.zip',
          },
        ],
        downloadedPicos: [],
      );

      repositorio.indiceData.value = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = cragId
            ..nome = 'Pedra do Baú'
            ..timestampUpdate = Timestamp.fromDateTime(
              DateTime(2026, 5, 20, 14, 30),
            ),
        );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.tamanhoFormatado, '15.0 MB');
      expect(vm.textoUltimaAtualizacao, contains('20/05/2026 às 14:30'));
      vm.dispose();
    });
  });

  group('PicoViewModel - Interceptação e Ciclo de Vida de Download', () {
    test(
      'deveInterceptarSaida retorna falso quando permanece no mesmo croqui',
      () {
        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        expect(vm.deveInterceptarSaida(staysInSameCroqui: true), isFalse);
        vm.dispose();
      },
    );

    test('deveInterceptarSaida retorna falso quando croqui está baixado', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [
          {'id': cragId, 'nome': 'Pedra do Baú'},
        ],
      );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.isDownloaded, isTrue);
      expect(vm.deveInterceptarSaida(staysInSameCroqui: false), isFalse);
      vm.dispose();
    });

    test(
      'deveInterceptarSaida retorna verdadeiro quando não baixado e sai do croqui',
      () {
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {'id': cragId, 'nome': 'Pedra do Baú'},
          ],
          downloadedPicos: [],
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        expect(vm.isDownloaded, isFalse);
        expect(vm.deveInterceptarSaida(staysInSameCroqui: false), isTrue);
        vm.dispose();
      },
    );

    test(
      'excluirPico transiciona croqui para sessão online e remove arquivo local no DatasetRepository real',
      () async {
        final (_, syncService, _) = await iniciarServidorESyncReal(
          croquiRemoto: croqui,
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        final baixou = await vm.baixarPico(syncService: syncService);
        expect(baixou, isTrue);
        expect(repositorio.isPicoDownloaded(cragId), isTrue);

        final sucesso = await vm.excluirPico();

        expect(sucesso, isTrue);
        expect(repositorio.isPicoDownloaded(cragId), isFalse);
        expect(
          repositorio.gerenciadorSessaoOnline.obterCroquiOnline(cragId),
          isNotNull,
        );
        vm.dispose();
      },
    );

    test('baixarPico executa download real com sucesso e atualiza estado', () async {
      final (_, syncService, _) = await iniciarServidorESyncReal(
        croquiRemoto: croqui,
      );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.isDownloaded, isFalse);
      final resultado = await vm.baixarPico(syncService: syncService);

      expect(resultado, isTrue);
      expect(vm.isDownloaded, isTrue);
      expect(vm.isInitiallyDownloaded, isTrue);
      vm.dispose();
    });

    test(
      'baixarPico não lança FlutterError quando PicoViewModel sofre dispose durante a atualização reativa do activeDataset',
      () async {
        final (_, syncService, _) = await iniciarServidorESyncReal(
          croquiRemoto: croqui,
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        // Simula o comportamento exato do PageListenableBuilder / didUpdateWidget (ou do botão Salvar e Sair):
        // Quando SyncService.downloadCrag atualiza o activeDataset antes do término de ServicoDownloadSegundoPlano,
        // a página reconstrói com um novo ViewModel e descarta a instância anterior ainda suspensa no await.
        void descartarAoAtualizarDataset() {
          if (repositorio.isPicoDownloaded(cragId)) {
            repositorio.activeDataset.removeListener(descartarAoAtualizarDataset);
            vm.dispose();
          }
        }

        repositorio.activeDataset.addListener(descartarAoAtualizarDataset);

        final resultado = await vm.baixarPico(syncService: syncService);
        expect(resultado, isTrue);
        expect(repositorio.isPicoDownloaded(cragId), isTrue);
      },
    );

    test(
      'excluirPico não lança FlutterError quando PicoViewModel sofre dispose durante a atualização reativa do activeDataset',
      () async {
        final (_, syncService, _) = await iniciarServidorESyncReal(
          croquiRemoto: croqui,
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
        );

        await vm.baixarPico(syncService: syncService);
        expect(repositorio.isPicoDownloaded(cragId), isTrue);

        // Quando deleteCrag atualiza o activeDataset, o PageListenableBuilder reconstrói
        // e descarta o PicoViewModel antigo antes do retorno final de excluirPico().
        void descartarAoExcluirDoDataset() {
          if (!repositorio.isPicoDownloaded(cragId)) {
            repositorio.activeDataset.removeListener(descartarAoExcluirDoDataset);
            vm.dispose();
          }
        }

        repositorio.activeDataset.addListener(descartarAoExcluirDoDataset);

        final resultado = await vm.excluirPico();
        expect(resultado, isTrue);
        expect(repositorio.isPicoDownloaded(cragId), isFalse);
      },
    );

    test(
      'PicoViewModel utiliza ServicoCroquiOnline compartilhado sem vazamento de polling',
      () {
        final servico = ServicoCroquiOnline(
          sessaoOnline: repositorio.gerenciadorSessaoOnline,
        );

        final vm1 = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
          servicoCroquiOnline: servico,
        );

        expect(servico.isPollingAtivo(cragId), isFalse);

        vm1.dispose();
        expect(servico.isPollingAtivo(cragId), isFalse);
      },
    );

    test(
      'PicoViewModel.dispose() não descarta o ServicoCroquiOnline compartilhado nem fecha seu cliente HTTP',
      () {
        final clienteRastreavel = _ClienteHttpRastreavel();
        final servico = ServicoCroquiOnline(
          client: ClienteHttpAresta.paraTestes(clienteRastreavel),
          sessaoOnline: repositorio.gerenciadorSessaoOnline,
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
          servicoCroquiOnline: servico,
        );

        vm.dispose();

        expect(clienteRastreavel.foiFechado, isFalse);
      },
    );

    test(
      'iniciarPollingOnlineSeNecessario notifica atualização na UI (modo oficial) e pulso de recarregamento (modo experimental) ao receber 200 OK',
      () async {
        final croquiNovo = Croqui()
          ..id = cragId
          ..nome = 'Pedra do Baú V2'
          ..picos.add(pico);
        final clienteRastreavel = _ClienteHttpRastreavel(
          bytesResposta: croquiNovo.writeToBuffer(),
          headersResposta: {'etag': '"etag-v2"'},
        );
        final servico = _ServicoCroquiOnlineComGatilho(
          client: ClienteHttpAresta.paraTestes(clienteRastreavel),
          sessaoOnline: repositorio.gerenciadorSessaoOnline,
          verificarPicoBaixado: (id) => repositorio.isPicoDownloaded(id),
        );

        repositorio.gerenciadorSessaoOnline.registrarCroquiOnline(
          cragId,
          croqui,
          etag: '"etag-v1"',
        );
        repositorio.activeDataset.value = TopoDataset(
          availablePicos: [
            {
              'id': cragId,
              'nome': 'Pedra do Baú',
              'url': 'https://exemplo.com/bau.binarypb',
            },
          ],
          downloadedPicos: [],
        );

        final vm = PicoViewModel(
          pico: pico,
          croqui: croqui,
          cragId: cragId,
          datasetRepo: repositorio,
          servicoCroquiOnline: servico,
        );

        expect(servico.isPollingAtivo(cragId), isTrue);
        expect(servico.dispararTickPolling, isNotNull);

        // 1. Modo oficial: dispara o tick de verificação ETag e valida notificação de croqui atualizado
        await servico.dispararTickPolling!();
        expect(
          repositorio.notificadorCroquiAtualizado.value,
          equals('Pedra do Baú'),
        );

        // 2. Modo experimental: dispara novamente e valida o pulso de recarregamento
        repositorio.editorDeCroqui.isExperimentalMode.value = true;
        repositorio.gerenciadorSessaoOnline.registrarCroquiOnline(
          cragId,
          croqui,
          etag: '"etag-v1"',
        );
        vm.iniciarPollingOnlineSeNecessario();
        final pulsoAntes =
            repositorio.editorDeCroqui.notificadorGatilhoRecarregamento.value;
        await servico.dispararTickPolling!();
        expect(
          repositorio.editorDeCroqui.notificadorGatilhoRecarregamento.value,
          greaterThan(pulsoAntes),
        );

        vm.dispose();
        expect(servico.isPollingAtivo(cragId), isFalse);

        // 3. Mesmo que uma requisição de ETag já em voo retorne após vm.dispose() (Issue #14),
        // o callback aoAtualizar não deve lançar FlutterError ao invocar notifyListeners().
        await servico.dispararTickPolling!();
      },
    );
  });

  group('PicoViewModel - Visibilidade de Subpáginas e URL Google Maps', () {
    test('temExplorarLocal reflete conteúdo existente ou ausente', () {
      final picoVazio = Pico();
      final croquiVazio = Croqui();
      final vmVazio = PicoViewModel(
        pico: picoVazio,
        croqui: croquiVazio,
        cragId: cragId,
        datasetRepo: repositorio,
      );
      expect(vmVazio.temExplorarLocal, isFalse);
      vmVazio.dispose();

      final picoComCoord = Pico()
        ..localizacao = (Coordenada()
          ..latitude = -198500000
          ..longitude = -436000000);
      final vmComCoord = PicoViewModel(
        pico: picoComCoord,
        croqui: croquiVazio,
        cragId: cragId,
        datasetRepo: repositorio,
      );
      expect(vmComCoord.temExplorarLocal, isTrue);
      vmComCoord.dispose();
    });

    test('temComunidade reflete conteúdo existente ou ausente', () {
      final picoVazio = Pico();
      final croquiVazio = Croqui();
      final vmVazio = PicoViewModel(
        pico: picoVazio,
        croqui: croquiVazio,
        cragId: cragId,
        datasetRepo: repositorio,
      );
      expect(vmVazio.temComunidade, isFalse);
      vmVazio.dispose();

      final croquiComComunidade = Croqui()
        ..botoes.add(
          Botao(
            texto: 'Comunidade e Contato',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
        );
      final vmComComunidade = PicoViewModel(
        pico: picoVazio,
        croqui: croquiComComunidade,
        cragId: cragId,
        datasetRepo: repositorio,
      );
      expect(vmComComunidade.temComunidade, isTrue);
      vmComComunidade.dispose();
    });

    test('urlGoogleMaps delega para resolverUrlGoogleMapsPico', () {
      final picoComUrl = Pico()..urlGoogleMaps = 'https://maps.app.goo.gl/teste';
      final vm = PicoViewModel(
        pico: picoComUrl,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );
      expect(vm.urlGoogleMaps, 'https://maps.app.goo.gl/teste');
      vm.dispose();
    });
  });
}
