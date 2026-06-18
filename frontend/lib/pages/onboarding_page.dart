import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onDone;

  const OnboardingPage({super.key, this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == 2;
              });
            },
            children: [
              _buildPage(
                color: Colors.blue.shade100,
                title: 'Bem-vindo ao Aresta Climb',
                description: 'Seu guia completo para explorar novas rotas.',
                icon: Icons.map_outlined,
              ),
              _buildPage(
                color: Colors.green.shade100,
                title: 'Offline First',
                description: 'Baixe os picos e acesse todas as informações mesmo sem internet na base da montanha.',
                icon: Icons.cloud_off,
              ),
              _buildPage(
                color: Colors.orange.shade100,
                title: 'Comunidade Forte',
                description: 'Ajude a manter os croquis atualizados e cresça junto com a comunidade.',
                icon: Icons.people_outline,
              ),
            ],
          ),
          
          // Indicador e botões inferiores
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _isLastPage
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: widget.onDone,
                    child: const Text('Começar a Usar'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onDone,
                        child: const Text('Pular'),
                      ),
                      SmoothPageIndicator(
                        controller: _controller,
                        count: 3,
                        effect: const WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: Colors.blue,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Próximo'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required Color color,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.black54),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
