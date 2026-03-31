import 'package:flutter/material.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Color palette
    const Color beastHide = Color(0xFFAE8F68);
    const Color nobleBlack = Color(0xFF1F2128);
    const Color fishBone = Color(0xFFE4DAC5);

    // A little map with data from the crag options
    final List<Map<String, String>> availableCrags = [
      {'name': 'Gruta do Baú', 'location': 'Pedro Leopoldo, MG'},
      {'name': 'Santuário', 'location': 'Santa Luzia, MG'},
      {'name': 'Pedra Grande', 'location': 'Igarapé, MG'},
      {'name': 'Lapinha', 'location': 'Lagoa Santa, MG'},
      {'name': 'Serra do Cipó', 'location': 'Santana do Riacho, MG'},
      {'name': 'Ouro Preto', 'location': 'Ouro Preto, MG'},
    ];

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: AppBar(
        title: const Text(
          'Explorar Locais',
          style: TextStyle(
            color: nobleBlack,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: beastHide,
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Picos Disponíveis',
              style: TextStyle(
                color: fishBone,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),


            // Makes boxes until all available crags are displayed
            const SizedBox(height: 20),
            ...availableCrags.map((crag) {
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

                  // Montain icon
                  // TODO: Implement cover image instead of mountain icon
                  child: Row(
                    children: [
                      Container(
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
                      ),
                      const SizedBox(width: 16),

                      // Crag name and details
                      Expanded(
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
                      ),

                      // Download icon button
                      IconButton(
                        onPressed: () {
                          // TODO: Implement sqflite download functionality
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          color: beastHide,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
