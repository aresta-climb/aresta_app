## Context

A API de navegação atual (`AppNav` / `TreeNavigationController`) utiliza identificadores (strings) em seus nós e realiza o binding (tradução de string para objeto Protobuf em memória) logo antes da renderização da página através do `PageListenableBuilder`. 
Com a breaking change no banco de dados, o `Mapa` passou a ser o "dono" da representação de localização das entidades, não mais as escaladas. Agora o mapa lista `referencias` (nomes de grupo, setor e escalada + lista de IDs geométricos).

## Goals / Non-Goals

**Goals:**
- Prover um mecanismo determinístico de `id` (POI no SVG) -> Entidade (Grupo, Setor, Escalada) sem iterar todo o Protobuf no frame de renderização do mapa.
- Substituir a propriedade `initialSelectedId` do mapa por um roteamento focado no TargetContext (grupo, setor, escalada), uma vez que a página de origem não sabe mais em qual ID ela está localizada.
- Habilitar links entre mapas (botão "Ir para Setor", abrir mapa de outro setor).
- Implementar o parâmetro `indice_mapa_padrao` nas entidades de escalada, setor e grupo (via Protobuf backend) para permitir foco num mapa principal.
- Garantir a confiabilidade da nova camada através de Test-Driven Development (TDD) cobrindo os novos trechos com 100% de testes unitários.

**Non-Goals:**
- Não mudaremos o mecanismo de renderização do SVG da imagem neste momento, apenas a camada lógica e os painéis/cards ao redor da imagem.

## Decisions

1. **DatasetResolver:** 
A lógica de varredura que hoje vive no método `build` do `PageListenableBuilder` será abstraída em uma classe utilitária (ex: `DatasetResolver`). Essa classe será testável isoladamente e receberá parâmetros explícitos `(Pico, grupoNome, setorNome, escaladaNome)` e retornará referências aos objetos em memória (custo O(1) sem alocações extras).

2. **Merge de Contexto Implícito:**
As referências dentro do Protobuf do Mapa são intencionalmente enxutas (uma escalada dentro do mesmo setor não precisa repetir a string do setor). Antes da UI tentar resolver, faremos um merge da Referência com o contexto atual da árvore de navegação para gerar a tríade `(grupo, setor, escalada)` explícita de busca.

3. **Indexação One-Time:**
O widget do Mapa precomputará os acessos no momento que carrega (`initState` / hook de reação):
- `Map<String, List<Referencia>>`: para múltiplos caminhos passarem pelo mesmo POI geométrico.
- `Map<Referencia, ResolvedReference>`: o resultado das validações, garantindo acesso ultra rápido ao toque.
Se houver algum Ponto de Interesse (POI geométrico) desenhado no mapa que não estiver sendo apontado por nenhuma referência da lista (não aparece no mapeamento de ID para referências), esse ponto específico simplesmente não será desenhado na tela (ficará invisível), para não confundir o usuário. A responsabilidade de avisar o autor sobre POIs órfãos passará para o linter de compilação do backend. As referências que não puderem ser resolvidas pelo DatasetResolver (dangling) simplesmente serão ignoradas para não invalidar todo o desenho.

4. **Cartões Contextuais Dinâmicos:**
Baseado no `ResolvedReference` clicado, a interface lançará os cartões: Card de Escalada, Card de Setor ou Card de Grupo. Cada um terá CTAs acoplados diretamente às funções de `AppNav`.

5. **indice_mapa_padrao (Adição no croqui.proto):**
Entidades como escalada, setor ou grupo devem poder declarar o seu mapa "oficial". Se uma entidade tiver este índice preenchido, a ação "Ver no Mapa" o usará; se não, usará o fallback do primeiro mapa do setor contendo ela. Adicionaremos um linter abrangente para o build no `aresta_db`.

## Risks / Trade-offs

- **[Risk] Perda de performance na criação do mapa.** -> A indexação (`DatasetResolver`) vai percorrer partes do pico, mas os dicionários de cache no `initState` diluirão o custo computacional, evitando recálculos em cada toque/pinch.
- **[Risk] Lixo no editor gerando crashes.** -> O map de referências ativas permite ignorar IDs que já não existem no mapa real ou entidades renomeadas. O fallback (cor cinza) mitiga exceções e atua como self-heal informacional.
