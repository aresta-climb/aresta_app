// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import '../../data/modelos/tipo_feedback.dart';
import '../../navigation/wrapper_navegacao_arvore.dart';
import '../../navigation/arvore/no_navegacao.dart';
import '../../theme/cores_app.dart';

/// Construtor de interface de feedback em texto para o usuário.
///
/// Este construtor substitui a caixa de texto padrão do pacote `feedback`,
/// integrando categorização contextual, aviso de transparência pública e
/// adequação ao design system do Aresta.
Widget construtorFeedbackUsuario(
  BuildContext context,
  OnSubmit onSubmit,
  ScrollController? scrollController, {
  String? cragId,
  String? Function()? resolverCragId,
}) {
  return CustomStringFeedback(
    onSubmit: onSubmit,
    scrollController: scrollController,
    cragId: cragId,
    resolverCragId: resolverCragId,
  );
}

/// Alias de compatibilidade retroativa para [construtorFeedbackUsuario].
const customFeedbackBuilder = construtorFeedbackUsuario;

/// Widget Stateful que renderiza o formulário de feedback do Aresta.
///
/// Apresenta o título "Sobre o que é a sugestão?", seleção contextual
/// via [SegmentedButton] quando um croqui está ativo, campo descritivo,
/// aviso de transparência do GitHub e despacho com extras tipados.
class CustomStringFeedback extends StatefulWidget {
  const CustomStringFeedback({
    super.key,
    required this.onSubmit,
    required this.scrollController,
    this.cragId,
    this.resolverCragId,
  });

  /// Função executada ao clicar no botão "Enviar".
  final OnSubmit onSubmit;

  /// Controlador de rolagem integrado com a folha arrastável (bottom sheet).
  final ScrollController? scrollController;

  /// Identificador opcional do croqui ativo injetado diretamente (ex: em testes).
  final String? cragId;

  /// Função opcional para resolução dinâmica do croqui ativo.
  final String? Function()? resolverCragId;

  @override
  State<CustomStringFeedback> createState() => _CustomStringFeedbackState();
}

class _CustomStringFeedbackState extends State<CustomStringFeedback>
    with WidgetsBindingObserver {
  /// Controlador do campo de texto de feedback.
  late TextEditingController controller;

  /// Categoria selecionada pelo usuário no [SegmentedButton].
  TipoFeedback? _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  /// Descobre se há um croqui ativo na árvore de navegação atual.
  String? _obterCragIdAtivo() {
    if (widget.resolverCragId != null) {
      return widget.resolverCragId!();
    }
    if (widget.cragId != null) {
      return widget.cragId;
    }
    try {
      final treeController = TreeNavigationWrapper.currentTreeController;
      if (treeController != null) {
        NavNode? current = treeController.currentNode;
        while (current != null) {
          if (current is PicoContextNode) {
            return current.cragId;
          }
          current = current.parent;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.chalkWhite;
    final hintColor = context.colors.ashGrey;
    final fillColor = context.colors.caveShadow;
    final borderColor = context.colors.graniteEdge;
    const buttonColor = Color(0xFFC04F34);

    final cragIdAtivo = _obterCragIdAtivo();
    final temCroquiAtivo = cragIdAtivo != null && cragIdAtivo.isNotEmpty;

    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final minLines = isKeyboardVisible ? 2 : 1;
    final maxLines = isKeyboardVisible ? 3 : 2;

    return SafeArea(
      bottom: true,
      top: false,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sobre o que é a sugestão?',
              maxLines: 2,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (temCroquiAtivo) ...[
              const SizedBox(height: 10),
              SegmentedButton<TipoFeedback>(
                segments: const [
                  ButtonSegment<TipoFeedback>(
                    value: TipoFeedback.croqui,
                    label: Text('Sobre o Croqui'),
                    icon: Icon(Icons.terrain_rounded, size: 18),
                  ),
                  ButtonSegment<TipoFeedback>(
                    value: TipoFeedback.aplicativo,
                    label: Text('Sobre o App'),
                    icon: Icon(Icons.phone_android_rounded, size: 18),
                  ),
                ],
                selected: _tipoSelecionado != null
                    ? {_tipoSelecionado!}
                    : <TipoFeedback>{},
                emptySelectionAllowed: true,
                onSelectionChanged: (Set<TipoFeedback> novaSelecao) {
                  setState(() {
                    _tipoSelecionado =
                        novaSelecao.isNotEmpty ? novaSelecao.first : null;
                  });
                },
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return buttonColor;
                    }
                    return fillColor;
                  }),
                  foregroundColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return context.colors.chalkWhite;
                    }
                    return context.colors.ashGrey;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: borderColor),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: buttonColor,
                  selectionColor: buttonColor.withValues(alpha: 0.4),
                  selectionHandleColor: buttonColor,
                ),
              ),
              child: DefaultTextEditingShortcuts(
                child: TextField(
                  key: const Key('text_input_field'),
                  maxLines: maxLines,
                  minLines: minLines,
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: textColor),
                  cursorColor: buttonColor,
                  decoration: InputDecoration(
                    hintText: 'Descreva o problema ou sugestão...',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: buttonColor, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: fillColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu relato e a captura da tela serão registrados publicamente no nosso GitHub comunitário para que os mantenedores possam atuar. Nenhum dado pessoal ou de dispositivo é exposto.',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final isEmpty = value.text.trim().isEmpty;
                final isValid =
                    (!temCroquiAtivo || _tipoSelecionado != null) && !isEmpty;

                return ElevatedButton(
                  key: const Key('submit_feedback_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: context.colors.chalkWhite,
                    disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        context.colors.chalkWhite.withValues(alpha: 0.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isValid
                      ? () {
                          final categoriaFinal = temCroquiAtivo
                              ? _tipoSelecionado!
                              : TipoFeedback.aplicativo;
                          widget.onSubmit(
                            controller.text,
                            extras: {'tipo_feedback': categoriaFinal.valor},
                          );
                        }
                        : null,
                  child: const Text(
                    'Enviar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
