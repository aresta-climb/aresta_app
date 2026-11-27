// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import '../../navigation/wrapper_navegacao_arvore.dart';
import '../../theme/temas.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/cliente_cadenas_supabase.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../comunidade/cliente_fila_interacoes_supabase.dart';
import '../comunidade/repositorio_interacoes_via.dart';
import '../editor_croqui.dart';
import '../http/sync_service.dart';
import '../repositorio_dataset.dart';
import 'configuracao_smoke_ci.dart';
import 'executor_jornada_smoke.dart';

/// Entrypoint dedicado exclusivamente à compilação descartável de Smoke Test pós-build no CI.
///
/// Os pacotes oficiais publicados nas lojas (`.aab` e `.ipa`) são compilados a partir de
/// `lib/main.dart`, que não importa este módulo — garantindo remoção física total pelo
/// tree-shaking AOT do Dart e pelo R8/Xcode nos celulares de usuários reais.
void main() {
  unawaited(iniciarSmokeCi());
}

/// Inicializa a árvore real do aplicativo e dispara a jornada automatizada contra o loopback local.
Future<void> iniciarSmokeCi() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configuracao = await ConfiguracaoSmokeCi.exigirDoCanalNativo();

  final editor = EditorDeCroqui();
  await editor.loadFromDisk();
  final datasetRepo = DatasetRepository(editorDeCroqui: editor);
  final syncService = SyncService(datasetRepository: datasetRepo);
  final repoCaderneta = RepositorioCadernetaLocal(
    clienteCadenas: ClienteCadenasSupabase(
      resolvedorBaseUrl: () => configuracao.uriBase.toString(),
      resolvedorAnonKey: () => 'smoke-anon-key-ci',
    ),
  );
  // ignore: invalid_use_of_visible_for_testing_member
  RepositorioCadernetaLocal.instancia = repoCaderneta;

  final servicoAuth = ServicoAutenticacaoLocal(
    repositorio: repoCaderneta,
    obterUrlSupabase: () => configuracao.uriBase.toString(),
    obterAnonKeySupabase: () => 'smoke-anon-key-ci',
  );
  ServicoAutenticacaoLocal.instancia = servicoAuth;

  final repoInteracoes = RepositorioInteracoesViaMemoria(
    repositorioCaderneta: repoCaderneta,
    servicoAutenticacao: servicoAuth,
    clienteFila: ClienteFilaInteracoesSupabase(
      resolvedorBaseUrl: () => configuracao.uriBase.toString(),
      resolvedorAnonKey: () => 'smoke-anon-key-ci',
    ),
  );
  // ignore: invalid_use_of_visible_for_testing_member
  RepositorioInteracoesViaMemoria.instancia = repoInteracoes;

  runApp(
    BetterFeedback(
      child: MaterialApp(
        title: 'Aresta Climb Smoke CI',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: construirTemaClaro(),
        darkTheme: construirTemaEscuro(),
        home: TreeNavigationWrapper(
          key: TreeNavigationWrapper.navKey,
          datasetRepo: datasetRepo,
          syncService: syncService,
        ),
      ),
    ),
  );

  final executor = ExecutorJornadaSmoke(
    configuracao: configuracao,
    datasetRepo: datasetRepo,
    syncService: syncService,
    repositorioCaderneta: repoCaderneta,
    servicoAutenticacao: servicoAuth,
    repositorioInteracoes: repoInteracoes,
  );
  await executor.executarEEnviarRelatorio();
}
