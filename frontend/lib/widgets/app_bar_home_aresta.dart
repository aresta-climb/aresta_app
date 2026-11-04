// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/cores_app.dart';
import '../view/view_models/home_view_model.dart';
import '../navigation/funcoes_navegacao.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import 'micro_badge_beta.dart';
import 'modal_beta_aberto.dart';

/// Barra de aplicativo superior dedicada da página inicial do Aresta Climb (Dumb UI).
///
/// Apresenta o logotipo vetorizado, a marca com selo interativo [MicroBadgeBeta]
/// e os botões de ação para sincronização manual, feedback e acesso ao Perfil/Login
/// (por onde as Configurações também são acessadas).
class ArestaHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// ViewModel da tela inicial para sincronização manual.
  final HomeViewModel? viewModel;

  /// Visibilidade estática do botão de perfil quando [exibirBotaoPerfilListenable] não é fornecido (padrão `true`).
  final bool exibirBotaoPerfil;

  /// Notificador opcional para controle reativo de visibilidade do botão de perfil.
  final ValueListenable<bool>? exibirBotaoPerfilListenable;

  /// Callback executado ao pressionar o botão de sincronização.
  final VoidCallback? onSync;

  /// Callback executado ao pressionar o botão de perfil do escalador.
  final VoidCallback? onProfile;

  const ArestaHomeAppBar({
    super.key,
    this.viewModel,
    this.exibirBotaoPerfil = true,
    this.exibirBotaoPerfilListenable,
    this.onSync,
    this.onProfile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  void _executarSincronizacao(BuildContext context) {
    if (onSync != null) {
      onSync!();
    } else {
      viewModel?.sincronizarManual(context);
    }
  }

  void _executarPerfil(BuildContext context) {
    if (onProfile != null) {
      onProfile!();
    } else {
      AppNav.abrirPerfilOuLogin(context);
    }
  }

  Widget _construirBotaoPerfil(BuildContext context) {
    return IconButton(
      key: const Key('btn_home_perfil'),
      icon: Icon(
        Icons.person_outline,
        color: context.colors.ashGrey,
      ),
      tooltip: 'Meu Perfil',
      onPressed: () => _executarPerfil(context),
    );
  }

  Widget _construirSlotBotaoPerfil(BuildContext context) {
    final listenable = exibirBotaoPerfilListenable;
    if (listenable != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: listenable,
        builder: (context, visivel, _) {
          return visivel
              ? _construirBotaoPerfil(context)
              : const SizedBox.shrink();
        },
      );
    }

    return exibirBotaoPerfil
        ? _construirBotaoPerfil(context)
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.deepBasalt,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logo_app_trace.svg',
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 7),
                  InkWell(
                    onTap: () => exibirModalBetaAberto(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, bottom: 5),
                          child: Text(
                            'ARESTA CLIMB',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: 0.5,
                              color: context.colors.chalkWhite,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: MicroBadgeBeta(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.sync, color: context.colors.ashGrey),
                tooltip: 'Sincronizar catálogo e croquis',
                onPressed: () => _executarSincronizacao(context),
              ),
              buildFeedbackButton(context, color: context.colors.ashGrey),
              _construirSlotBotaoPerfil(context),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sinônimo em português para [ArestaHomeAppBar].
typedef AppBarHomeAresta = ArestaHomeAppBar;
