import 'package:flutter/material.dart';
import 'common_functions.dart';

// Earthy Color Palette for Cards
const Color leatherWork = Color(0xFF896449);
const Color obsidianBrown = Color(0xFF543E35);
const Color slateStone = Color(0xFF4A4E5A);
const Color mossRock = Color(0xFF5B614D);
const Color clayEarth = Color(0xFF7D4F43);
const Color weatheredIron = Color(0xFF3E4247);

/// A palette of colors used to background the crag cards.
final List<Color> cardPalette = [
  leatherWork,
  slateStone,
  mossRock,
  clayEarth,
  weatheredIron,
];

/// Builds the main scrollable body of the Home page.
/// 
/// Displays a carousel of recently downloaded crags and a dropdown list 
/// of all available guides.
Widget buildHomeBody(List<Map<String, dynamic>> downloadedPicos, {required VoidCallback onAddCrag}) {
  // Take only the 4 most recent crags (first 4 in the list) for the carousel.
  final List<Map<String, dynamic>> recentPicos = downloadedPicos.take(4).toList();

  return Container(
    width: double.infinity,
    height: double.infinity,
    // Making the background color a gradient for prettiness
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          nobleBlack, // Main background color
          obsidianBrown, // Transitions from dark to a earthy brown
        ],
      ),
    ),
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensures it always bounces/scrolls
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          buildSectionHeader('Guias Recentes'),
          buildPicosCarousel(recentPicos),
          buildFooterInstructions('Deslize para ver seus downloads'),
          const SizedBox(height: 10),
          _buildAllGuidesDropdown(downloadedPicos, onAddCrag: onAddCrag),
          const SizedBox(height: 100), // Extra space at bottom to ensure everything is scrollable
        ],
      ),
    ),
  );
}

/// Builds an expandable list showing all downloaded guides.
Widget _buildAllGuidesDropdown(List<Map<String, dynamic>> picos, {required VoidCallback onAddCrag}) {
  return Theme(
    data: ThemeData(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      iconColor: fishBone,
      collapsedIconColor: fishBone,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: fishBone.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: const Text(
          'Todos os guias baixados',
          style: TextStyle(
            color: fishBone,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.3), // Darker than background when expanded for emphasis
      collapsedBackgroundColor: Colors.transparent,
      children: [
        ...picos.map((pico) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 32),
          title: Text(
            safeString(pico['nome']),
            style: const TextStyle(color: fishBone, fontSize: 15),
          ),
          trailing: const Icon(Icons.chevron_right, color: fishBone, size: 18),
          onTap: () {
            // TODO: Implement navigation to the selected pico's guide
            print('Selected: ${safeString(pico['nome'])}');
          },
        )),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 32),
          leading: const Icon(Icons.add_circle_outline, color: beastHide, size: 20),
          title: const Text(
            'Adicionar novo local',
            style: TextStyle(
              color: beastHide,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          onTap: onAddCrag,
        ),
      ],
    ),
  );
}

/// A stylized header for sections.
Widget buildSectionHeader(String title) {
  return Padding(
    // Padding on the text to give it some space
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: fishBone, // Light text for visibility
      ),
    ),
  );
}

/// Builds a horizontal, infinitely-looping carousel of crag cards.
Widget buildPicosCarousel(List<Map<String, dynamic>> recentPicos) {
  if (recentPicos.isEmpty) return const SizedBox();

  // Total number of items
  final int actualCount = recentPicos.length;
  // Starting in the middle of a very large number of items to allow infinite looping in both directions
  final int initialPage = actualCount * 100;

  // Carousel with offline crag data
  return SizedBox(
    height: 350,
    child: PageView.builder(
      controller: PageController(
        viewportFraction: 0.85,
        initialPage: initialPage,
      ),
      // Using initialPage and modulo we can allow infinite looping in both directions
      itemBuilder: (context, index) {
        // Calculate the actual index in the list using modulo
        final int actualIndex = index % actualCount;

        // Randomly pick a color from the palette based on the item index
        // This also ensures the same "pico container" has a constant color during navigation
        final Color cardColor = cardPalette[actualIndex % cardPalette.length];

        return buildPicoCard(recentPicos[actualIndex], 10.0, cardColor);
      },
    ),
  );
}

/// Builds an individual card for a crag in the carousel.
Widget buildPicoCard(Map<String, dynamic> pico, double rightPadding, Color cardColor) {
  return Padding(
    padding: EdgeInsets.only(left: 10, right: rightPadding, top: 20, bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeString(pico['nome'], fallback: 'Sem Nome'),
              style: const TextStyle(
                color: nobleBlack,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: nobleBlack, size: 18),
                const SizedBox(width: 5),
                Text(
                  safeString(pico['local'], fallback: 'Local Desconhecido'),
                  style: TextStyle(
                    color: nobleBlack.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            buildVerGuiaButton(),
          ],
        ),
      ),
    ),
  );
}

/// A small button on the card to indicate it can be opened.
Widget buildVerGuiaButton() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: nobleBlack.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'VER GUIA',
      style: TextStyle(
        color: nobleBlack,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// Instructions text at the bottom of the carousel.
Widget buildFooterInstructions(String text) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: fishBone,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    ),
  );
}
