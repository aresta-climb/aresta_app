// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/dados_cartao_compartilhamento.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../provedor_imagem_aresta.dart';

/// Cor âmbar-dourada de destaque para o selo de vias clássicas (`★ CLÁSSICA`).
const Color _corEstrelaClassica = Color(0xFFFBBF24);

/// Cartão visual editorial (Dumb UI) gerado em estética escura para compartilhamento
/// de **Pico**, **Grupo**, **Setor** ou **Escalada** nos Stories e mensageiros.
///
/// Omite integralmente notas privadas da caderneta e exibe apenas uma assinatura discreta
/// da marca no rodapé (`Aresta Climb • arestaclimb.com • @arestaclimb`) sem QR Code.
class CartaoCompartilhamentoAresta extends StatefulWidget {
  /// Modelo imutável com os metadados da entidade e selo pessoal opcional.
  final DadosCartaoCompartilhamento dados;

  /// Provedor de imagem opcional para injeção direta em pré-visualizações ou testes.
  final ImageProvider? imageProviderOverride;

  /// Futuro opcional de provedor de imagem para testes determinísticos de resolução assíncrona.
  final Future<ImageProvider?>? imageProviderFutureOverride;

  /// Cria uma instância de [CartaoCompartilhamentoAresta].
  const CartaoCompartilhamentoAresta({
    super.key,
    required this.dados,
    this.imageProviderOverride,
    this.imageProviderFutureOverride,
  });

  @override
  State<CartaoCompartilhamentoAresta> createState() =>
      _CartaoCompartilhamentoArestaState();
}

class _CartaoCompartilhamentoArestaState
    extends State<CartaoCompartilhamentoAresta> {
  Future<ImageProvider?>? _futureImagem;

  @override
  void initState() {
    super.initState();
    _prepararFutureImagem();
  }

  @override
  void didUpdateWidget(covariant CartaoCompartilhamentoAresta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProviderOverride != widget.imageProviderOverride ||
        oldWidget.imageProviderFutureOverride !=
            widget.imageProviderFutureOverride ||
        oldWidget.dados.idCroqui != widget.dados.idCroqui ||
        oldWidget.dados.caminhoImagemHeroi != widget.dados.caminhoImagemHeroi) {
      _prepararFutureImagem();
    }
  }

  void _prepararFutureImagem() {
    if (widget.imageProviderOverride != null) {
      _futureImagem = null;
      return;
    }
    if (widget.imageProviderFutureOverride != null) {
      _futureImagem = widget.imageProviderFutureOverride;
      return;
    }
    final caminho = widget.dados.caminhoImagemHeroi?.trim() ?? '';
    if (caminho.isEmpty) {
      _futureImagem = null;
      return;
    }
    _futureImagem = ProvedorImagemAresta.resolver(
      picoId: widget.dados.idCroqui,
      caminho: caminho,
      larguraAlvo: 900,
    );
  }

  @override
  Widget build(BuildContext context) {
    const cores = AppColors.dark;
    final dados = widget.dados;
    final seloPessoal = dados.seloPessoal;

    return Container(
      key: const Key('cartao_compartilhamento_fundo'),
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1114), Color(0xFF171C21)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cores.graniteEdge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _construirBlocoImagemHeroi(cores),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cores.deepBasalt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Text(
                    dados.etiquetaCategoria,
                    style: TextStyle(
                      color: cores.beastHide,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (dados.ehClassica)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _corEstrelaClassica.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _corEstrelaClassica.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: _corEstrelaClassica,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr(ChaveTexto.viaClassica),
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    dados.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cores.chalkWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                ),
                if (dados.grauDestaque != null &&
                    dados.grauDestaque!.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cores.deepBasalt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.brandColor.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Text(
                      dados.grauDestaque!,
                      style: TextStyle(
                        color: cores.chalkWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (dados.subtituloLocalizacao.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: cores.ashGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dados.subtituloLocalizacao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cores.ashGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (seloPessoal != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: seloPessoal.ehCadena
                      ? cores.darkPine.withValues(alpha: 0.78)
                      : cores.deepBasalt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: seloPessoal.ehCadena
                        ? cores.fernGreen.withValues(alpha: 0.75)
                        : cores.graniteEdge,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      seloPessoal.ehCadena
                          ? Icons.check_circle_rounded
                          : Icons.refresh_rounded,
                      size: 16,
                      color: seloPessoal.ehCadena
                          ? cores.fernGreen
                          : cores.rustIron,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        seloPessoal.textoResumo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cores.chalkWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (dados.chipsResumo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dados.chipsResumo
                    .take(4)
                    .map(
                      (chip) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cores.deepBasalt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cores.graniteEdge),
                        ),
                        child: Text(
                          chip,
                          style: TextStyle(
                            color: cores.chalkWhite.withValues(alpha: 0.88),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 14),
            Divider(color: cores.graniteEdge, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/logo_app.png',
                    width: 15,
                    height: 15,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aresta Climb  •  arestaclimb.com  •  @arestaclimb',
                      style: TextStyle(
                        color: cores.ashGrey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBlocoImagemHeroi(AppColors cores) {
    if (widget.imageProviderOverride != null) {
      return _renderizarImagemHeroi(widget.imageProviderOverride!, cores);
    }
    if (_futureImagem == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<ImageProvider?>(
      future: _futureImagem,
      builder: (context, snapshot) {
        final provedor = snapshot.data;
        if (provedor == null) {
          return const SizedBox.shrink();
        }
        return _renderizarImagemHeroi(provedor, cores);
      },
    );
  }

  Widget _renderizarImagemHeroi(ImageProvider provedor, AppColors cores) {
    final rotuloLinha = widget.dados.rotuloLinhaNoMapa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1.55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: cores.deepBasalt),
              Image(image: provedor, fit: BoxFit.cover),
              if (rotuloLinha != null && rotuloLinha.trim().isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      context.tr(
                        ChaveTexto.viaLinhaNumero,
                        {'n': rotuloLinha},
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
