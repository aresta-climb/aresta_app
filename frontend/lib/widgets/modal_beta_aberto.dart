// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase/remote_config_service.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';
import '../services/firebase/app_logger.dart';

/// Exibe o modal explicativo da fase de Beta Aberto como um Bottom Sheet personalizado.
///
/// Permite injetar [onFeedbackSolicitado], [onAbrirWhatsapp] e [onAbrirInstagram] para fins de teste ou customização de fluxo.
/// Caso [onFeedbackSolicitado] seja nulo, o fluxo padrão do [BetterFeedback] é acionado.
Future<void> exibirModalBetaAberto(
  BuildContext context, {
  VoidCallback? onFeedbackSolicitado,
  VoidCallback? onAbrirWhatsapp,
  VoidCallback? onAbrirInstagram,
  String origem = 'home_header',
}) {
  TelemetryService.instance.logAcaoBetaAberto('abrir_modal_beta', origem: origem);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return ModalBetaAberto(
        onFeedbackSolicitado: onFeedbackSolicitado,
        onAbrirWhatsapp: onAbrirWhatsapp,
        onAbrirInstagram: onAbrirInstagram,
      );
    },
  );
}

/// Widget modular que renderiza o conteúdo explicativo sobre o estágio de Beta Aberto do Aresta Climb.
///
/// Explica os objetivos do momento atual do aplicativo, estabelece expectativas claras quanto
/// à adição gradual de setores e funcionalidades e oferece canais diretos para envio de feedback,
/// participação na comunidade do WhatsApp e acompanhamento no Instagram.
class ModalBetaAberto extends StatelessWidget {
  /// Callback opcional executado após o fechamento do modal ao acionar o botão de feedback.
  final VoidCallback? onFeedbackSolicitado;

  /// Callback opcional executado ao acionar o botão de acesso à comunidade no WhatsApp.
  final VoidCallback? onAbrirWhatsapp;

  /// Callback opcional executado ao acionar o botão de acesso ao Instagram oficial.
  final VoidCallback? onAbrirInstagram;

  const ModalBetaAberto({
    super.key,
    this.onFeedbackSolicitado,
    this.onAbrirWhatsapp,
    this.onAbrirInstagram,
  });

  Future<void> _acionarWhatsapp(BuildContext context) async {
    TelemetryService.instance.logAcaoBetaAberto(
      'clique_whatsapp',
      canal: 'whatsapp',
    );
    if (onAbrirWhatsapp != null) {
      onAbrirWhatsapp!();
      return;
    }
    final url = RemoteConfigService.instance.whatsappCommunityUrl;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao abrir link da comunidade WhatsApp ($url)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _acionarInstagram(BuildContext context) async {
    TelemetryService.instance.logAcaoBetaAberto(
      'clique_instagram',
      canal: 'instagram',
    );
    if (onAbrirInstagram != null) {
      onAbrirInstagram!();
      return;
    }
    const url = 'https://www.instagram.com/arestaclimb/';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao abrir link do Instagram ($url)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.colors.ashGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fase Beta Aberta',
                    style: TextStyle(
                      color: context.colors.chalkWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.colors.ashGrey),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'O Aresta Climb é uma iniciativa independente e está em desenvolvimento ativo com a comunidade de escaladores.',
                style: TextStyle(
                  color: context.colors.chalkWhite,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _construirTopico(
                context,
                icone: Icons.explore_outlined,
                titulo: 'Novos setores e croquis contínuos',
                descricao: 'Nossa base de vias, croquis e mapas é expandida e atualizada frequentemente.',
              ),
              const SizedBox(height: 12),
              _construirTopico(
                context,
                icone: Icons.construction_outlined,
                titulo: 'Recursos em constante evolução',
                descricao: 'Filtros avançados, ferramentas de navegação e melhorias de performance estão a caminho.',
              ),
              const SizedBox(height: 12),
              _construirTopico(
                context,
                icone: Icons.volunteer_activism_outlined,
                titulo: 'Construção comunitária',
                descricao: 'Sua experiência na rocha é essencial para identificarmos ajustes e priorizarmos o que importa.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.colors.graniteEdge.withValues(alpha: 0.2),
                    foregroundColor: context.colors.chalkWhite,
                    side: BorderSide(color: context.colors.graniteEdge.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFE1306C), size: 20),
                  label: const Text(
                    'Instagram Oficial',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => _acionarInstagram(context),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.colors.graniteEdge.withValues(alpha: 0.2),
                    foregroundColor: context.colors.chalkWhite,
                    side: BorderSide(color: context.colors.graniteEdge.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                  label: const Text(
                    'Comunidade no WhatsApp',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => _acionarWhatsapp(context),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.colors.graniteEdge.withValues(alpha: 0.2),
                    foregroundColor: context.colors.chalkWhite,
                    side: BorderSide(color: context.colors.graniteEdge.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.feedback_outlined, color: context.colors.beastHide, size: 20),
                  label: const Text(
                    'Enviar Sugestão',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () {
                    TelemetryService.instance.logAcaoBetaAberto(
                      'clique_feedback',
                      canal: 'feedback',
                    );
                    Navigator.of(context).pop();
                    if (onFeedbackSolicitado != null) {
                      onFeedbackSolicitado!();
                    } else {
                      BetterFeedback.of(context).show((UserFeedback feedback) {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final versao = snapshot.data?.version ?? '0.2.8';
                    return Text(
                      'Aresta Climb v$versao (Beta Aberto)',
                      style: TextStyle(
                        color: context.colors.ashGrey.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTopico(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: context.colors.dryMoss, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: context.colors.chalkWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descricao,
                style: TextStyle(
                  color: context.colors.ashGrey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
