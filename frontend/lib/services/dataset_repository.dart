import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../kmon_api/proto/indice.pb.dart';
import '../kmon_api/proto/croqui.pb.dart';

/// Represents the synchronization state of the application.
enum SyncStatus {
  updated,
  updating,
  outdated,
  error 
}

class TopoDataset {
  final List<Map<String, dynamic>> availablePicos;
  final List<Map<String, dynamic>> downloadedPicos;

  TopoDataset({
    required this.availablePicos,
    required this.downloadedPicos,
  });
}

/// A repository that manages the synchronization and storage of climbing data.
/// 
/// It acts as the central state manager for crag information, handling 
/// local storage, downloads, and the guides priority logic.
class DatasetRepository {
  /// This notifies the UI whenever the data changes
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(null);

  /// Notifies listeners about the current synchronization status.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.updating);

  /// Tracks which crags are currently being downloaded
  final ValueNotifier<Set<String>> downloadingCrags = ValueNotifier({});

  // Github pages backend
  final String _baseUrl = 'https://acecmg.github.io/kmon_serving';

  /// Processes a protobuf [Indice] and updates the [activeDataset].
  /// 
  /// It maps the protobuf data to a list of maps and identifies which crags
  /// are already stored locally.
  Future<void> loadIndiceToMemory(Indice indice) async {
    final List<Map<String, dynamic>> parsedPicos = indice.croquis.map((resumo) {
      // TODO: Using the descricao field as the location/subtitle for now
      String locationText;
      if (resumo.descricao.isNotEmpty) {
        locationText = resumo.descricao;
      } else {
        locationText = 'Local Desconhecido';
      }
      
      return {
        'nome': resumo.nome,
        'local': locationText,
        'id': resumo.id,
        'url': '$_baseUrl/${resumo.url}',
        'checksum': resumo.checksumSha256,
      };
    }).toList();

    // Identify which ones are already downloaded
    final List<Map<String, dynamic>> downloaded = await _filterDownloaded(parsedPicos);

    // Update the state manager, which instantly rebuilds Home and Browse pages
    activeDataset.value = TopoDataset(
      availablePicos: parsedPicos,
      downloadedPicos: downloaded,
    );
  }

