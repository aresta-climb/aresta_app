# Renato's Migration Changes

This document summarizes the changes made by Renato, leading up to commit `60f6d72`. A major highlight of these changes is the migration to Cloudflare for serving the application.

## 1. Cloudflare Migration & Sync System
- **CDN Migration (Cloudflare):** Fixed the `update_serving.py` deploy script which was previously sending purge requests to a mock URL instead of the production domain (`serving.arestaclimb.com`). This resolved an issue where the cache was getting stuck in Cloudflare after deployments (`31bab82`).
- **Cache Bypass Fallback:** Implemented a fallback mechanism in the app that detects stale CDN indices (Hash Mismatches) and automatically retries by forcing a cache bypass (`?t=` timestamp parameter) (`31bab82`).
- **Atomic Global Updates:** Implemented atomic global updates with robust offline-first support using TDD (`60f6d72`).
- **Robustness:** Ensured robust sync after breaking changes and prevented protobuf crashes (`3f618f5`).
- **Deployment & Update Flows:** Improved update flows, version locking, and beta store links, including remote config support to redirect iOS users to TestFlight (`b9921bd`).

## 2. Feedback System Enhancements
- **Offline-First & Reliability:** Implemented an atomic file-system queue for feedback submission and improved network stabilization for offline-first support (`5446735`).
- **Refactoring & UI Fixes:** Moved UUID generation to the collector and improved timestamp readability (`9b6640e`). Optimized the feedback box layout, removed unwanted internal scrolling (`46b1482`), and simplified padding (`fd8b1ca`).

## 3. Navigation & Routing
- **Navigator 2.0 Migration:** Refactored routing to use declarative Navigator 2.0 while preserving state (`31c6513`). Integrated TextNode modals into this new routing system (`4fca1bf`).
- **Map/Modal Routing:** Refactored routing specifically for maps and modals (`fb48280`).

## 4. Mapas & UI Enhancements
- **Interactive Maps & v3 Schema:** Integrated interactive "Mapas Gerais" and migrated to the v3 schema (`3f0b0d5`).
- **Architecture Updates:** Migrated map references to a new architecture based on `DatasetResolver` (`cd17f21`).
- **UI & Usability:** Fixed a visual break in the interactive map card badge (`bd9b763`). Improved layout, adaptive colors, and intelligent auto-zoom logic for maps (`86493a9`).
- **Bug Fixes:** Improved context resolution for interactive maps to eliminate warnings (`dd854d4`) and fixed the de-selection of markers in the background, adding coverage scripts (`1bb8c9f`).

## 5. Access System & ESP32-CAM
- **Reliability:** Migrated to a more reliable image reading system for access (`4fdcdf6`).
- **Documentation:** Added a design document for the application's access system (`c4a20ae`) and detailed instructions for using the ESP32-CAM (`d6a6548`).

## 6. Features & Misc
- **SOS Button:** Added an SOS button (`2f493c1`).
- **API & Tests:** Bumped the API version (`fd34795`) and fixed broken tests (`a9380e6`).
- **Cleanup:** Deleted temporary files (`1aa119d`).
