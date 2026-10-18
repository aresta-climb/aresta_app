# Spec Delta

## MODIFIED Requirements

### Requirement: Descompactação de Primeiro Acesso
O sistema MUST (DEVE) empacotar no script de preload (`tool/sync_preload.dart`) e descompactar no primeiro acesso (`ExtratorAssetsPreload`) o banco SQLite `catalogo.db` juntamente com o `indice.binarypb` e as thumbnails pré-baixadas para o diretório de documentos local do dispositivo.

#### Scenario: Instalação nova sem internet
- **WHEN** o usuário instala e abre o app pela primeira vez sem internet
- **THEN** o app copia `assets/preload/indice.binarypb`, `assets/preload/catalogo.db` e `assets/preload/thumbnails/*.webp` para o diretório de documentos local, permitindo tanto a visualização do mapa inicial quanto a Busca Global em todo o catálogo offline imediatamente.
