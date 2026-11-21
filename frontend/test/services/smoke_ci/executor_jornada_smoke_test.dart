// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/application_managers/feedback/orquestrador_feedback.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/autenticacao/autenticador_nativo.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/smoke_ci/configuracao_smoke_ci.dart';
import 'package:frontend/services/smoke_ci/executor_jornada_smoke.dart';
import '../../mocks/mock_geolocator_platform.dart';
import '../autenticacao/servico_autenticacao_fake.dart';
import '../../../tool/release_tools/servidor_smoke_ci.dart';

class _PathProviderTemp extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _PathProviderTemp(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;

  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late Directory tempDir;

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FeedbackOrchestrator.debugIsConfiguredOverride = false;
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    ControladorInteracoesUsuario.redefinirParaTestes();
    AutenticadorNativoCanal.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
    tempDir = Directory.systemTemp.createTempSync('smoke_executor_aresta_');
    PathProviderPlatform.instance = _PathProviderTemp(tempDir.path);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(AutenticadorNativoCanal.nomeCanal),
          null,
        );
    SyncService.baseUrlOverride = null;
    FeedbackOrchestrator.debugIsConfiguredOverride = null;
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    AutenticadorNativoCanal.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  void registrarMockCanalAutenticacaoOidc(
    ServidorSmokeCi servidor, {
    bool falhar = false,
  }) {
    const canalAuth = MethodChannel(AutenticadorNativoCanal.nomeCanal);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalAuth, (MethodCall call) async {
      if (call.method == 'solicitarIdTokenGoogle') {
        if (falhar) {
          return <String, dynamic>{'erro': 'Falha simulada no CredentialManager'};
        }
        final client = HttpClient();
        final req = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
        );
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(<String, dynamic>{
          'rawNonce': 'nonce_canal_nativo',
          'webClientId': 'smoke-web-client',
        }));
        final resp = await req.close();
        final mapa = jsonDecode(
          await utf8.decoder.bind(resp).join(),
        ) as Map<String, dynamic>;
        client.close(force: true);
        return mapa;
      }
      return null;
    });
  }

  testWidgets(
    'executa jornada completa: Termos Legais, sincronização e abertura de Croqui Protobuf, navegação UI, login OIDC, perfil, Cadena e relatório',
    (WidgetTester tester) async {
      HttpOverrides.global = null;
      final editor = EditorDeCroqui();
      final datasetRepo = DatasetRepository(editorDeCroqui: editor);
      final syncService = SyncService(datasetRepository: datasetRepo);
      final repoCaderneta = RepositorioCadernetaLocal();

      await tester.pumpWidget(
        BetterFeedback(
          child: MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: syncService,
            ),
          ),
        ),
      );
      await tester.pump();

      late Map<String, dynamic> resultadoLocal;
      late Map<String, dynamic> relatorioServidor;
      late ServicoAutenticacaoLocal servicoAuth;

      await tester.runAsync(() async {
        final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok_exec_1');
        try {
          registrarMockCanalAutenticacaoOidc(servidor);
          final cfg = ConfiguracaoSmokeCi.validar(
            servidorUrl: servidor.uriLocalHost.toString(),
            token: 'tok_exec_1',
          );
          servicoAuth = ServicoAutenticacaoLocal(
            repositorio: repoCaderneta,
            obterUrlSupabase: () => cfg.uriBase.toString(),
            obterAnonKeySupabase: () => 'smoke-anon-key',
          );
          ServicoAutenticacaoLocal.instancia = servicoAuth;

          final futuroRelatorio = servidor.aguardarRelatorio();
          final executor = ExecutorJornadaSmoke(
            configuracao: cfg,
            datasetRepo: datasetRepo,
            syncService: syncService,
            repositorioCaderneta: repoCaderneta,
            servicoAutenticacao: servicoAuth,
            aguardarFrameUi: () => Future<void>.delayed(
              const Duration(milliseconds: 5),
            ),
          );
          resultadoLocal = await executor.executarEEnviarRelatorio();
          relatorioServidor = await futuroRelatorio;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        } finally {
          await servidor.encerrar();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(resultadoLocal['sucesso'], isTrue);
      expect(relatorioServidor['sucesso'], isTrue);
      expect(
        relatorioServidor['etapas'],
        containsAll(<String>[
          'termos_legais_aceitos',
          'croqui_protobuf_aberto',
          'arvore_ui_navegada',
          'login_oidc_concluido',
          'perfil_remoto_sincronizado',
          'cadena_registrada_e_contabilizada',
          'caderneta_ui_renderizada',
        ]),
      );
      expect(servicoAuth.estaAutenticado, isTrue);
      expect(repoCaderneta.calcularEstatisticas().totalCadenas, 1);
    },
  );

  testWidgets(
    'reporta falha estruturada (sucesso=false) ao servidor quando o login OIDC falha',
    (WidgetTester tester) async {
      HttpOverrides.global = null;
      late Map<String, dynamic> resultado;
      late Map<String, dynamic> recebido;

      await tester.runAsync(() async {
        final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok_exec_2');
        try {
          registrarMockCanalAutenticacaoOidc(servidor, falhar: true);
          final cfg = ConfiguracaoSmokeCi.validar(
            servidorUrl: servidor.uriLocalHost.toString(),
            token: 'tok_exec_2',
          );
          final editor = EditorDeCroqui();
          final datasetRepo = DatasetRepository(editorDeCroqui: editor);
          final syncService = SyncService(datasetRepository: datasetRepo);
          final repoCaderneta = RepositorioCadernetaLocal();
          final servicoAuth = ServicoAutenticacaoLocal(
            repositorio: repoCaderneta,
            obterUrlSupabase: () => cfg.uriBase.toString(),
            obterAnonKeySupabase: () => 'smoke-anon-key',
          );

          final futuroRelatorio = servidor.aguardarRelatorio();
          final executor = ExecutorJornadaSmoke(
            configuracao: cfg,
            datasetRepo: datasetRepo,
            syncService: syncService,
            repositorioCaderneta: repoCaderneta,
            servicoAutenticacao: servicoAuth,
          );
          resultado = await executor.executarEEnviarRelatorio();
          recebido = await futuroRelatorio;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        } finally {
          await servidor.encerrar();
        }
      });

      expect(resultado['sucesso'], isFalse);
      expect(recebido['sucesso'], isFalse);
      expect((recebido['erros'] as List<dynamic>).isNotEmpty, isTrue);
    },
  );

  testWidgets(
    'reporta falha de invariante quando serviço retorna perfil sem vínculo autenticado',
    (WidgetTester tester) async {
      HttpOverrides.global = null;
      late Map<String, dynamic> resultado;
      late Map<String, dynamic> recebido;

      await tester.runAsync(() async {
        final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok_exec_3');
        try {
          final cfg = ConfiguracaoSmokeCi.validar(
            servidorUrl: servidor.uriLocalHost.toString(),
            token: 'tok_exec_3',
          );
          final editor = EditorDeCroqui();
          final datasetRepo = DatasetRepository(editorDeCroqui: editor);
          final syncService = SyncService(datasetRepository: datasetRepo);
          final repoCaderneta = RepositorioCadernetaLocal();
          final authInvalido = _ServicoAutenticacaoSemVinculo(repoCaderneta);

          final futuroRelatorio = servidor.aguardarRelatorio();
          final executor = ExecutorJornadaSmoke(
            configuracao: cfg,
            datasetRepo: datasetRepo,
            syncService: syncService,
            repositorioCaderneta: repoCaderneta,
            servicoAutenticacao: authInvalido,
          );
          resultado = await executor.executarEEnviarRelatorio();
          recebido = await futuroRelatorio;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        } finally {
          await servidor.encerrar();
        }
      });

      expect(resultado['sucesso'], isFalse);
      expect(recebido['sucesso'], isFalse);
      expect(
        (recebido['erros'] as List<dynamic>).join('\n'),
        contains('Perfil não ficou autenticado'),
      );
    },
  );
}

class _ServicoAutenticacaoSemVinculo extends ServicoAutenticacaoFake {
  _ServicoAutenticacaoSemVinculo(RepositorioCaderneta repo)
      : super(repositorio: repo);

  @override
  Future<PerfilEscalador> entrarComGoogle() async => obterPerfil();
}
