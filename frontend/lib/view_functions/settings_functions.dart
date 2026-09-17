// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../view_functions/common_functions.dart';
import '../pages/qr_scanner.dart';
import '../services/http/sync_service.dart';
import '../services/http/servico_download_segundo_plano.dart';
import '../main.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../theme/theme_controller.dart';
import '../theme/app_colors.dart';
import 'package:frontend/widgets/app_version_checker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../navigation/navigation_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/modal_beta_aberto.dart';

/// Normaliza a URL do editor, garantindo scheme correto e removendo formatações espúrias (ex: de QR Codes).
@visibleForTesting
String normalizeEditorUrl(String rawUrl) {
  String checkUrl = rawUrl.trim();
  if (checkUrl.isEmpty) return checkUrl;

  final lowerUrl = checkUrl.toLowerCase();
  if (!lowerUrl.startsWith('http://') &&
      !lowerUrl.startsWith('https://')) {
    if (lowerUrl.startsWith('192.168.') ||
        lowerUrl.startsWith('10.') ||
        lowerUrl.startsWith('127.') ||
        lowerUrl.startsWith('localhost')) {
      checkUrl = 'http://$checkUrl';
    } else {
      checkUrl = 'https://$checkUrl';
    }
  }

  if (checkUrl.endsWith('/')) {
    checkUrl = checkUrl.substring(0, checkUrl.length - 1);
  }

  return checkUrl;
}

Future<bool> conectarEditor(
  BuildContext context,
  DatasetRepository datasetRepo,
  EditorDeCroqui configService,
  String url, {
  http.Client? client,
  SyncService? syncService,
}) async {
  if (url.isEmpty) return false;

  try {
    // Valida se o índice está acessível na URL fornecida, resolvendo códigos de prévia hibridamente
    final resolvedUrl = await configService.resolverUrlHibrida(
      url,
      client: client,
    );
    String checkUrl = normalizeEditorUrl(resolvedUrl);

    if (checkUrl.toLowerCase().endsWith('.zip') ||
        checkUrl.toLowerCase().endsWith('.croqui')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aviso: Importação de arquivos locais foi descontinuada. Conecte diretamente via Live Reload / URL.',
            ),
          ),
        );
      }
      return false;
    }

    final httpClient = client ?? http.Client();
    final response = await httpClient
        .get(Uri.parse('$checkUrl/indice.binarypb'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      await configService.activateExperimental(
        url: checkUrl,
        forceResetTimer: false,
      );
      final servicoSync = syncService ??
          SyncService(
            datasetRepository: datasetRepo,
            client: httpClient,
          );
      await servicoSync.syncIndex();
      await datasetRepo.init();

      // Auto-download imediato se houver exatamente 1 croqui no índice
      final croquis = datasetRepo.indiceData.value?.croquis ?? [];
      if (croquis.length == 1) {
        final resumo = croquis.first;
        try {
          await ServicoDownloadSegundoPlano(syncService: servicoSync)
              .executarDownload(resumo);
          await datasetRepo.init();
        } catch (e, stackTrace) {
          AppLogger.instance.logError(
            '[conectarEditor] Falha ao auto-baixar croqui único',
            error: e,
            stackTrace: stackTrace,
          );
        }

        // Se o download não completou offline (ex: streaming/remoto), garante disponibilidade na sessão online
        if (!datasetRepo.isPicoDownloaded(resumo.id)) {
          try {
            final baseUrl = datasetRepo.editorDeCroqui.activeBaseUrl;
            final relPath = resumo.caminhoRelativo.isNotEmpty
                ? resumo.caminhoRelativo
                : 'picos/${resumo.id}/compilado.binarypb';
            final checksum = resumo.checksumSha256Croqui;
            final croquiUrl = checksum.isNotEmpty
                ? '$baseUrl/$relPath?v=$checksum'
                : '$baseUrl/$relPath';
            final servicoOnline = ServicoCroquiOnline(
              client: httpClient,
              sessaoOnline: datasetRepo.gerenciadorSessaoOnline,
            );
            await servicoOnline.carregarCroquiRemoto(
              croquiUrl,
              picoId: resumo.id,
              checksumSha256: checksum.isNotEmpty ? checksum : null,
            );
            datasetRepo.notificarAtualizacaoSessaoOnline(resumo.id);
          } catch (e, stackTrace) {
            AppLogger.instance.logError(
              '[conectarEditor] Falha ao carregar na sessão online',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      TelemetryService.instance.logAcaoConfiguracoes('conectar_editor_url');
      return true;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: Não foi possível acessar o índice (Status ${response.statusCode})',
            ),
          ),
        );
      }
      return false;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão: Verifique a URL')),
      );
    }
    return false;
  }
}

