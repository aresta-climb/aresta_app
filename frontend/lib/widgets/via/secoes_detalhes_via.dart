// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../navigation/arvore_navegacao.dart';
import '../../navigation/construtor_reativo_pagina.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../services/firebase/telemetria.dart';
import '../../theme/cores_app.dart';
import '../../utils/consulta_dataset.dart';
import '../../utils/formatador_escalada.dart';
import '../linha_localizacao_setor.dart';
import '../mapa_thumbnail.dart';
import 'bolha_alerta_seguranca_via.dart';

/// Cabeçalho de identidade da `ViaPage` apresentando o nome completo da via sem truncamento,
/// pílulas de modalidade/`CLÁSSICA` e o atalho hierárquico `Grupo > Setor`.
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

/// Área heroica superior combinando o croqui/mapa e o cartão de grau sob um [Stack]
/// para ancorar as bolhas vermelhas flutuantes de alerta no canto superior direito.
class AreaHeroiTopoGrauVia extends StatelessWidget {
  /// Escalada Protobuf exibida.
  final Escalada escalada;

  /// Identificador do croqui.
  final String cragId;

  /// Pico pai para resolução de referências de mapa.
  final Pico? pico;

  /// Setor pai da escalada.
  final Setor? setor;

  /// Grupo pai do setor.
  final Grupo? grupo;

  /// Indica se a navegação partiu diretamente da `MapaPage`.
  final bool fromMapaPage;

  /// Indica se o cartão de grau deve ser renderizado.
  final bool exibirCartaoGrau;

  /// Rótulo do grau oficial (`'GRAU OFICIAL'` ou `'GRAU MÁXIMO'`).
  final String rotuloGrauOficial;

  /// Grau oficial formatado, ou `null` quando indefinido.
  final String? grauOficial;

  /// Subtítulo abaixo do grau oficial.
  final String complementoGrauOficial;

  /// Consenso de grau da comunidade (nulo quando a feature flag estiver desativada).
  final ConsensoGrauVia? consensoGrau;

  /// Alertas ativos exibidos como bolhas vermelhas flutuantes no canto superior direito.
  final List<AlertaSegurancaVia> alertasAtivos;

  /// Callback acionado ao tocar em uma bolha de alerta.
  final ValueChanged<AlertaSegurancaVia> aoTocarAlerta;

  /// Cria uma instância de [AreaHeroiTopoGrauVia].
  const AreaHeroiTopoGrauVia({
    super.key,
    required this.escalada,
    required this.cragId,
    this.pico,
    this.setor,
    this.grupo,
    this.fromMapaPage = false,
    required this.exibirCartaoGrau,
    required this.rotuloGrauOficial,
    required this.grauOficial,
    required this.complementoGrauOficial,
    required this.consensoGrau,
    required this.alertasAtivos,
    required this.aoTocarAlerta,
  });

