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
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../view/function_library/markdown_offline.dart';
import '../../view/view_models/via_view_model.dart';
import '../linha_localizacao_setor.dart';
import '../mapa_thumbnail.dart';
import 'bolha_alerta_seguranca_via.dart';
import 'grafico_consenso_grau_via.dart';

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

  /// Código numérico Protobuf do grau oficial para rotulagem do gráfico de consenso.
  final int? codigoGrauOficial;

  /// Indica se a escalada pertence à modalidade Boulder (escala V).
  final bool ehBoulder;

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
    this.codigoGrauOficial,
    this.ehBoulder = false,
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
            codigoGrauOficial: codigoGrauOficial,
            ehBoulder: ehBoulder,
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

  /// Código numérico Protobuf do grau oficial para o gráfico de consenso.
  final int? codigoGrauOficial;

  /// Indica se a escalada pertence à modalidade Boulder (escala V).
  final bool ehBoulder;

  /// Subtítulo contextual do grau oficial.
  final String complementoGrauOficial;

  /// Dados do consenso comunitário (quando habilitado).
  final ConsensoGrauVia? consensoGrau;

  /// Cria uma instância de [CartaoGrauVia].
  const CartaoGrauVia({
    super.key,
    required this.rotuloGrauOficial,
    required this.grauOficial,
    this.codigoGrauOficial,
    this.ehBoulder = false,
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
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
                if (consenso.possuiVotos &&
                    consenso.distribuicaoDeltas.isNotEmpty) ...[
                  Divider(color: cores.graniteEdge, height: 24),
                  BarrasDistribuicaoGrauVia(
                    consenso: consenso,
                    codigoGrauOficial: codigoGrauOficial,
                    ehBoulder: ehBoulder,
                  ),
                ],
              ],
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
        if (possuiVotos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnelConsensoGrauVia(consenso: consenso),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  consenso.grauSugerido!,
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontSize: 28,
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
              fontSize: 18,
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
      );
    }
  }
}
/// Grade responsiva de especificações técnicas (`EXTENSÃO`, `PROTEÇÕES`, `PAREDE`, etc.) + tipo de ancoragem.
class GradeAtributosTecnicosVia extends StatelessWidget {
  /// Lista de atributos técnicos extraídos pelo `ViaViewModel`.
  final List<AtributoTecnicoVia> atributos;

  /// Descrição textual da parada/ancoragem, quando presente.
  final String? tipoAncoragem;

  /// Cria uma instância de [GradeAtributosTecnicosVia].
  const GradeAtributosTecnicosVia({
    super.key,
    required this.atributos,
    this.tipoAncoragem,
  });