/// Navega para a tela adequada após uma conexão com o editor bem-sucedida.
///
/// Se o índice contiver exatamente 1 croqui, abre diretamente na tela do Pico (`PicoNode`).
/// Se contiver múltiplos croquis (ou nenhum), navega para a aba de exploração (`BrowseNode`).
void navegarAposConexaoExperimental(
  BuildContext context,
  DatasetRepository datasetRepo,
) {
  final croquis = datasetRepo.indiceData.value?.croquis ?? [];
  if (croquis.length == 1) {
    AppNav.toPico(context, cragId: croquis.first.id);
  } else {
    AppNav.toBrowse(context);
  }
}

/// Exibe o diálogo para conectar o aplicativo a um servidor do Editor Desktop.
///
/// Permite que o usuário digite manualmente a URL ou código de 8 caracteres gerado
/// no Editor, ou escaneie o QR Code diretamente pela câmera.
///
/// Parâmetros:
/// - [context]: O contexto de build da tela de origem (usado como fallback de navegação).
/// - [datasetRepo]: Repositório de dados que gerencia a sessão e os índices de croquis.
/// - [titulo]: Título opcional do diálogo (padrão: "Conectar Editor").
/// - [client]: Cliente HTTP opcional para injeção de dependência em testes.
/// - [syncService]: Serviço de sincronização opcional para download e atualização de índices.
/// - [construtorScannerQr]: Construtor opcional de widget para a tela de escaneamento de QR Code.
///   Permite injetar telas de simulação em testes automatizados, evitando acionar plugins nativos
///   de câmera em ambientes headless. Por padrão, instancia [QRScannerPage].
///
/// Detalhes Arquiteturais de Navegação:
/// O diálogo é exibido no `Navigator` raiz (`useRootNavigator: true`). Para garantir que a tela da câmera
/// do scanner cubra completamente o diálogo e seu fundo sem sobreposições visuais, a rota do scanner
/// é empilhada a partir do `dialogContext` no `Navigator` raiz. Ao ler um QR Code válido, a conexão
/// é disparada automaticamente via [conectarEditor].
void mostrarDialogConexao(
  BuildContext context,
  DatasetRepository datasetRepo, {
  String? titulo,
  http.Client? client,
  SyncService? syncService,
  WidgetBuilder? construtorScannerQr,
}) {
  final BuildContext parentContext = context;
  final EditorDeCroqui configService = datasetRepo.editorDeCroqui;
  // Inicia vazio, pois a URL atual já é exibida na interface de configurações
  final TextEditingController urlController = TextEditingController();
  bool isLoading = false;
  final brandColor = const Color(0xFFC04F34);

  showDialog(
    context: parentContext,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> executarConexao(String urlAlvo) async {
            final url = urlAlvo.trim();
            if (url.isEmpty) return;

            setDialogState(() => isLoading = true);

            final success = await conectarEditor(
              dialogContext,
              datasetRepo,
              configService,
              url,
              client: client,
              syncService: syncService,
            );
            if (dialogContext.mounted) {
              setDialogState(() => isLoading = false);
              if (success) {
                Navigator.of(dialogContext).pop();
                final navContext =
                    TreeNavigationWrapper.navKey.currentContext ??
                    parentContext;
                navegarAposConexaoExperimental(navContext, datasetRepo);
                if (navContext.mounted) {
                  ScaffoldMessenger.of(navContext).showSnackBar(
                    const SnackBar(
                      content: Text('Conectado ao repositório editor!'),
                    ),
                  );
                }
              }
            }
          }

          return AlertDialog(
            backgroundColor: context.colors.caveShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.graniteEdge),
            ),
            title: Column(
              children: [
                Icon(Icons.link, color: brandColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  titulo ?? 'Conectar Editor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Digite o código de 8 caracteres gerado no Editor ou escaneie o QR Code.',
                    style: TextStyle(
                      color: context.colors.ashGrey,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      hintText: 'ex: k9x2-p83a ou URL completa',
                      hintStyle: TextStyle(
                        color: context.colors.ashGrey.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: context.colors.deepBasalt,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: context.colors.graniteEdge,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: brandColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.qr_code_scanner,
                        color: brandColor,
                        size: 20,
                      ),
                      label: Text(
                        'ESCANEAR QR CODE',
                        style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: brandColor.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        TelemetryService.instance.logAcaoConfiguracoes(
                          'abrir_qr_scanner',
                        );
                        // Abre o scanner no Root Navigator para sobrepor completamente o diálogo
                        final urlEscaneada = await Navigator.of(dialogContext)
                            .push<String>(
                          MaterialPageRoute(
                            builder: construtorScannerQr ??
                                (context) => const QRScannerPage(),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        if (urlEscaneada != null &&
                            urlEscaneada.trim().isNotEmpty) {
                          urlController.text = urlEscaneada;
                          await executarConexao(urlEscaneada);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('https://arestaclimb.com/editor');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 14,
                          color: context.colors.ashGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Como funciona o Editor Desktop? Saiba mais',
                          style: TextStyle(
                            color: context.colors.ashGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: context.colors.ashGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: TextButton(
                  onPressed: () {
                    if (isLoading) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: context.colors.ashGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (buttonContext) {
                  final VoidCallback? onConnect = isLoading
                      ? null
                      : () async {
                          await executarConexao(urlController.text);
                        };

                  Widget buttonChild;
                  if (isLoading) {
                    buttonChild = const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  } else {
                    buttonChild = const Text(
                      'CONECTAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onConnect,
                      child: buttonChild,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget buildEditorCard({
  required BuildContext context,
  required DatasetRepository datasetRepo,
  int clickCount = 0,
  Function(int)? onSetClickCount,
}) {
  final configService = datasetRepo.editorDeCroqui;

  return ValueListenableBuilder<bool>(
    valueListenable: configService.isExperimentalMode,
    builder: (context, isExperimental, _) {
      return ValueListenableBuilder<String?>(
        valueListenable: configService.editorUrl,
        builder: (context, activeUrl, _) {
          final isEditor = isExperimental;

          IconData statusIcon;
          String statusLabel;
          String description;
          String buttonText;

          if (isEditor) {
            statusIcon = Icons.science;
            statusLabel = 'MODO EXPERIMENTAL / PRÉVIA';
            description =
                'Visualizando croquis transmitidos em tempo real pelo Editor Desktop ou arquivo importado.';
            buttonText = 'VOLTAR PARA MODO OFICIAL';
          } else {
            statusIcon = Icons.verified;
            statusLabel = 'MODO OFICIAL';
            description =
                'Conectado à base oficial do Aresta Climb. Você pode conectar ao Editor Desktop para testar novos croquis em tempo real.';
            buttonText = 'CONECTAR AO EDITOR / PRÉVIA';
          }

          return Card(
            elevation: 0,
            color: context.colors.caveShadow,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isEditor
                              ? const Color(0xFFC04F34).withValues(alpha: 0.15)
                              : context.colors.graniteEdge,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: isEditor
                              ? const Color(0xFFC04F34)
                              : context.colors.ashGrey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: context.colors.ashGrey,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            if (!isEditor) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse(
                                    'https://arestaclimb.com/editor',
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.help_outline_rounded,
                                      size: 14,
                                      color: Color(0xFFC04F34),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Como fazer? Saiba mais',
                                      style: TextStyle(
                                        color: Color(0xFFC04F34),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFC04F34),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isExperimental && activeUrl != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.deepBasalt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colors.graniteEdge,
                        ),
                      ),
                      child: Text(
                        activeUrl,
                        style: TextStyle(
                          color: context.colors.ashGrey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      if (isEditor) {
                        TelemetryService.instance.logAcaoConfiguracoes(
                          'desconectar_editor',
                        );
                        await configService.disconnect();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Voltando ao repositório oficial...',
                              ),
                            ),
                          );
                        }
                      } else {
                        mostrarDialogConexao(context, datasetRepo);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC04F34),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                        if (!isEditor)
                          FutureBuilder<bool>(
                            future: configService.hasExperimentalData(),
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      TelemetryService.instance
                                          .logAcaoConfiguracoes(
                                            'reativar_experimental',
                                          );
                                      await configService
                                          .activateExperimental();
                                      await datasetRepo.init();
                                      final navContext =
                                          TreeNavigationWrapper
                                              .navKey
                                              .currentContext ??
                                          (context.mounted ? context : null);
                                      if (navContext != null &&
                                          navContext.mounted) {
                                        navegarAposConexaoExperimental(
                                          navContext,
                                          datasetRepo,
                                        );
                                        ScaffoldMessenger.of(
                                          navContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Reativando dados experimentais locais...',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: context.colors.graniteEdge,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history_rounded,
                                            color: context.colors.ashGrey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'REATIVAR MODO EXPERIMENTAL',
                                            style: TextStyle(
                                              color: context.colors.ashGrey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        if (isEditor) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: context.colors.caveShadow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    'Apagar Tudo?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Isso apagará permanentemente todo o índice experimental e todos os picos baixados nesse modo. Deseja continuar?',
                                    style: TextStyle(
                                      color: context.colors.ashGrey,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        'CANCELAR',
                                        style: TextStyle(
                                          color: context.colors.ashGrey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'APAGAR TUDO',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                TelemetryService.instance.logAcaoConfiguracoes(
                                  'limpar_dados_experimentais',
                                );
                                await configService.nukeExperimentalData();
                                datasetRepo.loadEmpty();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ambiente experimental limpo.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: Colors.red.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LIMPAR DADOS EXPERIMENTAIS',
                                    style: TextStyle(
                                      color: Colors.red.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              Future.microtask(() {
                                if (context.mounted) {
                                  showDeprecatedAppVersionSnackBar(context);
                                }
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TESTAR ALERTA DE OBSOLESCÊNCIA',
                                    style: TextStyle(
                                      color: Colors.orange.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AppVersionHardBlockScreen(
                                        onUpdatePressed: () =>
                                            Navigator.pop(context),
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.red.shade900.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.system_update_rounded,
                                    color: Colors.red.shade900.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TESTAR TELA DE BLOQUEIO',
                                    style: TextStyle(
                                      color: Colors.red.shade900.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
}

Widget buildThemeSelectionCard(BuildContext context) {
  return Card(
    elevation: 0,
    color: context.colors.caveShadow,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.graniteEdge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette,
                  color: context.colors.ashGrey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APARÊNCIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalize o tema do aplicativo.',
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
          const SizedBox(height: 16),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController().themeMode,
            builder: (context, currentMode, _) {
              final isManual = currentMode != ThemeMode.system;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Escolher tema manualmente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isManual,
                        onChanged: (value) {
                          if (value) {
                            ThemeController().setThemeMode(ThemeMode.dark);
                          } else {
                            ThemeController().setThemeMode(ThemeMode.system);
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white.withValues(alpha: 0.5),
                        inactiveThumbColor: context.colors.ashGrey,
                        inactiveTrackColor: context.colors.graniteEdge,
                      ),
                    ],
                  ),
                  if (isManual) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        /* Expanded(
                          child: buildThemeOption(
                            context: context,
                            title: 'CLARO',
                            icon: Icons.light_mode,
                            isSelected: currentMode == ThemeMode.light,
                            onTap: () {
                              TelemetryService.instance.logAcaoConfiguracoes('tema_claro');
                              ThemeController().setThemeMode(ThemeMode.light);
                            },
                          ),
                        ),
                        const SizedBox(width: 12), */
                        Expanded(
                          child: buildThemeOption(
                            context: context,
                            title: 'ESCURO',
                            icon: Icons.dark_mode,
                            isSelected: currentMode == ThemeMode.dark,
                            onTap: () {
                              TelemetryService.instance.logAcaoConfiguracoes(
                                'tema_escuro',
                              );
                              ThemeController().setThemeMode(ThemeMode.dark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget buildThemeOption({
  required BuildContext context,
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.white : context.colors.graniteEdge,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : context.colors.ashGrey,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.ashGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
}

/*
Widget buildLegalLinks(BuildContext context) {
  return Center(
    child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => showTermsBottomSheet(context),
      child: Text(
        'Termos de Uso e Privacidade',
        style: TextStyle(
          color: context.colors.ashGrey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
*/

/// Constrói o rodapé informativo de versão com o rótulo de Beta Aberto na tela de Configurações.
///
/// Ao ser tocado, exibe o [ModalBetaAberto] com detalhes do projeto e atalho para envio de feedback.
Widget buildVersaoBetaFooter(BuildContext context) {
  return FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      final versao = snapshot.data?.version ?? '0.2.8';
      return Center(
        child: InkWell(
          onTap: () => exibirModalBetaAberto(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Aresta Climb v$versao (Beta Aberto)',
              style: TextStyle(
                color: context.colors.ashGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    },
  );
}
