import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../proto/indice.pb.dart';
import '../proto/croqui.pb.dart'; // Import Croqui proto

class TopoDataset {
  final List<Map<String, dynamic>> availablePicos;
  final List<Map<String, dynamic>> downloadedPicos;

  TopoDataset({
    required this.availablePicos,
    required this.downloadedPicos,
  });
}

class DatasetRepository {
  // This notifies the UI whenever the data changes
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(null);

  // Github pages backend
  final String _baseUrl = 'https://acecmg.github.io/kmon_serving';

  Future<void> initialize() async {
    try {
      // 1. Fetch the master index file from the live server
      print('Fetching live database from $_baseUrl/indice.binarypb...');
      final response = await http.get(Uri.parse('$_baseUrl/indice.binarypb'));

      if (response.statusCode == 200) {
        // 2. Decode the raw bytes into Dart objects using Protobuf
        final indice = Indice.fromBuffer(response.bodyBytes);
        print('Successfully parsed index! Found ${indice.croquis.length} crags.');

        // 3. Map the Protobuf ResumoCroqui objects to the Map format of the UI
        final List<Map<String, dynamic>> parsedPicos = indice.croquis.map((resumo) {
          return {
            'nome': resumo.nome,
            // Using the descricao field as the location/subtitle for now
            'local': resumo.descricao.isNotEmpty ? resumo.descricao : 'Local Desconhecido',
            'id': resumo.id,
            'url': '$_baseUrl/${resumo.url}',
            'checksum': resumo.checksumSha256,
          };
        }).toList();

        // 4. Identify which ones are already downloaded
        final List<Map<String, dynamic>> downloaded = await _filterDownloaded(parsedPicos);

        // 5. Update the state manager, which instantly rebuilds Home and Browse pages
        activeDataset.value = TopoDataset(
          availablePicos: parsedPicos,
          downloadedPicos: downloaded,
        );

        // 6. Kick off background sync process
        _checkForUpdatesInBackground(indice);

      } else {
        print('Server returned an error: ${response.statusCode}');
        _loadOfflineCache();
      }
    } catch (e) {
      print('Failed to connect to the server: $e');
      _loadOfflineCache();
    }
  }

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
      print('Error reading priority list: $e');
    }
    return [];
  }

  Future<void> _updatePriority(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/recent_picos.json');
      List<String> priorityList = await _getPriorityList();
      
      priorityList.remove(id);
      priorityList.insert(0, id);
      
      await file.writeAsString(jsonEncode(priorityList));
    } catch (e) {
      print('Error updating priority list: $e');
    }
  }

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

  /// Downloads a crag's binarypb and saves it to local storage
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    final String? url = crag['url'];
    final String? id = crag['id'];

    if (url == null || id == null) return false;

    try {
      print('Downloading crag $id from $url...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads');
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$id.binarypb');
        await file.writeAsBytes(response.bodyBytes);
        
        print('Saved to: ${file.path}');

        // Refresh the dataset so the UI knows there's a new download
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
      print('Error downloading crag: $e');
    }
    return false;
  }

  /// Loads the full Croqui data from a local binarypb file
  Future<Croqui?> getCroqui(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/downloads/$id.binarypb');
      
      if (await file.exists()) {
        // Move ID to the front of the priority list
        await _updatePriority(id);

        // Update dataset to reflect new sorting
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
      print('Error loading croqui $id: $e');
    }
    return null;
  }

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
      print('Error deleting crag: $e');
    }
    return false;
  }

  void _checkForUpdatesInBackground(Indice remoteIndice) {
    /* TODO: Compare remoteIndice.croquis[i].checksumSha256
        with the locally saved files. If they differ, download the new compilado.binarypb
    */
    print('Background update check complete.');
  }

  void _loadOfflineCache() async {
    // In a real offline scenario, we'd need a local index or to scan the downloads directory.
    // For now, let's just show what's downloaded if we can't reach the server.
    activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);
  }
}