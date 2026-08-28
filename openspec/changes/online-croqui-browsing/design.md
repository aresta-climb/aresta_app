## Context

Historically, the Aresta Climb mobile application enforced an offline-first paradigm where exploring a crag required downloading its full binary and media package into `/downloads/<cragId>/`. While this guarantees 100% offline availability in mountains, it creates high friction for users exploring areas from home, testing betas, or checking route grades.

The existing backend distributes croquis as compiled `.binarypb` protobufs with associated WebP images and map overlays over CDN HTTP endpoints (and locally via the Ghost Protocol `aresta-zip://`). Furthermore, each `ResumoCroqui` in `indice.binarypb` already contains SHA-256 checksums, and `Croqui` contains SHA-256 hashes for all `arquivosExternos`.

This design establishes a hybrid online/offline architecture enabling instant online exploration with volatile caching, live ETag polling, explicit download guards, and resilient background downloading with ongoing OS notifications.

## Goals / Non-Goals

**Goals:**
- Enable immediate browsing of any crag without prior download.
- Stream `.binarypb` and render UI in milliseconds while storing media in volatile OS cache.
- Implement periodic ETag polling (`If-None-Match`) while browsing online to notify users of live backend edits.
- Expose pre-calculated `tamanho_download_bytes` in `indice.proto` for instant UI size labels.
- Provide a persistent floating Online Mode banner and an Exit Guard confirmation to protect climbers from the "no-signal mountain surprise".
- Implement background downloads powered by Android Foreground Service (and iOS background URLSession) with ongoing system notifications that survive app closure.

**Non-Goals:**
- Deprecating or weakening offline-first support — offline usage remains the primary core feature of Aresta.
- Automatic background caching of every crag in the world (downloads remain explicitly chosen by the user).
- In-app authoring or editing of croquis (handled separately via the desktop/web editor).

## Decisions

### Decision 1: Volatile Temporary Cache + RAM for Online Sessions
- **Rationale**: `.binarypb` is very small (~tens of KB) and parses in memory. Storing downloaded media in `getTemporaryDirectory()` allows the OS to reclaim storage when needed without corrupting the permanent `/downloads` directory.
- **Alternatives Considered**:
  - *Saving directly to `/downloads`*: Fills user storage silently with uncurated data and blurs the line of what is truly guaranteed offline.
  - *Pure in-memory only*: Re-downloads images whenever widgets rebuild or recreate, wasting bandwidth.

### Decision 2: Active ETag Polling on Open Online Croquis
- **Rationale**: When viewing an online crag, a background timer sends a lightweight `If-None-Match: <etag>` request every 30-60s. A `304 Not Modified` returns zero body bytes (negligible bandwidth/battery impact). A `200 OK` delivers the updated buffer and presents a non-intrusive "Croqui Atualizado • Recarregar" pill in the UI.
- **Alternatives Considered**:
  - *WebSockets / SSE*: Unnecessary server complexity and battery drain for static CDN-hosted files.
  - *No Polling (Cache indefinitely)*: Users browsing for minutes or hours wouldn't see newly published route updates.

### Decision 3: Pre-computed `tamanho_download_bytes` in Protobuf
- **Rationale**: `aresta_db` sums the byte size of `.binarypb` + all `arquivosExternos` during build and embeds it into `PrecomputadosResumoCroqui`. This lets cards, banners, and exit guards display "18.4 MB" instantly without any network `HEAD` calls.
- **Alternatives Considered**:
  - *Runtime HTTP HEAD calls*: Slow, adds round-trip latency, and fails when connections are throttled.

### Decision 4: Tiered Image Resolution Pipeline
- **Pipeline**:
  1. `/downloads/<cragId>/<imagePath>` (Permanent Offline Storage)
  2. `/temp_cache/<cragId>/<imagePath>` (Volatile OS Cache)
  3. `https://<servingBaseUrl>/<imagePath>?v=<sha256>` (CDN Streaming with Cache-Busting)
- **Rationale**: Unifies all image consumers (`OfflineMarkdown`, `MapaThumbnail`, `MapaInterativo`, `SetorPage`) through a single provider without duplicating lookup logic.

### Decision 5: Resilient Background Download via OS Foreground Service
- **Rationale**: Android kills standard Dart background isolates when apps are minimized. A Foreground Service with an ongoing system notification (`ongoing: true`, progress bar) guarantees execution until completion.
- **Completion Flow**: Downloads write to `.tmp` files $\rightarrow$ validate SHA-256 $\rightarrow$ atomic rename into `/downloads/<cragId>` $\rightarrow$ update `DatasetRepository` $\rightarrow$ update notification to "Download Concluído".

### Decision 6: Navigation Interception via Exit Guard
- **Rationale**: Wraps the online `PicoDetailsPage` in a `PopScope`. If the user spent significant time or navigated deeply in an online crag without downloading, popping navigation triggers a confirmation modal alerting them to save before heading to the crag.

## Risks / Trade-offs

- **[Risk] User assumes online viewing cached all images for offline use** → **Mitigation**: Clear visual distinction with persistent top banner (`☁️ Modo Online`), distinct badge colors, and the Exit Guard prompt.
- **[Risk] High memory usage when opening multiple online crags** → **Mitigation**: Online buffers are tied to active view models; previous online buffers are garbage collected when not pinned.
- **[Risk] OS kills background download on extreme memory pressure** → **Mitigation**: Foreground service notification with auto-retry and backoff policies.
- **[Risk] Stale cached binarypb in volatile directory** → **Mitigation**: Checksum validation against `indice.binarypb` hash plus ETag `304/200` revalidation.
