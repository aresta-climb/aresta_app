import 'package:flutter/material.dart';
import '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Color palette
    const Color fishBone = Color(0xFFE4DAC5);
    const Color sycoraxBronze = Color(0xFFC9B595);
    const Color beastHide = Color(0xFFAE8F68);
    const Color leatherWork = Color(0xFF896449);
    const Color obsidianBrown = Color(0xFF543E35);
    const Color nobleBlack = Color(0xFF1F2128);

    // A little map with data from the crag options
    final List<Map<String, dynamic>> downloadedPicos = [
      {
        'nome': 'Gruta do Baú',
        'local': 'Pedro Leopoldo, MG',
        'vias': '100+',
        'color': leatherWork,
      },
      {
        'nome': 'Pedra Grande',
        'local': 'Igarapé, MG',
        'vias': '150+',
        'color': beastHide,
      },
      {
        'nome': 'Santuário',
        'local': 'Santa Luzia, MG',
        'vias': '40+',
        'color': sycoraxBronze,
      },
    ];

    // Total number of items including the "Add New Crag" card
    final int actualCount = downloadedPicos.length + 1;
    // Starting in the middle of a very large number of items to allow infinite looping in both directions
    final int initialPage = actualCount * 100;

    return Scaffold(
      // First things first, we want to set up the background and appBar
      backgroundColor: nobleBlack, // Main background color
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: nobleBlack, // Text contrast on the brown AppBar
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: beastHide, // Using a "Leather/Hide" color for the AppBar
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),

      // Big main page container
      // Making the background color a gradient
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              nobleBlack,
              obsidianBrown, // Transitions from dark to a earthy brown
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding on the text to give it some space
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Text(
                  'Guias Baixados',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fishBone, // Light text for visibility
                  ),
                ),
              ),


              // Carousel with offline crag data
              SizedBox(
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

                    /* Adding extra right padding only to the last element (Adicionar novo local)
                      to create space before the first element loops back around.*/
                    final double rightPadding = (actualIndex == downloadedPicos.length) ? 40.0 : 10.0;

                    /*----------------------------------------------------------
                      Check if it's the last item in our sequence,
                      if it is, we'll use this format.*/
                    if (actualIndex == downloadedPicos.length) {
                      return Padding(
                        padding: EdgeInsets.only(left: 10, right: rightPadding, top: 20, bottom: 20),
                        child: InkWell(
                          onTap: () {
                            // Call helper to switch to the "Explorar" tab when clicked (index 2)
                            MainNavigationWrapper.switchTab(2);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2), // (Adicionar novo local) color
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: fishBone.withValues(alpha: 0.3),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline, // Big plus sign
                                  color: fishBone.withValues(alpha: 0.6),
                                  size: 80,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Adicionar novo local',
                                  style: TextStyle(
                                    color: fishBone.withValues(alpha: 0.6),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    /*----------------------------------------------------------
                      If it isn't, we'll use this other format*/
                    final pico = downloadedPicos[actualIndex];
                    return Padding(
                      padding: EdgeInsets.only(left: 10, right: rightPadding, top: 20, bottom: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: pico['color'] as Color,
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
                                pico['nome'] as String,
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
                                    pico['local'] as String,
                                    style: TextStyle(
                                      color: nobleBlack.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),


              // Instructions on how to use the carousel
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Deslize para ver seus downloads',
                    style: TextStyle(
                      color: fishBone,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
