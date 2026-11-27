// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/formulario_alerta_via_view_model.dart';

const Color _corVermelhoAlertaModal = Color(0xFFD93829);

/// Abre o modal rápido (Dumb UI) para reportar um novo alerta ou editar [alertaInicial] na via.
Future<void> exibirModalFormularioAlertaVia(
  BuildContext context, {
  AlertaSegurancaVia? alertaInicial,
  required Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoSubmeter,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: _FormularioAlertaViaSheet(
          alertaInicial: alertaInicial,
          aoSubmeter: aoSubmeter,
        ),
      );
    },
  );
}

class _FormularioAlertaViaSheet extends StatefulWidget {
  final AlertaSegurancaVia? alertaInicial;
  final Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoSubmeter;

  const _FormularioAlertaViaSheet({
    this.alertaInicial,
    required this.aoSubmeter,
  });

  @override
  State<_FormularioAlertaViaSheet> createState() =>
      _FormularioAlertaViaSheetState();
}

class _FormularioAlertaViaSheetState extends State<_FormularioAlertaViaSheet> {
  late final FormularioAlertaViaViewModel _viewModel;
  late final TextEditingController _detalheController;

  @override
  void initState() {
    super.initState();
    final inicial = widget.alertaInicial;
    _viewModel = FormularioAlertaViaViewModel(
      categoriaInicial: inicial?.categoria ?? CategoriaAlertaSeguranca.fauna,
      detalheInicial: inicial?.detalhe ?? '',
    );
    _detalheController = TextEditingController(text: _viewModel.detalhe)
      ..addListener(() => _viewModel.definirDetalhe(_detalheController.text));
  }

  @override
  void dispose() {
    _detalheController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final modoEdicao = widget.alertaInicial != null;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  modoEdicao
                      ? context.tr(ChaveTexto.alertaEditarModalTitulo)
                      : context.tr(ChaveTexto.alertaReportarModalTitulo),
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modoEdicao
                      ? context.tr(ChaveTexto.alertaEditarModalSub)
                      : context.tr(ChaveTexto.alertaReportarModalSub),
                  style: TextStyle(color: cores.ashGrey, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _viewModel.opcoesCategorias.map((cat) {
                    final selecionado = cat == _viewModel.categoriaSelecionada;
                    return InkWell(
                      key: Key('opcao_alerta_${cat.codigoBanco}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _viewModel.selecionarCategoria(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? _corVermelhoAlertaModal.withValues(alpha: 0.18)
                              : cores.caveShadow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selecionado
                                ? _corVermelhoAlertaModal
                                : cores.graniteEdge,
                            width: selecionado ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                cat.rotulo,
                                style: TextStyle(
                                  color: cores.chalkWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  _viewModel.descricaoCategoriaSelecionada,
                  style: TextStyle(color: cores.ashGrey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('campo_detalhe_alerta_via'),
                  controller: _detalheController,
                  maxLength: AlertaSegurancaVia.limiteCaracteresDetalhe,
                  style: TextStyle(color: cores.chalkWhite, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr(ChaveTexto.alertaDetalheLabel),
                    labelStyle: TextStyle(color: cores.ashGrey),
                    hintText: context.tr(ChaveTexto.alertaDetalheHint),
                    hintStyle: TextStyle(
                      color: cores.ashGrey.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: cores.caveShadow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cores.graniteEdge),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const Key('btn_enviar_alerta_via'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _viewModel.submeter(widget.aoSubmeter);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _corVermelhoAlertaModal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    modoEdicao
                        ? context.tr(ChaveTexto.comumSalvarAlteracoes)
                        : context.tr(ChaveTexto.alertaEnviarBtn),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Abre o modal inferior (Dumb UI) para o autor editar um comentário público (`1..280` caracteres).
Future<void> exibirModalEditarComentarioVia(
  BuildContext context, {
  required String textoInicial,
  required Future<void> Function(String novoTexto) aoSalvar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: _FormularioEditarComentarioVia(
          textoInicial: textoInicial,
          aoSalvar: aoSalvar,
        ),
      );
    },
  );
}

class _FormularioEditarComentarioVia extends StatefulWidget {
  final String textoInicial;
  final Future<void> Function(String novoTexto) aoSalvar;

  const _FormularioEditarComentarioVia({
    required this.textoInicial,
    required this.aoSalvar,
  });

  @override
  State<_FormularioEditarComentarioVia> createState() =>
      _FormularioEditarComentarioViaState();
}

class _FormularioEditarComentarioViaState
    extends State<_FormularioEditarComentarioVia> {
  late final TextEditingController _controller;
  late bool _valido;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textoInicial);
    _valido = _controller.text.trim().isNotEmpty;
    _controller.addListener(() {
      final novoValido = _controller.text.trim().isNotEmpty;
      if (novoValido != _valido) {
        setState(() => _valido = novoValido);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(ChaveTexto.viaEditarComentarioTitulo),
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(ChaveTexto.viaEditarComentarioSubtitulo),
              style: TextStyle(color: cores.ashGrey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('campo_editar_comentario_via'),
              controller: _controller,
              maxLines: 4,
              minLines: 2,
              maxLength: ComentarioComunidadeVia.limiteCaracteres,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: cores.caveShadow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cores.graniteEdge),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('btn_cancelar_edicao_comentario_via'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cores.chalkWhite,
                      side: BorderSide(color: cores.graniteEdge),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.tr(ChaveTexto.comumCancelar)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_salvar_comentario_editado_via'),
                    onPressed: _valido
                        ? () async {
                            final textoLimpo = _controller.text.trim();
                            Navigator.of(context).pop();
                            await widget.aoSalvar(textoLimpo);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cores.rustIron,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: cores.caveShadow,
                      disabledForegroundColor: cores.ashGrey,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr(ChaveTexto.comumSalvarAlteracoes),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}

/// Exibe o diálogo declarativo (Dumb UI) de confirmação para exclusão permanente de comentário ou alerta.
Future<bool?> exibirDialogoConfirmarExclusaoInteracao(
  BuildContext context, {
  required bool ehAlerta,
}) {
  final cores = context.colors;
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: cores.deepBasalt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cores.graniteEdge),
      ),
      title: Text(
        ehAlerta
            ? dialogCtx.tr(ChaveTexto.alertaExcluirModalTitulo)
            : dialogCtx.tr(ChaveTexto.viaExcluirComentarioTitulo),
        style: TextStyle(color: cores.chalkWhite, fontWeight: FontWeight.bold),
      ),
      content: Text(
        ehAlerta
            ? dialogCtx.tr(ChaveTexto.alertaExcluirModalCorpo)
            : dialogCtx.tr(ChaveTexto.viaExcluirComentarioCorpo),
        style: TextStyle(color: cores.ashGrey, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(
            dialogCtx.tr(ChaveTexto.comumCancelar),
            style: TextStyle(color: cores.ashGrey),
          ),
        ),
        ElevatedButton(
          key: const Key('btn_confirmar_exclusao_interacao_via'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _corVermelhoAlertaModal,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: Text(dialogCtx.tr(ChaveTexto.comumExcluir)),
        ),
      ],
    ),
  );
}
