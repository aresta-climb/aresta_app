// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../idioma/tradutor_app.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../utils/categorizacao_pico.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/cores_app.dart';
import '../../navigation/arvore_navegacao.dart';
import '../../services/firebase/telemetria.dart';
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
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: ControladorIdiomaApp.instancia.notificadorIdioma,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(
            context,
            context.tr(ChaveTexto.picoSubApoieTitulo),
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
                if (pico.chavePixManutencao.isNotEmpty)
                  PicoMenuCard(
                    title: context.tr(ChaveTexto.picoSubDoacaoPix),
                    subtitle: context.tr(
                      ChaveTexto.picoSubDoacaoPixSubtitulo,
                      {'chave': pico.chavePixManutencao},
                    ),
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor:
                        context.colors.chalkWhite.withValues(alpha: 0.7),
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: pico.chavePixManutencao),
                      );
                      TelemetryService.instance.logApoioPix(cragId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(ChaveTexto.picoSubPixCopiadoToast),
                          ),
                          backgroundColor: context.colors.mossRock,
                        ),
                      );
                    },
                  ),

                if (categories.apoioProdutos.isNotEmpty)
                  ...categories.apoioProdutos.map(
                    (b) => PicoMenuCard(
                      title: context.tr(ChaveTexto.picoSubProdutos),
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
                        context.tr(ChaveTexto.picoSubProdutos),
                        b.destino.secaoTextual.conteudo,
                        icon: Icons.shopping_bag,
                      ),
                    ),
                  ),

                if (pico.patrocinadores.isNotEmpty)
                  PicoMenuCard(
                    title: context.tr(ChaveTexto.picoSubPatrocinador),
                    subtitle: context.tr(
                      ChaveTexto.picoSubPatrocinadorSubtitulo,
                    ),
                    icon: Icons.star_border,
                    iconColor: context.colors.dryMoss,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor:
                        context.colors.chalkWhite.withValues(alpha: 0.7),
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                          'mailto:contato@aresta.app?subject=Patrocinio ${pico.nome}',
                        ),
                      );
                    },
                  ),

                PicoMenuCard(
                  title: context.tr(ChaveTexto.picoSubEnviarInfo),
                  subtitle: context.tr(ChaveTexto.picoSubEnviarInfoSubtitulo),
                  icon: Icons.camera_alt_outlined,
                  iconColor: context.colors.rustIron,
                  backgroundColor: context.colors.caveShadow,
                  titleColor: context.colors.chalkWhite,
                  subtitleColor:
                      context.colors.chalkWhite.withValues(alpha: 0.7),
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
      },
    );
  }
}
