import '../../main.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/common_functions.dart';
import '../../utils/pico_categorization.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/app_colors.dart';
import '../../navigation/navigation_tree.dart';
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

  void _pushTextNode(BuildContext context, String title, String content) {
    final treeNav = TreeNavigationWrapper.currentTreeController;
    if (treeNav != null) {
      treeNav.navigateTo(TextNode(
        title: title,
        content: content,
        cragId: cragId,
        parent: treeNav.currentNode,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'COMUNIDADE', subtitle: pico.nome),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (categories.comunidadeInfo.isNotEmpty)
              ...categories.comunidadeInfo.map((b) => PicoMenuCard(
                title: 'Informações',
                subtitle: b.texto,
                icon: Icons.info_outline,
                iconColor: context.colors.dryMoss,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () => _pushTextNode(context, 'Informações', b.destino.secaoTextual.conteudo),
              )),

            if (pico.nomeAssociacao.isNotEmpty && pico.urlFiliacaoAssociacao.isNotEmpty)
              PicoMenuCard(
                title: 'Associação Local',
                subtitle: pico.nomeAssociacao,
                icon: Icons.groups,
                iconColor: context.colors.clayEarth,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () => launchUrl(Uri.parse(pico.urlFiliacaoAssociacao)),
              ),
              
            if (categories.comunidadeParceiros.isNotEmpty)
              ...categories.comunidadeParceiros.map((b) => PicoMenuCard(
                title: 'Parceiros',
                subtitle: b.texto,
                icon: Icons.handshake,
                iconColor: context.colors.rustIron,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () => _pushTextNode(context, 'Parceiros', b.destino.secaoTextual.conteudo),
              )),

            if (categories.comunidadeComercio.isNotEmpty)
              ...categories.comunidadeComercio.map((b) => PicoMenuCard(
                title: 'Comércio local',
                subtitle: b.texto,
                icon: Icons.storefront,
                iconColor: context.colors.clayEarth,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () => _pushTextNode(context, 'Comércio local', b.destino.secaoTextual.conteudo),
              )),
          ],
        ),
      ),
    );
  }
}
