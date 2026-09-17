## Context

Ao visualizar setores com múltiplos mapas ou carrosséis de croquis (`MapasCarrosselPage`), o download de cada imagem ocorre tradicionalmente sob demanda no momento em que a página é exibida. Na escalada ao ar livre, a conexão celular costuma ser oscilante ou inexistente na rocha. Baixar previamente as imagens para o disco enquanto o usuário lê o setor ou visualiza o primeiro mapa garante que todo o croqui esteja disponível offline.

Veja `proposal.md` para a motivação detalhada.

## Goals / Non-Goals

**Goals:**
- Criar o método `ProvedorImagemAresta.preCarregarNoDisco` com as três propriedades basilares: Idempotente, Deduplicado e Leve (sem instanciar bitmaps nem tocar no `ImageCache` da RAM).
- Disparar o pré-download em disco no **Setor** (`MapaThumbnail`) para todas as páginas subsequentes (a partir do índice 1) assim que a miniatura for exibida.
- Disparar o pré-download de garantia complementar no **Carrossel** (`MapasCarrosselPage`) para cobrir eventuais acessos diretos.
- Garantir que a persistência em disco ocorra de forma não-bloqueante e resiliente a falhas temporárias de rede.

**Non-Goals:**
- Decodificar antecipadamente imagens na GPU/RAM via `precacheImage` (evitando consumo desnecessário de CPU, bateria e pressão de memória).
- Baixar imagens de outros picos ou setores não relacionados ao contexto ativo.

## Decisions

### 1. Novo Método `ProvedorImagemAresta.preCarregarNoDisco`
- **Decisão**: Adicionar à classe `ProvedorImagemAresta`:
  ```dart
  static Future<File?> preCarregarNoDisco({
    required String picoId,
    required String caminho,
    String? checksumSha256,
    String? baseUrl,
    String? caminhoDownloads,
    String? caminhoCacheVolatil,
    DatasetRepository? datasetRepository,
    http.Client? clienteHttp,
  }) async
  ```
- **Racional e Propriedades**:
  - *Idempotente:* Verifica se o arquivo já existe em `/downloads` ou `/temp_cache`. Se existir, retorna imediatamente o `File` sem tráfego de rede.
  - *Deduplicado:* Se houver download em andamento da mesma URL, aguarda a finalização do `Future` já existente em `_downloadsEmAndamento`.
  - *Leve:* Invoca internamente a resolução e gravação em disco (`_baixarESalvarNoCache`), sem chamar `precacheImage` e sem criar texturas de renderização. O `PaintingBinding.instance.imageCache` da memória RAM não é alterado, prevenindo *cache eviction* de outras imagens em uso.

### 2. Disparo Antecipado no Setor (`MapaThumbnail`)
- **Decisão**: No `initState` (e no `didUpdateWidget`) do `MapaThumbnail`, se `widget.mapas.length > 1`:
  - Após renderizar a primeira miniatura, dispara-se uma rotina em segundo plano iterando sobre `widget.mapas.skip(1)`.
  - Cada mapa é repassado para `ProvedorImagemAresta.preCarregarNoDisco`.
- **Racional**: O usuário geralmente gasta vários segundos ou minutos lendo o setor e escolhendo vias. Esse intervalo é suficiente para que todas as imagens subsequentes sejam salvas em disco de forma imperceptível e silenciosa.

### 3. Disparo Complementar no Carrossel (`MapasCarrosselPage`)
- **Decisão**: No `initState` da `MapasCarrosselPage`, via `WidgetsBinding.instance.addPostFrameCallback`, o carrossel também invoca `ProvedorImagemAresta.preCarregarNoDisco` para todas as suas páginas.
- **Racional**: Garante a integridade e disponibilidade offline caso o usuário tenha aberto o mapa interativo direto de um botão de via ou histórico de navegação, sem ter passado pelo `MapaThumbnail`.

## Risks / Trade-offs

- **[Risco] Saída rápida do usuário da tela antes do término dos downloads**:
  - *Mitigação*: A gravação em disco é feita de forma atômica (`.tmp` seguido de `rename`) pelo `_baixarESalvarNoCache`. Mesmo que o widget seja descartado (`dispose`), o download que estiver em progresso é finalizado e salvo em disco para uso futuro.
- **[Risco] Interrupção de rede na rocha**:
  - *Mitigação*: Exceções no download são capturadas graciosamente com log informativo, permitindo que as imagens já salvas permaneçam válidas e que novas tentativas ocorram naturalmente na próxima oportunidade.

## Migration Plan

1. Adicionar testes unitários em `provedor_imagem_aresta_test.dart` exercitando `preCarregarNoDisco`.
2. Implementar `preCarregarNoDisco` em `provedor_imagem_aresta.dart`.
3. Adicionar testes de widget e integração do pré-download em `mapa_thumbnail_test.dart` e `mapas_carrossel_test.dart`.
4. Implementar o disparo em segundo plano no `MapaThumbnail` e na `MapasCarrosselPage`.
5. Validar a passagem de todos os testes com 100% de cobertura.


