## Why

Ao visualizar setores ou picos que possuem múltiplos mapas interativos organizados em carrossel (`MapasCarrosselPage`), o download de cada mapa ocorre sob demanda apenas no instante em que o usuário avança para a respectiva página. Como os escaladores frequentemente utilizam o aplicativo em locais com sinal de internet instável ou inexistente na rocha, abrir a primeira página de um croqui sem pré-baixar as demais faz com que a navegação para as páginas seguintes falhe ou fique travada aguardando rede.

O objetivo central desta melhoria é garantir que, assim que o mapa interativo for aberto (renderizando a primeira imagem), o sistema baixe em segundo plano todas as outras páginas do mapa *da internet diretamente para o cache em disco local* (`temp_cache`). Dessa forma, toda a sequência de páginas do croqui fica imediatamente disponível em disco, tornando a navegação ágil e 100% utilizável offline.

## What Changes

- **Pré-download em Segundo Plano para Cache em Disco na `MapasCarrosselPage`**:
  - Disparo de rotina não-bloqueante via `WidgetsBinding.instance.addPostFrameCallback` logo após a renderização inicial da página ativa.
  - Iteração sobre todas as páginas do carrossel (`widget.mapas`), acionando `ProvedorImagemAresta.resolver(picoId: widget.cragId, caminho: item.mapaCaminhoImagem)`.
  - O `ProvedorImagemAresta` se encarrega de verificar o armazenamento local e, para qualquer imagem ainda não baixada, realizar o download atômico da CDN persistindo-a no cache em disco (`temp_cache`).
  - Como o foco é a persistência em disco local, o download de todas as páginas do carrossel é garantido independentemente de limites ou descarte de bitmaps em memória RAM.
  - Reutilização dos `ImageProvider`s pré-resolvidos no `_defaultMapBuilder` via `imageProviderOverride` para transições instantâneas entre páginas.
- **Testes de Widget e Unidade**:
  - Testes em `frontend/test/pages/mapas_carrossel_test.dart` validando que todas as páginas do carrossel são disparadas para download/resolução em disco em segundo plano, sem bloquear a exibição do mapa ativo, com tratamento resiliente a falhas de rede.

## Capabilities

### New Capabilities

### Modified Capabilities
- `interactive-map`: Adiciona o requisito de download assíncrono em segundo plano de todas as páginas subsequentes de mapas em carrossel da internet para o cache em disco local (`temp_cache`).

## Impact

- **Código Afetado**: `frontend/lib/pages/mapas_carrossel.dart` e `frontend/test/pages/mapas_carrossel_test.dart`.
- **Dependências / APIs**: Utiliza a infraestrutura de download e cache em disco já existente de `ProvedorImagemAresta.resolver`.
- **Ruptura**: Nenhuma alteração com quebra de compatibilidade (Non-breaking).
