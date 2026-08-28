## Why

Currently, users must fully download an entire crag package (binary data + all high-resolution images/maps) before they can view its sectors, routes, and topos. This creates high friction for exploration, wastes storage and mobile data, and slows down users who just want to check a single route grade or compare areas while at home.

Allowing instant online croqui browsing unlocks friction-free exploration while maintaining Aresta's core promise: 100% reliable offline access when climbing at the crag without cellular signal.

## What Changes

- **Instant Online Navigation**: Tapping a crag in Explore, Global Map, or Search opens `PicoDetailsPage` immediately without requiring a prior download.
- **On-Demand Streaming & Volatile Media Cache**: The crag's lightweight `.binarypb` (~tens of KB) is fetched on demand and parsed in memory/temp cache. Media images and map tiles are streamed on demand and cached in volatile temporary storage using SHA-256 query parameters (`?v=hash`) for cache busting.
- **Live ETag Polling**: While viewing an online crag, lightweight periodic requests (`If-None-Match: <etag>`) check for backend updates every 30-60s, showing an unobtrusive update banner if a newer version is published.
- **Pre-Computed Download Size in Protobuf**: Extend `ResumoCroqui`/`PrecomputadosResumoCroqui` in `indice.proto` with `tamanho_download_bytes` (populated by `aresta_db`) so the UI displays exact download sizes instantly.
- **Conscious Offline UX (Banner & Exit Guard)**: Display a prominent floating Online Mode banner with a 1-tap "Salvar pra Pedra" CTA, plus an Exit Guard confirmation prompt when navigating away after exploring online without saving.
- **Resilient Background Downloads**: When "Salvar" is triggered, downloads run as a Foreground Service on Android with an ongoing system notification (and background URLSession on iOS) so the bundle finishes downloading and moving to permanent storage even if the user exits the app.

## Capabilities

### New Capabilities
- `online-croqui-streaming`: On-demand fetching and parsing of `.binarypb`, volatile media caching with cache busting, and active ETag polling for live online updates.
- `online-browsing-guard`: Visual indicators and guards (floating Online Mode Banner, dynamic size badges, and Exit Guard modal upon popping navigation) to prevent users from inadvertently heading to the crag without offline data.
- `persistent-background-download`: Background download manager with OS-level persistent ongoing notifications ensuring downloads complete reliably even when the app is minimized or terminated.

### Modified Capabilities
- `navigation`: Update crag selection flows across Explore (`browse.dart`), Home, and Global Map (`mapa_global.dart`) to immediately navigate into `PicoDetailsPage` in online mode instead of displaying a mandatory download bottom sheet.

## Impact

- **Protobuf / API**: Add `tamanho_download_bytes` to `indice.proto` (and coordinate with `aresta_db` builder).
- **Frontend Architecture**:
  - `DatasetRepository`: Support loading online croquis into state alongside downloaded crags.
  - Image Resolution: Introduce unified image provider supporting local permanent -> volatile cache -> CDN stream.
  - HTTP / Sync: Add `OnlineCroquiService` with ETag polling and `BackgroundDownloadService` with native notification channels.
- **Dependencies**: Add/configure foreground service or background downloader plugin with native notification permissions on Android/iOS.
