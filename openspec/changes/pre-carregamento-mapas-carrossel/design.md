## Context

Atualmente a `MapasCarrosselPage` delega a renderização de múltiplos mapas a um `PageView.builder`, instanciando cada `MapaInterativoPage` somente quando o usuário navega para a página correspondente. O download das imagens da CDN ocorre sob demanda para cada página. Quando o usuário está na rocha com sinal fraco ou intermitente, abrir um croqui permite visualizar a primeira página, mas avançar para as páginas subsequentes pode falhar ou demorar se não houver mais conexão com a internet.

Veja `proposal.md` para a motivação detalhada.

## Goals / Non-Goals

**Goals:**
- Realizar o download assíncrono em segundo plano de todas as páginas subsequentes do carrossel da internet para o cache em disco local (`temp_cache`) assim que o mapa interativo for aberto.
- Garantir que todas as imagens do carrossel fiquem persistidas em disco para viabilizar navegação instantânea e 100% offline.
- Executar o download de forma não-bloqueante via `WidgetsBinding.instance.addPostFrameCallback` para priorizar a renderização do mapa ativo na tela.
- Manter resiliência total: falhas de download individuais (ex.: conexão perdida) não devem lançar exceções não tratadas ou interferir na visualização do mapa atual.
- Reutilizar instâncias de `ImageProvider` já resolvidas repassando-as como `imageProviderOverride` para `MapaInterativoPage`.

**Non-Goals:**
- Restringir o pré-carregamento por orçamentos artificiais de memória RAM (a retenção em RAM e eventuais evictions de LRU em memória são independentes da persistência em disco).
- Baixar imagens de outros picos ou setores não pertencentes ao carrossel atualmente aberto.

## Decisions

### 1. Download de Todas as Imagens do Carrossel para Cache em Disco
- **Decisão**: Ao abrir `MapasCarrosselPage`, o sistema iterará por todos os itens de `widget.mapas` invocando `ProvedorImagemAresta.resolver(picoId: widget.cragId, caminho: item.mapaCaminhoImagem)`.
- **Racional**:
  - A camada de cache do `ProvedorImagemAresta` já verifica se a mídia existe no armazenamento local permanente (`/downloads`) ou no cache temporário volátil (`/temp_cache`).
  - Caso o arquivo não esteja no disco, `ProvedorImagemAresta._baixarESalvarNoCache` realiza o streaming remoto da CDN e persiste o arquivo de forma atômica no diretório `temp_cache` em disco.
  - A deduplicação nativa via `_downloadsEmAndamento` impede downloads concorrentes repetidos para o mesmo arquivo.
  - O espaço em disco é mais do que suficiente para armazenar todas as páginas de um mapa de setor, eliminando qualquer dependência de sinal de internet após a primeira abertura.

### 2. Disparo Assíncrono Não-Bloqueante via `addPostFrameCallback`
- **Decisão**: O agendamento da rotina de download `_preCarregarImagensNoDisco` é registrado no callback `WidgetsBinding.instance.addPostFrameCallback`.
- **Racional**: Garante que o Flutter renderize o primeiro quadro do mapa ativo com fluidez total (60/120 FPS) antes de iniciar as requisições de download I/O em segundo plano.

### 3. Reutilização de Provedores Resolvidos no `_defaultMapBuilder`
- **Decisão**: Manter um mapa em memória `Map<String, ImageProvider> _provedoresResolvidos` na `MapasCarrosselPage`. Ao construir `MapaInterativoPage`, injeta-se o provedor resolvido via `imageProviderOverride`.
- **Racional**: Se o usuário avançar para a página cujo download já terminou, o `MapaInterativoPage` recebe diretamente o `ImageProvider` pronto (apontando para o arquivo em disco), sem novo ciclo assíncrono de busca.

## Risks / Trade-offs

- **[Risco] O usuário fecha a tela antes da conclusão de todos os downloads**:
  - *Mitigação*: A persistência atômica no disco de cada arquivo é gerenciada pelo `_baixarESalvarNoCache`. Na `MapasCarrosselPage`, verificações de `if (!mounted) return;` antes de atualizar estados de UI evitam `setState` após descarte.
- **[Risco] Falha temporária de rede durante o download em segundo plano**:
  - *Mitigação*: O loop de download em segundo plano captura exceções individualmente com log informativo/aviso, permitindo que as páginas já baixadas permaneçam válidas e que tentativas futuras ocorram se o usuário navegar.

## Migration Plan

1. Adicionar testes unitários e de widget em `mapas_carrossel_test.dart` simulando carrossel com múltiplos mapas e verificando o acionamento do download para disco de todas as páginas.
2. Implementar a rotina `_preCarregarImagensNoDisco` em `_MapasCarrosselPageState`.
3. Validar a passagem de todos os testes unitários e de widget.

