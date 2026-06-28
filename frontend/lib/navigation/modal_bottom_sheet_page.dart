import 'package:flutter/material.dart';

/// Uma página (Page) customizada para o Navigator 2.0 que renderiza
/// seu conteúdo através de uma ModalBottomSheetRoute em vez de uma rota padrão.
/// Isso permite que modais sejam controlados nativamente de forma declarativa.
class ModalBottomSheetPage<T> extends Page<T> {
  final WidgetBuilder builder;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const ModalBottomSheetPage({
    required this.builder,
    this.isScrollControlled = false,
    this.backgroundColor,
    this.shape,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      builder: builder,
      isScrollControlled: isScrollControlled,
      settings: this,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}
