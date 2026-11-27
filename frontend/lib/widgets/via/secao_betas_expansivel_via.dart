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

  @override
  State<_CartaoSecaoExpansivelVia> createState() =>
      _CartaoSecaoExpansivelViaState();
}

class _CartaoSecaoExpansivelViaState extends State<_CartaoSecaoExpansivelVia> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cores.graniteEdge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: widget.chaveCabecalho,
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CabecalhoSecaoPadraoVia(
                  icone: widget.icone,
                  tituloCaixaAlta: widget.tituloCaixaAlta,
                  sufixo: AnimatedRotation(
                    turns: _expandido ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: cores.ashGrey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expandido
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.filhosExpandidos,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seção recolhível (Dumb UI) de vídeos e postagens curadas de beta, iniciando fechada por padrão.
class SecaoBetasMidiaVia extends StatelessWidget {
  /// Mídias disponíveis para a escalada.
  final List<ItemMidiaBetaVia> midias;

  /// Callback acionado ao tocar em um vídeo ou post de beta.
  final ValueChanged<String> aoAbrirMidia;

  /// Cria uma instância de [SecaoBetasMidiaVia].
  const SecaoBetasMidiaVia({
    super.key,
    required this.midias,
    required this.aoAbrirMidia,
  });

  @override
  Widget build(BuildContext context) {
    if (midias.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return _CartaoSecaoExpansivelVia(
      chaveCabecalho: const Key('cabecalho_betas_midia_via'),
      icone: Icons.play_circle_outline_rounded,
      tituloCaixaAlta: context.tr(
        ChaveTexto.viaVideosBetasContagem,
        {'n': midias.length},
      ),
      filhosExpandidos: [
        for (var i = 0; i < midias.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == midias.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => aoAbrirMidia(midias[i].url),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cores.deepBasalt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cores.graniteEdge),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: cores.rustIron,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            midias[i].titulo,
                            style: TextStyle(
                              color: cores.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            midias[i].origemRotulo,
                            style: TextStyle(
                              color: cores.ashGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: cores.ashGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Feed recolhível (Dumb UI) de betas públicos da comunidade com foto de perfil do autor,
/// iniciando fechado por padrão para proteger tentativas à vista e expondo edição/exclusão ao autor.
class SecaoNotasComunidadeVia extends StatelessWidget {
  /// Notas públicas pré-formatadas para exibição direta.
  final List<NotaComunidadeApresentacao> notas;

  /// Callback opcional acionado quando o próprio autor toca para editar seu comentário.
  final ValueChanged<NotaComunidadeApresentacao>? aoEditarNota;

  /// Callback opcional acionado quando o próprio autor toca para excluir seu comentário.
  final ValueChanged<NotaComunidadeApresentacao>? aoExcluirNota;

  /// Cria uma instância de [SecaoNotasComunidadeVia].
  const SecaoNotasComunidadeVia({
    super.key,
    required this.notas,
    this.aoEditarNota,
    this.aoExcluirNota,
  });

  @override
  Widget build(BuildContext context) {
    if (notas.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

