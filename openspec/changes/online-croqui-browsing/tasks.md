## 1. Protobuf & Data Model Updates

- [ ] 1.1 Add `tamanho_download_bytes` to `PrecomputadosResumoCroqui` in `indice.proto` and recompile generated protobuf files
- [ ] 1.2 Update `DatasetRepository` and data parsers to expose formatted download size string helper

## 2. Online Croqui Streaming & ETag Polling Service

- [ ] 2.1 Implement `OnlineCroquiService` to fetch `.binarypb` over HTTP with ETag and hash verification
- [ ] 2.2 Implement active ETag periodic polling loop (30s-60s) returning 304/200 and emitting updates
- [ ] 2.3 Integrate volatile temporary cache management for `.binarypb` in `getTemporaryDirectory()`
- [ ] 2.4 Add unit tests for `OnlineCroquiService` (online loading, ETag 304, ETag 200, offline network fallback)

## 3. Tiered Media Image Provider (ArestaImageProvider)

- [ ] 3.1 Implement `ArestaImageProvider` with tiered lookup (Permanent `/downloads` -> Volatile `/temp_cache` -> CDN streaming with `?v=sha256`)
- [ ] 3.2 Refactor `resolveImagePathProvider`, `OfflineMarkdown`, `MapaThumbnail`, and `MapaInterativo` to use `ArestaImageProvider`
- [ ] 3.3 Add unit and widget tests for image provider tier fallback and cache-busting URLs

## 4. UI Components: Banner & Exit Guard

- [ ] 4.1 Create `OnlineModeBanner` widget with status indicators, dynamic size badge, and 1-tap download trigger
- [ ] 4.2 Create `ExitGuardModal` dialog / bottom sheet with download confirmation before navigation pop
- [ ] 4.3 Integrate `PopScope` into `PicoDetailsPage` to activate the Exit Guard upon leaving an online session
- [ ] 4.4 Implement `LiveUpdatePill` widget triggered when ETag polling detects a 200 update
- [ ] 4.5 Add widget tests for `OnlineModeBanner`, `ExitGuardModal`, and `LiveUpdatePill`

## 5. Direct Navigation from Exploration Views

- [ ] 5.1 Update `browse.dart` (`CragCard`) to navigate directly to `AppNav.toPico` in online mode when `!isDownloaded`
- [ ] 5.2 Update `mapa_global.dart` and `home.dart` to support instant online opening
- [ ] 5.3 Update `PageListenableBuilder` to resolve online crags smoothly without failing when not in `downloadedPicos`
- [ ] 5.4 Add navigation flow tests for opening non-downloaded crags directly

## 6. Resilient Background Download Service with OS Notification

- [ ] 6.1 Setup native background download manager / foreground service with continuous notification (`ongoing: true`, progress bar)
- [ ] 6.2 Implement atomic batch download and verification of `.binarypb` + mídias into permanent `/downloads/<cragId>`
- [ ] 6.3 Handle completion state: update notification, notify `DatasetRepository`, and toggle UI to `isDownloaded = true`
- [ ] 6.4 Add tests for background download lifecycle, cancellation, and error handling