  /// Sets the dataset to an empty state.
  void loadEmpty() {
    activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);
  }

  /// Retrieves the list of recently accessed crag IDs from local storage.
  Future<List<String>> _getPriorityList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/recent_picos.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.cast<String>();
      }
    } catch (e) {
      debugPrint('Error reading priority list: $e');
    }
    return [];
  }

  /// Updates the "Recent" list by moving the given [id] to the front of priority.
  Future<void> _updatePriority(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/recent_picos.json');
      List<String> priorityList = await _getPriorityList();
      
      priorityList.remove(id);
      priorityList.insert(0, id);
      
      await file.writeAsString(jsonEncode(priorityList));
    } catch (e) {
      debugPrint('Error updating priority list: $e');
    }
  }

  /// Filters and sorts the list of crags based on what is available locally.
  /// 
  /// Crags are sorted according to the priority list (most recent first).
  Future<List<Map<String, dynamic>>> _filterDownloaded(List<Map<String, dynamic>> picos) async {
    final directory = await getApplicationDocumentsDirectory();
    final List<String> priorityList = await _getPriorityList();
    final List<Map<String, dynamic>> downloaded = [];
    
    for (var pico in picos) {
      final file = File('${directory.path}/downloads/${pico['id']}.binarypb');
      if (await file.exists()) {
        downloaded.add(pico);
      }
    }
    
    // Sort based on index in priorityList (lower index = higher priority)
    // Items not in the list are placed at the end, hence they do not appear in the carousel, only on the dropdown
    downloaded.sort((a, b) {
      int indexA = priorityList.indexOf(a['id']);
      int indexB = priorityList.indexOf(b['id']);
      // Fallback for items not in the list (put them at the end)
      if (indexA == -1) indexA = 999999;
      if (indexB == -1) indexB = 999999;
      return indexA.compareTo(indexB);
    });
    
    return downloaded;
  }

  /// Downloads a crag's binarypb and its associated external files to local storage.
  /// 
  /// Returns [true] if the download and save operations were successful.
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    final String? url = crag['url'];
    final String? id = crag['id'];

    if (url == null || id == null) return false;

    // Mark as downloading
    downloadingCrags.value = {...downloadingCrags.value, id};

    try {
      debugPrint('Downloading crag $id from $url...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads');
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$id.binarypb');
        await file.writeAsBytes(response.bodyBytes);
        
        debugPrint('Saved to: ${file.path}');

        // Refresh the dataset so the UI knows there's a new download (partial)
        if (activeDataset.value != null) {
          final updatedDownloaded = await _filterDownloaded(activeDataset.value!.availablePicos);
          activeDataset.value = TopoDataset(
            availablePicos: activeDataset.value!.availablePicos,
            downloadedPicos: updatedDownloaded,
          );
        }

        // --- Download all External Files (Images/Markdowns) ---
        try {
          final parsedPico = Croqui.fromBuffer(response.bodyBytes);
          
          String baseDir = '';
          if (url.startsWith(_baseUrl)) {
            String relative = url.substring(_baseUrl.length);
            if (relative.startsWith('/')) relative = relative.substring(1);
            int lastSlash = relative.lastIndexOf('/');
            if (lastSlash != -1) {
              baseDir = relative.substring(0, lastSlash);
            }
          } else {
             // Fallback if URL doesn't start with baseUrl for some reason
             int lastSlash = url.lastIndexOf('/');
             if (lastSlash != -1) {
                baseDir = url.substring(url.indexOf('://') + 3); // strip https://
                baseDir = baseDir.substring(baseDir.indexOf('/')); // strip domain
                if (baseDir.startsWith('/')) baseDir = baseDir.substring(1);
                baseDir = baseDir.substring(0, baseDir.lastIndexOf('/'));
             }
          }

          for (var ext in parsedPico.arquivosExternos) {
             final imageUrl = '$_baseUrl/${ext.caminho}';
             final imgResponse = await http.get(Uri.parse(imageUrl));
             if (imgResponse.statusCode == 200) {
                final imgFile = File('${downloadsDir.path}/${ext.caminho}');
                if (!await imgFile.parent.exists()) {
                   await imgFile.parent.create(recursive: true);
                }
                await imgFile.writeAsBytes(imgResponse.bodyBytes);
             }
          }

          // Extract and download markdown images
          try {
            final jsonStr = jsonEncode(parsedPico.toProto3Json());
            final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
            final matches = regex.allMatches(jsonStr);
            for (final match in matches) {
              if (match.groupCount >= 1) {
                String path = match.group(1)!;
                if (!path.startsWith('http://') && !path.startsWith('https://')) {
                  if (path.startsWith('./')) path = path.substring(2);
                  if (path.startsWith('/')) path = path.substring(1);
                  
                  String fullCaminho;
                  if (baseDir.isNotEmpty) {
                    fullCaminho = '$baseDir/$path';
                  } else {
                    fullCaminho = path;
                  }
                  
                  final imageUrl = '$_baseUrl/$fullCaminho';
                  debugPrint('Attempting to download markdown image: $imageUrl');
                  
                  final imgResponse = await http.get(Uri.parse(imageUrl));
                  if (imgResponse.statusCode == 200) {
                    final imgFile = File('${downloadsDir.path}/$fullCaminho');
                    if (!await imgFile.parent.exists()) {
                       await imgFile.parent.create(recursive: true);
                    }
                    await imgFile.writeAsBytes(imgResponse.bodyBytes);
                    debugPrint('Successfully downloaded markdown image to ${imgFile.path}');
                  } else {
                    debugPrint('Failed to download markdown image: $imageUrl, status: ${imgResponse.statusCode}');
                  }
                }
              }
            }
          } catch (mdEx) {
            debugPrint('Error downloading markdown images for $id: $mdEx');
          }

        } catch (downloadEx) {
          debugPrint('Error downloading external files for $id: $downloadEx');
        }

        return true;
      }
    } catch (e) {
      debugPrint('Error downloading crag: $e');
    } finally {
      // Unmark as downloading regardless of success or failure
      downloadingCrags.value = {...downloadingCrags.value}..remove(id);
    }
    return false;
  }

  /// Loads the full [Croqui] data from a local file and updates its priority.
  Future<Croqui?> getCroqui(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/downloads/$id.binarypb');
      
      if (await file.exists()) {
        // Move ID to the front of the priority list if it's being viewed
        await _updatePriority(id);

        // Update dataset to reflect new sorting in the UI
        if (activeDataset.value != null) {
          final updated = await _filterDownloaded(activeDataset.value!.availablePicos);
          activeDataset.value = TopoDataset(
            availablePicos: activeDataset.value!.availablePicos,
            downloadedPicos: updated,
          );
        }

        final bytes = await file.readAsBytes();
        return Croqui.fromBuffer(bytes);
      }
    } catch (e) {
      debugPrint('Error loading croqui $id: $e');
    }
    return null;
  }

  /// Deletes a crag's binarypb from local storage and refreshes the dataset.
  Future<bool> deleteCrag(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/downloads/$id.binarypb');
      if (await file.exists()) {
        await file.delete();
        if (activeDataset.value != null) {
          final updatedDownloaded = await _filterDownloaded(activeDataset.value!.availablePicos);
          activeDataset.value = TopoDataset(
            availablePicos: activeDataset.value!.availablePicos,
            downloadedPicos: updatedDownloaded,
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting crag: $e');
    }
    return false;
  }
}
