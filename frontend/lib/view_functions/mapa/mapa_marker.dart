import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';

/// Gera um BitmapDescriptor customizado com o formato de um pino de mapa (teardrop)
/// contendo a imagem do logo do app dentro dele.
Future<BitmapDescriptor> createCustomMarkerBitmap(String imagePath, {int size = 150}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

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
    centerPoint + circleRadius, size.toDouble() - circleRadius, 
    centerPoint + circleRadius, circleY
  );
  
  // Arco superior (meia-lua) da direita para a esquerda
  pinPath.arcToPoint(
    Offset(centerPoint - circleRadius, circleY),
    radius: Radius.circular(circleRadius),
    clockwise: false,
  );
  
  // Curva descendo para a ponta inferior
  pinPath.quadraticBezierTo(
    centerPoint - circleRadius, size.toDouble() - circleRadius, 
    centerPoint, size.toDouble() - 5.0
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
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0,
  );

  // Raio do círculo interno onde a imagem ficará
  final double innerRadius = circleRadius * 0.8;

  // Fundo branco interno
  canvas.drawCircle(
    Offset(centerPoint, circleY),
    innerRadius,
    Paint()..color = Colors.white,
  );

  try {
    // Carregar a imagem
    final ByteData data = await rootBundle.load(imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (innerRadius * 2).toInt(),
      targetHeight: (innerRadius * 2).toInt(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    // Recortar e desenhar a imagem
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(centerPoint, circleY), radius: innerRadius)));
    canvas.drawImage(
      image,
      Offset(centerPoint - image.width / 2, circleY - image.height / 2),
      Paint(),
    );
    canvas.restore();
  } catch (e) {
    // Silently continue se a imagem falhar
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

  // Converter o canvas em uma imagem PNG
  final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(size, size);
  final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List uint8List = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(uint8List);
}

/// Gera um BitmapDescriptor customizado com texto acima do pino
Future<BitmapDescriptor> createCustomMarkerBitmapWithText(String imagePath, String text, {int size = 150}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // Setup text painter
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  
  textPainter.layout(maxWidth: 800); // Permite que o texto cresça até 800px de largura
  
  final double textWidth = textPainter.width;
  final double textHeight = textPainter.height;
  
  // Define o espaçamento (padding) interno do balão de texto para que não fique colado nas bordas
  final double bubblePaddingX = 16.0;
  final double bubblePaddingY = 10.0;
  // A largura e altura total do balão incluem o tamanho do texto mais o espaçamento
  final double bubbleWidth = textWidth + bubblePaddingX * 2;
  final double bubbleHeight = textHeight + bubblePaddingY * 2;
  // Distância entre a base do balão e o topo do pino do mapa
  final double spacingBetweenBubbleAndPin = 10.0;
  
  // Calcula as dimensões finais do canvas.
  // A largura deve ser o suficiente para acomodar o maior elemento (o balão ou o pino).
  final double canvasWidth = bubbleWidth > size ? bubbleWidth + 20 : size.toDouble();
  // A altura do canvas deve acomodar o balão + espaço + pino + espaço para a sombra do pino
  final double canvasHeight = bubbleHeight + spacingBetweenBubbleAndPin + size.toDouble() + 5.0; // +5 para a margem da sombra
  final double renderCenterX = canvasWidth / 2;
  
  // Desenhando o balão de texto na parte superior
  final bubbleRect = Rect.fromCenter(
    center: Offset(renderCenterX, bubbleHeight / 2),
    width: bubbleWidth,
    height: bubbleHeight,
  );
  
  // Sombra do balão
  canvas.drawRRect(
    RRect.fromRectAndRadius(bubbleRect.shift(const Offset(0, 4)), const Radius.circular(12)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
  );
  
  // Fundo principal do balão
  canvas.drawRRect(
    RRect.fromRectAndRadius(bubbleRect, const Radius.circular(12)),
    Paint()..color = Colors.black.withValues(alpha: 0.75),
  );
  
  // Pinta o texto centralizado dentro do balão
  textPainter.paint(
    canvas, 
    Offset(renderCenterX - textWidth / 2, bubbleHeight / 2 - textHeight / 2)
  );

  // Desenhando o pino do mapa logo abaixo do balão
  final double pinTopY = bubbleHeight + spacingBetweenBubbleAndPin;
  final double circleRadius = size * 0.35;
  final double circleY = pinTopY + size * 0.4;
  // A ponta inferior do pino ficará quase no limite do canvas, deixando espaço apenas para a sombra.
  // Como o "anchor" (âncora) padrão do Google Maps é (0.5, 1.0) - ou seja, inferior centro - 
  // deixar a ponta do pino na base garante que ele aponte exatamente para as coordenadas GPS no mapa.
  final double pinBottomY = pinTopY + size - 5.0;
  
  final Path pinPath = Path();
  // Começa na ponta inferior
  pinPath.moveTo(renderCenterX, pinBottomY);
  
  pinPath.quadraticBezierTo(
    renderCenterX + circleRadius, pinBottomY - circleRadius, 
    renderCenterX + circleRadius, circleY
  );
  
  pinPath.arcToPoint(
    Offset(renderCenterX - circleRadius, circleY),
    radius: Radius.circular(circleRadius),
    clockwise: false,
  );
  
  pinPath.quadraticBezierTo(
    renderCenterX - circleRadius, pinBottomY - circleRadius, 
    renderCenterX, pinBottomY
  );
  pinPath.close();

  // Sombra do pino
  canvas.drawPath(
    pinPath.shift(const Offset(0, 4)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
  );

  // Pino
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = AppColors.brandColor
      ..style = PaintingStyle.fill,
  );

  // Borda
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0,
  );

  final double innerRadius = circleRadius * 0.8;

  // Fundo branco
  canvas.drawCircle(
    Offset(renderCenterX, circleY),
    innerRadius,
    Paint()..color = Colors.white,
  );

  try {
    final ByteData data = await rootBundle.load(imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (innerRadius * 2).toInt(),
      targetHeight: (innerRadius * 2).toInt(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(renderCenterX, circleY), radius: innerRadius)));
    canvas.drawImage(
      image,
      Offset(renderCenterX - image.width / 2, circleY - image.height / 2),
      Paint(),
    );
    canvas.restore();
  } catch (e) {
    // Silently continue
  }
  
  // Borda interna
  canvas.drawCircle(
    Offset(renderCenterX, circleY),
    innerRadius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
  final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List uint8List = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(uint8List);
}
