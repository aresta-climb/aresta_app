// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../services/editor_croqui.dart';

/// Widget modular e desacoplado que exibe o banner superior durante o modo experimental ativo.
///
/// Responsabilidades:
/// - Apresenta o indicador textual do modo experimental ativo sem limite de tempo.
/// - Executa uma animação de pulso luminoso sutil (transição de cor/brilho) ao receber eventos de Hot Reload.
/// - Oferece um botão de ação rápida [ SAIR ✕ ] para permitir ao usuário retornar à biblioteca oficial.
class BannerModoExperimental extends StatefulWidget {
  final EditorDeCroqui editorDeCroqui;
  final VoidCallback? onSairModoExperimental;

  const BannerModoExperimental({
    super.key,
    required this.editorDeCroqui,
    this.onSairModoExperimental,
  });

  @override
  State<BannerModoExperimental> createState() => _BannerModoExperimentalState();
}

class _BannerModoExperimentalState extends State<BannerModoExperimental>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacaoController;
  late final Animation<Color?> _corAnimacao;

  @override
  void initState() {
    super.initState();
    _animacaoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _corAnimacao = ColorTween(
      begin: const Color(0xFFC04F34),
      end: const Color(0xFFFFA726),
    ).animate(
      CurvedAnimation(
        parent: _animacaoController,
        curve: Curves.easeInOut,
      ),
    );

    widget.editorDeCroqui.notificadorGatilhoRecarregamento.addListener(
      _aoDispararRecarregamento,
    );
  }

  void _aoDispararRecarregamento() {
    if (!mounted) return;
    _animacaoController.forward(from: 0.0).then((_) {
      if (mounted) {
        _animacaoController.reverse();
      }
    });
  }

  @override
  void dispose() {
    widget.editorDeCroqui.notificadorGatilhoRecarregamento.removeListener(
      _aoDispararRecarregamento,
    );
    _animacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.editorDeCroqui.isExperimentalMode,
      builder: (context, isExperimental, _) {
        if (!isExperimental) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: _corAnimacao,
              builder: (context, _) {
                final corFundo = _corAnimacao.value ?? const Color(0xFFC04F34);

                return Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 2,
                    bottom: 4,
                    left: 12,
                    right: 12,
                  ),
                  color: corFundo.withValues(alpha: 0.9),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'MODO EXPERIMENTAL ATIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onSairModoExperimental != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: const Key('btn_sair_modo_experimental'),
                          onTap: widget.onSairModoExperimental,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white38,
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SAIR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
