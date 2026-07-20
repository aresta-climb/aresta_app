import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../view_functions/comunidade_functions.dart';
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
                title: 'WHATSAPP DO PROJETO',
                subtitle: 'Participe do grupo para tirar dúvidas, dar ideias e receber avisos do Aresta.',
                iconData: Icons.chat_bubble_outline,
                iconBgColor: const Color(0xFF128C7E), // WhatsApp Green
                onTap: () => showLinkOverlay(
                  context,
                  title: 'WhatsApp Oficial',
                  link: 'https://chat.whatsapp.com/Ip28rjQj4YbHgPgtN5Arcv',
                  iconData: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF128C7E),
                ),
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'INSTAGRAM OFICIAL',
                subtitle: 'Acompanhe as últimas novidades, atualizações e bastidores do aplicativo.',
                iconData: Icons.camera_alt_outlined,
                iconBgColor: const Color(0xFFE1306C), // Instagram Pink/Red
                onTap: () => showLinkOverlay(
                  context,
                  title: 'Instagram',
                  link: '', // No link yet, triggers fallback
                  iconData: Icons.camera_alt_outlined,
                  iconColor: const Color(0xFFE1306C),
                ),
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'DISCORD DOS DESENVOLVEDORES',
                subtitle: 'Converse com a equipe, acompanhe o código e colabore com o futuro do Aresta.',
                iconData: Icons.discord,
                iconBgColor: const Color(0xFF5865F2), // Discord Blurple
                onTap: () => showLinkOverlay(
                  context,
                  title: 'Discord do Projeto',
                  link: 'https://discord.gg/3KDTwcxHK',
                  iconData: Icons.discord,
                  iconColor: const Color(0xFF5865F2),
                ),
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'GITHUB DO ARESTA',
                subtitle: 'Acesse o perfil com os repositórios do github.',
                iconData: Icons.code,
                iconBgColor: const Color(0xFF333333), // GitHub Dark Gray
                onTap: () => showLinkOverlay(
                  context,
                  title: 'GitHub Oficial',
                  link: 'https://github.com/aresta-climb',
                  iconData: Icons.code,
                  iconColor: const Color(0xFF333333),
                ),
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