  static IconData _resolverIcone(TipoIconeAtributoVia tipo) {
    return switch (tipo) {
      TipoIconeAtributoVia.extensao => Icons.height_rounded,
      TipoIconeAtributoVia.protecoes => Icons.shield_outlined,
      TipoIconeAtributoVia.parede => Icons.terrain_rounded,
      TipoIconeAtributoVia.exposicao => Icons.warning_amber_rounded,
      TipoIconeAtributoVia.enfiadas => Icons.format_list_numbered_rounded,
      TipoIconeAtributoVia.duracao => Icons.timer_outlined,
      TipoIconeAtributoVia.modalidade => Icons.merge_type_rounded,
      TipoIconeAtributoVia.distancia => Icons.straighten_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (atributos.isEmpty && tipoAncoragem == null) {
      return const SizedBox.shrink();
    }
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (atributos.isNotEmpty)
            LayoutBuilder(
              builder: (context, restricoes) {
                final larguraTotal = restricoes.maxWidth;
                final usarDuasColunas = larguraTotal >= 250;
                final larguraItem = usarDuasColunas
                    ? (larguraTotal - 12) / 2
                    : larguraTotal;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: atributos
                      .map(
                        (a) => SizedBox(
                          width: larguraItem,
                          child: buildOutlineStatCard(
                            context,
                            a.rotulo,
                            a.valor,
                            _resolverIcone(a.icone),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          if (tipoAncoragem != null) ...[
            if (atributos.isNotEmpty) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Row(
                children: [
                  Icon(Icons.anchor_rounded, size: 18, color: cores.beastHide),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ancoragem: $tipoAncoragem',
                      style: TextStyle(color: cores.chalkWhite, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Seções textuais de descrição oficial, peças móveis, rack e acesso.
class SecaoTextosETecnicasVia extends StatelessWidget {
  /// Identificador do croqui para resolução de imagens locais no `OfflineMarkdown`.
  final String cragId;

  /// Lista de seções textuais não vazias.
  final List<SecaoTextoVia> secoes;

  /// Cria uma instância de [SecaoTextosETecnicasVia].
  const SecaoTextosETecnicasVia({
    super.key,
    required this.cragId,
    required this.secoes,
  });

  @override
  Widget build(BuildContext context) {
    if (secoes.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: secoes.map((secao) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TituloSecaoVia(titulo: secao.titulo),
              const SizedBox(height: 10),
              secao.ehMarkdown
                  ? OfflineMarkdown(data: secao.conteudo, cragId: cragId)
                  : Text(
                      secao.conteudo,
                      style: TextStyle(
                        color: cores.chalkWhite,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Linha do tempo vertical detalhando cada enfiada de uma via de múltiplas enfiadas.
class SecaoEnfiadasVia extends StatelessWidget {
  /// Lista de enfiadas resumidas pelo `ViaViewModel`.
  final List<ResumoEnfiadaVia> enfiadas;

  /// Cria uma instância de [SecaoEnfiadasVia].
  const SecaoEnfiadasVia({super.key, required this.enfiadas});

  @override
  Widget build(BuildContext context) {
    if (enfiadas.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TituloSecaoVia(titulo: 'Enfiadas'),
          const SizedBox(height: 12),
          ...enfiadas.map((enf) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        enf.titulo,
                        style: TextStyle(
                          color: cores.chalkWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (enf.grau != null)
                        _PilulaDetalheCurto(texto: enf.grau!),
                      if (enf.extensao != null)
                        _PilulaDetalheCurto(texto: enf.extensao!),
                      if (enf.protecoes != null)
                        _PilulaDetalheCurto(texto: '${enf.protecoes} prot.'),
                    ],
                  ),
                  if (enf.equipamentoMovel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Móvel: ${enf.equipamentoMovel}',
                      style: TextStyle(color: cores.ashGrey, fontSize: 12),
                    ),
                  ],
                  if (enf.descricao != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      enf.descricao!,
                      style: TextStyle(color: cores.chalkWhite, fontSize: 13),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Lista de cartões clicáveis para vídeos e postagens curadas de beta (`escalada.betas` e `urlVideoBeta`).
class SecaoBetasMidiaVia extends StatelessWidget {
  /// Mídias disponíveis para a escalada.
  final List<ItemMidiaBetaVia> midias;

  /// Callback acionado ao tocar em um vídeo ou post de beta.
  final ValueChanged<String> aoAbrirMidia;

  /// Cria uma instância de [SecaoBetasMidiaVia].
  const SecaoBetasMidiaVia({
    super.key,
    required this.midias,
    required this.aoAbrirMidia,
  });

  @override
  Widget build(BuildContext context) {
    if (midias.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TituloSecaoVia(titulo: 'Vídeos & Betas'),
          const SizedBox(height: 10),
          ...midias.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => aoAbrirMidia(item.url),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: cores.rustIron,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titulo,
                              style: TextStyle(
                                color: cores.chalkWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.origemRotulo,
                              style: TextStyle(
                                color: cores.ashGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded, size: 18, color: cores.ashGrey),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Feed de notas e dicas públicas de beta registradas por escaladores da comunidade.
class SecaoNotasComunidadeVia extends StatelessWidget {
  /// Comentários públicos da via.
  final List<ComentarioComunidadeVia> comentarios;

  /// Cria uma instância de [SecaoNotasComunidadeVia].
  const SecaoNotasComunidadeVia({super.key, required this.comentarios});

  @override
  Widget build(BuildContext context) {
    if (comentarios.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSecaoVia(
            titulo: 'Notas da Comunidade (${comentarios.length})',
          ),
          const SizedBox(height: 10),
          ...comentarios.map((c) {
            final dia = c.criadoEm.day.toString().padLeft(2, '0');
            final mes = c.criadoEm.month.toString().padLeft(2, '0');
            final estilo = c.rotuloEstilo;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${c.autorNomePublico} • $dia/$mes/${c.criadoEm.year}',
                        style: TextStyle(
                          color: cores.ashGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (estilo != null) _PilulaDetalheCurto(texto: estilo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.texto,
                    style: TextStyle(
                      color: cores.chalkWhite,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Cartão de histórico de conquista/manutenção e botão funcional de cópia da chave Pix.
class SecaoHistoricoEPixVia extends StatelessWidget {
  /// Nomes dos conquistadores formatados.
  final String? conquistadoresTexto;

  /// Data de abertura da via.
  final String? dataAbertura;

  /// Data da última manutenção.
  final String? dataManutencao;

  /// Chave Pix opcional para apoio à manutenção.
  final String? chavePixManutencao;

  /// Callback acionado ao copiar a chave Pix.
  final VoidCallback aoCopiarPix;

  /// Cria uma instância de [SecaoHistoricoEPixVia].
  const SecaoHistoricoEPixVia({
    super.key,
    this.conquistadoresTexto,
    this.dataAbertura,
    this.dataManutencao,
    this.chavePixManutencao,
    required this.aoCopiarPix,
  });

  @override
  Widget build(BuildContext context) {
    final temHistorico =
        conquistadoresTexto != null ||
        dataAbertura != null ||
        dataManutencao != null;
    if (!temHistorico && chavePixManutencao == null) {
      return const SizedBox.shrink();
    }
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (temHistorico)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: cores.ashGrey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HISTÓRICO & CONQUISTA',
                        style: TextStyle(
                          color: cores.ashGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (conquistadoresTexto != null)
                  _LinhaHistorico(
                    rotulo: 'CONQUISTADORES',
                    valor: conquistadoresTexto!,
                  ),
                if (dataAbertura != null)
                  _LinhaHistorico(rotulo: 'ABERTURA', valor: dataAbertura!),
                if (dataManutencao != null)
                  _LinhaHistorico(rotulo: 'MANUTENÇÃO', valor: dataManutencao!),
              ],
            ),
          ),
        if (chavePixManutencao != null) ...[
          if (temHistorico) const SizedBox(height: 12),
          InkWell(
            key: const Key('btn_copiar_pix_manutencao'),
            borderRadius: BorderRadius.circular(12),
            onTap: aoCopiarPix,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: cores.fernGreen.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cores.fernGreen.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    color: cores.fernGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Apoie a Manutenção (Copiar Pix: $chavePixManutencao)',
                      style: TextStyle(
                        color: cores.chalkWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.copy_rounded, color: cores.fernGreen, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TituloSecaoVia extends StatelessWidget {
  final String titulo;

  const _TituloSecaoVia({required this.titulo});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: cores.beastHide,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 36,
          color: cores.beastHide.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _PilulaDetalheCurto extends StatelessWidget {
  final String texto;

  const _PilulaDetalheCurto({required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cores.deepBasalt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cores.beastHide,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LinhaHistorico extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _LinhaHistorico({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              color: cores.ashGrey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(color: cores.chalkWhite, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
