## Context

The app bundles a preloaded dataset of crags (croquis) and their thumbnails via `tool/sync_preload.dart`. Currently, this script assumes a thumbnail has changed only if the `checksumSha256Croqui` (the hash of the data itself) has changed. This is logically incorrect, as a thumbnail image can be updated independently of the croqui data. This leads to a situation where the script updates the bundled `indice.binarypb` (which contains the new thumbnail hash) but retains the old `thumbnail.webp` image file in the preload package.

## Goals / Non-Goals

**Goals:**
- Fix `tool/sync_preload.dart` to correctly evaluate thumbnail updates based on `checksumSha256Thumbnail` instead of `checksumSha256Croqui`.
- Add a unit test to verify this behavior, ensuring thumbnails are updated even if the croqui data remains the same.

**Non-Goals:**
- Fix any issues outside the scope of the `sync_preload.dart` script and its test.
- Refactor the entire preload mechanism.

## Decisions

- **Store Thumbnail Hashes Separately:** In `sync_preload.dart`, we will extract both `checksumSha256Croqui` and `checksumSha256Thumbnail` from the old index. We will store the thumbnail hashes in a new map `oldThumbnailHashes`.
- **Compare Thumbnail Hashes:** When deciding whether to download a thumbnail, the script will evaluate `oldThumbnailHashes[cragId] != resumo.checksumSha256Thumbnail`.

## Risks / Trade-offs

- **Risk:** Existing unit tests or CI pipelines might depend on the current broken behavior.
  - **Mitigation:** Run tests locally and fix them if they are too tightly coupled to the old logic. Add a dedicated unit test to cover this specific scenario.
