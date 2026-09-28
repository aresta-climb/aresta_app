# Testes de Funções Utilitárias

Esta pasta contém testes unitários das funções utilitárias compartilhadas entre páginas e serviços da aplicação.

## Arquivos

| Arquivo | Função testada | Descrição |
|---|---|---|
| `common_functions_test.dart` | `safeString`, `isBoulderArea`, `normalizeSearchString` | Testa a conversão segura de valores para string, a detecção de área predominantemente boulder e a normalização de strings de busca. |
| `fuzzy_search_test.dart` | Busca Global | Testa a lógica do Fuzzy Search integrada com a normalização para ignorar acentos e pontuação em pesquisas. |
| `via_functions_test.dart` | `getGrauString`, `getGrauValue` | Testa a extração e formatação do grau de vias em strings e valores numéricos utilizados para ordenação e busca por dificuldade. |
| `via_functions_widget_test.dart` | Widgets de Vias | Testa a renderização da visualização de via, abas de beta e croqui topográfico. |
| `browse_functions_test.dart` | `buildBrowseBody`, Interface de Exploração | Testa as funcionalidades da tela de exploração, como a exibição granular do progresso de download (`LinearProgressIndicator`), a renderização da descrição curta do pico e acionamento de telemetria de visualização do pico. |
| `home_functions_test.dart` | `buildHomeBody`, Carrossel | Testa a renderização da tela inicial, busca de picos locais e reatividade de download com `ResumoPico`. |
| `pico_functions_test.dart` | Funções de Apoio do Pico | Testa geração de menus, cabeçalho e contagem de vias do pico. |
| `pico_functions_widget_test.dart` | Widgets do Pico | Testa a montagem dos botões e seções da página de pico. |
| `pico_search_online_test.dart` | Busca Online | Testa o fluxo de busca e carregamento de picos sob demanda no servidor. |
| `setor_functions_test.dart` | `resolveRouteLabels`, `buildRouteTile` | Testa resolução fortemente tipada de rótulos com `RotulosVia`, cores oficiais FEMEMG, graus de dificuldade e decomposição modular de itens de lista. |
| `grupo_functions_test.dart` | Grupos de Setores | Testa a renderização e consolidação quantitativa de vias em grupos de setores. |
| `meus_croquis_functions_test.dart`| Gestão de Croquis Salvos | Testa as ações de remoção, exibição de tamanho e status de croquis baixados. |
| `comunidade_functions_test.dart` | Hub Comunitário | Testa a montagem de links de redes sociais, canais Discord e grupos WhatsApp. |
| `sobre_time_functions_test.dart` | `carregarMembrosTime`, `buildTeamMemberCard` | Testa o carregamento tipado de membros (`MembroTime`) e a renderização dos cartões no Sobre Nós. |
| `settings_functions_test.dart` | Configurações e Dev Mode | Testa a validação de QR Code, conexão com o Editor Desktop e alternância de temas. |
| `offline_markdown_test.dart` | Visualizador Offline | Testa a interceptação de imagens embutidas em Markdown para leitura direta do sistema de arquivos local. |
| `mapa/mapa_global_functions_test.dart` | `buildMapMarkers`, `obterFaixaZoom`, Interface do Mapa Global | Testa a criação e montagem interativa do Mapa Global, resolução de faixas de zoom (Macro, Regional, Local), com interações de bottom sheet e navegação. |
| `mapa/mapa_marker_test.dart` | `createCustomMarkerBitmap`, `createCustomMarkerBitmapWithText`, `calcularDimensoesMarcador` | Testa a geração de bitmaps customizados de marcadores com redimensionamento proporcional, truncamento automático de nomes extensos e resiliência de buffers de GPU. |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/view/function_library/

# Um arquivo específico
flutter test test/view/function_library/common_functions_test.dart
```

## Funções cobertas

### `safeString(dynamic value, {String fallback})`
Converte qualquer valor para `String` de forma segura. Retorna o `fallback` (padrão `''`) quando o valor for `null`.

**Casos testados:**
- String normal
- `null` com fallback padrão
- `null` com fallback customizado
- Número inteiro
- Boolean

### `isBoulderArea(List<Escalada> escaladas)`
Determina se uma lista de escaladas é predominantemente de boulders (≥ 50%).

**Casos testados:**
- Lista vazia → `false`
- Maioria boulder → `true`
- Minoria boulder → `false`
- Todas boulder → `true`
- Nenhum boulder → `false`
- Empate 50% → `true`
- Tipo `viaMovel` (não-boulder) → contabilizado corretamente

### `normalizeSearchString(String value)`
Remove acentos e caracteres não-padrão (diacríticos) de uma string e a converte para minúsculas. Usado intensivamente na pesquisa global.

**Casos testados:**
- Conversão para minúsculas
- Remoção de todos os acentos comuns (á, ã, ç, etc.)
- String vazia
- Conservação de números e alguns caracteres especiais

### Lógica de Fuzzy Search (Busca Global)
Testa se a integração do pacote `fuzzy` com a função `normalizeSearchString` fornece pesquisas tolerantes a erros ortográficos e acentuação, priorizando os matches no título (`weight: 1.0`) antes do subtítulo (`weight: 0.5`).

### `getGrauString` e `getGrauValue`
Funções utilitárias usadas para extrair informações de dificuldade das vias.
**Casos testados:**
- Formatação de texto para vias esportivas, móveis, boulders e multienfiadas (`BR_` strips).
- Obtenção do valor numérico (`int`) do enum Protobuf para ordenação de vias por grau de dificuldade de forma consistente.

### `resolveRouteLabels(Escalada via)` e `RotulosVia`
Extrai e formata os metadados de uma via em um modelo fortemente tipado `RotulosVia`.
**Casos testados:**
- Rótulo principal formatado com grau e extensão.
- Rótulos secundários de atributos (conquistadores, proteções, estilo).
- Atribuição de cores padronizadas da FEMEMG conforme o tipo de escalada.
- Decomposição em funções puras sem aninhamentos condicionais profundos.

### `carregarMembrosTime()` e `MembroTime`
Carrega e mapeia a lista estática da equipe do projeto utilizando o modelo imutável `MembroTime`.
**Casos testados:**
- Mapeamento correto de nome, papel e links de contato.
- Imutabilidade e validação de consistência dos dados do time.
