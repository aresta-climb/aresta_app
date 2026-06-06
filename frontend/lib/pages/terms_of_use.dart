import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:frontend/constants/legal_version.g.dart';


/// Formata a data ISO (YYYY-MM-DD) para "DIA de MÊS de ANO"
String formatLegalDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  
  final day = parts[2];
  final year = parts[0];
  final monthInt = int.tryParse(parts[1]) ?? 1;
  
  const months = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  
  final monthName = (monthInt >= 1 && monthInt <= 12) ? months[monthInt] : parts[1];
  
  return '$day de $monthName de $year';
}

class TermsOfUsePage extends StatefulWidget {
  final VoidCallback onAccepted;
  final bool isUpdatingTerms;
  final AssetBundle? assetBundle;
  final bool showAcceptButton;

  const TermsOfUsePage({
    super.key,
    required this.onAccepted,
    this.isUpdatingTerms = false,
    this.assetBundle,
    this.showAcceptButton = true,
  });

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  bool _isChecked = false;
  String? _termsMarkdown;
  String? _privacyMarkdown;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final bundle = widget.assetBundle ?? rootBundle;

      final terms = await bundle.loadString(
        'legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md',
      );
      
      final privacy = await bundle.loadString(
        'legal/repo/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md',
      );
      setState(() {
        _termsMarkdown = terms;
        _privacyMarkdown = privacy;
      });
    } catch (e) {
      AppLogger.instance.logError(
        'carregar_documentos_legais',
        error: e.toString(),
      );
      setState(() {
        _termsMarkdown =
            'Erro ao carregar os termos. Por favor, tente novamente mais tarde.';
        _privacyMarkdown = 'Erro ao carregar a política.';
      });
    }
  }

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href != null) {
      if (href == 'https://aresta-climb.github.io/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.html' || 
          href.endsWith('POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md')) {
        _showPrivacyPolicy();
        return;
      }

      TelemetryService.instance.logLinkExterno(href, 'termos_uso');
      final url = Uri.parse(href);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        AppLogger.instance.logError('abrir_link_termos', error: e.toString());
        debugPrint('Erro ao abrir link: $e');
      }
    }
  }

  void _showPrivacyPolicy() {
    TelemetryService.instance.logAcaoConfiguracoes('abrir_politica_privacidade');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Política de Privacidade',
              style: TextStyle(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _privacyMarkdown != null
                ? MarkdownBody(
                    data: _privacyMarkdown!,
                    onTapLink: _onTapLink,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 16, 
                        height: 1.6, 
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      h3: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      h3Align: WrapAlignment.center,
                      strong: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      blockSpacing: 16.0,
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildUpdateBanner() {
    if (!widget.isUpdatingTerms) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🌟 Atualizamos nossos documentos legais. Por favor, revise-os e confirme seu aceite.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data da atualização: ${formatLegalDate(kLegalLastUpdatedDate)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAcceptButton 
        ? null 
        : AppBar(
            title: const Text('Termos de Uso', style: TextStyle(fontSize: 16)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      body: SafeArea(
        child: _termsMarkdown == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpdateBanner(),
                    MarkdownBody(
                      data: _termsMarkdown!,
                      onTapLink: _onTapLink,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16, 
                          height: 1.6, 
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        h3: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        h3Align: WrapAlignment.center,
                        strong: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        blockSpacing: 16.0,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (widget.showAcceptButton)
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          CheckboxListTile(
                              title: const Text(
                                'Li e concordo com os Termos de Uso e a Política de Privacidade.',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              value: _isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isChecked = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _isChecked
                                    ? () {
                                        TelemetryService.instance.logAcaoConfiguracoes(
                                          'aceitar_termos_uso',
                                        );
                                        widget.onAccepted();
                                      }
                                    : null,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Aceitar Termos e Continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }
}
