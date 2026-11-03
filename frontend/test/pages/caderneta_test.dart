// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/pages/caderneta.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/perfil_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  Widget criarCadernetaWidget({PerfilViewModel? viewModel}) {
    final vm =
        viewModel ??
        PerfilViewModel(
          repositorio: repositorio,
          obterGrauDaVia: (uid) => uid == 'via-1' ? '7a' : 'V4',
          obterNomeDaVia: (uid) =>
              uid == 'via-1' ? 'Fenda do Crepúsculo' : 'Bloco Lunar',
        );

    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: CadernetaPage(viewModel: vm),
    );
  }

  group('CadernetaPage', () {
    testWidgets('renderiza pirâmide de graus e estado vazio quando não há cadenas', (tester) async {
      await tester.pumpWidget(criarCadernetaWidget());
      await tester.pumpAndSettle();

      expect(find.text('MINHA CADERNETA'), findsOneWidget);
      expect(find.text('Total de Cadenas'), findsOneWidget);
      expect(find.text('Taxa À Vista/Flash'), findsOneWidget);
      expect(find.text('Maior Grau (Vias)'), findsOneWidget);
      expect(find.text('Maior Grau (Boulders)'), findsOneWidget);
      expect(find.text('Pirâmide de Graduação'), findsOneWidget);
      expect(
        find.text('Nenhuma ascensão registrada nesta modalidade.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Nenhuma ascensão registrada ainda'),
        findsOneWidget,
      );
    });

    testWidgets('renderiza histórico com cadenas e permite cancelar ou confirmar exclusão', (tester) async {
      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
        notasPrivadas: 'Super suave',
      );
      final c2 = Cadena.criar(
        escaladaUid: 'via-2',
        dataAscensao: DateTime(2026, 9, 15),
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.boulder,
      );

      await repositorio.salvarCadena(c1);
      await repositorio.salvarCadena(c2);

      await tester.pumpWidget(criarCadernetaWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fenda do Crepúsculo'), findsOneWidget);
      expect(find.text('Flash'), findsOneWidget);
      expect(find.text('Tentativa'), findsOneWidget);
      expect(find.text('“Super suave”'), findsOneWidget);

      final btnExcluir = find.byKey(Key('btn_excluir_cadena_${c1.id}'));
      await tester.ensureVisible(btnExcluir);

      // Toca para excluir e cancela
      await tester.tap(btnExcluir);
      await tester.pumpAndSettle();
      expect(find.text('Excluir Ascensão?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir Ascensão?'), findsNothing);
      expect(find.text('Fenda do Crepúsculo'), findsOneWidget);

      // Toca novamente e confirma
      await tester.tap(btnExcluir);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirmar_exclusao')));
      await tester.pumpAndSettle();

      expect(find.text('Fenda do Crepúsculo'), findsNothing);
      expect(repositorio.cadenasNotifier.value.length, 1);
    });

    testWidgets('permite editar uma ascensão existente pelo histórico e exibe snackbar de confirmação', (tester) async {
      final c1 = Cadena(
        id: 'cadena-edicao-1',
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 2,
        notasPrivadas: 'Faltou força no crux',
      );
      await repositorio.salvarCadena(c1);

      await tester.pumpWidget(criarCadernetaWidget());
      await tester.pumpAndSettle();

      final btnEditar = find.byKey(const Key('btn_editar_cadena_cadena-edicao-1'));
      await tester.ensureVisible(btnEditar);
      await tester.tap(btnEditar);
      await tester.pumpAndSettle();

      expect(find.text('Editar Ascensão'), findsOneWidget);
      expect(find.text('Fenda do Crepúsculo'), findsWidgets);

      await tester.tap(find.text('Trabalhado'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_notas_privadas')),
        'Encadenada com beta novo!',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_salvar_cadena')));
      await tester.pumpAndSettle();

      expect(find.text('Ascensão atualizada na caderneta!'), findsOneWidget);
      expect(find.text('“Encadenada com beta novo!”'), findsOneWidget);
      expect(repositorio.cadenasNotifier.value.first.tipoAscensao, TipoAscensao.trabalhado);
    });

    testWidgets('delega ações de edição, exclusão e toque na via para callbacks customizados do PerfilViewModel', (tester) async {
      final c1 = Cadena(
        id: 'cadena-cb-1',
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
      );
      await repositorio.salvarCadena(c1);

      Cadena? editada;
      Cadena? excluida;
      Cadena? tocada;

      final vm = PerfilViewModel(
        repositorio: repositorio,
        obterNomeDaVia: (_) => 'Fenda do Crepúsculo',
        obterGrauDaVia: (_) => '7a',
        aoEditarCadena: (c) => editada = c,
        aoExcluirCadena: (c) => excluida = c,
        aoTocarVia: (c) => tocada = c,
      );

      await tester.pumpWidget(criarCadernetaWidget(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_historico_cadena_cadena-cb-1')));
      await tester.pump();
      expect(tocada, equals(c1));

      await tester.tap(find.byKey(const Key('btn_editar_cadena_cadena-cb-1')));
      await tester.pump();
      expect(editada, equals(c1));

      await tester.tap(find.byKey(const Key('btn_excluir_cadena_cadena-cb-1')));
      await tester.pump();
      expect(excluida, equals(c1));
    });

    testWidgets('tocar em item do histórico navega para a ViaPage quando encontrada ou exibe snackbar quando indisponível', (tester) async {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      ControladorInteracoesUsuario.redefinirParaTestes();
      addTearDown(() {
        ConfiguracaoRecursos.redefinirParaTestes();
        ControladorInteracoesUsuario.redefinirParaTestes();
      });

      final cEncontrada = Cadena(
        id: 'cadena-nav-ok',
        escaladaUid: 'uidViaEncontrada',
        dataAscensao: DateTime(2026, 10, 1),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
      );
      final cAusente = Cadena(
        id: 'cadena-nav-ausente',
        escaladaUid: 'uidViaInexistente',
        dataAscensao: DateTime(2026, 9, 1),
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.guiado,
      );
      await repositorio.salvarCadena(cEncontrada);
      await repositorio.salvarCadena(cAusente);

      final escalada = Escalada()
        ..uid = 'uidViaEncontrada'
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Encontrada');
      final setor = Setor()
        ..nome = 'Setor Sol'
        ..escaladas.add(escalada);
      final pico = Pico()
        ..nome = 'Pico Sol'
        ..setoresOuGrupos.add(
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
        );
      final croqui = Croqui()
        ..id = 'pico_sol'
        ..nome = 'Pico Sol'
        ..picos.add(pico);

      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      datasetRepo.activeDataset.value = ConjuntoDadosCroqui(
        picosBaixados: [
          ResumoPico(
            id: 'pico_sol',
            nome: 'Pico Sol',
            local: 'MG',
            isDownloaded: true,
            pico: pico,
            croqui: croqui,
          ),
        ],
        croquisBaixados: [croqui],
      );
      final syncService = SyncService(datasetRepository: datasetRepo);
      syncService.syncStatus.value = SyncStatus.updated;
      final treeController = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(noAtual: CadernetaNode(HomeNode())),
      );

      final vm = PerfilViewModel(
        repositorio: repositorio,
        obterNomeDaVia: (uid) =>
            uid == 'uidViaEncontrada' ? 'Via Encontrada' : 'Via Ausente',
        obterGrauDaVia: (_) => '7a',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: CadernetaPage(viewModel: vm),
          ),
        ),
      );
      await tester.pump();

      final itemAusente = find.byKey(const Key('item_historico_cadena_cadena-nav-ausente'));
      await tester.ensureVisible(itemAusente);
      await tester.tap(itemAusente);
      await tester.pump();

      expect(find.text('Via não disponível offline no momento.'), findsOneWidget);
      expect(treeController.currentNode, isA<CadernetaNode>());

      final itemEncontrado = find.byKey(const Key('item_historico_cadena_cadena-nav-ok'));
      await tester.ensureVisible(itemEncontrado);
      await tester.tap(itemEncontrado);
      await tester.pump();

      expect(treeController.currentNode, isA<ViaNode>());
      expect(treeController.currentNode.parent, isA<CadernetaNode>());
    });

    testWidgets('CadernetaPage instancia e descarta viewModel interno quando não injetado', (tester) async {
      RepositorioCadernetaLocal.instancia = repositorio;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [AppColors.dark],
          ),
          home: const CadernetaPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MINHA CADERNETA'), findsOneWidget);

      // Desmonta a página para exercitar o dispose
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('não causa overflow em tela compacta (360x800) com cadeias e dados completos', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 1,
        notasPrivadas: 'Super suave no crux de reglete',
      );
      await repositorio.salvarCadena(c1);

      await tester.pumpWidget(criarCadernetaWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MINHA CADERNETA'), findsOneWidget);
      expect(find.text('Fenda do Crepúsculo'), findsOneWidget);
    });

    testWidgets('não causa overflow em tela ultracompacta (320x568) com escala de fonte 1.5x e pirâmide preenchida', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 1,
      );
      final c2 = Cadena.criar(
        escaladaUid: 'via-2',
        dataAscensao: DateTime(2026, 9, 21),
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 1,
      );
      await repositorio.salvarCadena(c1);
      await repositorio.salvarCadena(c2);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: CadernetaPage(
            viewModel: PerfilViewModel(
              repositorio: repositorio,
              obterGrauDaVia: (uid) => uid == 'via-1' ? '7a' : '8a',
              obterNomeDaVia: (uid) => uid == 'via-1' ? 'Fenda do Crepúsculo' : 'Via Lunar',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MINHA CADERNETA'), findsOneWidget);
      expect(find.text('Pirâmide de Graduação'), findsOneWidget);
      expect(find.text('Fenda do Crepúsculo'), findsOneWidget);
    });

    testWidgets('botão de voltar desempilha a CadernetaPage com sucesso', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CadernetaPage(
                      viewModel: PerfilViewModel(repositorio: repositorio),
                    ),
                  ),
                ),
                child: const Text('Abrir Caderneta'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Caderneta'));
      await tester.pumpAndSettle();
      expect(find.text('MINHA CADERNETA'), findsOneWidget);

      // Toca na seta de voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Confirma que CadernetaPage foi desempilhada
      expect(find.text('MINHA CADERNETA'), findsNothing);
      expect(find.text('Abrir Caderneta'), findsOneWidget);
    });
  });
}
