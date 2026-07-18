import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../pages/terms_of_use.dart';

Widget buildActionCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData iconData,
  required Color iconBgColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: Colors.white, size: 24),
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
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.colors.textGrey,
                    fontSize: 12,
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

Widget buildTermsCard(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TermsOfUsePage(
            onAccepted: () {},
            showAcceptButton: false,
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFC05244), // Red outline matching mockup
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Termos de Uso e Privacidade',
                  style: TextStyle(
                    color: context.colors.textDarkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controle voluntário de riscos e diretrizes de privacidade offline.',
                  style: TextStyle(
                    color: context.colors.textDarkBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textDarkBlue.withValues(alpha: 0.5)),
        ],
      ),
    ),
  );
}

Widget buildAvisosCard(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVISOS',
          style: TextStyle(
            color: context.colors.textDarkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 16),
        Text(
          'Mutirão de Limpeza no Cume da Pedra Grande',
          style: TextStyle(
            color: context.colors.textDarkBlue,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Traga sacos de lixo de alta resistência e luvas de proteção. Encontro marcado para as 7h30 no estacionamento principal das falésias de Igarapé para fazermos a limpeza coletiva.',
          style: TextStyle(
            color: context.colors.textDarkBlue.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 16),
        Text(
          'Re-chapeamento do setor G3 concluído',
          style: TextStyle(
            color: context.colors.textDarkBlue,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A associação local substituiu todas as paradas antigas por argolas de inox duplicadas novíssimas. Setor totalmente liberado e seguro para as cadenas.',
          style: TextStyle(
            color: context.colors.textDarkBlue.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget buildFooter(BuildContext context) {
  return FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      String version = '1.0.0'; // Fallback
      if (snapshot.hasData) {
        version = snapshot.data!.version;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.cardOlive,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.borderGrey),
        ),
        child: Column(
          children: [
            Text(
              'Aresta Climb v$version',
              style: TextStyle(
                color: context.colors.textOlive,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uma iniciativa independente pelo montanhismo conservador e livre de Minas Gerais.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> launchURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao abrir o link.')),
      );
    }
  }
}
