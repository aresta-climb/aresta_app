// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../services/editor_croqui.dart';
import '../widgets/provedor_imagem_aresta.dart';
import 'common_functions.dart';

/// Um widget que renderiza conteúdo Markdown com suporte a imagens offline locais.
///
/// Ele resolve automaticamente caminhos de imagem relativos com o diretório
/// 'downloads' local do aplicativo.
class OfflineMarkdown extends StatefulWidget {
  /// A string markdown original a ser renderizada.
  final String data;
  final String cragId;

  const OfflineMarkdown({super.key, required this.data, required this.cragId});

  @override
  State<OfflineMarkdown> createState() => _OfflineMarkdownState();
}

class _OfflineMarkdownState extends State<OfflineMarkdown> {
  // Guarda os image providers criados para limpar da memória depois
  final List<ImageProvider> _imageProviders = [];

  @override
  void didUpdateWidget(OfflineMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var provider in _imageProviders) {
      provider.evict();
    }
    _imageProviders.clear();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final editor = EditorDeCroqui.instance;
        final downloadsPath =
            '${editor.downloadsPath(snapshot.data!.path)}/${widget.cragId}';

        String markdownData = widget.data;

        return MarkdownBody(
          data: markdownData,
          extensionSet: md.ExtensionSet.gitHubFlavored,
          onTapLink: (text, href, title) async {
            if (href != null) {
              TelemetryService.instance.logLinkExterno(
                href,
                'markdown_offline',
              );
              try {
                await launchUrl(
                  Uri.parse(href),
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                AppLogger.instance.logError(
                  'abrir_link_markdown',
                  error: e.toString(),
                );
              }
            }
          },
          imageBuilder: (Uri uri, String? title, String? alt) {
            final String path = Uri.decodeFull(uri.toString());

            Widget buildZoomableImage(ImageProvider provider) {
              _imageProviders.add(provider);
              final imageWidget = Image(
                image: provider,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              );

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (context) => Scaffold(
                      backgroundColor: Colors.black,
                      body: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              maxScale: 5.0,
                              child: Image(
                                image: imageWidget.image,
                                fit: BoxFit.contain,
                                errorBuilder: imageWidget.errorBuilder,
                              ),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            right: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildFeedbackButton(
                                  context,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: imageWidget,
              );
            }

            return FutureBuilder<ImageProvider?>(
              future: ProvedorImagemAresta.resolver(
                picoId: widget.cragId,
                caminho: path,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return buildZoomableImage(snapshot.data!);
                }
                return const Icon(Icons.broken_image, color: Colors.grey);
              },
            );
          },
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: fishBone.withValues(alpha: 0.8), fontSize: 16),
            h1: TextStyle(
              color: fishBone,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            h2: TextStyle(
              color: fishBone,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            h3: TextStyle(
              color: fishBone,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            blockquoteDecoration: const BoxDecoration(),
            codeblockDecoration: const BoxDecoration(),
            horizontalRuleDecoration: const BoxDecoration(),
            tableBorder: TableBorder.all(color: Colors.transparent, width: 0),
          ),
        );
      },
    );
  }
}
