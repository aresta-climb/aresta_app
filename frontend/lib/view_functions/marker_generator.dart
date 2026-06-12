import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

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