  @override
  Widget build(BuildContext context) {
    final filhos = <Widget>[
      SecaoMapaCroquiVia(
        escalada: escalada,
        cragId: cragId,
        pico: pico,
        setor: setor,
        grupo: grupo,
        fromMapaPage: fromMapaPage,
      ),
      if (exibirCartaoGrau)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CartaoGrauVia(
            rotuloGrauOficial: rotuloGrauOficial,
            grauOficial: grauOficial,
            complementoGrauOficial: complementoGrauOficial,
            consensoGrau: consensoGrau,
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

/// Cartão de destaque exibindo o Grau Oficial do Conquistador em harmonia com o Consenso da Comunidade.
class CartaoGrauVia extends StatelessWidget {
  /// Rótulo superior da coluna oficial (`'GRAU OFICIAL'` ou `'GRAU MÁXIMO'`).
  final String rotuloGrauOficial;

  /// Valor textual do grau oficial, ou `null` quando indefinido.
  final String? grauOficial;

  /// Subtítulo contextual do grau oficial.
  final String complementoGrauOficial;

  /// Dados do consenso comunitário (quando habilitado).
  final ConsensoGrauVia? consensoGrau;

  /// Cria uma instância de [CartaoGrauVia].
  const CartaoGrauVia({
    super.key,
    required this.rotuloGrauOficial,
    required this.grauOficial,
    required this.complementoGrauOficial,
    this.consensoGrau,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final consenso = consensoGrau;

    final blocoOficial = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotuloGrauOficial,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          grauOficial ?? '—',
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          complementoGrauOficial,
          style: TextStyle(color: cores.ashGrey, fontSize: 12),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: consenso == null
          ? blocoOficial
          : LayoutBuilder(
              builder: (context, restricoes) {
                final empilhar = restricoes.maxWidth < 260;
                final blocoComunidade = _BlocoConsensoComunidade(
                  consenso: consenso,
                );
                if (empilhar) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      blocoOficial,
                      Divider(color: cores.graniteEdge, height: 24),
                      blocoComunidade,
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: blocoOficial),
                      VerticalDivider(
                        color: cores.graniteEdge,
                        width: 24,
                        thickness: 1,
                      ),
                      Expanded(child: blocoComunidade),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _BlocoConsensoComunidade extends StatelessWidget {
  final ConsensoGrauVia consenso;

  const _BlocoConsensoComunidade({required this.consenso});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final possuiVotos = consenso.possuiVotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONSENSO DA COMUNIDADE',
          style: TextStyle(
            color: cores.rustIron,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          possuiVotos ? consenso.grauSugerido! : 'Sem votos',
          style: TextStyle(
            color: possuiVotos ? cores.chalkWhite : cores.ashGrey,
            fontSize: possuiVotos ? 28 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          possuiVotos
              ? (consenso.resumoTendencia ?? '${consenso.totalVotos} avaliações')
              : 'Registre sua ascensão para avaliar',
          style: TextStyle(color: cores.ashGrey, fontSize: 12),
        ),
      ],
    );
  }
}

/// Renderiza a miniatura interativa do croqui (`MapaThumbnail`) ou o botão `'VER NO CROQUI INTERATIVO'`
/// para qualquer modalidade mapeada (incluindo Highlines).
class SecaoMapaCroquiVia extends StatelessWidget {
  /// Escalada exibida.
  final Escalada escalada;

  /// Identificador do croqui.
  final String cragId;

  /// Pico pai usado para localizar referências em mapas.
  final Pico? pico;

  /// Setor pai.
  final Setor? setor;

  /// Grupo pai.
  final Grupo? grupo;

  /// Indica se a tela atual foi aberta diretamente a partir da `MapaPage`.
  final bool fromMapaPage;

  /// Cria uma instância de [SecaoMapaCroquiVia].
  const SecaoMapaCroquiVia({
    super.key,
    required this.escalada,
    required this.cragId,
    this.pico,
    this.setor,
    this.grupo,
    this.fromMapaPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final nome = obterNomeEscalada(escalada);
    ResolvedDataset? resolved;
    if (pico != null) {
      final resolver =
          PageListenableBuilder.resolverOf(context) ??
          DatasetResolver(pico: pico!);
      resolved = escalada.uid.isNotEmpty
          ? resolver.obterPorUid(escalada.uid)
          : resolver.buscarPorNome(
              grupoNome: grupo?.nome,
              setorNome: setor?.nome,
              escaladaNome: nome,
            );
    }

    final mapasValidos = escalada.mapas
        .where(
          (m) =>
              m.caminhoImagemMapa.isNotEmpty &&
              m.larguraMapa > 0 &&
              m.alturaMapa > 0,
        )
        .toList();

    if (mapasValidos.isNotEmpty) {
      final carrosselItens = resolved != null
          ? resolved.resolverCarrosselUnificado()
          : mapasValidos
                .map(
                  (m) => CarrosselItemData(
                    mapaCaminhoImagem: m.caminhoImagemMapa,
                    setorContextNome: setor?.nome,
                    grupoContextNome: grupo?.nome,
                    escaladaContextNome: nome,
                  ),
                )
                .toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio:
                mapasValidos.first.larguraMapa / mapasValidos.first.alturaMapa,
            child: MapaThumbnail(
              mapas: mapasValidos,
              cragId: cragId,
              setorContext: setor,
              grupoContext: grupo,
              nomeContexto: nome,
              carrosselItensOverride: carrosselItens,
            ),
          ),
        ),
      );
    }

    final referencias = resolved?.referencias ?? const [];
    if (referencias.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          TelemetryService.instance.logAcaoEscalada(
            cragId,
            setor?.nome ?? '',
            nome,
            'ver_no_mapa_destaque',
            'detalhes_via',
          );
          if (fromMapaPage) {
            AppNav.back(context);
          } else {
            final mapasData = referencias
                .map(
                  (refNoMapa) => CarrosselItemData(
                    mapaCaminhoImagem: refNoMapa.mapa.caminhoImagemMapa,
                    setorContextNome: refNoMapa.setorContexto?.nome,
                    grupoContextNome: refNoMapa.grupoContexto?.nome,
                    escaladaContextNome: nome,
                    initialSelectedId:
                        refNoMapa.referencia.pontosUids.isNotEmpty
                        ? refNoMapa.referencia.pontosUids.first
                        : null,
                  ),
                )
                .toList();
            AppNav.toMapas(context, cragId: cragId, mapas: mapasData);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.brandColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'VER NO CROQUI INTERATIVO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
