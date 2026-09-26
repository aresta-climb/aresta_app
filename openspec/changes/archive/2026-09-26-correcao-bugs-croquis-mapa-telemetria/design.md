## Context

Consulte `proposal.md` para a motivação detalhada dos problemas corrigidos.
O aplicativo possui serviços centrais consolidados para persistência e rede:
- `DatasetRepository`: orquestrador de croquis que gerencia a hierarquia de quatro etapas (RAM, permanente `/downloads`, volátil `/temp_cache`, e CDN remoto).
- `ProvedorImagemAresta`: provedor de imagens em camadas que assegura resolução prioritária local, cache volátil indexado por SHA-256 e download via CDN com gravação atômica em disco.
- `TelemetryService` e `AppLogger`: serviços de telemetria analítica e observabilidade de erros estruturados.

Esta arquitetura técnica define como esses serviços centrais assumem a responsabilidade integral nas interfaces de catálogo, navegação e mapas, eliminando lógicas ad-hoc de arquivos e contornando as limitações de hit-testing do SDK nativo do Google Maps.

## Goals / Non-Goals

**Goals:**
- Eliminar 100% dos falsos positivos de seleção no Mapa Global quando picos estão geograficamente próximos, mantendo a legibilidade dos nomes no zoom local.
- Unificar a resolução de croquis e capas no `DatasetRepository` e `ProvedorImagemAresta`, garantindo os fallbacks canônicos de cache e rede.
- Garantir que falhas de abertura de links externos em `comunidade.dart` e `sobre_time.dart` sejam capturadas e logadas no `AppLogger`, mesmo quando `launchUrl` retornar `false` sem lançar exceções.
- Manter 100% de cobertura de testes unitários e de widget, seguindo estritamente TDD.

**Non-Goals:**
- Substituir o pacote `google_maps_flutter` por outra biblioteca de mapas.
- Alterar o design visual ou temas das páginas de Comunidade e Sobre o Time.
- Modificar contratos de API ou esquemas Protobuf existentes.

## Decisions

### Decisão 1: Desacoplamento de Marcadores em Dois `Marker`s no Zoom Local

No Google Maps nativo, todo marcador é tratado como uma textura retangular única e seu hitbox é a bounding box (AABB) da imagem.
Para preservar o balão de texto no zoom local (`zoom >= 9.0`) sem que suas laterais transparentes capturem toques indevidos:
- **Pino Principal (`id`)**: Gerado com `createCustomMarkerBitmap` (85x85px). O bitmap não possui nenhuma asa lateral vazia. Âncora configurada na ponta da agulha (`Offset(0.5, 0.94)`), `zIndex: 2.0` e `onTap` ativo que exibe o `showCragModal`.
- **Rótulo Textual (`${id}_rotulo`)**: Gerado por `createCustomMarkerLabelBitmap` contendo estritamente o balão preto e o texto centralizado (ex: 180x32px, sem pino embaixo). Posicionado com âncora vertical deslocada para cima (ex: `Offset(0.5, 3.2)`), `zIndex: 1.0` e `consumeTapEvents: false` (pass-through).

*Alternativas consideradas:*
- *Hitbox única com balão embutido*: Mantém o bug de área transparente colidindo com picos vizinhos. Rejeitada.
- *Remover balão de texto e exibir nome apenas em card inferior*: Perderia a visão panorâmica com nomes no zoom local desejada pelo usuário. Rejeitada.

### Decisão 2: Centralização de Resolução de Croquis e Capas no `DatasetRepository` e `ProvedorImagemAresta`

Em `extrator_metadados_croqui.dart`, substituímos as leituras manuais de arquivos `File('$downloadsPath/...')` e buscas recursivas em disco:
- O croqui é obtido diretamente via `DatasetRepository.getCroqui(id)` (ou resolver injetado), herdando automaticamente os 4 estágios de fallback: RAM ➔ `/downloads/<id>/compilado.binarypb` (com *lazy rename*) ➔ `/temp_cache/<id>/compilado.binarypb.<sha256>` ➔ CDN remoto.
- A resolução de capas e fotos é delegada ao `ProvedorImagemAresta.resolver`, eliminando código duplicado de listagem de diretórios.

*Alternativas consideradas:*
- *Duplicar a lógica de fallbacks e requisições HTTP dentro de `ExtratorMetadadosCroqui`*: Viola DRY e o princípio de Simplicidade. Rejeitada.

### Decisão 3: Verificação de Retorno `bool` em `launchUrl` e Telemetria Completa

Abertura de URLs externas via `url_launcher` retorna um booleano:
```dart
final sucesso = await launchUrl(uri, mode: LaunchMode.externalApplication);
if (!sucesso) {
  AppLogger.instance.logError('Falha ao abrir aplicativo para $nomeServico ($url)');
}
```
Adicionalmente, restabelecemos as chamadas de telemetria nos eventos de toque em cards institucionais de `comunidade.dart` (card "Sobre o Time" e modal de Termos) e nos botões de membros em `sobre_time.dart`.

### Decisão 4: Suporte a `capaPath` e Checksums em `CragCard`

O widget `CragCard` e seu auxiliar `_CragBackgroundWidget` são atualizados para:
1. Extrair prioritariamente `capaPath` (caminho local da imagem resolvido pelo extrator para picos baixados).
2. Se ausente, utilizar `thumbnailUrl` ou `'thumbnails/$id.webp'`.
3. Repassar sempre `checksumSha256Thumbnail` (de `MetadadosIndice`) ou `checksum` (de `ResumoPico`) ao `ProvedorImagemAresta.resolver` com largura alvo de 300px.
4. Eliminar qualquer desvio para `NetworkImage` sem cache.

## Risks / Trade-offs

- **[Carga de Marcadores no Zoom Local]** → O desacoplamento dobra a quantidade de marcadores no zoom local (1 marcador de pino + 1 marcador de rótulo por pico visível).
  - *Mitigação*: Isso ocorre apenas na faixa `FaixaZoomMapa.local` (zoom >= 9.0), onde o frustum da câmera abrange uma área geográfica muito menor, contendo tipicamente menos de 20 picos visíveis. Nas faixas macro e regional, apenas 1 marcador compacto é renderizado. Bitmaps desacoplados são menores e consomem menos memória de textura da GPU que o antigo canvas unificado de 240px.
- **[Compatibilidade de Testes Existentes]** → Mocks e testes de widget que verificavam a contagem exata de `markers` no mapa precisarão validar o pino e o rótulo desacoplado na faixa local.
  - *Mitigação*: Atualização sistemática dos testes em `mapa_global_test.dart` e `mapa_global_functions_test.dart` refletindo a nova semântica.
