import 'package:flutter/material.dart';
import 'common_functions.dart';

List<Map<String, String>> getAvailableCrags() {
  // A little map with data from the crag options
  return [
    {'name': 'Gruta do Baú', 'location': 'Pedro Leopoldo, MG'},
    {'name': 'Santuário', 'location': 'Santa Luzia, MG'},
    {'name': 'Pedra Grande', 'location': 'Igarapé, MG'},
    {'name': 'Lapinha', 'location': 'Lagoa Santa, MG'},
    {'name': 'Serra do Cipó', 'location': 'Santana do Riacho, MG'},
    {'name': 'Ouro Preto', 'location': 'Ouro Preto, MG'},
  ];
}

Widget buildBrowseBody(List<Map<String, String>> availableCrags) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBrowseSectionTitle('Picos Disponíveis'),
        
        // Makes boxes until all available crags are displayed
        const SizedBox(height: 20),
        ...availableCrags.map((crag) => buildCragListItem(crag)),
      ],
    ),
  );
}

Widget buildBrowseSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: fishBone,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget buildCragListItem(Map<String, String> crag) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fishBone.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildCragIcon(),
          const SizedBox(width: 16),
          _buildCragDetails(crag),
          _buildDownloadButton(),
        ],
      ),
    ),
  );
}

Widget _buildCragIcon() {
  // Montain icon
  // TODO: Implement cover image instead of mountain icon
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: beastHide.withValues(alpha: 0.2),
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.terrain,
      color: beastHide,
      size: 24,
    ),
  );
}

Widget _buildCragDetails(Map<String, String> crag) {
  // Crag name and details
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          crag['name']!,
          style: const TextStyle(
            color: fishBone,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          crag['location']!,
          style: TextStyle(
            color: fishBone.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDownloadButton() {
  // Download icon button
  return IconButton(
    onPressed: () {
      // TODO: Implement download functionality
    },
    icon: const Icon(
      Icons.download_rounded,
      color: beastHide,
    ),
  );
}
