import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../view_functions/comunidade_functions.dart';

class ComunidadePage extends StatelessWidget {
  const ComunidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.homeBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÍDIAS, APOIOS E INTERATIVIDADES',
                style: TextStyle(
                  color: context.colors.textOlive,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              buildActionCard(
                context,
                title: 'GRUPOS DE WHATSAPP',
                subtitle: 'Combine escaladas, tire dúvidas e receba avisos.',
                iconData: Icons.chat_bubble_outline,
                iconBgColor: const Color(0xFF128C7E), // WhatsApp Green
                onTap: () => launchURL(context, 'https://whatsapp.com'), // Placeholder
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'PERFIS DE INSTAGRAM',
                subtitle: 'Acompanhe fotos, croquis e relatos de cadenas.',
                iconData: Icons.camera_alt_outlined,
                iconBgColor: const Color(0xFFE1306C), // Instagram Pink/Red
                onTap: () => launchURL(context, 'https://instagram.com'), // Placeholder
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: 'CANAIS DO YOUTUBE',
                subtitle: 'Confira vídeos das betas e conquistas locais.',
                iconData: Icons.play_arrow_rounded,
                iconBgColor: const Color(0xFFFF0000), // YouTube Red
                onTap: () => launchURL(context, 'https://youtube.com'), // Placeholder
              ),
              const SizedBox(height: 16),
              buildTermsCard(context),
              const SizedBox(height: 32),
              buildAvisosCard(context),
              const SizedBox(height: 32),
              buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }
}
