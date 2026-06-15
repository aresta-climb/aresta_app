import 'package:feedback/feedback.dart';
import 'package:feedback/src/theme/feedback_theme.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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

class CustomStringFeedback extends StatefulWidget {
  const CustomStringFeedback({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  @override
  State<CustomStringFeedback> createState() => _CustomStringFeedbackState();
}

class _CustomStringFeedbackState extends State<CustomStringFeedback> {
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

    return SafeArea(
      bottom: true,
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                widget.scrollController != null ? 20 : 16,
                16,
                0,
              ),
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
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: buttonColor,
                      selectionColor: buttonColor.withValues(alpha: 0.4),
                      selectionHandleColor: buttonColor,
                    ),
                  ),
                  child: TextField(
                    key: const Key('text_input_field'),
                    maxLines: 4,
                    minLines: 2,
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
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
          ),
        ],
      ),
    );
  }
}
