import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/sobre_time_functions.dart';
import '../main.dart';

class SobreTimePage extends StatefulWidget {
  const SobreTimePage({super.key});

  @override
  State<SobreTimePage> createState() => _SobreTimePageState();
}

class _SobreTimePageState extends State<SobreTimePage>
    with SingleTickerProviderStateMixin {
  int? _activeQuadrant;
  late AnimationController _animationController;
  late Animation<double> _animation;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onQuadrantTapped(int index) {
    if (_animationController.isAnimating) return;
    if (_activeQuadrant == index) {
      _animationController.reverse().then((_) {
        if (mounted) setState(() => _activeQuadrant = null);
      });
    } else {
      if (_activeQuadrant != null) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() => _activeQuadrant = index);
            _animationController.forward(from: 0.0);
          }
        });
      } else {
        setState(() => _activeQuadrant = index);
        _animationController.forward(from: 0.0);
      }
    }
  }

  void _onBackgroundTapped() {
    if (_animationController.isAnimating) return;
    if (_activeQuadrant != null) {
      _animationController.reverse().then((_) {
        if (mounted) setState(() => _activeQuadrant = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      appBar: AppBar(
        backgroundColor: context.colors.deepBasalt,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.dryMoss),
          onPressed: () {
            final tree = TreeNavigationWrapper.currentTreeController;
            tree?.goBack();
          },
        ),
        title: Text(
          'SOBRE O TIME',
          style: TextStyle(
            color: context.colors.dryMoss,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          buildFeedbackButton(context, color: context.colors.ashGrey),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: _onBackgroundTapped,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'CONHEÇA QUEM FAZ O ARESTA',
                style: TextStyle(
                  color: context.colors.ashGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: math.min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) - 64,
                  height: math.min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) - 64,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // Order the children so the active one is drawn last (on top)
                      List<int> drawOrder = [0, 1, 2, 3];
                      if (_activeQuadrant != null) {
                        drawOrder.remove(_activeQuadrant!);
                        drawOrder.add(_activeQuadrant!);
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: drawOrder.map((index) {
                          return buildAnimatedQuadrant(
                            context: context,
                            index: index,
                            activeQuadrant: _activeQuadrant,
                            animation: _animation,
                            onTap: () => _onQuadrantTapped(index),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse('https://discord.gg/3KDTwcxHK'), mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Error launching url: $e');
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.darkPine,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.colors.graniteEdge),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'O ARESTA É OPEN SOURCE',
                        style: TextStyle(
                          color: context.colors.dryMoss,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tem interesse em contribuir e ter sua foto aqui? Entre no nosso Discord e nos envie uma mensagem!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.ashGrey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
