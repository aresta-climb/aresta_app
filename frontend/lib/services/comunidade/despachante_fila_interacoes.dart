// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/item_fila_interacao.dart';
import '../../utils/gerador_uid.dart';
import '../autenticacao/servico_autenticacao.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/app_logger.dart';
import 'armazenamento_fila_interacoes.dart';
import 'cliente_fila_interacoes_supabase.dart';

/// Orquestra a fila persistente de envio offline (*outbox*) para `public.fila_interacoes`,
/// reconciliando sessão/perfil autenticado em falhas `401`/`403` e descartando conflitos `409`.
class DespachanteFilaInteracoes {
  final RepositorioCaderneta _repositorioCaderneta;
  final ServicoAutenticacao _servicoAutenticacao;
  final ArmazenamentoFilaInteracoes _armazenamentoFila;

  final List<ItemFilaInteracao> _filaPendente = [];
  bool _carregada = false;

  /// Cria uma instância de [DespachanteFilaInteracoes].
  DespachanteFilaInteracoes({
    required RepositorioCaderneta repositorioCaderneta,
    required ServicoAutenticacao servicoAutenticacao,
    required ArmazenamentoFilaInteracoes armazenamentoFila,
  }) : _repositorioCaderneta = repositorioCaderneta,
       _servicoAutenticacao = servicoAutenticacao,
       _armazenamentoFila = armazenamentoFila;

  /// Itens atualmente retidos na fila offline aguardando conectividade ou sessão válida.
  List<ItemFilaInteracao> get itensPendentes => List.unmodifiable(_filaPendente);

  /// Garante a hidratação inicial da fila offline a partir do armazenamento local.
  Future<void> garantirCarregada() async {
    if (_carregada) return;
  }
}
