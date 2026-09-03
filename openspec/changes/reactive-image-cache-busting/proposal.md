## Why

Durante o recarregamento em tempo real (*Hot Reload* / *Live Reload* via Editor Desktop, push WebSocket ou download em segundo plano), alterações textuais na interface atualizam instantaneamente, mas imagens modificadas continuam exibindo versões antigas presas na memória de texturas do Flutter (`PaintingBinding.instance.imageCache`). Isso ocorre porque o caminho do arquivo em disco (`FileImage`) e a URL remota (`NetworkImage`) mantêm chaves inalteradas, e os componentes visuais com estado não re-resolvem seus futuros ou ficam retidos em comparações superficiais de igualdade do Protobuf.

Esta proposta elimina essa limitação, assegurando que toda mídia alterada seja refletida na tela imediatamente, de forma determinística, sem cintilação (*flicker*) e preservando estritamente a posição de rolagem do usuário, em conformidade com as diretrizes de engenharia do repositório.

## What Changes

- **Pré-indexação Centralizada $O(1)$ de SHA-256 no Repositório**: O `DatasetRepository` passa a manter uma tabela de dispersão em memória (`caminhoCanônico -> checksumSha256`) indexando as mídias de croquis (`croqui.arquivosExternos`) e as miniaturas de picos (`indice.croquis`).
- **Provedor de Imagem com Invalidação por Hash (`ImagemArquivoAresta`)**:
  - Para arquivos locais: criação da classe `ImagemArquivoAresta` (estendendo `ImageProvider`), cuja chave `ChaveImagemArquivoAresta` embute o `checksumSha256`, provocando invalidação atômica no `ImageCache` do Flutter apenas quando os bytes forem alterados.
  - Para imagens remotas (streaming CDN): anexação obrigatória do parâmetro de versão `?v=<checksumSha256>`, impedindo que caches da CDN ou da memória do aplicativo entreguem imagens defasadas.
- **Auto-resolução no `ProvedorImagemAresta`**: O `ProvedorImagemAresta.resolver` passa a consultar a tabela de dispersão do repositório automaticamente caso o chamador não forneça o hash, desonerando os componentes de interface de buscas manuais.
- **Alinhamento do Ciclo de Vida em Telas com Estado**:
  - `SetorPage` e `GrupoPage`: Re-resolução da imagem de capa (`_coverProviderFuture`) no método `didUpdateWidget` com `setState()`.
  - `MapaInterativoPage` e `MapaThumbnail`: Re-resolução do futuro da imagem do mapa no método `didUpdateWidget` com `setState()`, eliminando a checagem falha de igualdade do Protobuf (`widget.mapa != oldWidget.mapa`) e o código assíncrono legado de `evict()`.
- **Eliminação de Código Frágil de Despejo Manual (`evict()`)**: Remoção de chamadas manuais espalhadas que geravam condições de corrida assíncronas.

## Capabilities

### New Capabilities
- `invalidacao-reativa-cache-imagens`: Invalidação e atualização reativa de imagens locais e remotas com chave versionada por checksum SHA-256 pré-indexado.

### Modified Capabilities

## Impact

- **Componentes de Interface & Mídia**:
  - `frontend/lib/widgets/imagem_arquivo_aresta.dart`: Novo componente modular autossuficiente estendendo `ImageProvider`.
  - `frontend/lib/widgets/provedor_imagem_aresta.dart`: Consulta à tabela de dispersão e cache-busting unificado.
  - `frontend/lib/services/dataset_repository.dart`: Manutenção da tabela de dispersão $O(1)$ de mídias.
  - `frontend/lib/pages/setor.dart`, `frontend/lib/pages/grupo.dart`, `frontend/lib/pages/mapa_interativo.dart`, `frontend/lib/widgets/mapa_thumbnail.dart`: Ciclo de vida atualizado no `didUpdateWidget`.
- **Testes & Documentação**:
  - Criação de testes de widget e de integração para validar a atualização visual ponta a ponta (TDD e 100% de cobertura).
  - Atualização dos arquivos `frontend/HOT_RELOAD.md`, `frontend/lib/README.md` e docstrings detalhadas em português brasileiro.
