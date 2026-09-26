// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';

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

      // Recortar e desenhar a imagem com alta qualidade de filtragem
      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(centerPoint, circleY),
            radius: innerRadius,
          ),
        ),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(
          center: Offset(centerPoint, circleY),
          radius: innerRadius,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } catch (e) {
      // Silently continue se a imagem falhar
    }
  }

  // Desenhar uma borda interna sutil para separar a imagem do pino
  canvas.drawCircle(
    Offset(centerPoint, circleY),
    innerRadius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  // Converter o canvas em uma imagem PNG em alta resolução física
  final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
    rasterSize.toInt(),
    rasterSize.toInt(),
  );
  final ByteData? byteData = await markerAsImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return converterByteDataEmBitmap(
    byteData,
    imagePixelRatio: pixelRatio,
    width: size.toDouble(),
    height: size.toDouble(),
  );
}

/// Dimensões calculadas para o balão de texto e o canvas do marcador com texto.
class DimensoesMarcador {
  /// Largura total do canvas gerado.
  final double larguraCanvas;

  /// Altura total do canvas gerado.
  final double alturaCanvas;

  /// Largura total do balão de texto.
  final double larguraBalao;

  /// Altura total do balão de texto.
  final double alturaBalao;

  /// Largura calculada estritamente para o texto.
  final double larguraTexto;

  /// Altura calculada estritamente para o texto.
  final double alturaTexto;

  /// Tamanho da fonte tipográfica utilizado no desenho.
  final double tamanhoFonte;

  const DimensoesMarcador({
    required this.larguraCanvas,
    required this.alturaCanvas,
    required this.larguraBalao,
    required this.alturaBalao,
    required this.larguraTexto,
    required this.alturaTexto,
    required this.tamanhoFonte,
  });
}

/// Calcula as dimensões proporcionais do balão e do canvas para um marcador com texto,
/// aplicando limites de largura máxima e truncamento com reticências (`...`) para nomes longos.
DimensoesMarcador calcularDimensoesMarcador({
  required String texto,
  required int tamanhoPino,
  double larguraMaximaTexto = 200.0,
}) {
  // Tamanho de fonte proporcional contido (entre 11 e 15px) para preservar densidade visual
  final double tamanhoFonte = (tamanhoPino * 0.16).clamp(11.0, 15.0);

  final textPainter = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        color: Colors.white,
        fontSize: tamanhoFonte,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 1,
    ellipsis: '...',
  );

  textPainter.layout(maxWidth: larguraMaximaTexto);

  final double textWidth = textPainter.width;
  final double textHeight = textPainter.height;

  const double bubblePaddingX = 12.0;
  const double bubblePaddingY = 6.0;
  final double bubbleWidth = textWidth + bubblePaddingX * 2;
  final double bubbleHeight = textHeight + bubblePaddingY * 2;
  const double spacingBetweenBubbleAndPin = 6.0;

  final double canvasWidth = bubbleWidth > tamanhoPino
      ? bubbleWidth + 16.0
      : tamanhoPino.toDouble() + 16.0;
  final double canvasHeight =
      bubbleHeight + spacingBetweenBubbleAndPin + tamanhoPino.toDouble() + 5.0;

  return DimensoesMarcador(
    larguraCanvas: canvasWidth,
    alturaCanvas: canvasHeight,
    larguraBalao: bubbleWidth,
    alturaBalao: bubbleHeight,
    larguraTexto: textWidth,
    alturaTexto: textHeight,
    tamanhoFonte: tamanhoFonte,
  );
}

