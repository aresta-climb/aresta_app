// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/view/view_models/formulario_alerta_via_view_model.dart';

void main() {
  test(
    'gerencia seleção de categoria, truncamento de detalhe e submissão normalizada',
    () async {
      CategoriaAlertaSeguranca? categoriaRecebida;
      String? detalheRecebido = 'nao_chamado';
      var notificacoes = 0;

      final vm = FormularioAlertaViaViewModel()
        ..addListener(() => notificacoes++);

      expect(vm.categoriaSelecionada, CategoriaAlertaSeguranca.fauna);
      expect(vm.opcoesCategorias, hasLength(CategoriaAlertaSeguranca.values.length));
      expect(vm.descricaoCategoriaSelecionada, isNotEmpty);

      // Reatribuir mesma categoria não dispara rebuild redundante
      vm.selecionarCategoria(CategoriaAlertaSeguranca.fauna);
      expect(notificacoes, 0);

      vm.selecionarCategoria(CategoriaAlertaSeguranca.protecaoPrecaria);
      expect(vm.categoriaSelecionada, CategoriaAlertaSeguranca.protecaoPrecaria);
      expect(notificacoes, 1);

      vm.definirDetalhe('   ');
      expect(vm.detalheNormalizado, isNull);

      await vm.submeter((cat, det) async {
        categoriaRecebida = cat;
        detalheRecebido = det;
      });
      expect(categoriaRecebida, CategoriaAlertaSeguranca.protecaoPrecaria);
      expect(detalheRecebido, isNull);

      vm.definirDetalhe('  Chapeleta 2 girando  ');
      expect(vm.detalheNormalizado, 'Chapeleta 2 girando');
      vm.definirDetalhe('X' * 200);
      expect(
        vm.detalhe.length,
        AlertaSegurancaVia.limiteCaracteresDetalhe,
      );
      vm.dispose();
    },
  );

  test('formata subtítulo e citação para o modal de confirmação de alerta', () {
    final alerta = AlertaSegurancaVia(
      uid: 'alertaRocha001',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
      detalhe: 'Laca oca no teto',
      autorNomePublico: 'Mariana Silva',
      criadoEm: DateTime.utc(2026, 9, 5),
      confirmacoesAtivas: 3,
    );

    expect(
      FormularioAlertaViaViewModel.formatarSubtituloConfirmacao(alerta),
      'Reportado por Mariana Silva em 05/09 • 3x confirmado',
    );
    expect(
      FormularioAlertaViaViewModel.formatarCitacaoDetalhe(alerta),
      '“Laca oca no teto”',
    );

    final semDetalhe = AlertaSegurancaVia(
      uid: 'alertaAgua0001',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
      autorNomePublico: 'Escalador',
      criadoEm: DateTime.utc(2026, 10, 12),
    );
    expect(
      FormularioAlertaViaViewModel.formatarCitacaoDetalhe(semDetalhe),
      isNull,
    );
  });
}
