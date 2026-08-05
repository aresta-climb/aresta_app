import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/network_constants.dart';

import '../../tool/sync_preload.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late Directory tempDir;

  setUp(() {
    mockClient = MockHttpClient();
    tempDir = Directory.systemTemp.createTempSync('sync_preload_test');
    registerFallbackValue(Uri.parse(NetworkConstants.officialServerUrl));
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
    'Deve falhar ao tentar baixar indice.binarypb se a rede falhar',
    () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      expect(() => runner.run(), throwsException);
    },
  );

  test(
    'Deve baixar indice.binarypb, salvar no disco e baixar thumbnails',
    () async {
      final fakeIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash1',
            checksumSha256Thumbnail: 'thumb1',
          ),
          ResumoCroqui(
            id: 'crag2',
            caminhoRelativo: 'crag2/compilado.binarypb',
            checksumSha256Croqui: 'hash2',
            checksumSha256Thumbnail: 'thumb2',
          ),
        ],
      );
      final bytes = fakeIndice.writeToBuffer();

      // Mock indice download
      when(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200, headers: {'etag': '123'}),
      );

      // Mock thumbnails downloads
      when(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response.bytes([1, 2, 3], 200));

      when(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag2.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response.bytes([4, 5, 6], 200));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      await runner.run();

      final indiceFile = File('${tempDir.path}/indice.binarypb');
      expect(indiceFile.existsSync(), isTrue);

      // ETag test
      final etagFile = File('${tempDir.path}/indice.etag');
      expect(etagFile.existsSync(), isTrue);
      expect(etagFile.readAsStringSync(), '123');

      // Thumbnails tests
      final thumb1 = File('${tempDir.path}/thumbnails/crag1.webp');
      final thumb2 = File('${tempDir.path}/thumbnails/crag2.webp');
      expect(thumb1.existsSync(), isTrue);
      expect(thumb2.existsSync(), isTrue);
      expect(thumb1.readAsBytesSync(), [1, 2, 3]);
      expect(thumb2.readAsBytesSync(), [4, 5, 6]);
    },
  );

  test(
    'Deve mandar ETag se existir localmente e parar se retornar 304',
    () async {
      File('${tempDir.path}/indice.etag').writeAsStringSync('old_etag');

      when(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: {'If-None-Match': 'old_etag'},
        ),
      ).thenAnswer((_) async => http.Response('', 304));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      await runner.run();

      verify(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: {'If-None-Match': 'old_etag'},
        ),
      ).called(1);

      verifyNever(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
        ),
      );
    },
  );

  test(
    'Deve comparar hashes antigos com novos e apenas baixar thumbnails que mudaram',
    () async {
      // 1. Setup local old indice and thumbnails
      final oldIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash1_old',
            checksumSha256Thumbnail: 'thumb1_old',
          ), // Mudou
          ResumoCroqui(
            id: 'crag2',
            caminhoRelativo: 'crag2/compilado.binarypb',
            checksumSha256Croqui: 'hash2_same',
            checksumSha256Thumbnail: 'thumb2_same',
          ), // Não mudou
        ],
      );
      File(
        '${tempDir.path}/indice.binarypb',
      ).writeAsBytesSync(oldIndice.writeToBuffer());

      final thumbsDir = Directory('${tempDir.path}/thumbnails');
      thumbsDir.createSync(recursive: true);
      File('${thumbsDir.path}/crag1.webp').writeAsBytesSync([1, 1]);
      File('${thumbsDir.path}/crag2.webp').writeAsBytesSync([2, 2]);

      // 2. Setup mock for new indice
      final newIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash1_new',
            checksumSha256Thumbnail: 'thumb1_new',
          ),
          ResumoCroqui(
            id: 'crag2',
            caminhoRelativo: 'crag2/compilado.binarypb',
            checksumSha256Croqui: 'hash2_same',
            checksumSha256Thumbnail: 'thumb2_same',
          ),
        ],
      );

      when(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          newIndice.writeToBuffer(),
          200,
          headers: {'etag': 'new_etag'},
        ),
      );

      // Mock only crag1 thumbnail since crag2 shouldn't be downloaded
      when(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response.bytes([9, 9], 200));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      await runner.run();

      // Verify only crag1 was requested
      verify(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
      verifyNever(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag2.webp',
          ),
          headers: any(named: 'headers'),
        ),
      );

      // Verify files
      expect(File('${tempDir.path}/thumbnails/crag1.webp').readAsBytesSync(), [
        9,
        9,
      ]); // Atualizado
      expect(File('${tempDir.path}/thumbnails/crag2.webp').readAsBytesSync(), [
        2,
        2,
      ]); // Mantido
      expect(
        File('${tempDir.path}/indice.etag').readAsStringSync(),
        'new_etag',
      );
    },
  );

  test(
    'Deve baixar thumbnail se apenas o checksumSha256Thumbnail mudar (mesmo croqui)',
    () async {
      // 1. Setup local old indice and thumbnails
      final oldIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash_croqui_same',
            checksumSha256Thumbnail: 'hash_thumb_old',
          ),
        ],
      );
      File('${tempDir.path}/indice.binarypb').writeAsBytesSync(oldIndice.writeToBuffer());

      final thumbsDir = Directory('${tempDir.path}/thumbnails');
      thumbsDir.createSync(recursive: true);
      File('${thumbsDir.path}/crag1.webp').writeAsBytesSync([1, 1]);

      // 2. Setup mock for new indice
      final newIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash_croqui_same',
            checksumSha256Thumbnail: 'hash_thumb_new', // MUDOU AQUI
          ),
        ],
      );

      when(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          newIndice.writeToBuffer(),
          200,
          headers: {'etag': 'new_etag'},
        ),
      );

      // Mock thumbnail download
      when(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response.bytes([9, 9], 200));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      await runner.run();

      verify(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);

      expect(File('${tempDir.path}/thumbnails/crag1.webp').readAsBytesSync(), [9, 9]);
    },
  );

  test(
    'Deve falhar com Exception se o download da thumbnail não retornar 200',
    () async {
      // 1. Setup mock for new indice
      final newIndice = Indice(
        croquis: [
          ResumoCroqui(
            id: 'crag1',
            caminhoRelativo: 'crag1/compilado.binarypb',
            checksumSha256Croqui: 'hash1',
            checksumSha256Thumbnail: 'thumb1',
          ),
        ],
      );

      when(
        () => mockClient.get(
          Uri.parse('${NetworkConstants.officialServerUrl}/indice.binarypb'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          newIndice.writeToBuffer(),
          200,
          headers: {'etag': 'new_etag'},
        ),
      );

      // Mock thumbnail download to return 404
      when(
        () => mockClient.get(
          Uri.parse(
            '${NetworkConstants.officialServerUrl}/thumbnails/crag1.webp',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      final runner = SyncPreloadRunner(
        client: mockClient,
        baseUrl: NetworkConstants.officialServerUrl,
        outputDir: tempDir.path,
      );

      expect(() => runner.run(), throwsException);
    },
  );
}
