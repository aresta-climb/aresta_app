// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'cliente_cadenas_supabase_fake.dart';

void main() {
  test('ClienteCadenasFake isola cadenas por userId, suporta upsert, exclusão e erros determinísticos', () async {
    final fake = ClienteCadenasFake();
    expect(fake.cadenasDaConta('usr-1'), isEmpty);

    final c1 = Cadena.criar(
      escaladaUid: 'x8siJek3FiG3aB',
      dataAscensao: DateTime(2026, 9, 10),
      tipoAscensao: TipoAscensao.aVista,
    );
    final c2 = Cadena.criar(
      escaladaUid: 'm8Kq2L1x9Y7zWq',
      dataAscensao: DateTime(2026, 9, 20),
      tipoAscensao: TipoAscensao.flash,
    );

    await fake.upsertCadenas(const [], userId: 'usr-1', accessToken: 'jwt-1');
    await fake.upsertCadenas([c1, c2], userId: 'usr-1', accessToken: 'jwt-1');
    expect(fake.ultimoAccessToken, 'jwt-1');

    final listadas = await fake.listarCadenasDoUsuario(
      userId: 'usr-1',
      accessToken: 'jwt-2',
    );
    expect(fake.ultimoAccessToken, 'jwt-2');
    expect(listadas.map((c) => c.id), equals([c2.id, c1.id]));
    expect(
      await fake.listarCadenasDoUsuario(userId: 'usr-outro', accessToken: 'jwt'),
      isEmpty,
    );

    await fake.excluirCadenaRemota(c1.id, userId: 'usr-1', accessToken: 'jwt-3');
    expect(fake.cadenasDaConta('usr-1').single.id, c2.id);

    fake.filaErros.add(StateError('Falha pontual'));
    await expectLater(
      () => fake.listarCadenasDoUsuario(userId: 'usr-1', accessToken: 'jwt'),
      throwsStateError,
    );
    expect(
      await fake.listarCadenasDoUsuario(userId: 'usr-1', accessToken: 'jwt'),
      hasLength(1),
    );

    fake.erroSimulado = StateError('Offline');
    await expectLater(
      () => fake.upsertCadenas([c1], userId: 'usr-1', accessToken: 'jwt'),
      throwsStateError,
    );
    await expectLater(
      () => fake.excluirCadenaRemota(c2.id, userId: 'usr-1', accessToken: 'jwt'),
      throwsStateError,
    );
  });
}
