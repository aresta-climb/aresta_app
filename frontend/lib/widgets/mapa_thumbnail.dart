import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/constants/network_constants.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../navigation/navigation_tree.dart';

class MapaThumbnail extends StatefulWidget {
  final Mapa mapa;
  final String cragId;
  final Setor? setorContext;
  final Grupo? grupoContext;
  final String? nomeContexto;
  final ImageProvider? imageProviderOverride;

  const MapaThumbnail({
    super.key,
    required this.mapa,
    required this.cragId,
    this.setorContext,
    this.grupoContext,
    this.nomeContexto,
    this.imageProviderOverride,
  });

  @override
  State<MapaThumbnail> createState() => _MapaThumbnailState();
}

class _MapaThumbnailState extends State<MapaThumbnail> {
  Future<ImageProvider?>? _imageProviderFuture;

  @override
  void initState() {
    super.initState();
    _imageProviderFuture = _resolveImageProvider();
  }

  @override
  void didUpdateWidget(MapaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapa != oldWidget.mapa ||
        widget.imageProviderOverride != oldWidget.imageProviderOverride) {
      _imageProviderFuture?.then((provider) {
        provider?.evict();
      });
      _imageProviderFuture = _resolveImageProvider();
    }
  }

  Future<ImageProvider?> _resolveImageProvider() async {
    if (widget.imageProviderOverride != null) {
      return widget.imageProviderOverride;
    }
    return resolveMapImageProvider(widget.cragId, widget.mapa);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapa.larguraMapa == 0 || widget.mapa.alturaMapa == 0) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<ImageProvider?>(
      future: _imageProviderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AspectRatio(
            aspectRatio: widget.mapa.larguraMapa / widget.mapa.alturaMapa,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: beastHide),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            TelemetryService.instance.logAbrirMapa(
              widget.cragId,
              widget.nomeContexto ?? widget.setorContext?.nome ?? 'Geral',
            );
            AppNav.toMapas(
              context,
              cragId: widget.cragId,
              mapas: [
                CarrosselItemData(
                  mapaCaminhoImagem: widget.mapa.caminhoImagemMapa,
                  setorContextNome: widget.setorContext?.nome,
                  grupoContextNome: widget.grupoContext?.nome,
                ),
              ],
              imageProviderOverride: widget.imageProviderOverride,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagem de fundo
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: widget.mapa.larguraMapa / widget.mapa.alturaMapa,
                  child: Image(image: snapshot.data!, fit: BoxFit.cover),
                ),
              ),
              // Overlay escuro
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Botão Translúcido
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: beastHide.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Abrir Mapa Interativo',
                      style: TextStyle(
                        color: fishBone,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<ImageProvider?> resolveMapImageProvider(String cragId, Mapa mapa) async {
  return resolveImagePathProvider(cragId, mapa.caminhoImagemMapa);
}

Future<ImageProvider?> resolveImagePathProvider(
  String cragId,
  String path,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final editor = EditorDeCroqui.instance;
  final downloadsPath = '${editor.downloadsPath(dir.path)}/$cragId';

  String fileName = path.split('/').last;

  File? localFile;

  final baseUrl = '${NetworkConstants.officialServerUrl}/';
  if (path.startsWith(baseUrl)) {
    final relativePath = path.replaceFirst(baseUrl, '');
    final directFile = File('$downloadsPath/$relativePath');
    if (directFile.existsSync()) {
      localFile = directFile;
    }
  }

  if (localFile == null) {
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final directFile = File('$downloadsPath/$cleanPath');
    if (directFile.existsSync()) {
      localFile = directFile;
    }
  }

  if (localFile == null && fileName.isNotEmpty) {
    final searchName = Uri.decodeComponent(fileName).toLowerCase();
    String searchBaseName = searchName.contains('.')
        ? searchName.substring(0, searchName.lastIndexOf('.'))
        : searchName;

    try {
      final downloadsDir = Directory(downloadsPath);
      if (downloadsDir.existsSync()) {
        final entities = downloadsDir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final String ePath = entity.path.replaceAll('\\', '/');
            final String eName = ePath.split('/').last;
            final String eNameLower = Uri.decodeComponent(eName).toLowerCase();
            if (eNameLower == searchName) {
              localFile = entity;
              break;
            }
            String eBaseName = eNameLower.contains('.')
                ? eNameLower.substring(0, eNameLower.lastIndexOf('.'))
                : eNameLower;
            if (eBaseName == searchBaseName) {
              localFile = entity;
              break;
            }
          }
        }
      }
    } catch (e) {
      // ignora erros
    }
  }

  if (localFile != null && localFile.existsSync()) {
    return FileImage(localFile);
  }

  return null;
}
