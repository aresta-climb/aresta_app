// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../main.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../view/function_library/comunidade_functions.dart';
import '../../view/function_library/markdown_offline.dart';
import '../../utils/categorizacao_pico.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/cores_app.dart';
import '../../navigation/arvore_navegacao.dart';

/// Subpágina dedicada a apresentar dados de acesso, contexto e exploração do pico.
///
/// Exibe seções de introdução, sobre o local, instruções de como chegar e atalho
/// direto para abertura no Google Maps com rota predefinida.
class ExplorarLocalPage extends StatelessWidget {
  /// Dados gerais do pico.
  final Pico pico;

  /// Identificador do croqui/crag.
  final String cragId;

  /// Categorias semânticas extraídas dos botões e textos do croqui.
  final PicoCategorizedData categories;

  /// Callback opcional para abertura de link externo, facilitando testes e injeção de dependência.
  final Future<void> Function(String url, String nomeServico)? aoAbrirLinkExterno;

  const ExplorarLocalPage({
    super.key,
    required this.pico,
    required this.cragId,
    required this.categories,
    this.aoAbrirLinkExterno,
  });

  void _pushTextNode(BuildContext context, String title, String content, {IconData? icon}) {
    final treeNav = TreeNavigationWrapper.currentTreeController;
    if (treeNav != null) {
      treeNav.navigateTo(
        TextNode(
          title: title,
          content: content,
          cragId: cragId,
          icon: icon,
          parent: treeNav.currentNode,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final urlMaps = resolverUrlGoogleMapsPico(pico);

    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      appBar: buildCommonAppBar(
        context,
        'EXPLORAR O LOCAL',
        subtitle: pico.nome,
        backgroundColor: context.colors.deepBasalt,
        foregroundColor: context.colors.chalkWhite,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            if (categories.capa.isNotEmpty) ...[
              OfflineMarkdown(
                data: categories.capa.first.destino.secaoTextual.conteudo,
                cragId: cragId,
              ),
              const SizedBox(height: 24),
            ],
            if (categories.introducao.isNotEmpty)
              ...categories.introducao.map(
                (b) => PicoMenuCard(
                  title: b.texto,
                  subtitle: 'Apresentação geral e introdução ao local.',
                  icon: Icons.info_outline,
                  iconColor: context.colors.ashGrey,
                  backgroundColor: context.colors.caveShadow,
                  titleColor: context.colors.chalkWhite,
                  subtitleColor: context.colors.fishBone,
                  onTap: () => _pushTextNode(
                    context,
                    b.texto,
                    b.destino.secaoTextual.conteudo,
                    icon: Icons.info_outline,
                  ),
                ),
              ),

            if (categories.sobre.isNotEmpty)
              PicoMenuCard(
                title: 'Sobre o local',
                subtitle: categories.sobre.length == 1
                    ? categories.sobre.first.texto
                    : 'História do complexo de montanha, conquistas pioneiras e curiosidades locais.',
                icon: Icons.menu_book,
                iconColor: context.colors.dryMoss,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.fishBone,
                onTap: () {
                  if (categories.sobre.length == 1) {
                    _pushTextNode(
                      context,
                      'Sobre o local',
                      categories.sobre.first.destino.secaoTextual.conteudo,
                      icon: Icons.menu_book,
                    );
                  } else {
                    final carouselData = categories.sobre.map((b) => TextCarouselData(
                      title: b.texto,
                      content: b.destino.secaoTextual.conteudo,
                      icon: Icons.menu_book,
                    )).toList();
                    final treeNav = TreeNavigationWrapper.currentTreeController;
                    if (treeNav != null) {
                      treeNav.navigateTo(
                        TextCarouselNode(
                          cragId: cragId,
                          texts: carouselData,
                          parent: treeNav.currentNode,
                        ),
                      );
                    }
                  }
                },
              ),
            if (categories.sobre.isEmpty && pico.descricao.isNotEmpty)
              PicoMenuCard(
                title: 'Sobre o local',
                subtitle:
                    'História do complexo de montanha, conquistas pioneiras e curiosidades locais.',
                icon: Icons.menu_book,
                iconColor: context.colors.dryMoss,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.fishBone,
                onTap: () =>
                    _pushTextNode(context, 'Sobre o local', pico.descricao, icon: Icons.menu_book),
              ),

            if (categories.comoChegar.isNotEmpty)
              PicoMenuCard(
                title: 'Como chegar',
                subtitle: categories.comoChegar.length == 1
                    ? categories.comoChegar.first.texto
                    : 'Instruções de acesso e navegação até a base da montanha.',
                icon: Icons.near_me,
                iconColor: context.colors.rustIron,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.fishBone,
                onTap: () {
                  if (categories.comoChegar.length == 1) {
                    _pushTextNode(
                      context,
                      'Como chegar',
                      categories.comoChegar.first.destino.secaoTextual.conteudo,
                      icon: Icons.near_me,
                    );
                  } else {
                    final carouselData = categories.comoChegar.map((b) => TextCarouselData(
                      title: b.texto,
                      content: b.destino.secaoTextual.conteudo,
                      icon: Icons.near_me,
                    )).toList();
                    final treeNav = TreeNavigationWrapper.currentTreeController;
                    if (treeNav != null) {
                      treeNav.navigateTo(
                        TextCarouselNode(
                          cragId: cragId,
                          texts: carouselData,
                          parent: treeNav.currentNode,
                        ),
                      );
                    }
                  }
                },
              ),

            if (urlMaps != null)
              PicoMenuCard(
                title: 'Abrir no Google Maps',
                subtitle: 'Ver localização e traçar rota até o pico.',
                icon: Icons.map_outlined,
                iconColor: context.colors.rustIron,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.fishBone,
                onTap: () async {
                  if (aoAbrirLinkExterno != null) {
                    await aoAbrirLinkExterno!(urlMaps, 'Google Maps');
                  } else {
                    await abrirLinkExterno(urlMaps, 'Google Maps');
                  }
                },
              ),

            if (categories.outros.isNotEmpty)
              ...categories.outros.map(
                (b) => PicoMenuCard(
                  title: b.texto,
                  subtitle: 'Informações extras sobre o local.',
                  icon: Icons.info_outline,
                  iconColor: context.colors.ashGrey,
                  backgroundColor: context.colors.caveShadow,
                  titleColor: context.colors.chalkWhite,
                  subtitleColor: context.colors.fishBone,
                  onTap: () => _pushTextNode(
                    context,
                    b.texto,
                    b.destino.secaoTextual.conteudo,
                    icon: Icons.info_outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
