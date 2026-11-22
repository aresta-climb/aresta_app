// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/services/comunidade/armazenamento_fila_interacoes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'carrega lista vazia inicialmente, persiste itens na fila e remove chave ao esvaziar ou limpar',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final armazenamento = ArmazenamentoFilaInteracoes(preferencias: prefs);

      expect(await armazenamento.carregarItensPendentes(), isEmpty);

      final itens = <ItemFilaInteracao>[
        ItemFilaInteracao.votoGrau(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana Silva',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 1,
        ),
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana Silva',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'a9Rt3M2y0Z8aXr',
          categoriaAlerta: CategoriaAlertaSeguranca.abelhasInsetos,
          detalhe: 'Colmeia na 3ª costura',
        ),
      ];

      await armazenamento.salvarItensPendentes(itens);

      final reaberto = ArmazenamentoFilaInteracoes();
      final carregados = await reaberto.carregarItensPendentes();
      expect(carregados, hasLength(2));
      expect(carregados.first.tipo, TipoFilaInteracao.votoGrau);
      expect(carregados.last.textoComentario, 'Colmeia na 3ª costura');

      await reaberto.salvarItensPendentes(const []);
      expect(
        prefs.getString(ArmazenamentoFilaInteracoes.chaveFilaPendente),
        isNull,
      );

      await reaberto.salvarItensPendentes(itens);
      await reaberto.limparFila();
      expect(await reaberto.carregarItensPendentes(), isEmpty);
    },
  );

  test(
    'recupera lista vazia quando o JSON salvo na fila offline estiver corrompido',
    () async {
      SharedPreferences.setMockInitialValues({
        ArmazenamentoFilaInteracoes.chaveFilaPendente: '{json_invalido',
      });
      final armazenamento = ArmazenamentoFilaInteracoes();
      expect(await armazenamento.carregarItensPendentes(), isEmpty);
    },
  );
}
