// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/dados_cartao_compartilhamento.dart';
import '../../idioma/tradutor_app.dart';
import '../../services/compartilhamento/capturador_imagem_cartao.dart';
import '../../services/compartilhamento/servico_compartilhamento.dart';
import '../../theme/cores_app.dart';
import '../via/snackbar_flutuante_seguro.dart';
import 'cartao_compartilhamento_aresta.dart';

/// Abre o BottomSheet unificado de compartilhamento com pré-visualização ao vivo do cartão
/// editorial e escolha explícita entre **Imagem (Stories)** e **Link Rápido (WhatsApp)**.
Future<void> exibirModalCompartilhamentoEntidade(
  BuildContext context, {
  required DadosCartaoCompartilhamento dados,
  ServicoCompartilhamento? servicoCompartilhamento,
  CapturadorBytesCartao? capturadorCartao,
  ImageProvider? imageProviderOverride,
  double recuoExtraSnackBar = 0.0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ModalCompartilhamentoEntidade(
      dados: dados,
      servicoCompartilhamento: servicoCompartilhamento,
      capturadorCartao: capturadorCartao,
      imageProviderOverride: imageProviderOverride,
      recuoExtraSnackBar: recuoExtraSnackBar,
    ),
  );
}

/// Folha modal (BottomSheet) declarativa com pré-visualização do [CartaoCompartilhamentoAresta]
/// e botões de ação para exportação PNG (`image/png`) ou link clicável (`text/plain`).
class ModalCompartilhamentoEntidade extends StatefulWidget {
  /// Metadados unificados da entidade compartilhada.
  final DadosCartaoCompartilhamento dados;

  /// Instância opcional do serviço de compartilhamento para injeção em testes.
  final ServicoCompartilhamento? servicoCompartilhamento;

  /// Capturador opcional de bytes PNG para injeção em testes.
  final CapturadorBytesCartao? capturadorCartao;

  /// Provedor de imagem opcional encaminhado ao cartão de pré-visualização.
  final ImageProvider? imageProviderOverride;

  /// Folga extra inferior preservada ao exibir o toast de link copiado sobre docks fixos.
  final double recuoExtraSnackBar;

  /// Cria uma instância de [ModalCompartilhamentoEntidade].
  const ModalCompartilhamentoEntidade({
    super.key,
    required this.dados,
    this.servicoCompartilhamento,
    this.capturadorCartao,
    this.imageProviderOverride,
    this.recuoExtraSnackBar = 0.0,
  });

  @override
  State<ModalCompartilhamentoEntidade> createState() =>
      _ModalCompartilhamentoEntidadeState();
}

class _ModalCompartilhamentoEntidadeState
    extends State<ModalCompartilhamentoEntidade> {
  final GlobalKey _chaveRepaint = GlobalKey();
  bool _processando = false;

  Future<void> _compartilharImagemStories(BuildContext context) async {
    if (_processando) return;
    setState(() => _processando = true);

    final servico =
        widget.servicoCompartilhamento ?? ServicoCompartilhamento.instancia;
    final capturador =
        widget.capturadorCartao ??
        servico.capturadorCartao ??
        ServicoCompartilhamento.capturadorPadrao;
    final despachanteSnack = capturarDespachanteSnackBarSeguro(
      context,
      recuoExtraInferior: widget.recuoExtraSnackBar,
    );

    try {
      final bytesPng = await capturador(_chaveRepaint);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      await servico.compartilharImagemStories(
        dados: widget.dados,
        bytesPng: bytesPng,
      );
      despachanteSnack.exibir(
        texto: tr(ChaveTexto.shareLinkCopiadoParaStoriesToast),
        duracao: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  Future<void> _compartilharLinkRapido(BuildContext context) async {
    if (_processando) return;
    final servico =
        widget.servicoCompartilhamento ?? ServicoCompartilhamento.instancia;
    Navigator.of(context).pop();
    await servico.compartilharLinkPorDados(widget.dados);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: cores.deepBasalt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cores.graniteEdge,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(ChaveTexto.shareModalTitulo),
                          style: TextStyle(
                            color: cores.chalkWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(ChaveTexto.shareModalSubtitulo),
                          style: TextStyle(
                            color: cores.ashGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cores.ashGrey),
                    tooltip: context.tr(ChaveTexto.comumFechar),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _chaveRepaint,
                      child: CartaoCompartilhamentoAresta(
                        dados: widget.dados,
                        imageProviderOverride: widget.imageProviderOverride,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                key: const Key('btn_compartilhar_imagem_stories'),
                onPressed: _processando
                    ? null
                    : () => _compartilharImagemStories(context),
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: Text(
                  context.tr(ChaveTexto.shareBtnImagemStories),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('btn_compartilhar_link_rapido'),
                onPressed: _processando
                    ? null
                    : () => _compartilharLinkRapido(context),
                icon: Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: cores.chalkWhite,
                ),
                label: Text(
                  context.tr(ChaveTexto.shareBtnLinkRapido),
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cores.graniteEdge),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
