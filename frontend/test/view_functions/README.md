# Testes de Funções Utilitárias

Esta pasta contém testes unitários das funções utilitárias compartilhadas entre páginas e serviços da aplicação.

## Arquivos

| Arquivo | Função testada | Descrição |
|---|---|---|
| `common_functions_test.dart` | `safeString`, `isBoulderArea`, `normalizeSearchString` | Testa a conversão segura de valores para string, a detecção de área predominantemente boulder e a normalização de strings de busca. |
| `fuzzy_search_test.dart` | Busca Global | Testa a lógica do Fuzzy Search integrada com a normalização para ignorar acentos e pontuação em pesquisas. |
| `via_functions_test.dart` | `getGrauString`, `getGrauValue` | Testa a extração e formatação do grau de vias em strings e valores numéricos utilizados para ordenação e busca por dificuldade. |
| `browse_functions_test.dart` | `buildBrowseBody`, Interface de Exploração | Testa as funcionalidades da tela de exploração, como a exibição granular do progresso de download (`LinearProgressIndicator`), a renderização da descrição curta do pico e acionamento de telemetria de visualização do pico. |
| `mapa_global_functions_test.dart` | `buildMapaBody`, Interface do Mapa Global | Testa a criação e montagem interativa do Mapa Global, com interações de bottom sheet e navegação. |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/view_functions/

# Um arquivo específico
flutter test test/view_functions/common_functions_test.dart
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
- Formatação de texto para vias esportivas, móveis, boulders e multipitch (`BR_` strips).
- Obtenção do valor numérico (`int`) do enum Protobuf para ordenação de vias por grau de dificuldade de forma consistente.
