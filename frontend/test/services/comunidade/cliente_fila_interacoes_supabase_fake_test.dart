// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'cliente_fila_interacoes_supabase_fake.dart';

void main() {
  test('ClienteFilaInteracoesFake semeia, filtra por escaladaUid, registra token e simula erros', () async {
    final fake = ClienteFilaInteracoesFake();
    final alerta = ItemFilaInteracao.alertaSeguranca(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Mariana',
      escaladaUid: 'x8siJek3FiG3aB',
      alertaAlvoUid: 'alertaAbelha01',
      categoriaAlerta: CategoriaAlertaSeguranca.fauna,
    );
    fake.semearItens([alerta]);

    expect(await fake.buscarInteracoesPendentes('x8siJek3FiG3aB'), hasLength(1));
    expect(await fake.buscarInteracoesPendentes('outraVia000001'), isEmpty);
    expect(
      await fake.buscarInteracoesPendentesEmLote([
        'x8siJek3FiG3aB',
        'outraVia000001',
      ]),
      hasLength(1),
    );
    expect(
      await fake.buscarInteracoesRelacionadasAoAutor('c3Lk9P1x4Vw8Mn'),
      hasLength(1),
    );
    expect(
      await fake.buscarInteracoesRelacionadasAoAutor('semAlertas0001'),
      isEmpty,
    );

    final voto = ItemFilaInteracao.votoGrau(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Mariana',
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 0,
    );
    await fake.inserirInteracao(voto, accessToken: 'jwt-token-123');
    expect(fake.ultimoAccessTokenInsercao, 'jwt-token-123');
    expect(fake.itensInseridos, hasLength(2));

    fake.filaErrosInsercao.add(StateError('Erro pontual 1'));
    await expectLater(() => fake.inserirInteracao(voto), throwsStateError);
    await fake.inserirInteracao(voto, accessToken: 'jwt-retentativa');
    expect(fake.ultimoAccessTokenInsercao, 'jwt-retentativa');

    fake.erroSimulado = StateError('Offline simulado');
    await expectLater(
      () => fake.buscarInteracoesPendentes('x8siJek3FiG3aB'),
      throwsStateError,
    );
    await expectLater(
      () => fake.buscarInteracoesPendentesEmLote(['x8siJek3FiG3aB']),
      throwsStateError,
    );
    await expectLater(
      () => fake.buscarInteracoesRelacionadasAoAutor('c3Lk9P1x4Vw8Mn'),
      throwsStateError,
    );
    await expectLater(
      () => fake.inserirInteracao(voto),
      throwsStateError,
    );

    fake.erroSimulado = null;
    final comentario = ItemFilaInteracao.comentario(
      id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Mariana',
      escaladaUid: 'x8siJek3FiG3aB',
      textoComentario: 'Original',
    );
    await fake.inserirInteracao(comentario, accessToken: 'jwt-com');
    await fake.atualizarComentario(
      comentarioId: comentario.id,
      autorIdPublico: 'outroAutor0001',
      novoTexto: 'Tentativa indevida',
    );
    expect(
      fake.itensInseridos
          .firstWhere((i) => i.id == comentario.id)
          .textoComentario,
      'Original',
    );
    await fake.atualizarComentario(
      comentarioId: comentario.id,
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      novoTexto: 'Atualizado pela autora',
      accessToken: 'jwt-edit-com',
    );
    expect(fake.ultimoAccessTokenInsercao, 'jwt-edit-com');
    expect(
      fake.itensInseridos
          .firstWhere((i) => i.id == comentario.id)
          .textoComentario,
      'Atualizado pela autora',
    );

    await fake.atualizarAlerta(
      alertaAlvoUid: 'alertaAbelha01',
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
      detalhe: 'Chapeleta solta',
      accessToken: 'jwt-edit-alerta',
    );
    expect(fake.ultimoAccessTokenInsercao, 'jwt-edit-alerta');
    final alertaEditado = fake.itensInseridos.firstWhere(
      (i) => i.alertaAlvoUid == 'alertaAbelha01',
    );
    expect(alertaEditado.categoriaAlerta, CategoriaAlertaSeguranca.protecaoPrecaria);
    expect(alertaEditado.textoComentario, 'Chapeleta solta');

    await fake.excluirComentario(
      comentarioId: comentario.id,
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      accessToken: 'jwt-del-com',
    );
    expect(fake.itensInseridos.any((i) => i.id == comentario.id), isFalse);

    await fake.excluirAlerta(
      alertaAlvoUid: 'alertaAbelha01',
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      accessToken: 'jwt-del-alerta',
    );
    expect(
      fake.itensInseridos.any((i) => i.alertaAlvoUid == 'alertaAbelha01'),
      isFalse,
    );
  });
}
