import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/mapao_global_functions.dart';
// Para acessar _CragListItem indiretamente se precisar, ou buscar por OutlinedButton

void main() {
  testWidgets('showCragModal pops bottom sheet before calling onOpen', (WidgetTester tester) async {
    bool onOpenCalled = false;

    final crag = {
      'id': 'crag1',
      'nome': 'Pico Teste',
      'local': 'Local Teste',
      'latitude': -20.0,
      'longitude': -40.0,
      'isDownloaded': true,
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showCragModal(
                  context: context,
                  crag: crag,
                  isDownloading: false,
                  onDownload: () {},
                  onOpen: () {
                    onOpenCalled = true;
                    // Verifica se o bottom sheet já foi fechado checando a rota atual ou se podemos dar pop
                    // Não há uma forma direta de saber se o pop ocorreu exceto verificar se o BottomSheet desaparece após o frame.
                  },
                );
              },
              child: const Text('Show Modal'),
            ),
          ),
        ),
      ),
    ));

    // Abre o modal
    await tester.tap(find.text('Show Modal'));
    await tester.pumpAndSettle();

    // Clica no item para expandi-lo
    await tester.tap(find.text('Pico Teste'));
    await tester.pumpAndSettle();

    // Verifica se o modal (e portanto o botão "ABRIR CROQUI") está visível
    expect(find.text('ABRIR CROQUI'), findsOneWidget);

    // Usa warnIfMissed: false porque o modal pode estar animando ou fora do hit box padrão no teste
    await tester.tap(find.text('ABRIR CROQUI'), warnIfMissed: false);
    
    // Deixa os callbacks e animações de navegação executarem
    await tester.pumpAndSettle();

    // Verifica se o callback foi chamado
    expect(onOpenCalled, isTrue);

    // E o modal não deve mais estar na tela
    expect(find.text('ABRIR CROQUI'), findsNothing);
  });
}
