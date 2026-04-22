import 'package:flutter/material.dart';
import '../main.dart';

// Paleta de Cores Compartilhada
const Color nobleBlack = Color(0xFF1F2128);
const Color beastHide = Color(0xFFAE8F68);
const Color fishBone = Color(0xFFE4DAC5);
const Color leatherWork = Color(0xFF896449);
const Color obsidianBrown = Color(0xFF543E35);
const Color slateStone = Color(0xFF4A4E5A);
const Color mossRock = Color(0xFF5B614D);
const Color clayEarth = Color(0xFF7D4F43);
const Color weatheredIron = Color(0xFF3E4247);

PreferredSizeWidget buildCommonAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        color: nobleBlack,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    backgroundColor: beastHide,
    centerTitle: true,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.5),
    actions: actions,
  );
}

/// Um widget de barra de pesquisa que lida com filtragem em tempo real
Widget buildSearchBar({
  required ValueChanged<String> onChanged,
  String hintText = 'Pesquisar...',
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(color: nobleBlack),
      cursorColor: nobleBlack,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: nobleBlack.withValues(alpha: 0.6)),
        prefixIcon: const Icon(Icons.search, color: nobleBlack),
        filled: true,
        fillColor: fishBone,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

/// Converte dados dinâmicos em uma string com segurança
/// Se o valor for nulo, ele retorna a string de fallback fornecida (o padrão é uma string vazia).
String safeString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

/// A barra de navegação inferior principal usada no MainNavigationWrapper raiz.
/// Ela renderiza as abas para alternar entre Início (Home), GPS e Explorar.
Widget buildPrimaryBottomNav(BuildContext context, int selectedIndex, Function(int) onItemTapped) {
  return Theme(
    data: Theme.of(context).copyWith(
      canvasColor: nobleBlack,
    ),
    child: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_rounded),
          label: 'GPS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_rounded),
          label: 'Explorar',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: beastHide,
      unselectedItemColor: fishBone.withValues(alpha: 0.5),
      backgroundColor: nobleBlack,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

/// Uma barra de navegação inferior secundária usada em páginas mais profundas (Pico, Setor, Via).
/// Ela imita o design da MainNavBar, mas fornece especificamente atalhos para voltar apenas para as abas Home ou GPS.
Widget buildSecondaryBottomNav(BuildContext context) {
  return Container(
    color: nobleBlack,
    child: SafeArea(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Atalho para Início
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    MainNavigationWrapper.switchTab(0);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_rounded, color: beastHide),
                      const SizedBox(height: 2),
                      const Text(
                        'Início',
                        style: TextStyle(
                          color: fishBone,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Atalho para GPS
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    MainNavigationWrapper.switchTab(1);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded, color: beastHide),
                      const SizedBox(height: 2),
                      const Text(
                        'GPS',
                        style: TextStyle(
                          color: fishBone,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}