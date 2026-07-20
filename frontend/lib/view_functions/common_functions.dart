import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/navigation_functions.dart';
import '../theme/theme_controller.dart';
import '../theme/app_colors.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:feedback/feedback.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import 'package:frontend/services/feedback/background_worker.dart';

// Paleta de Cores Compartilhada (Dinâmica por Tema)
bool get _isLight {
  final mode = ThemeController().themeMode.value;
  if (mode == ThemeMode.light) return true;
  if (mode == ThemeMode.dark) return false;
  // Fallback to system brightness
  return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
}

AppColors get _currentColors => _isLight ? AppColors.light : AppColors.dark;


Color get beastHide => _currentColors.beastHide;
Color get fishBone => _currentColors.fishBone;
Color get leatherWork => _currentColors.leatherWork;
Color get obsidianBrown => _currentColors.obsidianBrown;
Color get slateStone => _currentColors.slateStone;
Color get mossRock => _currentColors.mossRock;
Color get clayEarth => _currentColors.clayEarth;
Color get weatheredIron => _currentColors.weatheredIron;

Widget buildFeedbackButton(BuildContext context, {Color? color}) {
  return IconButton(
    icon: Icon(Icons.bug_report, color: color ?? Colors.black),
    tooltip: 'Enviar Feedback/Bug',
    onPressed: () {
      if (!BackgroundWorker.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Envio de feedback indisponível neste ambiente de desenvolvimento.'),
            backgroundColor: Colors.red.shade800,
          ),
        );
        return;
      }

      TelemetryService.instance.logAcaoFeedback('abrir_feedback');

      BetterFeedback.of(context).show((UserFeedback feedback) async {
        TelemetryService.instance.logAcaoFeedback('enviar_feedback');
        final metadata = await FeedbackMetadataCollector().collect(context: context);
        await FeedbackQueueService().enqueueFeedback(
          description: feedback.text,
          screenshot: feedback.screenshot,
          metadata: metadata,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Feedback recebido! Muito obrigado por ajudar a melhorar o app.'),
              backgroundColor: beastHide,
            ),
          );
        }
      });
    },
  );
}

Widget buildOutlineStatCard(BuildContext context, String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.colors.ashGrey.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.brandColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(color: context.colors.slateStone, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(color: fishBone, fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget buildInfoCard(BuildContext context, String title, String description, IconData icon) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.brandColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.brandColor.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.brandColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(color: AppColors.brandColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(color: fishBone, fontSize: 14, height: 1.4),
        ),
      ],
    ),
  );
}

PreferredSizeWidget buildCommonAppBar(BuildContext context, String title, {List<Widget>? actions, String? subtitle}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? context.colors.deepBasalt : beastHide;
  final fgColor = isDark ? Colors.white : Colors.black;

  final feedbackButton = buildFeedbackButton(context, color: fgColor);

  final updatedActions = actions != null ? [...actions, feedbackButton] : [feedbackButton];

  Widget titleWidget = Text(
    title,
    style: TextStyle(
      color: fgColor,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );

  if (subtitle != null) {
    titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: fgColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: context.colors.dryMoss, // A nice subtle color for the subtitle
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  return AppBar(
    leading: AppNav.canGoBack(context)
        ? IconButton(
            icon: Icon(Icons.arrow_back, color: fgColor),
            onPressed: () => AppNav.back(context),
          )
        : null,
    title: titleWidget,
    backgroundColor: bgColor,
    centerTitle: true,
    elevation: isDark ? 0 : 4,
    shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.5),
    actions: updatedActions,
  );
}

/// Um widget de barra de pesquisa que lida com filtragem em tempo real
Widget buildSearchBar({
  required ValueChanged<String> onChanged,
  String hintText = 'Buscar picos para escalar...',
  VoidCallback? onFilterPressed,
  bool showFeedback = false,
}) {
  return Builder(
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: onChanged,
                  style: TextStyle(color: context.colors.slateBlue),
                  cursorColor: context.colors.slateBlue,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: context.colors.ashGrey,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune_rounded, // Filter icon similar to mockup
                  color: const Color(0xFFC05244), // Red matching mock
                ),
                onPressed: onFilterPressed ?? () {},
              ),
            ),
            if (showFeedback) ...[
              const SizedBox(width: 4),
              buildFeedbackButton(context, color: context.colors.ashGrey),
            ],
          ],
        ),
      );
    }
  );
}



/// Normaliza uma string de pesquisa convertendo para minúsculas e removendo acentos/diacríticos.
String normalizeSearchString(String value) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÑñ';
  const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuNn'; 

  String str = value;
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str.toLowerCase();
}

