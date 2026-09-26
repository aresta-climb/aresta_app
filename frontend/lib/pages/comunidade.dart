// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../view_functions/comunidade_functions.dart';
import '../view_functions/view_models/comunidade_view_model.dart';
import '../view_functions/common_functions.dart';

/// Página de apresentação dos canais da comunidade e mídias do Aresta (Dumb UI).
///
/// Renderiza exclusivamente elementos visuais e delega ações e conteúdo dinâmico
/// para [ComunidadeViewModel].
class ComunidadePage extends StatelessWidget {
  /// Modelo de apresentação da comunidade. Se nulo, utiliza [ComunidadeViewModel.doServico].
  final ComunidadeViewModel? viewModel;

  const ComunidadePage({
    super.key,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel ?? ComunidadeViewModel.doServico();

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
                onTap: navegarParaSobreTime,
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: vm.whatsapp.titulo,
                subtitle: vm.whatsapp.subtitulo,
                iconData: Icons.chat_bubble_outline,
                iconBgColor: const Color(0xFF128C7E), // WhatsApp Green
                onTap: vm.whatsapp.executar,
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: vm.instagram.titulo,
                subtitle: vm.instagram.subtitulo,
                iconData: Icons.camera_alt_outlined,
                iconBgColor: const Color(0xFFE1306C), // Instagram Pink/Red
                onTap: vm.instagram.executar,
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: vm.linkedin.titulo,
                subtitle: vm.linkedin.subtitulo,
                iconData: Icons.work_outline,
                iconBgColor: const Color(0xFF0A66C2), // LinkedIn Blue
                onTap: vm.linkedin.executar,
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: vm.discord.titulo,
                subtitle: vm.discord.subtitulo,
                iconData: Icons.discord,
                iconBgColor: const Color(0xFF5865F2), // Discord Blurple
                onTap: vm.discord.executar,
              ),
              const SizedBox(height: 16),
              buildActionCard(
                context,
                title: vm.github.titulo,
                subtitle: vm.github.subtitulo,
                iconData: Icons.code,
                iconBgColor: const Color(0xFF333333), // GitHub Dark Gray
                onTap: vm.github.executar,
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
