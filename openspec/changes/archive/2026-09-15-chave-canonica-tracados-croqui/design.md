## Context

Ver `proposal.md` para motivação e `specs/tracados-vetoriais-app/spec.md` para os requisitos. Atualmente, `ConstrutorCaminhoTrajeto` mantém caches estáticos em memória indexados apenas por `ponto.id`. Como IDs como `linha_1` e `linha_2` se repetem em diversos mapas de um mesmo pico, o cache é contaminado com a geometria do primeiro mapa renderizado.

## Goals / Non-Goals

**Goals:**
- Renderização 100% determinística de traçados vetoriais em qualquer celular, independentemente da ordem de navegação ou telas visitadas anteriormente.
- Isolamento total entre páginas adjacentes do carrossel de fotos (`MapasCarrosselPage`), mantendo 60/120 FPS sem recálculo desnecessário de CPU durante gestos de swipe.
- Eliminação estrita de fallbacks ambíguos: `chaveCache` torna-se obrigatória em `AreaHelper.getAreaInfo`, com atualização integral de todos os testes unitários legados.
- Higiene e liberação de memória em eventos macro de ciclo de vida (saída do pico ou atualização de croqui).

**Non-Goals:**
- Não alterar os esquemas de dados Protobuf (`croqui.proto`) nem os arquivos de banco de dados (`compilado.yaml` / `compilado.binarypb`).
- Não limpar o cache a cada transição de via ou swipe de carrossel, preservando a vida útil da bateria e a taxa de quadros (60/120 FPS).

## Decisions

### Decisão 1: Formato da Chave Canônica Composta (`"${caminhoImagemMapa}#${ponto.id}"`)
- **Abordagem**: Utilizar a concatenação do caminho relativo da imagem do mapa com o ID do ponto de interesse: `"${mapa.caminhoImagemMapa}#${ponto.id}"`.
- **Racional**:
  - `caminhoImagemMapa` (ex: `imagens/setor_fugitivos_i_p0.webp`) é único para cada foto no pico.
  - `ponto.id` é único dentro de cada mapa.
  - Juntos, formam uma chave primária composta natural, leve ($\approx 35\text{--}45$ caracteres), com custo $O(1)$ de comparação e hashing em Dart.
- **Alternativas consideradas**:
  - *Hashing do conteúdo do SVG*: Rejeitado pelo risco de custo de hashing e alocação de strings longas em SVGs densos.
  - *Apenas limpar o cache ao sair de cada tela*: Rejeitado porque não soluciona o carrossel de fotos (onde fotos 1 e 2 coexistem no `PageView`) e aumentaria significativamente o consumo de CPU e bateria em navegações frequentes.

### Decisão 2: Eliminação Estrita de Fallbacks em `AreaHelper.getAreaInfo`
- **Abordagem**: A assinatura do método torna-se:
  ```dart
  static AreaInfo? getAreaInfo(
    Mapa_PontoDeInteresse ponto, {
    required String chaveCache,
  })
  ```
- **Racional**: Adesão inegociável ao Princípio VI de `AGENTS.md` (Simplicidade e Anti-Abstração) e à diretriz explícita do usuário. Sem fallbacks para `ponto.id`. Erros de contexto devem ser identificados em tempo de compilação.
- **Alternativas consideradas**: Fallback automático para `ponto.id` se `chaveCache` fosse nula. Rejeitado por mascarar potenciais regressões em novas telas.

### Decisão 3: Chave Canônica no Cache de Viewport do `MarkerPainter`
- **Abordagem**: O `MarkerPainter` recebe a `chaveCache` composta obrigatória e indexa o cache de viewport com:
  ```dart
  final cacheKeyViewport = '${chaveCache}_${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}';
  ```
- **Racional**: Garante que o caminho com tracejado aplicado em dp de tela pertença estritamente à imagem e dimensão correspondentes, mesmo que duas fotos tenham o mesmo aspect ratio ou resolução de viewport.

### Decisão 4: Higiene de Memória Macro
- **Abordagem**: Disparar `ConstrutorCaminhoTrajeto.limparCache()` em eventos de descarte macro:
  1. Ao sair do contexto de um Pico para a listagem geral (`AppNav.toBrowse` e `AppNav.home`).
  2. Ao finalizar download ou atualização de croqui (`DatasetRepository.updateDatasetAfterDownload`).
  3. No descarte / esvaziamento de dados (`DatasetRepository.loadEmpty`).
- **Racional**: Libera instâncias de `Path` quando o usuário encerra o uso daquele maciço rochoso, sem degradar a performance de pan, zoom e swipe enquanto o usuário estiver escalando e consultando vias no mesmo pico.

## Risks / Trade-offs

- **[Risco] Atualização em lote de testes unitários existentes**
  → *Mitigação*: Mapear e atualizar todas as invocações de `AreaHelper.getAreaInfo` em `test/pages/mapa_interativo_test.dart` para fornecer a chave composta no padrão `'caminho_teste#id'`, assegurando 100% de cobertura e zero quebras.
- **[Trade-off] Acúmulo temporário de caminhos durante a exploração de múltiplos setores de um pico grande**
  → *Mitigação*: Instâncias de `Path` são leves ($\approx 1\text{--}4$ KB). Mesmo em picos com mais de 200 vias, o consumo total do cache permanece abaixo de 1 MB, sendo totalmente purgado ao retornar para a listagem de picos.
