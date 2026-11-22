// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../theme/cores_app.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';
import '../linha_localizacao_setor.dart';
import '../mapa_thumbnail.dart';
import 'bolha_alerta_seguranca_via.dart';
import 'grafico_consenso_grau_via.dart';

/// Cabeçalho declarativo (Dumb UI) da `ViaPage` exibindo nome completo, modalidade,
/// selo `CLÁSSICA` e o atalho hierárquico `Grupo > Setor`.
class CabecalhoIdentidadeVia extends StatelessWidget {
  /// Nome completo da escalada.
  final String nomeEscalada;

  /// Rótulo da modalidade (`'Esportiva'`, `'Boulder'`, etc.).
  final String modalidade;

  /// Indica se a via é destaque/clássica do setor.
  final bool ehDestaque;

  /// Identificador do croqui atual.
  final String cragId;

  /// Mensagem Protobuf da escalada para navegação no mapa.
  final Escalada escalada;

  /// Setor pai da escalada, quando disponível.
  final Setor? setor;

  /// Grupo pai do setor, quando disponível.
  final Grupo? grupo;

  /// Cria uma instância de [CabecalhoIdentidadeVia].
  const CabecalhoIdentidadeVia({
    super.key,
    required this.nomeEscalada,
    required this.modalidade,
    required this.ehDestaque,
    required this.cragId,
    required this.escalada,
    this.setor,
    this.grupo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nomeEscalada,
            style: TextStyle(
              color: cores.chalkWhite,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (modalidade.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
