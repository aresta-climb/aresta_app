// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view/view_models/edicao_perfil_view_model.dart';

void main() {
  test(
    'gerencia nome, seleção de nova foto e normalização do resultado ao salvar',
    () async {
      var notificacoes = 0;
      final vm = EdicaoPerfilViewModel(
        nomeInicial: 'Fernanda Rocha',
        fotoUrlInicial: 'https://cdn.aresta.cc/avatar1.jpg',
        aoSelecionarNovaFoto: () async => 'https://cdn.aresta.cc/avatar2.jpg',
      )..addListener(() => notificacoes++);

      expect(vm.nomeDigitado, 'Fernanda Rocha');
      expect(vm.fotoUrlExibida, 'https://cdn.aresta.cc/avatar1.jpg');
      expect(vm.permiteAlterarFoto, isTrue);

      await vm.selecionarNovaFoto();
      expect(vm.fotoUrlExibida, 'https://cdn.aresta.cc/avatar2.jpg');
      expect(notificacoes, 1);

      vm.definirNome('  Roberta Rocha  ');
      expect(vm.obterNomeNormalizadoParaSalvar(), 'Roberta Rocha');

      vm.definirNome('   ');
      expect(vm.obterNomeNormalizadoParaSalvar(), isNull);
      vm.dispose();
    },
  );

  test('ignora seleção de foto quando ausente ou cancelada pelo usuário', () async {
    final vmSemSeletor = EdicaoPerfilViewModel(nomeInicial: 'Escalador');
    expect(vmSemSeletor.permiteAlterarFoto, isFalse);
    await vmSemSeletor.selecionarNovaFoto();
    expect(vmSemSeletor.fotoUrlExibida, isNull);
    vmSemSeletor.dispose();

    var notificou = false;
    final vmCancelado = EdicaoPerfilViewModel(
      nomeInicial: 'Escalador',
      fotoUrlInicial: 'https://cdn.aresta.cc/original.jpg',
      aoSelecionarNovaFoto: () async => '   ',
    )..addListener(() => notificou = true);

    await vmCancelado.selecionarNovaFoto();
    expect(notificou, isFalse);
    expect(vmCancelado.fotoUrlExibida, 'https://cdn.aresta.cc/original.jpg');
    vmCancelado.dispose();
  });
}
