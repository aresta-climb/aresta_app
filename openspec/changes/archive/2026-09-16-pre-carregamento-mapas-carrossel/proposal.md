## Why

Ao visualizar setores ou picos que possuem múltiplos mapas interativos organizados em carrossel (`MapasCarrosselPage`), o download de cada mapa ocorre sob demanda apenas no instante em que o usuário avança para a respectiva página. Como os escaladores frequentemente utilizam o aplicativo em locais com sinal de internet instável ou inexistente na rocha, abrir a primeira página de um croqui sem pré-baixar as demais faz com que a navegação para as páginas seguintes falhe ou fique travada aguardando rede.

O objetivo central desta melhoria é garantir que, assim que um setor ou mapa interativo for aberto, o sistema baixe em segundo plano todas as demais páginas de mapa daquele setor *da internet diretamente para o cache em disco local* (`temp_cache`), com três propriedades fundamentais:
1. **Idempotente**: se a mídia já existir em disco (`/downloads` ou `/temp_cache`), a operação retorna imediatamente sem requisições adicionais.
2. **Deduplicado**: se houver download em andamento da mesma imagem, a requisição é reutilizada prevenindo tráfego redundante.
3. **Leve**: grava diretamente os bytes brutos no disco sem decodificar bitmaps na GPU/RAM e sem tocar no `ImageCache` do Flutter, economizando bateria, CPU e prevenindo *cache eviction* de texturas ativas.

## What Changes

- **Novo Método Estático em `ProvedorImagemAresta`**:
  - Implementação de `ProvedorImagemAresta.preCarregarNoDisco({required String picoId, required String caminho, ...})`, retornando `Future<File?>`. O método garante a persistência atômica da imagem em disco sem instanciar bitmaps nem registrar no `PaintingBinding.instance.imageCache`.
- **Pré-download no Setor (`MapaThumbnail`)**:
  - Ao renderizar a miniatura do mapa de um setor com múltiplos mapas (`widget.mapas.length > 1`), o widget agenda o pré-download em disco das páginas seguintes (índice 1 em diante) em segundo plano. Enquanto o escalador lê a descrição e vias do setor, as demais páginas já estão sendo gravadas localmente.
- **Pré-download Complementar no Carrossel (`MapasCarrosselPage`)**:
  - Disparo de garantia complementar via `WidgetsBinding.instance.addPostFrameCallback` ao abrir o carrossel, cobrindo eventuais acessos diretos (como atalhos de rotas ou deep links) para garantir que todas as páginas estejam no disco.
- **Testes Unitários e de Widget**:
  - Testes em `frontend/test/widgets/provedor_imagem_aresta_test.dart` cobrindo o método `preCarregarNoDisco` e suas propriedades de idempotência e ausência de decodificação em RAM.
  - Testes em `frontend/test/widgets/mapa_thumbnail_test.dart` verificando o disparo do pré-download das páginas subsequentes ao carregar o setor.
  - Testes em `frontend/test/pages/mapas_carrossel_test.dart` verificando a integridade do carrossel e o download de páginas complementares.

## Capabilities

### New Capabilities

### Modified Capabilities
- `interactive-map`: Adiciona o requisito de pré-download em disco de páginas adicionais de mapas tanto ao abrir o setor quanto ao abrir o carrossel de mapas, através de método dedicado, idempotente e leve em `ProvedorImagemAresta`.

## Impact

- **Código Afetado**: `frontend/lib/widgets/provedor_imagem_aresta.dart`, `frontend/lib/widgets/mapa_thumbnail.dart`, `frontend/lib/pages/mapas_carrossel.dart` e seus respectivos arquivos de teste em `frontend/test/`.
- **Dependências / APIs**: Utiliza a infraestrutura de download atômico existente de `ProvedorImagemAresta`.
- **Ruptura**: Nenhuma alteração com quebra de compatibilidade (Non-breaking).

