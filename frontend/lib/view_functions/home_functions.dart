import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/dataset_repository.dart';
import '../navigation/navigation_tree.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';

/// Navega para a página de detalhes de um pico selecionado.
/// (Mantido para compatibilidade com browse.dart e mapa_global.dart)
void handlePicoSelection(BuildContext context, DatasetRepository datasetRepo, Map<String, dynamic> pico, {String source = 'home'}) async {
  final id = pico['id'];
  if (id == null) return;
  
  TelemetryService.instance.logAcaoCroqui(id, 'abrir_croqui', origem: source);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator(color: context.colors.beastHide)),
  );

  final croqui = await datasetRepo.getCroqui(id);

  if (!context.mounted) return;
  
  Navigator.of(context, rootNavigator: true).pop();

  if (croqui != null && croqui.picos.isNotEmpty) {
    AppNav.toPico(
      context,
      pico: croqui.picos.first,
      croqui: croqui,
      cragId: id,
    );
    
    Future.delayed(const Duration(milliseconds: 300), () {
      datasetRepo.updatePriorityAfterNavigation(id);
      datasetRepo.triggerHomeReset();
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao abrir o guia.')),
    );
  }
}

/// Constrói o corpo principal da página inicial refatorada.
Widget buildHomeBody(BuildContext context, Function(int) onSwitchTab) {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        _buildSearchBar(context, onSwitchTab),
        _buildCarouselSection(context),
        _buildGuiaRapido(context),
        _buildConservacao(context),
        const SizedBox(height: 30),
      ],
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // TODO: Fake Logo (Placeholder for the real asset)
            Icon(Icons.terrain, color: context.colors.tagTextOrange, size: 28),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade800, // Darker grey background
                borderRadius: BorderRadius.circular(4),
              ),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.bebasNeue(
                    fontSize: 26,
                    letterSpacing: 1.5,
                    height: 1.2, // Tweak line height for new text font
                  ),
                  children: [
                    const TextSpan(
                      text: 'AREST',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'A',
                      style: TextStyle(color: context.colors.tagTextOrange),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.settings, color: context.colors.textGrey),
              onPressed: () {
                TreeNavigationWrapper.of(context).treeController.navigateTo(SettingsNode(const HomeNode()));
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'BEM VINDO!',
          style: TextStyle(
            color: context.colors.textOlive,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'O guia definitivo para facilitar a sua escalada. Explore setores, vias e boulders locais e salve os croquis para acessar totalmente offline.',
          style: TextStyle(
            color: context.colors.textGrey,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSearchBar(BuildContext context, Function(int) onSwitchTab) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
    child: GestureDetector(
      onTap: () {
        // Redireciona para a aba de explorar para realizar buscas
        onSwitchTab(1); 
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.searchBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.colors.borderGrey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: context.colors.textGrey, size: 20),
            const SizedBox(width: 12),
            Text(
              'Buscar picos para escalar...',
              style: TextStyle(
                color: context.colors.textGrey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCarouselSection(BuildContext context) {
  // Dados mockados conforme instrução ("picos próximos" is a placeholder)
  final mockPicos = [
    {
      'nome': 'PEDRA GRANDE',
      'local': 'IGARAPÉ, MG',
      'detalhes': '12 setores • 184 vias',
      'imageUrl': 'assets/images/placeholder1.jpg', // Usar asset se existir, ou fallback cor
      'color': const Color(0xFF2B3A42),
    },
    {
      'nome': 'PEDRA RACHADA',
      'local': 'SABARÁ, MG',
      'detalhes': '4 setores • 45 vias',
      'imageUrl': 'assets/images/placeholder2.jpg',
      'color': const Color(0xFF1B3135),
    },
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'MAIS PRÓXIMOS DE VOCÊ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 380,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: mockPicos.length,
          padding: const EdgeInsets.only(left: 24, right: 8),
          itemBuilder: (context, index) {
            final pico = mockPicos[index];
            return Container(
              width: 260,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: pico['color'] as Color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Fake image gradient since we don't have the assets
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pico['local'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pico['nome'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pico['detalhes'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildGuiaRapido(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardOffWhite,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.tagBgOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'COMO FUNCIONA',
              style: TextStyle(
                color: context.colors.tagTextOrange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GUIA RÁPIDO DO ARESTA',
            style: TextStyle(
              color: context.colors.textDarkBlue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quatro passos pra você sair do app direto pro paredão.',
            style: TextStyle(
              color: context.colors.textDarkBlue.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildStepItem(
            context,
            num: '01',
            icon: Icons.search,
            title: 'ENCONTRE O PICO',
            desc: 'Use a busca ou explore os picos próximos no carrossel superior da home.',
            iconColor: const Color(0xFFC05244),
            bgColor: const Color(0xFFFBECE9),
          ),
          _buildStepItem(
            context,
            num: '02',
            icon: Icons.download_outlined,
            title: 'SALVE OFFLINE',
            desc: 'Baixe os croquis e setores inteiros para continuar navegando sem sinal de internet.',
            iconColor: const Color(0xFF6D9578),
            bgColor: const Color(0xFFEAF2ED),
          ),
          _buildStepItem(
            context,
            num: '03',
            icon: Icons.menu_book_outlined,
            title: 'CROQUI INTERATIVO',
            desc: 'Toque nos pontos da imagem do paredão para consultar graus, altura e proteções.',
            iconColor: const Color(0xFFBCA646),
            bgColor: const Color(0xFFF9F5DE),
          ),
          _buildStepItem(
            context,
            num: '04',
            icon: Icons.people_outline,
            title: 'COMPARTILHE',
            desc: 'Avise outros escaladores sobre restrições de fauna, chuva ou itens perdidos.',
            iconColor: const Color(0xFF5B81A7),
            bgColor: const Color(0xFFEAF1F8),
            isLast: true,
          ),
        ],
      ),
    ),
  );
}

Widget _buildStepItem(
  BuildContext context, {
  required String num,
  required IconData icon,
  required String title,
  required String desc,
  required Color iconColor,
  required Color bgColor,
  bool isLast = false,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    num,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textDarkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: context.colors.textDarkBlue.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildConservacao(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardOlive,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderGrey),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: context.colors.iconOlive),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSERVAÇÃO E ACESSO',
                  style: TextStyle(
                    color: context.colors.iconOlive,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O acesso aos picos depende de cuidado, ética e envolvimento com as comunidades locais. Cada local tem suas regras, seus guardiões e sua história. Escalar com responsabilidade é garantir que os picos continuem abertos.',
                  style: TextStyle(
                    color: context.colors.iconOlive.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
