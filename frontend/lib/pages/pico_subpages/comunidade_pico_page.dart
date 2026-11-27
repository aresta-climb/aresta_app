// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../main.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../idioma/tradutor_app.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../utils/categorizacao_pico.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/cores_app.dart';
import '../../navigation/arvore_navegacao.dart';
import 'package:url_launcher/url_launcher.dart';

class ComunidadePicoPage extends StatelessWidget {
  final Pico pico;
  final String cragId;
  final PicoCategorizedData categories;

  const ComunidadePicoPage({
    super.key,
    required this.pico,
    required this.cragId,
    required this.categories,
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
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: ControladorIdiomaApp.instancia.notificadorIdioma,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(
            context,
            context.tr(ChaveTexto.picoSubComunidadeTitulo),
            subtitle: pico.nome,
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
                if (categories.comunidadeInfo.isNotEmpty)
                  ...categories.comunidadeInfo.map(
                    (b) => PicoMenuCard(
                      title: context.tr(ChaveTexto.picoSubInformacoes),
                      subtitle: b.texto,
                      icon: Icons.info_outline,
                      iconColor: context.colors.dryMoss,
                      backgroundColor: context.colors.caveShadow,
                      titleColor: context.colors.chalkWhite,
                      subtitleColor: context.colors.chalkWhite.withValues(
                        alpha: 0.7,
                      ),
                      onTap: () => _pushTextNode(
                        context,
                        context.tr(ChaveTexto.picoSubInformacoes),
                        b.destino.secaoTextual.conteudo,
                        icon: Icons.info_outline,
                      ),
                    ),
                  ),

                if (pico.nomeAssociacao.isNotEmpty &&
                    pico.urlFiliacaoAssociacao.isNotEmpty)
                  PicoMenuCard(
                    title: context.tr(ChaveTexto.picoSubAssociacaoLocal),
                    subtitle: pico.nomeAssociacao,
                    icon: Icons.groups,
                    iconColor: context.colors.clayEarth,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor:
                        context.colors.chalkWhite.withValues(alpha: 0.7),
                    onTap: () =>
                        launchUrl(Uri.parse(pico.urlFiliacaoAssociacao)),
                  ),

                if (categories.comunidadeParceiros.isNotEmpty)
                  ...categories.comunidadeParceiros.map(
                    (b) => PicoMenuCard(
                      title: context.tr(ChaveTexto.picoSubParceiros),
                      subtitle: b.texto,
                      icon: Icons.handshake,
                      iconColor: context.colors.rustIron,
                      backgroundColor: context.colors.caveShadow,
                      titleColor: context.colors.chalkWhite,
                      subtitleColor: context.colors.chalkWhite.withValues(
                        alpha: 0.7,
                      ),
                      onTap: () => _pushTextNode(
                        context,
                        context.tr(ChaveTexto.picoSubParceiros),
                        b.destino.secaoTextual.conteudo,
                        icon: Icons.handshake,
                      ),
                    ),
                  ),

                if (categories.comunidadeComercio.isNotEmpty)
                  ...categories.comunidadeComercio.map(
                    (b) => PicoMenuCard(
                      title: context.tr(ChaveTexto.picoSubComercioLocal),
                      subtitle: b.texto,
                      icon: Icons.storefront,
                      iconColor: context.colors.clayEarth,
                      backgroundColor: context.colors.caveShadow,
                      titleColor: context.colors.chalkWhite,
                      subtitleColor: context.colors.chalkWhite.withValues(
                        alpha: 0.7,
                      ),
                      onTap: () => _pushTextNode(
                        context,
                        context.tr(ChaveTexto.picoSubComercioLocal),
                        b.destino.secaoTextual.conteudo,
                        icon: Icons.storefront,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
