# Kmon Application Core Architecture

This document describes the structure and logical flow of the application, focusing on how data is fetched, managed, and presented to the user. The app consists of a Services layer for data management, a Functions layer for decoupled UI components/callbacks, and a Pages layer for routing and layout.

## 1. Services Layer (`lib/services/`)

The services layer is responsible for all external communication (HTTP requests), local storage management, data parsing (Protobuf), and application state.

### `DatasetRepository` (`dataset_repository.dart`)
This is the central state manager of the application, orchestrating the flow of climbing data from local storage up to the reactive UI layers. It exposes reactive `ValueNotifier` instances (e.g., `activeDataset`, `syncStatus`, `downloadingCrags`) that the Flutter widget tree listens to for instantaneous, jank-free updates.
- **Local Storage Management**: Ensures true offline isolation by creating dedicated directories for each downloaded Pico (Crag) inside the device's application documents directory (`<app_docs>/downloads/<pico_id>/`). This per-crag directory structure prevents naming collisions and makes targeted updates or deletions extremely efficient.
- **Pico Downloading & Parsing**: Handles the crucial task of downloading the binary Protocol Buffer (`.binarypb`) payloads representing a Pico. Once fetched, it acts as a bridge, mapping complex protobuf models into simpler Dart Maps/Lists for the UI to consume without knowing the underlying data protocol. It is also responsible for extracting and routing the download of external explicit assets.
- **Priority Tracking & Migration**: Manages a `recent_picos.yaml` file to track the chronological order of the user's recently accessed guides. This ensures the Home carousel dynamically shifts to present the most relevant content first. It also contains automated fallback logic to seamlessly migrate legacy `recent_picos.json` files to the YAML format without data loss.

### `SyncService` (`sync_service.dart`)
Acts as the background worker responsible for keeping the local dataset perfectly in sync with the remote GitHub Pages repository (`acecmg.github.io/kmon_serving`). It executes the HTTP flows, robust error handling, and silent background updates without blocking the user interface.
- **On Launch Sync (`syncOnLaunch`)**: Automatically fires upon app startup to fetch the latest master index (`indice.binarypb`). If the server returns a 304 Not Modified or is completely unreachable, the service gracefully falls back to the local cached index, updating the global `SyncStatus` state to `error` or `updated` accordingly.
- **Background Checksum Validation**: After the index is fetched, this process iterates through the locally downloaded Picos and compares their SHA-256 checksums against the new master index. If an outdated Pico is found, it silently downloads the newer binary. It then intelligently compares the checksums of individual images inside the old and new Pico to purge stale images and download only the new ones, saving bandwidth and storage.
- **Markdown Image Extraction**: Because markdown descriptions can contain dynamically linked images that aren't listed in the protobuf's external assets array, this service scans the raw Protobuf JSON string of a downloaded Pico using a regular expression (`RegExp(r'!\[.*?\]\((.*?)\)')`). This reliably extracts all embedded Markdown image paths (e.g., `![alt text](path.jpg)`) and triggers a supplementary download of these images directly into the Pico's isolated directory, guaranteeing total offline availability.

## 2. Pages Layer (`lib/pages/`)

The pages layer is responsible for the top-level routing, Scaffold structure, and putting together the widgets.

### Main Navigation (`main.dart`)
`main.dart` initializes the Flutter bindings, creates instances of the `DatasetRepository` and `SyncService`, triggers the initial sync, and sets up a `BottomNavigationBar` (via `MainNavigationWrapper`) to navigate between the main root pages: Home, GPS, and Browse.

### Top Level Pages
- **`home.dart`**: The main entry point. Listens to `activeDataset` and displays:
  1. A Carousel of the user's highest priority (recently accessed) downloaded crags.
  2. A dropdown list of all locally available crags.
- **`browse.dart`**: Displays a comprehensive list of all guides available in the master index, showing which ones are downloaded, which ones are missing, and allowing the user to trigger downloads.
- **`gps.dart`**: The map view of the app.

### Hierarchical Guide Pages
These pages represent the deeply nested topological structure of a climbing guide. State flows seamlessly down the widget tree by passing the `DatasetRepository` instance and the top-level `cragId` throughout the hierarchy:
- **`pico.dart` (Crag/Mountain)**: The root node of a specific guide. It displays a top-level summary, logistical and location info, and a list of all subgroups or sectors belonging to the mountain.
- **`grupo.dart` / `setor.dart` (Sector/Area)**: Represents a distinct geographical sub-area. These pages adapt their UI nomenclature dynamically (e.g., labeling sections as "Vias" vs "Boulders") depending on the type of climbing content present inside the sector's dataset.
- **`via.dart` (Route/Boulder Problem)**: The leaf node of the hierarchy containing the specific beta, detailed descriptions, and high-resolution croqui (topo) images necessary to successfully climb a route.

## 3. Functions Layer (`lib/functions/`)

To prevent the page files from becoming massive monolithic "spaghetti code", all complex UI builders, styling, and callback logic are extracted into the `functions/` directory.

- **Feature-Specific Functions** (`home_functions.dart`, `browse_functions.dart`, `pico_functions.dart`, etc.): Contain the `build...` functions (like `buildPicosCarousel` or `buildAllGuidesDropdown`) and action handlers (like `handlePicoSelection`) for their respective pages.
- **`common_functions.dart`**: Contains the design system. Defines the color palettes (e.g., `beastHide`, `nobleBlack`), standard text styles, and common components (like the `buildPrimaryBottomNav`).
- **`offline_markdown.dart`**: A custom Markdown viewer deeply tailored for the application's offline-first mandate. Standard Markdown widgets inherently try to resolve `![alt text](path)` via an active internet connection. This module overrides the default `imageBuilder` to intercept these network requests. By matching the sanitized image path—extracted previously by the SyncService's Regex logic—it completely bypasses the network layer. Instead, it utilizes `FileImage` to construct and render the image directly from the device's isolated local storage (`<app_docs>/downloads/<pico_id>/...`). This enables complex, rich-text beta to render instantly and flawlessly miles away from cell service.
