// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/firebase/app_logger.dart';
import '../../../theme/cores_app.dart';

/// Converte um [ByteData] gerado a partir de um canvas em um [BitmapDescriptor] com fallback seguro
/// e suporte a especificações de densidade de pixels (Retina / High-DPI).
///
/// Em ambientes com restrição de memória de textura ou GPUs sob pressão (como dispositivos
/// móveis em transições ou falhas de superfície gráfica), o método `toByteData()` pode retornar nulo.
/// Esta função trata a nulidade retornando [BitmapDescriptor.defaultMarker] em vez de disparar
/// exceções de force-unwrap (`!`).
BitmapDescriptor converterByteDataEmBitmap(
  ByteData? byteData, {
  double? imagePixelRatio,
  double? width,
  double? height,
}) {
  if (byteData == null) {
    return BitmapDescriptor.defaultMarker;
  }
  return BitmapDescriptor.bytes(
    byteData.buffer.asUint8List(),
    imagePixelRatio: imagePixelRatio,
    width: width,
    height: height,
  );
}

/// Gera um BitmapDescriptor customizado com o formato de um pino de mapa (teardrop)
/// contendo a imagem do logo do app dentro dele, com suporte a renderização vetorial de alta definição ([pixelRatio]).
Future<BitmapDescriptor> createCustomMarkerBitmap(
  String caminhoImagem, {
  int size = 150,
  double pixelRatio = 3.0,
  AssetBundle? bundle,
}) async {
  final double rasterSize = size * pixelRatio;
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // Escala todo o canvas pelo pixelRatio para garantir nitidez máxima (Retina / High-DPI)
  canvas.scale(pixelRatio);

  final double centerPoint = size / 2;
  // O raio da parte superior do pino
  final double circleRadius = size * 0.35;
  // O centro da parte circular superior
  final double circleY = size * 0.4;

  final Path pinPath = Path();
  // Começa na ponta inferior (deixando 5px de margem para a sombra)
  pinPath.moveTo(centerPoint, size.toDouble() - 5.0);

  // Curva subindo para o lado direito do círculo
  pinPath.quadraticBezierTo(
    centerPoint + circleRadius,
    size.toDouble() - circleRadius,
    centerPoint + circleRadius,
    circleY,
  );

  // Arco superior (meia-lua) da direita para a esquerda
  pinPath.arcToPoint(
    Offset(centerPoint - circleRadius, circleY),
    radius: Radius.circular(circleRadius),
    clockwise: false,
  );

  // Curva descendo para a ponta inferior
  pinPath.quadraticBezierTo(
    centerPoint - circleRadius,
    size.toDouble() - circleRadius,
    centerPoint,
    size.toDouble() - 5.0,
  );
  pinPath.close();

  // Desenhar a sombra
  canvas.drawPath(
    pinPath.shift(const Offset(0, 4)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
  );

  // Desenhar o pino principal (Cor da Logomarca)
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = AppColors.brandColor
      ..style = PaintingStyle.fill,
  );

  // Desenhar a borda externa preta
  final double espessuraBorda = (size * 0.025).clamp(1.5, 3.0);
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessuraBorda,
  );

  // Raio do círculo interno onde a imagem ficará
  final double innerRadius = circleRadius * 0.8;

  // Fundo branco interno
  canvas.drawCircle(
    Offset(centerPoint, circleY),
    innerRadius,
    Paint()..color = Colors.white,
  );

  if (caminhoImagem.isNotEmpty) {
    try {
      // Carregar a imagem com resolução proporcional ao pixelRatio para máxima fidelidade visual
      final bundleParaUsar = bundle ?? rootBundle;
      final ByteData data = await bundleParaUsar.load(caminhoImagem);
      final int targetPixelSize = (innerRadius * 2 * pixelRatio).toInt().clamp(1, 4096);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetPixelSize,
        targetHeight: targetPixelSize,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
