# Widgets e Componentes Reutilizáveis — Aresta Climb

Este diretório reúne os componentes visuais e utilitários de interface compartilhados por todo o aplicativo, estruturados segundo o princípio **Feature-First / Componentes Independentes** (Diretriz II do `AGENTS.md`).

---

## 1. Módulos de Imagem e Cache em Disco

### `ProvedorImagemAresta` (`provedor_imagem_aresta.dart`)
Fachada unificada e assíncrona para resolução e exibição de imagens em todo o ecossistema do Aresta Climb. Elimina dependências de pacotes externos pesados de cache HTTP e implementa persistência direta no sistema de arquivos do dispositivo.

#### Pipeline de Resolução em Três Camadas:
1. **Armazenamento Local Permanente (`/downloads` ou `/thumbnails`)**:
   - Mídias de croquis baixados offline pelo usuário ou miniaturas persistentes.
   - Retorna uma instância de `ImagemArquivoAresta`.
2. **Cache Volátil Endereçado por Conteúdo (`/temp_cache`)**:
   - Verifica se o arquivo já foi baixado previamente em sessões online sob o padrão `<temp_cache>/<picoId>/<caminho>.<hash>` (ou `<temp_cache>/thumbnails/<picoId>.webp.<hash>` para miniaturas de catálogo).
   - Se encontrado no disco, resolve imediatamente como `ImagemArquivoAresta`, evitando qualquer consumo de banda ou requisições HTTP.
3. **Download Atômico da CDN e Persistência Volátil**:
   - Caso a mídia não exista localmente, realiza o streaming HTTP a partir da URL base da CDN (`serverBase`).
   - **Exigência de SHA-256**: O checksum SHA-256 é obrigatório para persistência em disco. Se ausente no índice/croqui, emite log de erro no `AppLogger` e recorre a `NetworkImage` sem gravar no disco.
   - **Gravação Atômica**: Grava em arquivo temporário `.tmp` e aplica renomeação atômica para o arquivo final com extensão `.<hash>`.
   - **Expurgo de Versões Obsoletas**: Ao salvar com sucesso uma nova versão, varre o diretório pai e remove arquivos anteriores da mesma mídia que possuam hashes divergentes, evitando acúmulo de lixo.
   - **Deduplicação de Requisições Concorrentes**: Mantém um mapa em memória (`_downloadsEmAndamento`) indexado pelo caminho de destino. Múltiplos widgets solicitando a mesma imagem concorrentemente compartilham o mesmo `Future`, disparando apenas uma requisição HTTP real.
4. **Downsampling Opcional na Decodificação**:
   - Caso `larguraAlvo` ou `alturaAlvo` sejam informados, encapsula o provedor resultante com `ResizeImage.resizeIfNeeded`.
   - Utilizado de forma padronizada (`larguraAlvo: 300`) em cartões de picos (`OfflineCragCard`), fundos de lista (`_CragBackgroundWidget`) e carrosséis.

---

### `ImagemArquivoAresta` (`imagem_arquivo_aresta.dart`)
Extensão customizada de `FileImage` que incorpora o `checksumSha256` na chave de igualdade (`operator ==` e `hashCode`).
- **Garantia de Cache-Busting**: Quando o conteúdo de uma imagem é alterado no servidor ou via Live Reload, a alteração do checksum invalida a textura no `ImageCache` do Flutter automaticamente.
- **Fallback Dinâmico**: Se o arquivo for modificado localmente e não possuir SHA-256 explícito, recorre ao timestamp de modificação `lastModifiedSync` para invalidar a chave na memória.

---

## 2. Componentes de Navegação e Modos Operacionais

| Widget | Responsabilidade |
|---|---|
| `BannerModoExperimental` | Faixa fixa no topo da interface durante o Modo de Desenvolvimento/Live Reload, exibindo tempo restante e animação de pulso ao receber atualizações via WebSocket. |
| `BannerModoOnline` | Alerta visual discreto indicando navegação em croqui sob demanda (sem download offline completo). |
| `ModalConfirmacaoSaida` | Diálogo de confirmação que impede a perda de dados ou saída acidental de telas de exploração. |
| `NearbyCragsCarousel` | Carrossel horizontal de picos próximos com miniaturas otimizadas. |
| `MapaThumbnail` | Visualização estática leve de mapa vetorial/satélite para pré-visualização rápida de setores. |
| `GlobalSearch` | Barra unificada de busca textual por picos, setores e vias. |
