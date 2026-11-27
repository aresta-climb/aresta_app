// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../utils/modelos_apresentacao_via.dart';
import '../../view/function_library/funcoes_hub_perfil_caderneta.dart';

/// Cabeçalho padronizado (Dumb UI) compartilhado entre os cartões de seção da `ViaPage`
/// (`DESCRIÇÃO`, `ENFIADAS`, `VÍDEOS & BETAS`, `BETAS DA COMUNIDADE` e `HISTÓRICO & CONQUISTA`),
/// garantindo a mesma tipografia `Montserrat` 12px em caixa alta em toda a tela.
class CabecalhoSecaoPadraoVia extends StatelessWidget {
  /// Ícone semântico à esquerda do título.
  final IconData icone;

  /// Título em caixa alta da seção.
  final String tituloCaixaAlta;

  /// Elemento opcional à direita (ex.: seta de expansão em seções recolhíveis).
  final Widget? sufixo;

  /// Cria uma instância de [CabecalhoSecaoPadraoVia].
  const CabecalhoSecaoPadraoVia({
    super.key,
    required this.icone,
    required this.tituloCaixaAlta,
    this.sufixo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Row(
      children: [
        Icon(icone, color: cores.ashGrey, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tituloCaixaAlta,
            style: TextStyle(
              color: cores.ashGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (sufixo != null) ...[
          const SizedBox(width: 8),
          sufixo!,
        ],
      ],
    );
  }
}

/// Pílula compacta reutilizável para selos curtos (`FLASH ★`, graus e extensões de enfiada).
class PilulaDetalheCurtoVia extends StatelessWidget {
  /// Texto exibido dentro da pílula.
  final String texto;

  /// Cria uma instância de [PilulaDetalheCurtoVia].
  const PilulaDetalheCurtoVia({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cores.deepBasalt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cores.beastHide,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Avatar circular compacto exibido ao lado do nome do escalador nos betas da comunidade,
/// resolvendo fotos em memória/rede e caindo graciosamente para as iniciais em caso de ausência ou falha.
class AvatarAutorComunidadeVia extends StatefulWidget {
  /// URL pública ou Data URI opcional da foto de perfil.
  final String? avatarUrl;

  /// Iniciais pré-computadas do autor (`'EU'`, `'CL'`).
  final String iniciais;

  /// Cria uma instância de [AvatarAutorComunidadeVia].
  const AvatarAutorComunidadeVia({
    super.key,
    this.avatarUrl,
    required this.iniciais,
  });

  @override
  State<AvatarAutorComunidadeVia> createState() =>
      _AvatarAutorComunidadeViaState();
}

class _AvatarAutorComunidadeViaState extends State<AvatarAutorComunidadeVia> {
  bool _falhouCarregamento = false;

  @override
  void didUpdateWidget(covariant AvatarAutorComunidadeVia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _falhouCarregamento = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final provedor = _falhouCarregamento
        ? null
        : construirProvedorAvatarPerfil(widget.avatarUrl);

    return Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cores.rustIron.withValues(alpha: 0.65),
          width: 1.2,
        ),
      ),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: cores.caveShadow,
        backgroundImage: provedor,
        onBackgroundImageError: provedor != null
            ? (_, _) {
                if (mounted) {
                  setState(() => _falhouCarregamento = true);
                }
              }
            : null,
        child: provedor == null
            ? Text(
                widget.iniciais,
                maxLines: 1,
                style: TextStyle(
                  color: cores.chalkWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}

/// Cartão expansível (fechado por padrão) para mídias e betas comunitários, evitando spoilers
/// indesejados para quem busca escalar à vista e mantendo o padrão visual de `HISTÓRICO & CONQUISTA`.
class _CartaoSecaoExpansivelVia extends StatefulWidget {
  final Key chaveCabecalho;
  final IconData icone;
  final String tituloCaixaAlta;
  final List<Widget> filhosExpandidos;

  const _CartaoSecaoExpansivelVia({
    required this.chaveCabecalho,
    required this.icone,
    required this.tituloCaixaAlta,
    required this.filhosExpandidos,
  });

