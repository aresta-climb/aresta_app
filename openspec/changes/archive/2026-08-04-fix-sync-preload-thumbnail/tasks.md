## 1. Script Logic Fix

- [x] 1.1 In `tool/sync_preload.dart`, create `oldThumbnailHashes` map.
- [x] 1.2 Populate `oldThumbnailHashes` with `checksumSha256Thumbnail`.
- [x] 1.3 Update comparison logic to check `oldThumbnailHashes[cragId] != resumo.checksumSha256Thumbnail`.

## 2. Testing

- [x] 2.1 Add a unit test to verify that the script successfully identifies when only a thumbnail has changed (without the croqui changing).
