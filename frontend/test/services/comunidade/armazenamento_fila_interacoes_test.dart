// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/mutacao_fila_interacao.dart';
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
          categoriaAlerta: CategoriaAlertaSeguranca.fauna,
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

      expect(await reaberto.carregarCacheAlertasUsuario(), isEmpty);
      await reaberto.salvarCacheAlertasUsuario(itens);
      expect(await reaberto.carregarCacheAlertasUsuario(), hasLength(2));
      await reaberto.salvarCacheAlertasUsuario(const []);
      expect(await reaberto.carregarCacheAlertasUsuario(), isEmpty);
    },
  );

  test(
    'recupera lista vazia quando o JSON salvo na fila offline estiver corrompido',
    () async {
      SharedPreferences.setMockInitialValues({
        ArmazenamentoFilaInteracoes.chaveFilaPendente: '{json_invalido',
        ArmazenamentoFilaInteracoes.chaveMutacoesPendentes: '[corrompido',
      });
      final armazenamento = ArmazenamentoFilaInteracoes();
      expect(await armazenamento.carregarItensPendentes(), isEmpty);
      expect(await armazenamento.carregarMutacoesPendentes(), isEmpty);
    },
  );

  test(
    'persiste mutações de edição/exclusão e gerencia cache em memória de alertas por via',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final armazenamento = ArmazenamentoFilaInteracoes(preferencias: prefs);
      expect(await armazenamento.carregarMutacoesPendentes(), isEmpty);

      final mutacao = MutacaoFilaInteracao.editarComentario(
        alvoUid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        escaladaUid: 'x8siJek3FiG3aB',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        novoTexto: 'Novo texto',
      );
      await armazenamento.salvarMutacoesPendentes([mutacao]);
      expect(await armazenamento.carregarMutacoesPendentes(), hasLength(1));
      await armazenamento.salvarMutacoesPendentes(const []);
      expect(
        prefs.getString(ArmazenamentoFilaInteracoes.chaveMutacoesPendentes),
        isNull,
      );

      final eventoAlerta = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'alertaAbelha01',
        categoriaAlerta: CategoriaAlertaSeguranca.fauna,
        detalhe: 'Vespas',
      );
      await armazenamento.adicionarEventoAlerta(eventoAlerta);
      expect(armazenamento.eventosAlertasPorVia['x8siJek3FiG3aB'], hasLength(1));

      final outroArmazenamento = ArmazenamentoFilaInteracoes(preferencias: prefs);
      await outroArmazenamento.hidratarMemoriaAlertas();
      expect(
        outroArmazenamento.eventosAlertasPorVia['x8siJek3FiG3aB'],
        hasLength(1),
      );

      // Mutação em via ausente é ignorada sem erro; mutação na via atualiza e exclusão limpa chave
      await outroArmazenamento.aplicarMutacaoAlertaNaVia(
        'viaAusente0001',
        MutacaoFilaInteracao.excluirAlerta(
          alvoUid: 'alertaAbelha01',
          escaladaUid: 'viaAusente0001',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        ),
      );
      await outroArmazenamento.aplicarMutacaoAlertaNaVia(
        'x8siJek3FiG3aB',
        MutacaoFilaInteracao.editarAlerta(
          alvoUid: 'alertaAbelha01',
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novaCategoria: CategoriaAlertaSeguranca.protecaoPrecaria,
          detalhe: 'Grampo frouxo',
        ),
      );
      expect(
        outroArmazenamento
            .eventosAlertasPorVia['x8siJek3FiG3aB']!
            .single
            .categoriaAlerta,
        CategoriaAlertaSeguranca.protecaoPrecaria,
      );
      await outroArmazenamento.aplicarMutacaoAlertaNaVia(
        'x8siJek3FiG3aB',
        MutacaoFilaInteracao.excluirAlerta(
          alvoUid: 'alertaAbelha01',
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        ),
      );
      expect(outroArmazenamento.eventosAlertasPorVia.containsKey('x8siJek3FiG3aB'), isFalse);

      await outroArmazenamento.substituirTodosEventosAlertas([eventoAlerta]);
      expect(outroArmazenamento.eventosAlertasPorVia['x8siJek3FiG3aB'], hasLength(1));
      outroArmazenamento.atualizarEventosDaVia('x8siJek3FiG3aB', [
        ItemFilaInteracao.votoGrau(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 0,
        ),
      ]);
      expect(outroArmazenamento.eventosAlertasPorVia.containsKey('x8siJek3FiG3aB'), isFalse);
    },
  );
}