/// Converte dados dinâmicos em uma string com segurança
/// Se o valor for nulo, ele retorna a string de fallback fornecida (o padrão é uma string vazia).
String safeString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

/// Formata uma string de data/timestamp (ISO 8601 ou YYYY-MM-DD) para
/// exibição como "DD/MM/YYYY HH:mm". Retorna string vazia se inválido.
String formatDataUpdate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '';
  final DateTime? date = DateTime.tryParse(rawDate);
  if (date == null) return '';
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString();
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}

/// Converte uma data (ISO 8601) em uma string de tempo relativo (ex: "há 2 dias").
String formatTimeAgo(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '';
  final DateTime? date = DateTime.tryParse(rawDate);
  if (date == null) return '';

  final now = DateTime.now();
  final difference = now.difference(date.toLocal());

  if (difference.inDays >= 365) {
    final years = (difference.inDays / 365).floor();
    return 'atualizado há $years ${years == 1 ? 'ano' : 'anos'}';
  } else if (difference.inDays >= 30) {
    final months = (difference.inDays / 30).floor();
    return 'atualizado há $months ${months == 1 ? 'mês' : 'meses'}';
  } else if (difference.inDays >= 1) {
    return 'atualizado há ${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
  } else if (difference.inHours >= 1) {
    return 'atualizado há ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
  } else if (difference.inMinutes >= 1) {
    return 'atualizado há ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
  } else {
    return 'atualizado agora';
  }
}

/// Determina se uma lista de escaladas é predominantemente de boulders.
/// Se metade ou mais das escaladas forem boulders, retorna verdadeiro.
bool isBoulderArea(List<Escalada> escaladas) {
  if (escaladas.isEmpty) return false;
  
  int boulderCount = 0;
  for (var escalada in escaladas) {
    if (escalada.whichTipo() == Escalada_Tipo.boulder) {
      boulderCount++;
    }
  }
  return boulderCount >= (escaladas.length / 2);
}

/// A barra de navegação inferior principal usada no MainNavigationWrapper raiz.
Widget buildPrimaryBottomNav(BuildContext context, int selectedIndex, Function(int) onItemTapped) {
  return Theme(
    data: Theme.of(context).copyWith(
      canvasColor: context.colors.deepBasalt,
    ),
    child: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'INÍCIO',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore_rounded),
          label: 'EXPLORAR',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_outline),
          activeIcon: Icon(Icons.bookmark_rounded),
          label: 'MEUS CROQUIS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people_alt_rounded),
          label: 'COMUNIDADE',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: AppColors.brandColor,
      unselectedItemColor: context.colors.ashGrey,
      backgroundColor: context.colors.deepBasalt,
      onTap: (index) {
        final abas = ['home', 'explorar', 'meus_croquis', 'comunidade'];
        final aba = index < abas.length ? abas[index] : 'desconhecida';
        TelemetryService.instance.logNavegarAba(aba);
        onItemTapped(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
    ),
  );
}

/// Uma barra de navegação inferior secundária usada em páginas mais profundas (Pico, Setor, Via).
/// Ela imita o design da MainNavBar, mas fornece especificamente atalhos para voltar apenas para as abas Home ou GPS.
Widget buildSecondaryBottomNav(BuildContext context) {
  return Container(
    color: Colors.black,
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
                    TelemetryService.instance.logNavegarAba('home_secondary');
                    AppNav.home(context);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: beastHide),
                      const SizedBox(height: 2),
                      Text(
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
                    TelemetryService.instance.logNavegarAba('gps_secondary');
                    AppNav.toGPS(context);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: beastHide),
                      const SizedBox(height: 2),
                      Text(
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

/// Um componente genérico para construir menus de ordenação.
/// 
/// Aceita qualquer tipo enum [T] e um mapa de [options] ligando os valores do enum
/// aos textos de exibição.
Widget buildSortMenu<T>({
  required T currentMode,
  required ValueChanged<T> onSelected,
  required Map<T, String> options,
}) {
  PopupMenuItem<T> buildSortItem(T mode, String text) {
    final isSelected = currentMode == mode;
    return PopupMenuItem<T>(
      value: mode,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? beastHide : fishBone,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  return PopupMenuButton<T>(
    icon: Icon(Icons.sort, color: fishBone),
    color: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: onSelected,
    itemBuilder: (BuildContext context) => options.entries
        .map((entry) => buildSortItem(entry.key, entry.value))
        .toList(),
  );
}
void showDeprecatedAppVersionSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 4),
    ),
  );
}
