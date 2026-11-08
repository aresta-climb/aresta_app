// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';
import '../../mocks/mock_telemetria.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CaminhosTesteHomeVm extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _CaminhosTesteHomeVm(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
  @override
  Future<String?> getTemporaryPath() async => '$dir/tmp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late EditorDeCroqui editor;
  late DatasetRepository repositorio;
  late SyncService servicoSync;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_home_vm_test_');
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HomeViewModel Tests', () {
    test('inicia em estado de carregamento quando dataset é nulo', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      expect(vm.carregando, isTrue);
      expect(vm.picosProximos, isEmpty);
      vm.dispose();
    });

    test('reage a atualizações no activeDataset e calcula picos mais próximos ordenados por distância', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      final picosIndice = [
        ResumoCroqui(
          id: 'bau',
          nome: 'Pedra do Baú',
          caminhoRelativo: 'sp/bau',
          localizacao: Coordenada(
            latitude: -226844440,
            longitude: -456633330,
          ),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 4,
            totalEscaladas: 40,
          ),
        ),
        ResumoCroqui(
          id: 'cuscuzeiro',
          nome: 'Cuscuzeiro',
          caminhoRelativo: 'sp/cuscuzeiro',
          localizacao: Coordenada(
            latitude: -221000000,
            longitude: -477000000,
          ),
          precomputados: PrecomputadosResumoCroqui(
            totalSetores: 2,
            totalEscaladas: 20,
          ),
        ),
      ];

      repositorio.indiceData.value = Indice(croquis: picosIndice);
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: picosIndice,
      );

      // Usuário próximo a São Bento do Sapucaí (perto da Pedra do Baú)
      vm.atualizarLocalizacaoUsuario(-22.68, -45.66);

      expect(vm.carregando, isFalse);
      expect(vm.picosProximos.length, equals(2));
      expect(vm.picosProximos.first.id, equals('bau'));
      expect(vm.picosProximos.first.distanciaKm, isNotNull);
      expect(vm.picosProximos.first.distanciaKm!, lessThan(vm.picosProximos.last.distanciaKm!));

      vm.dispose();
    });

    test('estaBaixado verifica presença em croquisBaixados', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      final croquiBaixado = Croqui(id: 'cipo', nome: 'Serra do Cipó');
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        croquisBaixados: [croquiBaixado],
      );

      expect(vm.estaBaixado('cipo'), isTrue);
      expect(vm.estaBaixado('outro'), isFalse);

      vm.dispose();
    });

    test('temMaisPicosParaExplorar retorna verdadeiro apenas quando há mais de 6 picos disponíveis', () {
      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      expect(vm.temMaisPicosParaExplorar, isFalse);

      final seisPicos = List.generate(
        6,
        (i) => ResumoCroqui(
          id: 'pico_$i',
          nome: 'Pico $i',
          localizacao: Coordenada(
            latitude: -220000000 - i * 1000000,
            longitude: -450000000,
          ),
        ),
      );
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: seisPicos,
      );
      vm.atualizarLocalizacaoUsuario(-22.0, -45.0);
      expect(vm.temMaisPicosParaExplorar, isFalse);

      final setePicos = [
        ...seisPicos,
        ResumoCroqui(
          id: 'pico_6',
          nome: 'Pico 6',
          localizacao: Coordenada(
            latitude: -230000000,
            longitude: -450000000,
          ),
        ),
      ];
      repositorio.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: setePicos,
      );
      expect(vm.picosProximos.length, equals(6));
      expect(vm.temMaisPicosParaExplorar, isTrue);

      vm.dispose();
    });

    test('atualizarLocalizacaoUsuario propaga coordenadas para o callback aoAtualizarLocalizacao', () {
      double? latRecebida;
      double? lonRecebida;

      final vm = HomeViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
        aoAtualizarLocalizacao: (lat, lon) {
          latRecebida = lat;
          lonRecebida = lon;
        },
      );

      vm.atualizarLocalizacaoUsuario(-22.5, -44.8);

      expect(latRecebida, equals(-22.5));
      expect(lonRecebida, equals(-44.8));
      expect(vm.latitudeUsuario, equals(-22.5));
      expect(vm.longitudeUsuario, equals(-44.8));

      vm.dispose();
    });

    test(
      'expõe exibirBotaoPerfil e interacoesUsuarioAtivasListenable encapsulando ControladorInteracoesUsuario',
      () async {
        SharedPreferences.setMockInitialValues({});
        ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
        addTearDown(ConfiguracaoRecursos.redefinirParaTestes);

        final controlador = ControladorInteracoesUsuario();
        await controlador.inicializar();

        final vm = HomeViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
          controladorInteracoes: controlador,
        );

        expect(vm.exibirBotaoPerfil, isTrue);
        expect(vm.interacoesUsuarioAtivasListenable.value, isTrue);

        await controlador.definirInteracoesAtivas(false);
        expect(vm.exibirBotaoPerfil, isFalse);
        expect(vm.interacoesUsuarioAtivasListenable.value, isFalse);

        vm.dispose();
      },
    );

    test(
      'picosProximos utiliza a malha rodoviária de calculadoraDistanciaEstrada e reage quando a malha é atualizada',
      () {
        final vm = HomeViewModel(
          datasetRepo: repositorio,
          syncService: servicoSync,
        );

        final picosIndice = [
          ResumoCroqui(
            id: 'pico_serra',
            nome: 'Pico Atrás da Serra',
            localizacao: Coordenada(
              latitude: -201000000,
              longitude: -440000000,
            ),
          ),
          ResumoCroqui(
            id: 'pico_BR',
            nome: 'Pico na Rodovia',
            localizacao: Coordenada(
              latitude: -202000000,
              longitude: -440000000,
            ),
          ),
        ];

        repositorio.activeDataset.value = ConjuntoDadosCroqui(
          metadadosDisponiveis: picosIndice,
        );
        vm.atualizarLocalizacaoUsuario(-20.0, -44.0);

        expect(vm.picosProximos.first.id, equals('pico_serra'));

        repositorio.calculadoraDistanciaEstrada.value =
            CalculadoraDistanciaEstrada(
          nos: const <NoEstrada>[
            NoEstrada(
              noOsmId: 50,
              latitude: -20.001,
              longitude: -44.000,
              distanciasPorCroquiMetros: <String, int>{
                'pico_serra': 58000,
                'pico_BR': 24000,
              },
            ),
          ],
        );

        expect(vm.picosProximos.first.id, equals('pico_BR'));
        expect(vm.picosProximos.first.distanciaKm, closeTo(24.14, 0.2));
        expect(vm.picosProximos.last.id, equals('pico_serra'));
        expect(vm.picosProximos.last.distanciaKm, closeTo(58.14, 0.2));
        vm.dispose();
      },
    );

    testWidgets(
      'cobre downloadingCrags, acionarVerMaisProximos, sincronizarManual, baixarPico e abrirPico',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        RegistroPrimeiraVisita.resetForTesting();
        PathProviderPlatform.instance = _CaminhosTesteHomeVm(tempDir.path);
        final mockTelemetry = MockTelemetryService();
        TelemetryService.instance = mockTelemetry;

        final clienteHttp = ClienteHttpAresta.paraTestes(
          MockClient(( _) async => http.Response('Offline', 500)),
        );
        final syncLocal = SyncService(
          datasetRepository: repositorio,
          client: clienteHttp,
        );

        var verMaisAcionado = false;
        final vm = HomeViewModel(
          datasetRepo: repositorio,
          syncService: syncLocal,
          aoVerMaisProximos: () => verMaisAcionado = true,
        );
        addTearDown(vm.dispose);

        expect(vm.downloadingCrags, same(syncLocal.downloadingCrags));
        vm.acionarVerMaisProximos();
        expect(verMaisAcionado, isTrue);

        // Dataset com metadados vazios mas sem coordenadas retorna vazio
        repositorio.activeDataset.value = ConjuntoDadosCroqui.vazio();
        expect(vm.picosProximos, isEmpty);

        // Com picos disponíveis mas sem localização do usuário retorna vazio
        final resumo = ResumoCroqui(
          id: 'pico_dl',
          nome: 'Pico DL',
          caminhoRelativo: 'picos/pico_dl/compilado.binarypb',
          localizacao: Coordenada(latitude: -200000000, longitude: -440000000),
        );
        repositorio.indiceData.value = Indice(croquis: [resumo]);
        repositorio.activeDataset.value = ConjuntoDadosCroqui(
          metadadosDisponiveis: [resumo],
        );
        expect(vm.picosProximos, isEmpty);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        final context = tester.element(find.byType(Scaffold));

        await tester.runAsync(() async {
          await vm.sincronizarManual(context);
          await vm.baixarPico('pico_dl');
          await vm.baixarPico('pico_fallback_inexistente');

          // abrirPico com dataset nulo, encontrado e fallback orElse
          final datasetSalvo = repositorio.activeDataset.value;
          repositorio.activeDataset.value = null;
          await vm.abrirPico(context, 'pico_dl');

          repositorio.activeDataset.value = datasetSalvo;
          await vm.abrirPico(context, 'pico_dl');
          await vm.abrirPico(context, 'pico_ausente');
        });
        await tester.pump();
      },
    );
  });
}
