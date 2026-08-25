// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/common_functions.dart';
import '../../utils/pico_categorization.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/app_colors.dart';
import '../../navigation/navigation_tree.dart';
import 'package:url_launcher/url_launcher.dart';

class ApoiePicoPage extends StatelessWidget {
  final Pico pico;
  final String cragId;
  final PicoCategorizedData categories;

  const ApoiePicoPage({
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'APOIE O PICO', subtitle: pico.nome),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            if (pico.chavePixManutencao.isNotEmpty)
              PicoMenuCard(
                title: 'Doação via Pix',
                subtitle:
                    'Ajude a comprar chapeletas e correntes de inox.\nChave: ${pico.chavePixManutencao}',
                icon: Icons.attach_money,
                iconColor: Colors.green,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: pico.chavePixManutencao),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Chave PIX copiada para a área de transferência!',
                      ),
                      backgroundColor: context.colors.mossRock,
                    ),
                  );
                },
              ),

            if (categories.apoioProdutos.isNotEmpty)
              ...categories.apoioProdutos.map(
                (b) => PicoMenuCard(
                  title: 'Produtos do pico',
                  subtitle: b.texto,
                  icon: Icons.layers,
                  iconColor: context.colors.beastHide,
                  backgroundColor: context.colors.caveShadow,
                  titleColor: context.colors.chalkWhite,
                  subtitleColor: context.colors.chalkWhite.withValues(
                    alpha: 0.7,
                  ),
                  onTap: () => _pushTextNode(
                    context,
                    'Produtos do pico',
                    b.destino.secaoTextual.conteudo,
                    icon: Icons.shopping_bag,
                  ),
                ),
              ),

            if (pico.patrocinadores.isNotEmpty)
              PicoMenuCard(
                title: 'Seja um patrocinador',
                subtitle: 'Sua marca associada ética e ecologicamente à rocha.',
                icon: Icons.star_border,
                iconColor: context.colors.dryMoss,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () {
                  // If we had a specific page for sponsors we would push here, or we can just open a mailto link
                  launchUrl(
                    Uri.parse(
                      'mailto:contato@aresta.app?subject=Patrocinio ${pico.nome}',
                    ),
                  );
                },
              ),

            PicoMenuCard(
              title: 'Envie uma informação',
              subtitle: 'Contribuir sugerindo novas vias ou correções.',
              icon: Icons.camera_alt_outlined,
              iconColor: context.colors.rustIron,
              backgroundColor: context.colors.caveShadow,
              titleColor: context.colors.chalkWhite,
              subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
              onTap: () {
                launchUrl(
                  Uri.parse(
                    'mailto:contato@aresta.app?subject=Sugestão/Correção ${pico.nome}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