/// Gera um BitmapDescriptor customizado com texto acima do pino,
/// limitando a largura do balão para evitar sobreposição excessiva no mapa e renderizando em alta definição ([pixelRatio]).
Future<BitmapDescriptor> createCustomMarkerBitmapWithText(
  String caminhoImagem,
  String texto, {
  int size = 85,
  double larguraMaximaTexto = 200.0,
  double pixelRatio = 3.0,
  AssetBundle? bundle,
}) async {
  final dimensoes = calcularDimensoesMarcador(
    texto: texto,
    tamanhoPino: size,
    larguraMaximaTexto: larguraMaximaTexto,
  );

  final double rasterWidth = dimensoes.larguraCanvas * pixelRatio;
  final double rasterHeight = dimensoes.alturaCanvas * pixelRatio;

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // Escala todo o canvas pelo pixelRatio para garantir nitidez máxima (Retina / High-DPI)
  canvas.scale(pixelRatio);

  final textPainter = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        color: Colors.white,
        fontSize: dimensoes.tamanhoFonte,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 1,
    ellipsis: '...',
  );
  textPainter.layout(maxWidth: larguraMaximaTexto);

  final double renderCenterX = dimensoes.larguraCanvas / 2;

  // Desenhando o balão de texto na parte superior
  final bubbleRect = Rect.fromCenter(
    center: Offset(renderCenterX, dimensoes.alturaBalao / 2),
    width: dimensoes.larguraBalao,
    height: dimensoes.alturaBalao,
  );

  // Sombra do balão
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      bubbleRect.shift(const Offset(0, 3)),
      const Radius.circular(8),
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
  );

  // Fundo principal do balão
  canvas.drawRRect(
    RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8)),
    Paint()..color = Colors.black.withValues(alpha: 0.8),
  );

  // Pinta o texto centralizado dentro do balão
  textPainter.paint(
    canvas,
    Offset(
      renderCenterX - dimensoes.larguraTexto / 2,
      dimensoes.alturaBalao / 2 - dimensoes.alturaTexto / 2,
    ),
  );

  // Desenhando o pino do mapa logo abaixo do balão
  const double spacingBetweenBubbleAndPin = 6.0;
  final double pinTopY = dimensoes.alturaBalao + spacingBetweenBubbleAndPin;
  final double circleRadius = size * 0.35;
  final double circleY = pinTopY + size * 0.4;
  // A ponta inferior do pino repousa na base para apontar com precisão ao GPS
  final double pinBottomY = pinTopY + size - 5.0;

  final Path pinPath = Path();
  pinPath.moveTo(renderCenterX, pinBottomY);

  pinPath.quadraticBezierTo(
    renderCenterX + circleRadius,
    pinBottomY - circleRadius,
    renderCenterX + circleRadius,
    circleY,
  );

  pinPath.arcToPoint(
    Offset(renderCenterX - circleRadius, circleY),
    radius: Radius.circular(circleRadius),
    clockwise: false,
  );

  pinPath.quadraticBezierTo(
    renderCenterX - circleRadius,
    pinBottomY - circleRadius,
    renderCenterX,
    pinBottomY,
  );
  pinPath.close();

  // Sombra do pino
  canvas.drawPath(
    pinPath.shift(const Offset(0, 3)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
  );

  // Pino
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = AppColors.brandColor
      ..style = PaintingStyle.fill,
  );

  // Borda externa
  final double espessuraBorda = (size * 0.025).clamp(1.5, 3.0);
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessuraBorda,
  );

  final double innerRadius = circleRadius * 0.8;

  // Fundo branco
  canvas.drawCircle(
    Offset(renderCenterX, circleY),
    innerRadius,
    Paint()..color = Colors.white,
  );

  if (caminhoImagem.isNotEmpty) {
    try {
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

      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(renderCenterX, circleY),
            radius: innerRadius,
          ),
        ),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(
          center: Offset(renderCenterX, circleY),
          radius: innerRadius,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } catch (e) {
      // Silently continue
    }
  }

  // Borda interna
  canvas.drawCircle(
    Offset(renderCenterX, circleY),
    innerRadius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );

  final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
    rasterWidth.toInt(),
    rasterHeight.toInt(),
  );
  final ByteData? byteData = await markerAsImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return converterByteDataEmBitmap(
    byteData,
    imagePixelRatio: pixelRatio,
    width: dimensoes.larguraCanvas,
    height: dimensoes.alturaCanvas,
  );
}

/// Gera um [BitmapDescriptor] contendo exclusivamente o balão de texto com cantos arredondados,
/// projetado para exibição desacoplada como rótulo flutuante acima do pino do mapa.
///
/// Não inclui o desenho do pino nem gera asas laterais transparentes excedentes,
/// garantindo que a sobreposição visual não cause interferências espúrias de hit-test.
Future<BitmapDescriptor> createCustomMarkerLabelBitmap(
  String texto, {
  double larguraMaximaTexto = 200.0,
  double pixelRatio = 3.0,
}) async {
  // Tamanho de fonte proporcional equivalente ao utilizado no pino local (85 * 0.16)
  const double tamanhoFonte = 13.6;

  final textPainter = TextPainter(
    text: TextSpan(
      text: texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: tamanhoFonte,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 1,
    ellipsis: '...',
  );
  textPainter.layout(maxWidth: larguraMaximaTexto);

  const double bubblePaddingX = 12.0;
  const double bubblePaddingY = 6.0;
  final double bubbleWidth = textPainter.width + bubblePaddingX * 2;
  final double bubbleHeight = textPainter.height + bubblePaddingY * 2;

  // Margem mínima de 4px para conter suavemente a sombra sem criar asas largas
  const double shadowMargin = 4.0;
  final double canvasWidth = bubbleWidth + shadowMargin * 2;
  final double canvasHeight = bubbleHeight + shadowMargin * 2;

  final double rasterWidth = canvasWidth * pixelRatio;
  final double rasterHeight = canvasHeight * pixelRatio;

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  canvas.scale(pixelRatio);

  final bubbleRect = Rect.fromLTWH(
    shadowMargin,
    shadowMargin,
    bubbleWidth,
    bubbleHeight,
  );

  // Sombra suave do balão
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      bubbleRect.shift(const Offset(0, 2)),
      const Radius.circular(8),
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
  );

  // Fundo principal escuro com cantos arredondados
  canvas.drawRRect(
    RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8)),
    Paint()..color = Colors.black.withValues(alpha: 0.8),
  );

  // Renderiza o texto centralizado dentro do balão
  textPainter.paint(
    canvas,
    Offset(
      shadowMargin + bubblePaddingX,
      shadowMargin + bubblePaddingY,
    ),
  );

  final ui.Image labelImage = await pictureRecorder.endRecording().toImage(
    rasterWidth.toInt(),
    rasterHeight.toInt(),
  );
  final ByteData? byteData = await labelImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return converterByteDataEmBitmap(
    byteData,
    imagePixelRatio: pixelRatio,
    width: canvasWidth,
    height: canvasHeight,
  );
}

