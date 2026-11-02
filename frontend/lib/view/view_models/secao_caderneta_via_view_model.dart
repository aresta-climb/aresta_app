// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/controlador_interacoes_usuario.dart';
import '../../utils/formatador_escalada.dart';
import 'registro_cadena_view_model.dart';

/// Modelo de apresentação (MVVM) do bloco de Caderneta Esportiva exibido na tela de detalhes da Via.
///
/// Isola completamente a camada de UI ([SecaoCadernetaVia] e [ViaPage]) do acesso direto a
/// singletons de serviço, consultas de melhor ascensão, extração de graus Protobuf e
/// formatação de rótulos esportivos.
class SecaoCadernetaViaViewModel extends ChangeNotifier {
  /// Escalada Protobuf atualmente exibida na tela de detalhes.
  final Escalada escalada;

  /// Repositório local-first da caderneta esportiva.
  final RepositorioCaderneta repositorio;

  /// Controlador reativo de visibilidade das interações de perfil e caderneta.
  final ControladorInteracoesUsuario controladorInteracoes;

  /// Inicializa o ViewModel conectando ouvintes reativos à caderneta e às preferências do usuário.
  SecaoCadernetaViaViewModel({
    required this.escalada,
    RepositorioCaderneta? repositorio,
    ControladorInteracoesUsuario? controladorInteracoes,
  }) : repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia {
    this.repositorio.cadenasNotifier.addListener(_aoAtualizar);
    this.controladorInteracoes.interacoesAtivasNotifier.addListener(
      _aoAtualizar,
    );
  }

  void _aoAtualizar() => notifyListeners();

  @override
  void dispose() {
    repositorio.cadenasNotifier.removeListener(_aoAtualizar);
    controladorInteracoes.interacoesAtivasNotifier.removeListener(_aoAtualizar);
    super.dispose();
  }

  /// Indica se a seção de caderneta deve estar visível na tela da via.
  bool get visivel => controladorInteracoes.exibirElementosInterativos;

  /// Melhor ascensão ou tentativa já registrada para esta escalada, se houver.
  Cadena? get melhorAscensao =>
      escalada.hasUid() && escalada.uid.isNotEmpty
          ? repositorio.obterMelhorAscensao(escalada.uid)
          : null;

  /// Indica se existe ao menos um registro (cadena ou tentativa) para a escalada.
  bool get possuiAscensao => melhorAscensao != null;

  /// Indica se a melhor ascensão registrada corresponde a um encadenamento completo.
  bool get isCadena => melhorAscensao?.isCadena ?? false;

  /// Texto resumido do selo esportivo (ex.: `'Encadenada em 14/09 (Flash)'` ou `'Tentativa em 03/05'`).
  String? get resumoAscensao {
    final ascensao = melhorAscensao;
    if (ascensao == null) return null;

    final dia = ascensao.dataAscensao.day.toString().padLeft(2, '0');
    final mes = ascensao.dataAscensao.month.toString().padLeft(2, '0');
    if (ascensao.isCadena) {
      return 'Encadenada em $dia/$mes (${ascensao.tipoAscensao.rotulo})';
    }
    return 'Tentativa em $dia/$mes';
  }

  /// Notas privadas formatadas entre aspas tipográficas, ou `null` quando vazias.
  String? get citacaoNotasPrivadas {
    final notas = melhorAscensao?.notasPrivadas ?? '';
    if (notas.isEmpty) return null;
    return '“$notas”';
  }

  /// Rótulo contextual do botão de ação principal.
  String get rotuloBotao => possuiAscensao
      ? 'Nova Ascensão / Tentativa'
      : 'Registrar Cadena / Tentativa';

  /// Constrói um [RegistroCadenaViewModel] pré-configurado com os metadados da [escalada].
  RegistroCadenaViewModel criarViewModelRegistro() {
    final tipoEscalada = escalada.whichTipo() == Escalada_Tipo.boulder
        ? TipoEscalada.boulder
        : TipoEscalada.guiado;

    return RegistroCadenaViewModel(
      escaladaUid: escalada.uid,
      nomeEscalada: obterNomeEscalada(escalada),
      tipoEscaladaPadrao: tipoEscalada,
      grauSugerido: obterCodigoGrauOficial(escalada),
      repositorio: repositorio,
    );
  }
}
