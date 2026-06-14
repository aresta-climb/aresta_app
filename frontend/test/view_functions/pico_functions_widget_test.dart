import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';

void main() {
  testWidgets('buildBotoesExtras injects TextNode into FeedbackMetadataCollector on tap and removes on close', (WidgetTester tester) async {
    final md = ArquivoMarkdown()..conteudo = 'Este é um teste';
    final botao = Botao()
      ..texto = 'Regras Locais'
      ..destino = (DestinoBotao()..secaoTextual = md);

    final croqui = Croqui()..botoes.add(botao);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final widget = buildBotaoTile(context, botao, 'pico_id');
            return ListView(children: [widget]);
          },
        ),
      ),
    ));

    // Certifica de que não há override configurado antes do tap
    expect(FeedbackMetadataCollector.globalActiveNodeOverride, isNull);

    // Encontra o botão gerado
    final listTile = find.byType(ListTile);
    expect(listTile, findsOneWidget);
    expect(find.text('Regras Locais'), findsOneWidget);

    // Toca no botão para abrir o modal
    await tester.tap(listTile);
    await tester.pump(const Duration(seconds: 1));

    // Verifica se o modal abriu e se injetou o TextNode
    expect(find.byType(BottomSheet), findsOneWidget);

    // Fecha o modal
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    // Verifica se o override foi removido (restaurado)
    expect(find.byType(BottomSheet), findsNothing);
  });
}
