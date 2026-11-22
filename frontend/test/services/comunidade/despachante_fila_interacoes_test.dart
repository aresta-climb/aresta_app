// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/armazenamento_fila_interacoes.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';
import 'package:frontend/services/comunidade/despachante_fila_interacoes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../autenticacao/servico_autenticacao_fake.dart';
import 'cliente_fila_interacoes_supabase_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DespachanteFilaInteracoes reconcilia 401/403, descarta conflitos 409 de +1 duplicado e interrompe em queda de rede',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
      await repoCaderneta.inicializar();
      await repoCaderneta.salvarPerfil(
        PerfilEscalador(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          userId: 'uuid-mariana',
          refreshToken: 'refresh-mariana',
        ),
      );

      final authFake = ServicoAutenticacaoFake(repositorio: repoCaderneta);
      final clienteFake = ClienteFilaInteracoesFake();
      final armazenamento = ArmazenamentoFilaInteracoes(preferencias: prefs);
      final despachante = DespachanteFilaInteracoes(
        repositorioCaderneta: repoCaderneta,
        servicoAutenticacao: authFake,
        armazenamentoFila: armazenamento,
      );

      await despachante.drenar(clienteFake);
      expect(despachante.itensPendentes, isEmpty);

      // 1. Conflito 409 no envio inicial é descartado de forma idempotente
      clienteFake.filaErrosInsercao.add(
        const ExcecaoHttpFilaInteracoes(
          codigoStatusHttp: 409,
          message: 'Conflito 23505 duplicado',
        ),
      );
      await despachante.enfileirarEDespachar(clienteFake, [
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaAbelha01',
          alertaAtivo: true,
        ),
      ]);
      expect(despachante.itensPendentes, isEmpty);

      // 2. Erro 401 seguido de 409 na retentativa também descarta sem reter na fila
      clienteFake.filaErrosInsercao.addAll([
        const ExcecaoHttpFilaInteracoes(
          codigoStatusHttp: 401,
          message: 'JWT expirado',
        ),
        const ExcecaoHttpFilaInteracoes(
          codigoStatusHttp: 409,
          message: 'Já registrado na retentativa',
        ),
      ]);
      await despachante.enfileirarEDespachar(clienteFake, [
        ItemFilaInteracao.confirmacaoAlerta(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaAbelha01',
          alertaAtivo: true,
        ),
      ]);
      expect(despachante.itensPendentes, isEmpty);

      // 3. Queda real de rede preserva a ordem dos itens subsequentes
      clienteFake.erroSimulado = const SocketException('Sem sinal');
      await despachante.enfileirarEDespachar(clienteFake, [
        ItemFilaInteracao.alertaSeguranca(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          alertaAlvoUid: 'alertaRocha002',
          categoriaAlerta: CategoriaAlertaSeguranca.rochaAgarraInstavel,
        ),
        ItemFilaInteracao.votoGrau(
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Mariana',
          escaladaUid: 'x8siJek3FiG3aB',
          deltaGrau: 0,
        ),
      ]);
      expect(despachante.itensPendentes, hasLength(2));
    },
  );
}
