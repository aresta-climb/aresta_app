// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'repositorio_interacoes_via_fake.dart';

void main() {
  test('RepositorioInteracoesViaFake permite semear dados, reportar, confirmar e simular falhas', () async {
    final fake = RepositorioInteracoesViaFake();
    var notificacoes = 0;
    fake.alteracoesListenable.addListener(() => notificacoes++);

    fake.semearDados(
      'x8siJek3FiG3aB',
      const DadosComunidadeVia(
        consensoGrau: ConsensoGrauVia(
          grauSugerido: '7b',
          totalVotos: 5,
          distribuicaoDeltas: {1: 5},
        ),
      ),
    );
    expect(notificacoes, 1);
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.grauSugerido,
      '7b',
    );

    final alerta = await fake.reportarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.fauna,
      detalhe: 'Marimbondos na parada',
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos,
      hasLength(1),
    );
    expect(fake.obterMeusAlertasContribuidos(), hasLength(1));

    // Mesmo autor não duplica +1; segundo autor incrementa 1 vez
    await fake.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos.first.confirmacoesAtivas,
      1,
    );
    fake.autorIdSimulado = 'segundoAutor01';
    await fake.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos.first.confirmacoesAtivas,
      2,
    );

    await fake.sincronizarMeusAlertasContribuidos();
    expect(fake.sincronizacoesMeusAlertas, 1);
    fake.semearMeusAlertas(fake.obterMeusAlertasContribuidos());

    await fake.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: false,
    );
    expect(fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos, isEmpty);

    await fake.sincronizarEscalada('x8siJek3FiG3aB');
    expect(fake.escaladasSincronizadas, contains('x8siJek3FiG3aB'));

    await fake.sincronizarEscaladasEmLote(['viaLote0000001', 'viaLote0000002']);
    expect(
      fake.escaladasSincronizadas,
      containsAll(['viaLote0000001', 'viaLote0000002']),
    );

    await fake.registrarAvaliacaoAscensao(
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      comentarioPublico: 'Crux técnico!',
    );
    expect(fake.usuarioEstaAutenticado, isTrue);
    expect(fake.obterDeltaVotoUsuario('x8siJek3FiG3aB'), 1);
    expect(fake.obterDadosEscalada('x8siJek3FiG3aB').consensoGrau.totalVotos, 6);
    expect(fake.obterDadosEscalada('x8siJek3FiG3aB').comentarios, hasLength(1));
    final comUid =
        fake.obterDadosEscalada('x8siJek3FiG3aB').comentarios.single.uid;
    await fake.editarComentario(
      escaladaUid: 'x8siJek3FiG3aB',
      comentarioUid: comUid,
      novoTexto: 'Crux técnico na reglete!',
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').comentarios.single.texto,
      'Crux técnico na reglete!',
    );
    await fake.excluirComentario(
      escaladaUid: 'x8siJek3FiG3aB',
      comentarioUid: comUid,
    );
    expect(fake.obterDadosEscalada('x8siJek3FiG3aB').comentarios, isEmpty);

    // Editar e excluir alerta tanto em via já carregada quanto apenas semeada em Meus Alertas
    final alertaCaderneta = AlertaSegurancaVia.criar(
      escaladaUid: 'viaApenasCaderneta',
      categoria: CategoriaAlertaSeguranca.fauna,
      detalhe: 'Vespas',
      autorIdPublico: fake.autorIdSimulado,
      autorNomePublico: 'Escalador Teste',
    );
    fake.semearMeusAlertas([
      AlertaContribuidoCaderneta(
        alerta: alertaCaderneta,
        papel: PapelContribuicaoAlerta.criadoPorMim,
        ativo: true,
        ultimaInteracaoEm: alertaCaderneta.criadoEm,
      ),
    ]);
    final editadoCad = await fake.editarAlerta(
      escaladaUid: 'viaApenasCaderneta',
      alertaUid: alertaCaderneta.uid,
      novaCategoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
      detalhe: 'Laca solta',
    );
    expect(editadoCad.categoria, CategoriaAlertaSeguranca.rochaAgarraInstavel);
    expect(fake.obterMeusAlertasContribuidos().single.alerta.detalhe, 'Laca solta');

    final outroAlertaCad = AlertaSegurancaVia.criar(
      escaladaUid: 'viaOutraCaderneta',
      categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
      autorIdPublico: fake.autorIdSimulado,
      autorNomePublico: 'Escalador Teste',
    );
    fake.semearMeusAlertas([
      AlertaContribuidoCaderneta(
        alerta: outroAlertaCad,
        papel: PapelContribuicaoAlerta.criadoPorMim,
        ativo: true,
        ultimaInteracaoEm: outroAlertaCad.criadoEm,
      ),
    ]);
    await fake.excluirAlerta(
      escaladaUid: 'viaOutraCaderneta',
      alertaUid: outroAlertaCad.uid,
    );
    expect(fake.obterMeusAlertasContribuidos(), isEmpty);

    fake.erroSimulado = StateError('Falha determinística de rede');
    await expectLater(
      () => fake.editarComentario(
        escaladaUid: 'x8siJek3FiG3aB',
        comentarioUid: comUid,
        novoTexto: 'X',
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.excluirComentario(
        escaladaUid: 'x8siJek3FiG3aB',
        comentarioUid: comUid,
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.editarAlerta(
        escaladaUid: 'x8siJek3FiG3aB',
        alertaUid: alerta.uid,
        novaCategoria: CategoriaAlertaSeguranca.fauna,
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.excluirAlerta(
        escaladaUid: 'x8siJek3FiG3aB',
        alertaUid: alerta.uid,
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.sincronizarEscalada('x8siJek3FiG3aB'),
      throwsStateError,
    );
    await expectLater(
      () => fake.sincronizarEscaladasEmLote(['x8siJek3FiG3aB']),
      throwsStateError,
    );
    await expectLater(
      () => fake.sincronizarMeusAlertasContribuidos(),
      throwsStateError,
    );
    await expectLater(
      () => fake.registrarAvaliacaoAscensao(
        escaladaUid: 'x8siJek3FiG3aB',
        deltaGrau: 0,
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.reportarAlerta(
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.exposicaoE4Mais,
      ),
      throwsStateError,
    );
    await expectLater(
      () => fake.confirmarAlerta(
        escaladaUid: 'x8siJek3FiG3aB',
        alertaUid: alerta.uid,
        aindaEstaLa: true,
      ),
      throwsStateError,
    );
  });
}
