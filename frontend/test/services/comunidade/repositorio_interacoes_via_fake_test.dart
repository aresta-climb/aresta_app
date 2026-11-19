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
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      detalhe: 'Marimbondos na parada',
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos,
      hasLength(1),
    );

    await fake.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: true,
    );
    expect(
      fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos.first.confirmacoesAtivas,
      2,
    );

    await fake.confirmarAlerta(
      escaladaUid: 'x8siJek3FiG3aB',
      alertaUid: alerta.uid,
      aindaEstaLa: false,
    );
    expect(fake.obterDadosEscalada('x8siJek3FiG3aB').alertasAtivos, isEmpty);

    fake.erroSimulado = StateError('Falha determinística de rede');
    await expectLater(
      () => fake.reportarAlerta(
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.viaMolhada,
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
