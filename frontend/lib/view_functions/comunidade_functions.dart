import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'common_functions.dart';

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
                    color: context.colors.slateBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.colors.ashGrey,
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
    onTap: () => showTermsBottomSheet(context),
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
                    color: context.colors.slateBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controle voluntário de riscos e diretrizes de privacidade offline.',
                  style: TextStyle(
                    color: context.colors.slateBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.slateBlue.withValues(alpha: 0.5)),
        ],
      ),
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
          color: context.colors.darkPine,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.graniteEdge),
        ),
        child: Column(
          children: [
            Text(
              'Aresta Climb v$version',
              style: TextStyle(
                color: context.colors.dryMoss,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uma iniciativa independente pelo montanhismo conservador e livre de Minas Gerais.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.ashGrey,
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

/// Exibe os Termos de Uso e Privacidade em um bottom sheet customizado
void showTermsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return const _TermsBottomSheetContent();
    },
  );
}

class _TermsBottomSheetContent extends StatefulWidget {
  const _TermsBottomSheetContent();

  @override
  State<_TermsBottomSheetContent> createState() => _TermsBottomSheetContentState();
}

class _TermsBottomSheetContentState extends State<_TermsBottomSheetContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Verifica se já está no final caso o texto caiba na tela sem scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAtBottom();
    });
  }

  void _checkIfAtBottom() {
    if (!_scrollController.hasClients) return;
    
    // Se o maxScrollExtent for pequeno ou 0, significa que não precisa de scroll
    // ou se já rolou até o fim
    if (_scrollController.position.maxScrollExtent <= 0 ||
        _scrollController.offset >= _scrollController.position.maxScrollExtent - 10) {
      if (!_isAtBottom) {
        setState(() {
          _isAtBottom = true;
        });
      }
    }
  }

  void _scrollListener() {
    _checkIfAtBottom();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.graniteEdge,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Header
          Row(
            children: [
              Icon(
                Icons.gpp_maybe_outlined,
                color: context.colors.rustIron,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TERMOS E PRIVACIDADE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              buildFeedbackButton(context, color: context.colors.ashGrey),
            ],
          ),
          const SizedBox(height: 24),
          // Scrollable Content
          Flexible(
            child: FutureBuilder<String>(
              future: DefaultAssetBundle.of(context).loadString('legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Dispara a verificação após o conteúdo ser carregado
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkIfAtBottom();
                });

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: MarkdownBody(
                    data: snapshot.data!,
                    onTapLink: (text, href, title) {
                      if (href != null) launchURL(context, href);
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        color: context.colors.rustIron,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      h2: TextStyle(
                        color: context.colors.rustIron,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      h3: TextStyle(
                        color: context.colors.rustIron,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      blockSpacing: 16.0,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Footer
          if (_isAtBottom) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: context.colors.graniteEdge,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'FECHAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ] else ...[
             Center(
               child: GestureDetector(
                 onTap: () {
                   if (_scrollController.hasClients) {
                     _scrollController.animateTo(
                       _scrollController.position.maxScrollExtent,
                       duration: const Duration(milliseconds: 300),
                       curve: Curves.easeOut,
                     );
                   }
                 },
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   child: Icon(
                     Icons.keyboard_arrow_down,
                     color: context.colors.rustIron.withValues(alpha: 0.5),
                     size: 32,
                   ),
                 ),
               ),
             ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

void showLinkOverlay(
  BuildContext context, {
  required String title,
  required String link,
  required IconData iconData,
  required Color iconColor,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.graniteEdge,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Header
            Row(
              children: [
                Icon(iconData, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Link container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.darkPine,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.graniteEdge),
              ),
              child: Text(
                link.isNotEmpty ? link : 'link faltando',
                style: TextStyle(
                  color: link.isNotEmpty ? context.colors.dryMoss : context.colors.rustIron,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232323),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'FECHAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (link.isNotEmpty) {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copiado!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: link.isNotEmpty ? context.colors.slateBlue : Colors.grey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'COPIAR LINK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      );
    },
  );
}
