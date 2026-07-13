import 'package:feedback/feedback.dart';
import 'package:feedback/src/theme/feedback_theme.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Construtor customizado para a interface de feedback em texto.
///
/// Este builder substitui a caixa de texto padrão do pacote `feedback`,
/// permitindo que a UI se integre perfeitamente com o tema e as cores
/// do aplicativo Aresta.
Widget customFeedbackBuilder(
  BuildContext context,
  OnSubmit onSubmit,
  ScrollController? scrollController,
) {
  return CustomStringFeedback(
    onSubmit: onSubmit,
    scrollController: scrollController,
  );
}

/// Widget Stateful que renderiza o formulário de feedback.
///
/// Recebe um [onSubmit] callback para processar o texto digitado
/// e um [scrollController] opcional (geralmente fornecido por um
/// DraggableScrollableSheet do pacote pai) para gerenciar a rolagem
/// suave e expansão da tela inferior.
class CustomStringFeedback extends StatefulWidget {
  const CustomStringFeedback({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  /// Função executada ao clicar no botão "Enviar".
  final OnSubmit onSubmit;

  /// Controlador de rolagem integrado com a folha arrastável (bottom sheet).
  final ScrollController? scrollController;

  @override
  State<CustomStringFeedback> createState() => _CustomStringFeedbackState();
}

class _CustomStringFeedbackState extends State<CustomStringFeedback> {
  /// Controlador do campo de texto de feedback.
  late TextEditingController controller;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = FeedbackTheme.of(context).brightness == Brightness.dark;
    final appColors = isDark ? AppColors.dark : AppColors.light;

    // Determine colors for the text field and button
    final textColor = isDark ? appColors.fishBone : appColors.fishBone;
    final hintColor = isDark ? appColors.fishBone.withValues(alpha: 0.5) : appColors.fishBone.withValues(alpha: 0.6);
    final fillColor = isDark ? appColors.nobleBlack.withValues(alpha: 0.4) : appColors.slateStone;
    final borderColor = isDark ? appColors.weatheredIron.withValues(alpha: 0.5) : Colors.transparent;
    final buttonColor = appColors.beastHide;

    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    
    // Resize textual experience dynamically
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
            'Qual o problema?',
            maxLines: 2,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        const SizedBox(height: 8),
        ElevatedButton(
          key: const Key('submit_feedback_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: appColors.nobleBlack,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Enviar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onPressed: () => widget.onSubmit(controller.text),
        ),
      ],
        ),
      ),
    );
  }
}
