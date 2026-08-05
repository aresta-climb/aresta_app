import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';

Widget buildQuadrantCollapsedContent(BuildContext context, Map<String, String> data, int index) {
  AlignmentGeometry align = Alignment.center;
  if (index == 0) align = const Alignment(-0.5, -0.5);
  else if (index == 1) align = const Alignment(0.5, -0.5);
  else if (index == 2) align = const Alignment(-0.5, 0.5);
  else if (index == 3) align = const Alignment(0.5, 0.5);

  return Align(
    alignment: align,
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: context.colors.slateBlue.withValues(alpha: 0.5),
              backgroundImage: AssetImage(data['image']!),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['role']!,
            style: TextStyle(
              color: context.colors.chalkWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

const List<Map<String, String>> teamData = [
    {
      'role': 'Designer',
      'name': 'Lorena Carla',
      'desc': 'Responsável por toda a identidade visual do app, prototipagem e criação de layouts.',
      'linkedin': 'https://www.linkedin.com/in/lorenamelor/',
      'github': '',
      'image': 'assets/team/lorena.webp',
    },
    {
      'role': 'Produto',
      'name': 'Evandro Jaconi',
      'desc': 'Faz as pesquisas de persona, definições de visão de negócio e marketing do projeto.',
      'linkedin': 'https://www.linkedin.com/in/evandrojaconi/',
      'github': '',
      'image': 'assets/team/evandro.webp',
    },
    {
      'role': 'Backend',
      'name': 'Renato Utsch',
      'desc': 'Desenvolvimento de APIs, banco de dados, infraestrutura do servidor e auxilia a equipe de frontend.',
      'linkedin': 'https://www.linkedin.com/in/renatoutsch/',
      'github': 'https://github.com/renatoutsch',
      'image': 'assets/team/renato.webp',
    },
    {
      'role': 'Frontend',
      'name': 'Eduardo Utsch',
      'desc': 'Desenvolvimento da interface do aplicativo, testes de integração e auxilia a equipe de backend.',
      'linkedin': 'https://www.linkedin.com/in/eduardo-utsch-205745350/',
      'github': 'https://github.com/eduardoutsch',
      'image': 'assets/team/eduardo.webp',
    },
  ];

Widget buildAnimatedQuadrant({
  required BuildContext context,
  required int index,
  required int? activeQuadrant,
  required Animation<double> animation,
  required VoidCallback onTap,
}) {
    final bool isActive = activeQuadrant == index;
    final bool isAnyActive = activeQuadrant != null;
    
    double expandValue = 0.0;
    double scale = 1.0;
    double opacity = 1.0;
    Offset translate = Offset.zero;

    if (isAnyActive) {
      if (isActive) {
        expandValue = animation.value;
        scale = 1.0 + (animation.value * 0.05); // slight pop effect
      } else {
        scale = 1.0 - (animation.value * 0.15);
        opacity = 1.0 - animation.value;
        
        final double pushDist = 20.0 * animation.value;
        if (index == 0) translate = Offset(-pushDist, -pushDist);
        else if (index == 1) translate = Offset(pushDist, -pushDist);
        else if (index == 2) translate = Offset(-pushDist, pushDist);
        else if (index == 3) translate = Offset(pushDist, pushDist);
      }
    } else {
      // Doritos separados
      const double gap = 2.0;
      if (index == 0) translate = const Offset(-gap, -gap);
      else if (index == 1) translate = const Offset(gap, -gap);
      else if (index == 2) translate = const Offset(-gap, gap);
      else if (index == 3) translate = const Offset(gap, gap);
    }

    return Transform.translate(
      offset: translate,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: ClipPath(
            clipper: QuadrantClipper(index, expand: expandValue),
            child: GestureDetector(
              onTap: onTap,
              child: CustomPaint(
                painter: QuadrantPainter(
                  index: index,
                  expand: expandValue,
                  fillColor: context.colors.slateBlue,
                  canvasSize: Size(MediaQuery.of(context).size.width - 32, MediaQuery.of(context).size.width - 32),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isActive && animation.value > 0.5
                        ? buildQuadrantDetailedContent(context, teamData[index])
                        : buildQuadrantCollapsedContent(context, teamData[index], index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


Widget buildQuadrantDetailedContent(BuildContext context, Map<String, String> data) {
  final double canvasSize = MediaQuery.of(context).size.width - 32;
  final double inscribedSquareSize = canvasSize * 0.707;

  return Center(
    child: SizedBox(
      width: inscribedSquareSize,
      height: inscribedSquareSize,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          width: inscribedSquareSize,
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: context.colors.slateBlue.withValues(alpha: 0.8),
                backgroundImage: AssetImage(data['image']!),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data['name']!.toUpperCase(),
              style: TextStyle(
                color: context.colors.chalkWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              data['role']!,
              style: TextStyle(
                color: context.colors.dryMoss,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              data['desc']!,
              style: TextStyle(
                color: context.colors.ashGrey,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                if (data['linkedin']!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(Uri.parse(data['linkedin']!), mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Error launching url: ');
                      }
                    },
                    icon: const Icon(Icons.work_outline, size: 16, color: Colors.white),
                    label: const Text('LinkedIn', style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A66C2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                if (data['github']!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(Uri.parse(data['github']!), mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Error launching url: $e');
                      }
                    },
                    icon: const Icon(Icons.code, size: 16, color: Colors.black),
                    label: const Text('GitHub', style: TextStyle(color: Colors.black, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
}

Path getQuadrantPath(Size size, int index, double expand) {
  final Path path = Path();
  final double cx = size.width / 2;
  final double cy = size.height / 2;
  final double radius = math.min(size.width, size.height) / 2;

  if (expand >= 1.0) {
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    return path;
  }

  double startAngle = 0;
  double sweepAngle = math.pi / 2; 

  if (index == 0) startAngle = math.pi; // Top-Left
  else if (index == 1) startAngle = -math.pi / 2; // Top-Right
  else if (index == 2) startAngle = math.pi / 2; // Bottom-Left
  else if (index == 3) startAngle = 0; // Bottom-Right

  final double extraSweep = (math.pi * 2 - math.pi / 2) * expand;
  startAngle -= extraSweep / 2;
  sweepAngle += extraSweep;

  path.moveTo(cx, cy);
  path.arcTo(
    Rect.fromCircle(center: Offset(cx, cy), radius: radius),
    startAngle,
    sweepAngle,
    false,
  );
  path.close();

  return path;
}

class QuadrantClipper extends CustomClipper<Path> {
  final int index;
  final double expand;

  QuadrantClipper(this.index, {this.expand = 0.0});

  @override
  Path getClip(Size size) => getQuadrantPath(size, index, expand);

  @override
  bool shouldReclip(QuadrantClipper oldClipper) => 
      index != oldClipper.index || expand != oldClipper.expand;
}

class QuadrantPainter extends CustomPainter {
  final int index;
  final double expand;
  final Color fillColor;
  final Size canvasSize;

  QuadrantPainter({
    required this.index,
    required this.expand,
    required this.fillColor,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = getQuadrantPath(size, index, expand);

    // 1. Soft Drop Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 8.0, true);

    // 2. Base Fill (Solid color, completely opaque)
    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool? hitTest(Offset position) {
    final path = getQuadrantPath(canvasSize, index, expand);
    return path.contains(position);
  }

  @override
  bool shouldRepaint(QuadrantPainter oldDelegate) {
    return index != oldDelegate.index ||
           expand != oldDelegate.expand ||
           fillColor != oldDelegate.fillColor;
  }
}

