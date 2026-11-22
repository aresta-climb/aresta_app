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

/// Cor âmbar-dourada de destaque para o selo e a estrela de vias clássicas (`★ CLÁSSICA`).
const Color _corEstrelaClassica = Color(0xFFFBBF24);

/// Cabeçalho declarativo (Dumb UI) da `ViaPage` exibindo nome completo, modalidade,
/// selo dourado `★ CLÁSSICA` e o atalho hierárquico `Grupo > Setor`.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nomeEscalada,
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (modalidade.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: cores.deepBasalt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cores.graniteEdge),
                ),
                child: Text(
                  modalidade.toUpperCase(),
                  style: TextStyle(
                    color: cores.beastHide,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (ehDestaque)
              Container(
                key: const Key('selo_via_classica'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _corEstrelaClassica.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _corEstrelaClassica.withValues(alpha: 0.55),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: _corEstrelaClassica,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CLÁSSICA',
                      style: TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
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
    );
  }
}

/// Área heroica superior (Dumb UI) combinando croqui/mapa, cartão de grau, votação e bolhas de alerta.
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

  /// Callback acionado ao tocar para abrir o croqui interativo.
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

  /// Callback opcional para voto direto em uma das 5 pílulas de grau (`-2` a `+2`).
  final ValueChanged<int>? aoVotarGrau;

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
    this.aoVotarGrau,
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
        CartaoGrauVia(
          rotuloGrauOficial: rotuloGrauOficial,
          grauOficial: grauOficial,
          complementoGrauOficial: complementoGrauOficial,
          apresentacaoConsenso: apresentacaoConsenso,
          aoVotarGrau: aoVotarGrau,
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
          padding: EdgeInsets.only(
            top: estadoCroqui.mapasMiniatura.isNotEmpty
                ? 0
                : (exibirCartaoGrau ? 14 : 44),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: filhos,
          ),
        ),
        Positioned(
          top: estadoCroqui.mapasMiniatura.isNotEmpty ? 10 : 0,
          right: estadoCroqui.mapasMiniatura.isNotEmpty ? 10 : 4,
          child: BolhasFlutuantesAlertaVia(
            alertas: alertasAtivos,
            aoSelecionarAlerta: aoTocarAlerta,
          ),
        ),
      ],
    );
  }
}

/// Cartão declarativo (Dumb UI) exibindo o Grau Oficial, o Consenso da Comunidade,
/// o gráfico de distribuição e as 5 pílulas interativas de votação (Opção 2).
class CartaoGrauVia extends StatelessWidget {
  /// Rótulo superior da coluna oficial (`'GRAU OFICIAL'` ou `'GRAU MÁXIMO'`).
  final String rotuloGrauOficial;

  /// Valor textual do grau oficial, ou `null` quando indefinido.
  final String? grauOficial;

  /// Subtítulo contextual do grau oficial.
  final String complementoGrauOficial;

  /// Apresentação pré-calculada do consenso comunitário (quando habilitado).
  final ApresentacaoConsensoGrauVia? apresentacaoConsenso;

  /// Callback opcional para votação direta nas 5 pílulas de percepção de grau.
  final ValueChanged<int>? aoVotarGrau;

  /// Cria uma instância de [CartaoGrauVia].
  const CartaoGrauVia({
    super.key,
    required this.rotuloGrauOficial,
    required this.grauOficial,
    required this.complementoGrauOficial,
    this.apresentacaoConsenso,
    this.aoVotarGrau,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final consenso = apresentacaoConsenso;

    final blocoOficial = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotuloGrauOficial,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          grauOficial ?? '—',
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          complementoGrauOficial,
          style: TextStyle(color: cores.ashGrey, fontSize: 11),
        ),
      ],
    );

    if (consenso == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cores.deepBasalt.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cores.graniteEdge),
        ),
        child: blocoOficial,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.deepBasalt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, restricoes) {
              final empilhar = restricoes.maxWidth < 260;
              final blocoComunidade = _BlocoConsensoComunidade(
                apresentacao: consenso,
              );
              if (empilhar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    blocoOficial,
                    Divider(color: cores.graniteEdge, height: 20),
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
          if (consenso.possuiVotos &&
              consenso.faixasDistribuicao.isNotEmpty) ...[
            Divider(color: cores.graniteEdge, height: 20),
            BarrasDistribuicaoGrauVia(apresentacao: consenso),
          ],
          if (aoVotarGrau != null && consenso.pilulasVoto.isNotEmpty) ...[
            const SizedBox(height: 12),
            SeletorPilulasVotoGrauVia(
              pilulas: consenso.pilulasVoto,
              aoSelecionarDelta: aoVotarGrau!,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlocoConsensoComunidade extends StatelessWidget {
  final ApresentacaoConsensoGrauVia apresentacao;

  const _BlocoConsensoComunidade({required this.apresentacao});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONSENSO DA COMUNIDADE',
          style: TextStyle(
            color: cores.rustIron,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        if (apresentacao.possuiVotos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnelConsensoGrauVia(apresentacao: apresentacao, tamanho: 26),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  apresentacao.grauSugerido!,
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            'Sem votos',
            style: TextStyle(
              color: cores.ashGrey,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          apresentacao.subtituloTendencia,
          style: TextStyle(color: cores.ashGrey, fontSize: 11),
        ),
      ],
    );
  }
}

/// Seção declarativa (Dumb UI) que renderiza a foto do croqui (`MapaThumbnail` com rótulo da linha)
/// ou o atalho compacto `'VER NO CROQUI INTERATIVO'`.
class SecaoMapaCroquiVia extends StatelessWidget {
  /// Estado pré-resolvido de mapas e referências da escalada.
  final EstadoCroquiVia estadoCroqui;

  /// Identificador do croqui.
  final String cragId;

  /// Nome da escalada para contexto do carrossel.
  final String nomeEscalada;

  /// Setor pai opcional.
  final Setor? setor;

  /// Grupo pai opcional.
  final Grupo? grupo;

  /// Callback acionado ao tocar em `'VER NO CROQUI INTERATIVO'`.
  final VoidCallback aoAbrirCroquiInterativo;

  /// Cria uma instância de [SecaoMapaCroquiVia].
  const SecaoMapaCroquiVia({
    super.key,
    required this.estadoCroqui,
    required this.cragId,
    required this.nomeEscalada,
    this.setor,
    this.grupo,
    required this.aoAbrirCroquiInterativo,
  });

  @override
  Widget build(BuildContext context) {
    if (estadoCroqui.mapasMiniatura.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: estadoCroqui.aspectRatioMiniatura.clamp(1.2, 2.2),
                child: MapaThumbnail(
                  mapas: estadoCroqui.mapasMiniatura,
                  cragId: cragId,
                  setorContext: setor,
                  grupoContext: grupo,
                  nomeContexto: nomeEscalada,
                  carrosselItensOverride: estadoCroqui.itensCarrosselMiniatura,
                ),
              ),
              if (estadoCroqui.rotuloLinhaNoMapa != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      'Linha #${estadoCroqui.rotuloLinhaNoMapa}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (estadoCroqui.itensNavegacaoCroqui.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: aoAbrirCroquiInterativo,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: context.colors.deepBasalt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandColor.withValues(alpha: 0.65),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                color: AppColors.brandColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'VER NO CROQUI INTERATIVO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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
