// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/item_fila_interacao.dart';

/// Contrato de comunicação HTTP com a tabela `public.fila_interacoes` (PostgREST).
///
/// Separa a serialização/transporte de rede da orquestração reativa e da fila
/// offline de [RepositorioInteracoesVia], viabilizando Fakes determinísticos em memória.
abstract interface class ClienteFilaInteracoes {
  /// Consulta todas as interações com `status = 'PENDENTE'` para [escaladaUid].
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(
    String escaladaUid, {
    String? accessToken,
  });

  /// Insere um novo evento na tabela `public.fila_interacoes`.
  ///
  /// Quando [accessToken] é informado, autentica como `authenticated` (permitindo
  /// `VOTO_GRAU` e `COMENTARIO`); quando omitido, utiliza a chave `anon` (permitindo
  /// `ALERTA_SEGURANCA` e `CONFIRMACAO_ALERTA` sem barreira de login).
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  });
}
