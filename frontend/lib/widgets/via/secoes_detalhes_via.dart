// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';
import '../../view/function_library/markdown_offline.dart';
import 'secao_betas_expansivel_via.dart';

export 'secao_betas_expansivel_via.dart';

/// Faixa compacta declarativa (Dumb UI) de pílulas técnicas e parada da escalada,
/// eliminando caixas largas semivazias em vias esparsas.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (atributos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: atributos
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: cores.deepBasalt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cores.graniteEdge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          _resolverIcone(a.icone),
                          size: 14,
                          color: AppColors.brandColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  a.rotulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: cores.ashGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  a.valor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: cores.chalkWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        if (tipoAncoragem != null) ...[
          if (atributos.isNotEmpty) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: cores.deepBasalt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Row(
              children: [
                Icon(Icons.anchor_rounded, size: 16, color: cores.beastHide),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      ChaveTexto.viaAncoragemPrefixo,
                      {'tipo': tipoAncoragem},
                    ),
                    style: TextStyle(color: cores.chalkWhite, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Seções textuais declarativas (Dumb UI) de descrição oficial, peças móveis, rack e acesso,
/// unificadas sob o mesmo padrão visual e tipográfico de cartão de `HISTÓRICO & CONQUISTA`.
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

  static IconData _iconeParaSecao(String titulo) {
    final minusculo = titulo.toLowerCase();
    if (minusculo == tr(ChaveTexto.viaSecaoPecasMoveis).toLowerCase() ||
        minusculo == tr(ChaveTexto.viaSecaoRackEquipamento).toLowerCase() ||
        minusculo.contains('móveis') ||
        minusculo.contains('rack')) {
      return Icons.hardware_outlined;
    }
    if (minusculo == tr(ChaveTexto.viaSecaoDescricaoAcesso).toLowerCase() ||
        minusculo.contains('acesso')) {
      return Icons.hiking_rounded;
    }
    if (minusculo == tr(ChaveTexto.viaSecaoDescricaoAncoragem).toLowerCase() ||
        minusculo.contains('ancoragem')) {
      return Icons.anchor_rounded;
    }
    return Icons.notes_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (secoes.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: secoes.map((secao) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CabecalhoSecaoPadraoVia(
                  icone: _iconeParaSecao(secao.titulo),
                  tituloCaixaAlta: secao.titulo.toUpperCase(),
                ),
                const SizedBox(height: 12),
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
          ),
        );
      }).toList(),
    );
  }
}

/// Linha do tempo vertical declarativa (Dumb UI) detalhando cada enfiada de uma via multienfiada.
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cores.graniteEdge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CabecalhoSecaoPadraoVia(
              icone: Icons.format_list_numbered_rounded,
              tituloCaixaAlta: context.tr(
                ChaveTexto.viaEnfiadasContagem,
                {'n': enfiadas.length},
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < enfiadas.length; i++)
              Container(
                margin: EdgeInsets.only(
                  bottom: i == enfiadas.length - 1 ? 0 : 10,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cores.deepBasalt,
                  borderRadius: BorderRadius.circular(12),
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
                          enfiadas[i].titulo,
                          style: TextStyle(
                            color: cores.chalkWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (enfiadas[i].grau != null)
                          PilulaDetalheCurtoVia(texto: enfiadas[i].grau!),
                        if (enfiadas[i].extensao != null)
                          PilulaDetalheCurtoVia(texto: enfiadas[i].extensao!),
                        if (enfiadas[i].protecoes != null)
                          PilulaDetalheCurtoVia(
                            texto: context.tr(
                              ChaveTexto.viaProtecoesAbrev,
                              {'n': enfiadas[i].protecoes},
                            ),
                          ),
                      ],
                    ),
                    if (enfiadas[i].equipamentoMovel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.tr(
                          ChaveTexto.viaMovelPrefixo,
                          {'equip': enfiadas[i].equipamentoMovel},
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

/// Lista declarativa (Dumb UI) de cartões clicáveis para vídeos e postagens curadas de beta.
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
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: cores.ashGrey,
                      ),
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

/// Feed declarativo (Dumb UI) de notas e dicas públicas pré-formatadas pelo `ViaViewModel`.
class SecaoNotasComunidadeVia extends StatelessWidget {
  /// Notas públicas pré-formatadas para exibição direta.
  final List<NotaComunidadeApresentacao> notas;

  /// Cria uma instância de [SecaoNotasComunidadeVia].
  const SecaoNotasComunidadeVia({super.key, required this.notas});

  @override
  Widget build(BuildContext context) {
    if (notas.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TituloSecaoVia(
            titulo: 'Betas da Comunidade (${notas.length})',
          ),
          const SizedBox(height: 10),
          ...notas.map((nota) {
            final estilo = nota.rotuloEstilo;

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
                        nota.cabecalhoAutorData,
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
                    nota.texto,
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

/// Cartão declarativo (Dumb UI) de histórico de conquista/manutenção e cópia da chave Pix.
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
