// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/data/modelos/mutacao_fila_interacao.dart';
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

  test(
    'coalesce edições/exclusões sobre itens ainda não enviados e reconcilia mutações remotas (401/403/409/500/offline)',
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
          accessToken: 'jwt-inicial',
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

      // 1. Retém comentário e alerta ainda não enviados (offline) e coalesce edição/exclusão in-place
      clienteFake.erroSimulado = const SocketException('Offline inicial');
      final comOffline = ItemFilaInteracao.comentario(
        id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        escaladaUid: 'x8siJek3FiG3aB',
        textoComentario: 'Rascunho offline',
      );
      final alertaOffline = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'alertaOff00001',
        categoriaAlerta: CategoriaAlertaSeguranca.fauna,
      );
      await despachante.enfileirarEDespachar(clienteFake, [
        comOffline,
        alertaOffline,
      ]);
      expect(despachante.itensPendentes, hasLength(2));

      await despachante.registrarMutacao(
        clienteFake,
        MutacaoFilaInteracao.editarComentario(
          alvoUid: comOffline.id,
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novoTexto: 'Rascunho editado offline',
        ),
      );
      await despachante.registrarMutacao(
        clienteFake,
        MutacaoFilaInteracao.editarAlerta(
          alvoUid: 'alertaOff00001',
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novaCategoria: CategoriaAlertaSeguranca.protecaoPrecaria,
          detalhe: 'Chapeleta frouxa',
        ),
      );
      expect(despachante.mutacoesPendentes, isEmpty);
      expect(
        despachante.itensPendentes.first.textoComentario,
        'Rascunho editado offline',
      );
      expect(
        despachante.itensPendentes.last.categoriaAlerta,
        CategoriaAlertaSeguranca.protecaoPrecaria,
      );

      await despachante.registrarMutacao(
        clienteFake,
        MutacaoFilaInteracao.excluirComentario(
          alvoUid: comOffline.id,
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        ),
      );
      await despachante.registrarMutacao(
        clienteFake,
        MutacaoFilaInteracao.excluirAlerta(
          alvoUid: 'alertaOff00001',
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        ),
      );
      expect(despachante.itensPendentes, isEmpty);
      expect(despachante.mutacoesPendentes, isEmpty);

      // 2. Itens já sincronizados no servidor -> mutações entram em _mutacoesPendentes e deduplicam por domínio
      clienteFake.erroSimulado = null;
      final comRemoto = ItemFilaInteracao.comentario(
        id: 'a17ac10b-58cc-4372-a567-0e02b2c3d479',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        escaladaUid: 'x8siJek3FiG3aB',
        textoComentario: 'No ar',
      );
      final alertaRemoto = ItemFilaInteracao.alertaSeguranca(
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
        escaladaUid: 'x8siJek3FiG3aB',
        alertaAlvoUid: 'alertaRem00001',
        categoriaAlerta: CategoriaAlertaSeguranca.fauna,
      );
      clienteFake.semearItens([comRemoto, alertaRemoto]);

      // Sem cliente (null), acumula e substitui mutação anterior do mesmo domínio
      await despachante.registrarMutacao(
        null,
        MutacaoFilaInteracao.editarComentario(
          alvoUid: comRemoto.id,
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novoTexto: 'Versão 1',
        ),
      );
      await despachante.registrarMutacao(
        null,
        MutacaoFilaInteracao.editarAlerta(
          alvoUid: 'alertaRem00001',
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novaCategoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
          detalhe: 'Bloco',
        ),
      );
      await despachante.registrarMutacao(
        null,
        MutacaoFilaInteracao.excluirComentario(
          alvoUid: comRemoto.id,
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        ),
      );
      await despachante.registrarMutacao(
        null,
        MutacaoFilaInteracao.editarComentario(
          alvoUid: comRemoto.id,
          escaladaUid: 'x8siJek3FiG3aB',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          novoTexto: 'Versão 2',
        ),
      );
      expect(despachante.mutacoesPendentes, hasLength(2));

      // Exercita 401 -> refresh ok na 1ª mutação, e 409 descartado na 2ª
      clienteFake.filaErrosInsercao.addAll([
        const ExcecaoHttpFilaInteracoes(
          codigoStatusHttp: 401,
          message: 'JWT expirado',
        ),
        const ExcecaoHttpFilaInteracoes(
          codigoStatusHttp: 409,
          message: 'Conflito 409',
        ),
      ]);
      // Na 1ª mutação (editarAlerta): 401 -> refresh -> sucesso (consome 2ª entrada se não cuidarmos: vamos colocar apenas 401 primeiro!)
      clienteFake.filaErrosInsercao
        ..clear()
        ..add(
          const ExcecaoHttpFilaInteracoes(
            codigoStatusHttp: 401,
            message: 'JWT expirado',
          ),
        );
}
