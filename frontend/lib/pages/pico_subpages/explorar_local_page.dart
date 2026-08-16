import '../../main.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/common_functions.dart';
import '../../view_functions/offline_markdown.dart';
import '../../utils/pico_categorization.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/app_colors.dart';
import '../../navigation/navigation_tree.dart';

class ExplorarLocalPage extends StatelessWidget {
  final Pico pico;
  final String cragId;
  final PicoCategorizedData categories;

  const ExplorarLocalPage({
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
      backgroundColor: context.colors.deepBasalt,
      appBar: buildCommonAppBar(
        context,
        'EXPLORAR O LOCAL',
        subtitle: pico.nome,
        backgroundColor: context.colors.deepBasalt,
        foregroundColor: context.colors.chalkWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (categories.capa.isNotEmpty) ...[
              OfflineMarkdown(
                data: categories.capa.first.destino.secaoTextual.conteudo,
                cragId: cragId,
              ),
              const SizedBox(height: 24),
            ],
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
                  final combinedContent = categories.sobre.map((b) {
                    if (categories.sobre.length == 1) {
                      return b.destino.secaoTextual.conteudo;
                    }
                    return '## ${b.texto}\n\n${b.destino.secaoTextual.conteudo}';
                  }).join('\n\n');
                  
                  _pushTextNode(
                    context,
                    'Sobre o local',
                    combinedContent,
                    icon: Icons.menu_book,
                  );
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
              ...categories.comoChegar.map(
                (b) => PicoMenuCard(
                  title: 'Como chegar',
                  subtitle: b.texto,
                  icon: Icons.near_me,
                  iconColor: context.colors.rustIron,
                  backgroundColor: context.colors.caveShadow,
                  titleColor: context.colors.chalkWhite,
                  subtitleColor: context.colors.fishBone,
                  onTap: () => _pushTextNode(
                    context,
                    'Como chegar',
                    b.destino.secaoTextual.conteudo,
                    icon: Icons.near_me,
                  ),
                ),
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
