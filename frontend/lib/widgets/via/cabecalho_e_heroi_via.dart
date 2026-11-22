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
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Text(
                    modalidade.toUpperCase(),
                    style: TextStyle(
                      color: cores.beastHide,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (ehDestaque)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'CLÁSSICA',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (setor != null && setor!.nome.isNotEmpty) ...[
            const SizedBox(height: 10),
            LinhaLocalizacaoSetor(
              cragId: cragId,
              setor: setor!,
              grupo: grupo,
              escalada: escalada,
            ),
          ],
        ],
      ),
    );
  }
}

/// Área heroica superior (Dumb UI) combinando croqui/mapa, cartão de grau e bolhas flutuantes de alerta.
class AreaHeroiTopoGrauVia extends StatelessWidget {
  /// Estado pré-resolvido de miniatura ou navegação do croqui.
  final EstadoCroquiVia estadoCroqui;

  /// Identificador do croqui.
  final String cragId;

  /// Nome da escalada usado na miniatura.
  final String nomeEscalada;

  /// Setor pai opcional.
  final Setor? setor;

  /// Grupo pai opcional.
  final Grupo? grupo;

  /// Callback acionado ao tocar em `'VER NO CROQUI INTERATIVO'`.
  final VoidCallback aoAbrirCroquiInterativo;

  /// Indica se o cartão de grau deve ser renderizado.
  final bool exibirCartaoGrau;

  /// Rótulo do grau oficial (`'GRAU OFICIAL'` ou `'GRAU MÁXIMO'`).
  final String rotuloGrauOficial;

  /// Grau oficial formatado, ou `null` quando indefinido.
  final String? grauOficial;

  /// Subtítulo abaixo do grau oficial.
  final String complementoGrauOficial;

  /// Apresentação pré-calculada do consenso de grau da comunidade.
  final ApresentacaoConsensoGrauVia? apresentacaoConsenso;

  /// Alertas ativos exibidos como bolhas vermelhas flutuantes no canto superior direito.
  final List<AlertaSegurancaVia> alertasAtivos;

  /// Callback acionado ao tocar em uma bolha de alerta.
  final ValueChanged<AlertaSegurancaVia> aoTocarAlerta;

  /// Cria uma instância de [AreaHeroiTopoGrauVia].
  const AreaHeroiTopoGrauVia({
    super.key,
    required this.estadoCroqui,
    required this.cragId,
    required this.nomeEscalada,
    this.setor,
    this.grupo,
    required this.aoAbrirCroquiInterativo,
    required this.exibirCartaoGrau,
    required this.rotuloGrauOficial,
    required this.grauOficial,
    required this.complementoGrauOficial,
    required this.apresentacaoConsenso,
    required this.alertasAtivos,
    required this.aoTocarAlerta,
  });

  @override
  Widget build(BuildContext context) {
    final filhos = <Widget>[
      SecaoMapaCroquiVia(
        estadoCroqui: estadoCroqui,
        cragId: cragId,
        nomeEscalada: nomeEscalada,
        setor: setor,
        grupo: grupo,
        aoAbrirCroquiInterativo: aoAbrirCroquiInterativo,
      ),
      if (exibirCartaoGrau)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CartaoGrauVia(
            rotuloGrauOficial: rotuloGrauOficial,
            grauOficial: grauOficial,
            complementoGrauOficial: complementoGrauOficial,
            apresentacaoConsenso: apresentacaoConsenso,
          ),
        ),
    ];

    if (alertasAtivos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filhos,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: exibirCartaoGrau ? 14 : 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: filhos,
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: BolhasFlutuantesAlertaVia(
            alertas: alertasAtivos,
            aoSelecionarAlerta: aoTocarAlerta,
          ),
        ),
      ],
    );
  }
}

/// Cartão declarativo (Dumb UI) exibindo o Grau Oficial ao lado do Consenso da Comunidade.
class CartaoGrauVia extends StatelessWidget {
  /// Rótulo superior da coluna oficial (`'GRAU OFICIAL'` ou `'GRAU MÁXIMO'`).
  final String rotuloGrauOficial;

  /// Valor textual do grau oficial, ou `null` quando indefinido.
  final String? grauOficial;

}
