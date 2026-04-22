import 'package:flutter/material.dart';
import '../services/dataset_repository.dart';
import '../pages/pico.dart';
import 'common_functions.dart';

/// A palette of colors used to background the crag cards.
final List<Color> cardPalette = [
  leatherWork,
  slateStone,
  mossRock,
  clayEarth,
  weatheredIron,
];

/// Navigates to the details page of a selected pico.
/// 
/// It first shows a loading indicator while fetching the full Croqui data.
void handlePicoSelection(BuildContext context, DatasetRepository datasetRepo, Map<String, dynamic> pico) async {
  final id = pico['id'];
  if (id == null) return;

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator(color: beastHide)),
  );

  final croqui = await datasetRepo.getCroqui(id);

  if (context.mounted) {
    Navigator.pop(context); // Remove loading indicator

    if (croqui != null && croqui.picos.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PicoDetailsPage(
            pico: croqui.picos.first,
            croqui: croqui,
            cragId: id,
            datasetRepo: datasetRepo,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir o guia.')),
      );
    }
  }
}

/// Builds the main scrollable body of the Home page.
/// 
/// Displays a carousel of recently downloaded crags and a dropdown list 
/// of all available guides.
Widget buildHomeBody(
  BuildContext context,
  DatasetRepository datasetRepo,
  List<Map<String, dynamic>> downloadedPicos, {
  required VoidCallback onAddCrag,
}) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Guias Recentes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fishBone,
                  ),
                ),
                ValueListenableBuilder<SyncStatus>(
                  valueListenable: datasetRepo.syncStatus,
                  builder: (context, status, _) {
                    return buildSyncBadge(status);
                  },
                ),
              ],
            ),
          ),
          // The carousel handles the 4-card limit internally now
          buildPicosCarousel(
            downloadedPicos, 
            onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
          ),
          const SizedBox(height: 10),
          _buildAllGuidesDropdown(
            downloadedPicos, 
            onAddCrag: onAddCrag, 
            onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
          ),
          const SizedBox(height: 100), // Extra space at bottom to ensure everything is scrollable
        ],
      ),
    ),
  );
}

/// Builds a synchronization status badge.
Widget buildSyncBadge(SyncStatus status) {
  String text;
  Color color;
  IconData icon;

  switch (status) {
    case SyncStatus.updated:
      text = 'Atualizados';
      color = Colors.green.shade800;
      icon = Icons.check_circle;
      break;
    case SyncStatus.updating:
      text = 'Atualizando...';
      color = Colors.blue.shade800;
      icon = Icons.sync;
      break;
    case SyncStatus.outdated:
      text = 'Desatualizado';
      color = Colors.orange.shade800;
      icon = Icons.warning;
      break;
    case SyncStatus.error:
      text = 'Sem conexão';
      color = Colors.brown.shade800;
      icon = Icons.error;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Builds an expandable list showing all downloaded guides.
Widget _buildAllGuidesDropdown(
  List<Map<String, dynamic>> picos, {
  required VoidCallback onAddCrag,
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
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
          onTap: () => onPicoSelect(pico),
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

/// Builds a horizontal carousel of crag cards.
/// Limited to the 4 most recent crags.
/// Allows infinite looping if there are exactly 4 items.
Widget buildPicosCarousel(
  List<Map<String, dynamic>> allPicos, {
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
  if (allPicos.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Nenhum guia baixado ainda.',
          style: TextStyle(color: fishBone, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  // LIMITER: Take at most 4 cards for the carousel to avoid info clustering
  final List<Map<String, dynamic>> picosToShow = allPicos.take(4).toList();
  final int count = picosToShow.length;
  final bool shouldLoop = count >= 4;

  return Column(
    children: [
      SizedBox(
        height: 350,
        child: PageView.builder(
          itemCount: shouldLoop ? null : count,
          controller: PageController(
            viewportFraction: shouldLoop ? 0.85 : 0.9,
            initialPage: shouldLoop ? count * 100 : 0,
          ),
          physics: count > 1
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final int actualIndex = shouldLoop ? (index % count) : index;
            final Color cardColor = cardPalette[actualIndex % cardPalette.length];
            final double rightPadding = (!shouldLoop && actualIndex == count - 1) ? 0.0 : 10.0;

            return GestureDetector(
              onTap: () => onPicoSelect(picosToShow[actualIndex]),
              child: buildPicoCard(picosToShow[actualIndex], rightPadding, cardColor),
            );
          },
        ),
      ),
      if (count > 1)
        buildFooterInstructions('Deslize para ver seus downloads'),
    ],
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                Expanded(
                  child: Text(
                    safeString(pico['local'], fallback: 'Local Desconhecido'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nobleBlack.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
