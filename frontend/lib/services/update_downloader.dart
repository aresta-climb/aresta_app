import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// A simple model representing a file entry from your parsed index.binarypb
class IndexEntry {
  final String filename;
  final String expectedSha256;
  final String downloadUrl;

  IndexEntry({
    required this.filename,
    required this.expectedSha256,
    required this.downloadUrl,
  });
}

class UpdateDownloader {
  // A reusable HTTP client for downloading files
  final http.Client _client = http.Client();

  /// Downloads updates, verifies them, and places them in the staging directory.
  /// Throws an exception if a checksum fails.
  Future<void> downloadAndVerifyUpdates({
    required List<IndexEntry> filesToUpdate,
    required Directory stagingDir,
  }) async {
    for (final fileEntry in filesToUpdate) {
      final targetFile = File('${stagingDir.path}/${fileEntry.filename}');

      print('Downloading ${fileEntry.filename}...');

      // 1. Download the file directly to the staging directory
      final response = await _client.get(Uri.parse(fileEntry.downloadUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download ${fileEntry.filename}: HTTP ${response.statusCode}');
      }

      await targetFile.writeAsBytes(response.bodyBytes);

      // 2. Verify the Checksum via Streaming
      print('Verifying checksum for ${fileEntry.filename}...');

      final bool isChecksumValid = await _verifyFileChecksum(
        file: targetFile,
        expectedHexHash: fileEntry.expectedSha256,
      );

      if (!isChecksumValid) {
        // If it's corrupted or tampered with, delete the bad file
        await targetFile.delete();
        throw Exception('Checksum mismatch for ${fileEntry.filename}. Download corrupted.');
      }

      print('Verified ${fileEntry.filename} successfully.');
    }
  }

  /// Calculates the SHA-256 hash by reading the file in chunks (streams).
  Future<bool> _verifyFileChecksum({
    required File file,
    required String expectedHexHash,
  }) async {
    // Open a read stream from the file
    final stream = file.openRead();

    // Pass the stream into the crypto library's SHA-256 calculator
    final Digest hashResult = await sha256.bind(stream).first;

    // Compare the resulting hex string to your index
    return hashResult.toString() == expectedHexHash;
  }

  void dispose() {
    _client.close();
  }
}