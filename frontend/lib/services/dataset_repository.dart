import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'update_downloader.dart';

/// 1. The Immutable State Object
/// This represents a snapshot of your currently active data.
class TopoDataset {
  final int version;
  final String activeDirectoryPath;

  // Updated to match the UI's expected Map structure
  final List<Map<String, dynamic>> availablePicos;

  TopoDataset({
    required this.version,
    required this.activeDirectoryPath,
    required this.availablePicos,
  });
}

/// 2. The Repository Managing Local Storage and State
class DatasetRepository {
  // The UI listens to this notifier. When it updates, the app rebuilds.
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(null);

  // The downloader service is responsible for downloading and verifying updates
  final UpdateDownloader _downloader = UpdateDownloader();

  /// Called in main.dart to set up the initial local file state
  Future<void> initialize() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final v1Dir = Directory('${docsDir.path}/dataset_v1');
    final v2Dir = Directory('${docsDir.path}/dataset_v2');

    Directory activeDir;
    int currentVersion = 1;

    // Determine which directory is currently active
    if (await v2Dir.exists()) {
      activeDir = v2Dir;
      currentVersion = 2;
    } else {
      activeDir = v1Dir;
      if (!await activeDir.exists()) {
        await activeDir.create(recursive: true);
      }
    }

    // TODO: Read activeDir.path + '/index.binarypb' and parse it into availablePicos
    // For now, using dummy data structure
    final parsedPicos = [
      {
        'nome': 'Gruta do Baú',
        'local': 'Pedro Leopoldo, MG',
        'vias': '100+',
      },
      {
        'nome': 'Pedra Grande',
        'local': 'Igarapé, MG',
        'vias': '150+',
      },
    ];

    activeDataset.value = TopoDataset(
      version: currentVersion,
      activeDirectoryPath: activeDir.path,
      availablePicos: parsedPicos,
    );
  }

  /// Downloads updates, prepares the staging directory, and atomically swaps the UI
  Future<void> performAtomicSwap({
    required List<IndexEntry> filesToUpdate,
    required List<Map<String, dynamic>> newPicos, // Updated to accept the Map list
  }) async {
    if (activeDataset.value == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final currentDir = Directory(activeDataset.value!.activeDirectoryPath);

    // 1. Determine staging directory (if v1 is active, stage in v2, and vice versa)
    final isV1Active = currentDir.path.endsWith('dataset_v1');
    final stagingDir = Directory(isV1Active ? '${docsDir.path}/dataset_v2' : '${docsDir.path}/dataset_v1');

    // 2. Prepare staging directory (clear it if a previous update failed midway)
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create(recursive: true);

    // 3. Copy UNCHANGED files from current active directory to the staging directory
    // We do this to ensure the staging directory has a complete set of data.
    final filenamesToUpdate = filesToUpdate.map((e) => e.filename).toSet();

    if (await currentDir.exists()) {
      await for (final entity in currentDir.list()) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          // If this file is NOT in the update list, copy it to staging
          if (!filenamesToUpdate.contains(filename)) {
            await entity.copy('${stagingDir.path}/$filename');
          }
        }
      }
    }

    // 4. Download and Verify CHANGED files directly into the staging directory
    print('Downloading ${filesToUpdate.length} updates into staging...');
    await _downloader.downloadAndVerifyUpdates(
      filesToUpdate: filesToUpdate,
      stagingDir: stagingDir,
    );

    // 5. The Atomic Swap!
    // Create the new state object and emit it. The UI instantly rebuilds.
    final newDataset = TopoDataset(
      version: activeDataset.value!.version + 1,
      activeDirectoryPath: stagingDir.path,
      availablePicos: newPicos, // Pass the new data here
    );

    activeDataset.value = newDataset;
    print('Swap complete! UI is now reading from ${stagingDir.path}');

    // 6. Cleanup the old directory in the background to save disk space
    _cleanupOldDirectory(currentDir);
  }

  /// Silently deletes the old directory after a successful swap
  Future<void> _cleanupOldDirectory(Directory oldDir) async {
    try {
      if (await oldDir.exists()) {
        await oldDir.delete(recursive: true);
        print('Cleaned up old dataset directory: ${oldDir.path}');
      }
    } catch (e) {
      print('Warning: Could not delete old directory. It will be overwritten on the next swap. Error: $e');
    }
  }

  void dispose() {
    activeDataset.dispose();
    _downloader.dispose();
  }
}