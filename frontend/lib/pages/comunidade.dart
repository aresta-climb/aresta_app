// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../navigation/navigation_tree.dart';
import '../theme/app_colors.dart';
import '../view_functions/comunidade_functions.dart';
import '../services/firebase/app_logger.dart';
import '../view_functions/common_functions.dart';

class ComunidadePage extends StatelessWidget {
  const ComunidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'MÍDIAS, APOIOS E INTERATIVIDADES',
                      style: TextStyle(
                        color: context.colors.dryMoss,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  buildFeedbackButton(context, color: context.colors.ashGrey),
                ],
              ),
              const SizedBox(height: 24),
              buildActionCard(
                context,
                title: 'SOBRE O TIME',
                subtitle: 'Conheça os desenvolvedores e colaboradores do projeto Aresta.',
                iconData: Icons.groups_outlined,
                iconBgColor: context.colors.dryMoss,
                onTap: () {
                  final treeNav = TreeNavigationWrapper.currentTreeController;
                  if (treeNav != null) {
                    treeNav.navigateTo(SobreTimeNode(treeNav.currentNode));
                  }
                },
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'GRUPO DO WHATSAPP',
                subtitle:
                    'Participe para tirar dúvidas, dar ideias e receber avisos do Aresta.',
                iconData: Icons.chat_bubble_outline,
                iconBgColor: const Color(0xFF128C7E), // WhatsApp Green
                onTap: () async {
                  const url = 'https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e, stackTrace) {
                    AppLogger.instance.logError('Erro ao abrir link do WhatsApp ($url)', error: e, stackTrace: stackTrace);
                  }
                },
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'INSTAGRAM OFICIAL',
                subtitle:
                    'Acompanhe as últimas novidades, atualizações e bastidores do aplicativo.',
                iconData: Icons.camera_alt_outlined,
                iconBgColor: const Color(0xFFE1306C), // Instagram Pink/Red
                onTap: () async {
                  const url = 'https://www.instagram.com/arestaclimb/';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e, stackTrace) {
                    AppLogger.instance.logError('Erro ao abrir link do Instagram ($url)', error: e, stackTrace: stackTrace);
                  }
                },
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'LINKEDIN DO PROJETO',
                subtitle:
                    'Acompanhe novidades, nosso crescimento e o lado corporativo do Aresta.',
                iconData: Icons.work_outline,
                iconBgColor: const Color(0xFF0A66C2), // LinkedIn Blue
                onTap: () async {
                  const url = 'https://www.linkedin.com/company/arestaclimb/';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e, stackTrace) {
                    AppLogger.instance.logError('Erro ao abrir link do LinkedIn ($url)', error: e, stackTrace: stackTrace);
                  }
                },
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'DISCORD DOS DESENVOLVEDORES',
                subtitle:
                    'Converse com a equipe, acompanhe o código e colabore com o futuro do Aresta.',
                iconData: Icons.discord,
                iconBgColor: const Color(0xFF5865F2), // Discord Blurple
                onTap: () async {
                  const url = 'https://discord.gg/3KDTwcxHK';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e, stackTrace) {
                    AppLogger.instance.logError('Erro ao abrir link do Discord ($url)', error: e, stackTrace: stackTrace);
                  }
                },
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'GITHUB DO ARESTA',
                subtitle: 'Acesse o perfil com os repositórios do github.',
                iconData: Icons.code,
                iconBgColor: const Color(0xFF333333), // GitHub Dark Gray
                onTap: () async {
                  const url = 'https://github.com/aresta-climb';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e, stackTrace) {
                    AppLogger.instance.logError('Erro ao abrir link do GitHub ($url)', error: e, stackTrace: stackTrace);
                  }
                },
              ),

              const SizedBox(height: 16),
              buildTermsCard(context),
              const SizedBox(height: 32),
              buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }
}
