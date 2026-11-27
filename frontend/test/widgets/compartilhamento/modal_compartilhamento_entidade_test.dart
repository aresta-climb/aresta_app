// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/dados_cartao_compartilhamento.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/compartilhamento/modal_compartilhamento_entidade.dart';
import '../../fakes/servico_compartilhamento_fake.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  final pngMinimo = MemoryImage(ServicoCompartilhamentoFake.pngMinimoValido);

  const dadosVia = DadosCartaoCompartilhamento(
    tipoEntidade: TipoEntidadeCompartilhavel.via,
    idCroqui: 'br_mg_igarape_pedra_grande',
    uid: 'x8siJek3FiG3aB',
    titulo: 'Aresta Clássica',
    subtituloLocalizacao: 'Pedra Grande • Setor Principal',
    etiquetaCategoria: 'ESPORTIVA',
    grauDestaque: '6ºsup',
    seloPessoal: SeloPessoalCompartilhamento(
      ehCadena: true,
      textoResumo: 'Encadenada em 14/09 (Flash)',
    ),
    nomePico: 'Pedra Grande',
    nomeSetor: 'Setor Principal',
  );

  group('ModalCompartilhamentoEntidade', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    Widget envolverApp(Widget home) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: home,
      );
    }

    testWidgets('exibe pré-visualização e aciona Compartilhar Imagem (Stories) copiando link e exibindo toast orientativo', (tester) async {
      final fakeServico = ServicoCompartilhamentoFake();

      await tester.pumpWidget(
        envolverApp(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    exibirModalCompartilhamentoEntidade(
                      context,
                      dados: dadosVia,
                      servicoCompartilhamento: fakeServico,
                      capturadorCartao: fakeServico.capturarCartaoFake,
                      imageProviderOverride: pngMinimo,
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(ModalCompartilhamentoEntidade), findsOneWidget);
      expect(find.text('Aresta Clássica'), findsOneWidget);
      expect(find.textContaining('arestaclimb.com'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_compartilhar_imagem_stories')));
      await tester.pumpAndSettle();

      expect(find.byType(ModalCompartilhamentoEntidade), findsNothing);
      expect(fakeServico.imagensCompartilhadas, hasLength(1));
      expect(
        fakeServico.imagensCompartilhadas.single.nomeArquivo,
        'aresta_via_x8siJek3FiG3aB.png',
      );
      expect(
        fakeServico.textosCopiadosClipboard,
        equals(['https://aresta.cc/s/x8siJek3FiG3aB']),
      );
      expect(
        find.text('Link copiado! Cole na figurinha de Link nos Stories se quiser.'),
        findsOneWidget,
      );
    });

    testWidgets('aciona Compartilhar Link (WhatsApp) enviando texto e URL curta', (tester) async {
      final fakeServico = ServicoCompartilhamentoFake();

      await tester.pumpWidget(
        envolverApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  exibirModalCompartilhamentoEntidade(
                    context,
                    dados: dadosVia,
                    servicoCompartilhamento: fakeServico,
                    capturadorCartao: fakeServico.capturarCartaoFake,
                    imageProviderOverride: pngMinimo,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_compartilhar_link_rapido')));
      await tester.pumpAndSettle();

      expect(find.byType(ModalCompartilhamentoEntidade), findsNothing);
      expect(fakeServico.textosCompartilhados, hasLength(1));
      expect(
        fakeServico.textosCompartilhados.single,
        contains('https://aresta.cc/s/x8siJek3FiG3aB'),
      );
      expect(fakeServico.imagensCompartilhadas, isEmpty);
    });

    testWidgets('adapta-se sem overflow em tela estreita 320x568 e permite fechar pelo ícone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeServico = ServicoCompartilhamentoFake();

      await tester.pumpWidget(
        envolverApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  exibirModalCompartilhamentoEntidade(
                    context,
                    dados: dadosVia,
                    servicoCompartilhamento: fakeServico,
                    capturadorCartao: fakeServico.capturarCartaoFake,
                    imageProviderOverride: pngMinimo,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(ModalCompartilhamentoEntidade), findsNothing);
    });

    testWidgets('recorre a ServicoCompartilhamento.capturadorPadrao quando nenhum capturador personalizado é fornecido', (tester) async {
      addTearDown(ServicoCompartilhamento.restaurarPadrao);
      var capturadorPadraoChamado = false;
      ServicoCompartilhamento.capturadorPadrao = (_) async {
        capturadorPadraoChamado = true;
        return ServicoCompartilhamentoFake.pngMinimoValido;
      };
      final imagensRecebidas = <String>[];
      final servicoSemCapturador = ServicoCompartilhamento(
        executorImagem: (_, nomeArquivo) async =>
            imagensRecebidas.add(nomeArquivo),
        copiadorAreaTransferencia: (_) async {},
      );

      await tester.pumpWidget(
        envolverApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  exibirModalCompartilhamentoEntidade(
                    context,
                    dados: dadosVia,
                    servicoCompartilhamento: servicoSemCapturador,
                    imageProviderOverride: pngMinimo,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_compartilhar_imagem_stories')));
      await tester.pumpAndSettle();

      expect(capturadorPadraoChamado, isTrue);
      expect(imagensRecebidas, equals(['aresta_via_x8siJek3FiG3aB.png']));
    });
  });
}
