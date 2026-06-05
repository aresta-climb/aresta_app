import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:frontend/constants/legal_version.g.dart';

import 'dart:convert';

class TermsOfUsePage extends StatefulWidget {
  final VoidCallback onAccepted;
  final bool isUpdatingTerms;
  final AssetBundle? assetBundle;

  const TermsOfUsePage({
    super.key,
    required this.onAccepted,
    this.isUpdatingTerms = false,
    this.assetBundle,
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
                      p: const TextStyle(fontSize: 16),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
      child: Text(
        '🌟 Atualizamos nossos documentos legais. Por favor, revise-os e confirme seu aceite.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Privacidade'),
        centerTitle: true,
      ),
      body: _termsMarkdown == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUpdateBanner(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Última atualização: $kLegalLastUpdatedDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  MarkdownBody(
                    data: _termsMarkdown!,
                    onTapLink: _onTapLink,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Botão para Política de Privacidade
                  Center(
                    child: TextButton.icon(
                      onPressed: _showPrivacyPolicy,
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text(
                        'Ler Política de Privacidade',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0.0,
                      vertical: 8.0,
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Li e concordo com os Termos de Uso e a Política de Privacidade.',
                        style: TextStyle(fontSize: 14),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChecked
                            ? () {
                                TelemetryService.instance.logAcaoConfiguracoes(
                                  'aceitar_termos_uso',
                                );
                                widget.onAccepted();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Aceitar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
