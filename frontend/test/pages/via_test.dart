// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/beta.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/secao_caderneta_via_view_model.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:frontend/widgets/caderneta/modal_registro_cadena.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/comunidade/repositorio_interacoes_via_fake.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    RepositorioInteracoesViaMemoria.redefinirParaTestes();
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    RepositorioInteracoesViaMemoria.redefinirParaTestes();
    ServicoCompartilhamento.restaurarPadrao();
  });

  Widget envolver(Widget pagina) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: pagina,
    );
  }

  testWidgets('ViaPage envolve o corpo em SafeArea inferior e expõe hierarquia de localização', (tester) async {
    final pico = Pico(nome: 'Pedra do Baú');
    final grupo = Grupo(nome: 'Face Leste');
    final setor = Setor(nome: 'Setor da Divisa');
    final escalada = Escalada(
      viaEsportiva: ViaEsportiva(
        nome: 'Sol e Chuva',
        destaque: true,
        dificuldade: GrauVia_GrauVia.BR_7A,
      ),
    );

    await tester.pumpWidget(
      envolver(
        ViaPage(
          escalada: escalada,
          cragId: 'crag1',
          pico: pico,
          setor: setor,
          grupo: grupo,
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.body, isA<SafeArea>());
    expect((scaffold.body as SafeArea).bottom, isTrue);

    expect(find.text('Sol e Chuva'), findsOneWidget);
    expect(find.text('ESPORTIVA'), findsOneWidget);
    expect(find.text('CLÁSSICA'), findsOneWidget);
    expect(find.textContaining('Face Leste > Setor da Divisa'), findsOneWidget);
    expect(find.text('Ver no croqui'), findsOneWidget);
    expect(find.text('GRAU OFICIAL'), findsOneWidget);
    expect(find.text('7a'), findsOneWidget);
  });

  testWidgets('ViaPage oculta alertas, consenso, caderneta e notas quando perfilHabilitado for false', (tester) async {
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
    final repoFake = RepositorioInteracoesViaFake()
      ..semearDados(
        'via-uid-123',
        DadosComunidadeVia(
          consensoGrau: const ConsensoGrauVia(grauSugerido: '7b', totalVotos: 5),
          alertasAtivos: [
            AlertaSegurancaVia.criar(
              escaladaUid: 'via-uid-123',
              categoria: CategoriaAlertaSeguranca.abelhasInsetos,
            ),
          ],
        ),
      );

    final escalada = Escalada(
      uid: 'via-uid-123',
      viaEsportiva: ViaEsportiva(
        nome: 'Fenda da Esperança',
        dificuldade: GrauVia_GrauVia.BR_7A,
      ),
    );
    final vm = ViaViewModel(
      escalada: escalada,
      repositorioInteracoes: repoFake,
    );
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      envolver(
        ViaPage(
          escalada: escalada,
          cragId: 'crag1',
          viewModel: vm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_reportar_alerta_via')), findsNothing);
    expect(find.byType(BolhaEmojiAlertaVia), findsNothing);
    expect(find.text('CONSENSO DA COMUNIDADE'), findsNothing);
    expect(find.text('Registrar Cadena / Tentativa'), findsNothing);
  });

  testWidgets('ViaPage permite reportar alerta pelo AppBar, exibe bolha vermelha flutuante e confirma Ainda está lá?', (tester) async {
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    final repoFake = RepositorioInteracoesViaFake();
    final escalada = Escalada(
      uid: 'via-uid-alerta1',
      viaEsportiva: ViaEsportiva(
        nome: 'Via das Abelhas',
        dificuldade: GrauVia_GrauVia.BR_6SUP,
      ),
    );
    final vm = ViaViewModel(
      escalada: escalada,
      repositorioInteracoes: repoFake,
    );
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      envolver(
        ViaPage(
          escalada: escalada,
          cragId: 'crag1',
          viewModel: vm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Reportar novo alerta pela barra superior
    await tester.tap(find.byKey(const Key('btn_reportar_alerta_via')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo_detalhe_alerta_via')),
      'Colmeia ativa no diedro',
    );
    await tester.tap(find.byKey(const Key('btn_enviar_alerta_via')));
    await tester.pumpAndSettle();

    expect(find.text('Alerta de segurança registrado!'), findsOneWidget);
    expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);
    expect(find.text('🐝'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(ViaPage))).clearSnackBars();
    await tester.pumpAndSettle();

    // 2. Tocar na bolha vermelha e confirmar que o risco já foi resolvido
    await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
    await tester.pumpAndSettle();

    expect(find.text('Ainda está lá?'), findsOneWidget);
    expect(find.textContaining('Colmeia ativa no diedro'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_confirmar_alerta_resolvido')));
    await tester.pumpAndSettle();

    expect(find.byType(BolhaEmojiAlertaVia), findsNothing);
  });

  testWidgets('ViaPage abre modal de caderneta, exibe selo Flash, copia chave Pix, abre vídeo beta e compartilha via', (tester) async {
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);

    String? textoCompartilhado;
    String? pixCopiado;
    Uri? betaAberto;

    ServicoCompartilhamento.instancia = ServicoCompartilhamento(
      executorCompartilhamento: (texto) async => textoCompartilhado = texto,
    );

    final escalada = Escalada(
      uid: 'uidViaCompleta1',
      betas: [
        MidiaBeta(
          url: 'https://youtube.com/watch?v=xyz',
          titulo: 'Beta Oficial no YouTube',
          fonte: FonteMidia_Enum.YOUTUBE,
        ),
      ],
      viaEsportiva: ViaEsportiva(
        nome: 'Via Master',
        dificuldade: GrauVia_GrauVia.BR_7A,
        chavePixManutencao: 'pix@manutencao.org',
      ),
    );

    final repoCaderneta = RepositorioCadernetaLocal();
    await repoCaderneta.salvarCadena(
      Cadena.criar(
        escaladaUid: 'uidViaCompleta1',
        dataAscensao: DateTime(2026, 9, 14),
        tipoAscensao: TipoAscensao.flash,
        notasPrivadas: 'Costurou leve e rápido',
      ),
    );
    final cadernetaVm = SecaoCadernetaViaViewModel(
      escalada: escalada,
      repositorio: repoCaderneta,
    );
    final viaVm = ViaViewModel(
      escalada: escalada,
      copiadorAreaTransferencia: (texto) async => pixCopiado = texto,
      lancadorUrlExterna: (uri) async {
        betaAberto = uri;
        return true;
      },
    );
    addTearDown(() {
      cadernetaVm.dispose();
      viaVm.dispose();
    });

    await tester.pumpWidget(
      envolver(
        ViaPage(
          escalada: escalada,
          cragId: 'br_mg_serra_do_cipo',
          pico: Pico(nome: 'Serra do Cipó'),
          setor: Setor(nome: 'Fenda'),
          viewModel: viaVm,
          cadernetaViewModel: cadernetaVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Encadenada'), findsOneWidget);
    expect(find.textContaining('Flash'), findsOneWidget);
    expect(find.textContaining('Costurou leve e rápido'), findsOneWidget);

    // Abre modal de nova ascensão
    await tester.tap(find.text('Nova Ascensão / Tentativa'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ModalRegistroCadena),
        matching: find.text('Via Master'),
      ),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byType(ModalRegistroCadena))).pop();
    await tester.pumpAndSettle();

    // Abre vídeo beta
    await tester.ensureVisible(find.text('Beta Oficial no YouTube'));
    await tester.tap(find.text('Beta Oficial no YouTube'));
    await tester.pumpAndSettle();
    expect(betaAberto.toString(), 'https://youtube.com/watch?v=xyz');

    // Copia Pix de manutenção
    await tester.ensureVisible(find.byKey(const Key('btn_copiar_pix_manutencao')));
    await tester.tap(find.byKey(const Key('btn_copiar_pix_manutencao')));
    await tester.pumpAndSettle();
    expect(pixCopiado, 'pix@manutencao.org');
    expect(find.text('Chave Pix copiada para a área de transferência!'), findsOneWidget);

    // Compartilha via pelo AppBar
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(textoCompartilhado, contains('https://aresta.cc/s/uidViaCompleta1'));
  });

  testWidgets('ViaPage recria ViewModel interno ao receber nova escalada em didUpdateWidget e renderiza Highline mapeado sem overflow em 320x568 @ 1.5x', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final highline = Escalada(
      uid: 'uidHighline001',
      highline: Highline(
        nome: 'Travessia Aérea do Abismo',
        distancia: 90,
        altura: 150,
      ),
    );
    final mapaSetor = Mapa(
      caminhoImagemMapa: 'mapas/highline.png',
      larguraMapa: 800,
      alturaMapa: 600,
      referencias: [
        Mapa_Referencia(alvoUid: 'uidHighline001', pontosUids: ['h1']),
      ],
    );
    final setor = Setor(
      uid: 'set-hl',
      nome: 'Cânion',
      escaladas: [highline],
      mapas: [mapaSetor],
    );
    final pico = Pico(
      nome: 'Pico Alto',
      setoresOuGrupos: [SetorOuGrupo(setor: ArquivoSetor(conteudo: setor))],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: ViaPage(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Inicial')),
          cragId: 'crag1',
        ),
      ),
    );
    expect(find.text('Via Inicial'), findsOneWidget);

    // Atualiza escalada para o Highline mapeado
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: ViaPage(
          escalada: highline,
          cragId: 'crag1',
          pico: pico,
          setor: setor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Travessia Aérea do Abismo'), findsOneWidget);
    expect(find.text('HIGHLINE'), findsOneWidget);
    expect(find.text('VER NO CROQUI INTERATIVO'), findsOneWidget);
    expect(find.text('90m'), findsOneWidget);
  });
}
