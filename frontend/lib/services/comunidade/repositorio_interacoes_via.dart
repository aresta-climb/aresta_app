// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/interacao_via.dart';
import '../caderneta/repositorio_caderneta.dart';

/// Contrato reativo da camada de dados comunitários e alertas de segurança estilo Waze por via.
///
/// Desacopla o `ViaViewModel` e os componentes visuais da `ViaPage` da origem física
/// dos dados (memória local na Fase 1 e fusão Protobuf + `public.fila_interacoes` na Fase 2).
abstract interface class RepositorioInteracoesVia {
  /// Notificador que incrementa sempre que alertas, votos ou comentários sofrem alteração.
  ValueListenable<int> get alteracoesListenable;

  /// Retorna o agregado comunitário atual ([DadosComunidadeVia]) para [escaladaUid].
  DadosComunidadeVia obterDadosEscalada(String escaladaUid);

  /// Registra um novo alerta de segurança na via (ou reforça alerta ativo da mesma categoria).
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  });

  /// Registra a resposta do escalador à pergunta *"Ainda está lá?"* sobre [alertaUid].
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  });
}

/// Implementação reativa local em memória de [RepositorioInteracoesVia].
///
/// Garante responsividade imediata na `ViaPage` e funcionamento offline na base da falésia,
/// utilizando o apelido configurado no [RepositorioCaderneta] para identificar relatos.
class RepositorioInteracoesViaMemoria implements RepositorioInteracoesVia {
  static RepositorioInteracoesVia? _instanciaCompartilhada;

  /// Instância singleton padrão compartilhada na aplicação.
  static RepositorioInteracoesVia get instancia =>
      _instanciaCompartilhada ??= RepositorioInteracoesViaMemoria();

  /// Permite injetar instância substituta em testes de integração.
  @visibleForTesting
  static set instancia(RepositorioInteracoesVia? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Restaura a instância compartilhada para o estado inicial entre testes.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  final RepositorioCaderneta _repositorioCaderneta;
  final Map<String, DadosComunidadeVia> _dadosPorEscalada = {};
  final ValueNotifier<int> _versaoNotifier = ValueNotifier<int>(0);

  /// Cria uma instância de [RepositorioInteracoesViaMemoria].
  RepositorioInteracoesViaMemoria({RepositorioCaderneta? repositorioCaderneta})
    : _repositorioCaderneta =
          repositorioCaderneta ?? RepositorioCadernetaLocal.instancia;

  @override
  ValueListenable<int> get alteracoesListenable => _versaoNotifier;

  @override
  DadosComunidadeVia obterDadosEscalada(String escaladaUid) {
    return _dadosPorEscalada[escaladaUid] ?? const DadosComunidadeVia.vazio();
  }

  @override
  Future<AlertaSegurancaVia> reportarAlerta({
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
  }) async {
    final uidVia = escaladaUid.trim();
    if (uidVia.isEmpty) {
      throw ArgumentError.value(
        escaladaUid,
        'escaladaUid',
        'O identificador da escalada não pode ser vazio ao reportar um alerta.',
      );
    }

    final atual = obterDadosEscalada(uidVia);
    final alertas = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final indiceExistente = alertas.indexWhere((a) => a.categoria == categoria);

    final AlertaSegurancaVia resultado;
    if (indiceExistente >= 0) {
      final anterior = alertas[indiceExistente];
      final detalheLimpo = detalhe?.trim();
      resultado = anterior.copyWith(
        confirmacoesAtivas: anterior.confirmacoesAtivas + 1,
        detalhe: (detalheLimpo != null && detalheLimpo.isNotEmpty)
            ? detalheLimpo
            : anterior.detalhe,
      );
      alertas[indiceExistente] = resultado;
    } else {
      final perfil = _repositorioCaderneta.obterPerfil();
      resultado = AlertaSegurancaVia.criar(
        escaladaUid: uidVia,
        categoria: categoria,
        detalhe: detalhe,
        autorNomePublico: perfil.autorNomePublico,
      );
      alertas.insert(0, resultado);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    _versaoNotifier.value++;
    return resultado;
  }

  @override
  Future<void> confirmarAlerta({
    required String escaladaUid,
    required String alertaUid,
    required bool aindaEstaLa,
  }) async {
    final uidVia = escaladaUid.trim();
    final atual = obterDadosEscalada(uidVia);
    final alertas = List<AlertaSegurancaVia>.from(atual.alertasAtivos);
    final indice = alertas.indexWhere((a) => a.uid == alertaUid);
    if (indice < 0) return;

    if (aindaEstaLa) {
      final existente = alertas[indice];
      alertas[indice] = existente.copyWith(
        confirmacoesAtivas: existente.confirmacoesAtivas + 1,
      );
    } else {
      alertas.removeAt(indice);
    }

    _dadosPorEscalada[uidVia] = atual.copyWith(
      alertasAtivos: List.unmodifiable(alertas),
    );
    _versaoNotifier.value++;
  }
}
