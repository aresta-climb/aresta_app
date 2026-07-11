## Why

Quando o Carrossel de Mapas é aberto, o clique no botão "Mais Info" do cartão flutuante faz um `POP` em vez de um `PUSH` para a tela de Detalhes da Via. Isso ocorre porque o código atual no `MapaInterativoPage` assume que a presença de um `initialSelectedId` (utilizado pelo carrossel para abrir o mapa já focado num ponto) significa que a página anterior era a página de Detalhes da Via. Isso causa um "piscar" na tela e obriga o usuário a clicar duas vezes para ver os detalhes da via quando navegando a partir do carrossel.

## What Changes

- Modifica a lógica do botão `onAction` ("Mais Info") dentro de `_buildEscaladaCard` no arquivo `mapa_interativo.dart`.
- Adiciona o parâmetro `popOnActionIfOriginal` à classe `MapaInterativoPage`, com padrão `true` para retrocompatibilidade.
- Ajusta a instanciação do `MapaInterativoPage` dentro do `_defaultMapBuilder` em `mapas_carrossel.dart` para passar explicitamente `popOnActionIfOriginal: false`, garantindo que a tela da Via seja aberta (PUSH) ao invés de descartar o carrossel (POP).

## Capabilities

### New Capabilities
<!-- Capabilities being introduced. Replace <name> with kebab-case identifier (e.g., user-auth, data-export, api-rate-limiting). Each creates specs/<name>/spec.md -->
Nenhum.

### Modified Capabilities
<!-- Existing capabilities whose REQUIREMENTS are changing (not just implementation).
     Only list here if spec-level behavior changes. Each needs a delta spec file.
     Use existing spec names from openspec/specs/. Leave empty if no requirement changes. -->
- `multi-map-navigation`: A navegação secundária a partir do carrossel agora abrirá os detalhes da via em vez de voltar à origem.

## Impact

- Impacta a página `mapa_interativo.dart`, tornando seu fluxo de ação principal (Mais Info) parametrizável pelo chamador.
- Impacta o `mapas_carrossel.dart`, ajustando-o para usar essa nova parametrização.
- Não introduz dependências externas ou alterações de API severas, sendo apenas uma refatoração de estado de navegação de UI.
