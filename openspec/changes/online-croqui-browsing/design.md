## Contexto

Historicamente, o Aresta Climb impunha um modelo estritamente offline-first onde explorar um pico exigia baixar seu pacote completo de dados e imagens para a pasta `/downloads/<picoId>/`. Embora isso garanta 100% de disponibilidade na montanha, gera alta fricção para usuários que desejam apenas consultar graus de vias, verificar betas ou comparar picos em casa.

A infraestrutura remota do Aresta distribui os dados no formato `.binarypb` com imagens WebP e mapas estáticos sobre CDN HTTP (e localmente via Live Reload no Desktop). Além disso, cada `ResumoCroqui` no `indice.binarypb` já contém hashes SHA-256 e o `Croqui` mapeia hashes de todos os `arquivosExternos`.

Este design estabelece a arquitetura híbrida de navegação online com transmissão sob demanda, cache volátil, verificação de ETag, guardiões de conscientização visual e downloads em segundo plano com notificações persistentes do sistema operacional, respeitando rigorosamente os **Princípios de Engenharia do Aresta App** (`PRINCIPIOS.md`): nomenclatura 100% em português brasileiro, componentes independentes (feature-first), TDD com cobertura integral de testes, priorização de testes de widget e documentação contínua.

## Objetivos e Não-Objetivos

**Objetivos:**
- Permitir navegação instantânea em qualquer pico disponível sem exigir download prévio.
- Baixar `.binarypb` em milissegundos e armazenar imagens sob demanda em cache volátil (`getTemporaryDirectory()`).
- Implementar polling leve de ETag (`If-None-Match`) para avisar sobre atualizações em tempo real durante a leitura.
- Exibir tamanho pré-computado de download (`tamanho_download_bytes`) direto do `indice.proto`.
- Prover componentes visuais de proteção: `BannerModoOnline` e `ModalConfirmacaoSaida` (Guardião de Saída via `PopScope`).
- Implementar `ServicoDownloadSegundoPlano` acoplado a Foreground Service com notificação persistente (`ongoing: true`) no SO.

**Não-Objetivos:**
- Remover ou enfraquecer o suporte offline (o uso offline segue como pilar inegociável do app).
- Fazer cache em massa silencioso de todos os picos do índice (downloads permanentes continuam sob escolha explícita do usuário).
- Edição ou autoria de croquis no app mobile.

## Decisões Técnicas e Arquitetura

### Decisão 1: Cache Volátil e Memória para Sessões Online
- **Abordagem**: O `.binarypb` é mantido em memória no `DatasetRepository` e copiado para o diretório de cache temporário do sistema operacional (`getTemporaryDirectory()`). As mídias visualizadas são salvas em `/temp_cache/<picoId>/` com sufixo de quebra de cache `?v=<sha256>`.
- **Justificativa**: Evita ocupar armazenamento permanente do usuário com dados não selecionados e permite que o sistema operacional recicle espaço sob pressão sem afetar a pasta `/downloads` permanente.

### Decisão 2: Polling Ativo com ETag no `ServicoCroquiOnline`
- **Abordagem**: Enquanto a página de um pico online estiver ativa, um timer periódico dispara a cada 30-60 segundos uma requisição `GET` com o cabeçalho `If-None-Match: <etag>`.
- **Comportamento**:
  - `304 Not Modified`: Nenhuma ação, tráfego nulo de corpo.
  - `200 OK`: Atualiza o buffer do croqui e emite notificação reativa para a UI exibir a `PilulaAtualizacaoOnline`.
  - O timer é cancelado automaticamente no descarte (`dispose`) da página.

### Decisão 3: Tamanho de Download Pré-Computado no `indice.proto`
- **Abordagem**: O builder de dados (`aresta_db`) soma o tamanho do `.binarypb` e de todas as imagens externas, gravando o campo `tamanho_download_bytes` dentro de `PrecomputadosResumoCroqui`.
- **Justificativa**: Elimina requisições de rede `HEAD` em tempo de execução, permitindo que cards e banners exibam instantaneamente valores formatados (ex: "18.4 MB").

### Decisão 4: Provedor de Imagem em Camadas (`ProvedorImagemAresta`)
- **Ordem de Resolução**:
  1. `/downloads/<picoId>/<caminho>` (Armazenamento Permanente Local)
  2. `/temp_cache/<picoId>/<caminho>` (Cache Volátil do SO)
  3. `https://<url_servidor>/<caminho>?v=<sha256>` (Streaming Remoto da CDN)
- **Justificativa**: Unifica `OfflineMarkdown`, `MapaThumbnail`, `MapaInterativo` e `SetorPage` em um provedor modular e auto-suficiente.

### Decisão 5: Download Resiliente com Notificação Persistente (`ServicoDownloadSegundoPlano`)
- **Abordagem**: Utiliza Foreground Service com notificação persistente (`ongoing: true`) no Android e tarefas em segundo plano gerenciadas via `URLSession` no iOS.
- **Ciclo Atômico**:
  - Baixa arquivos como `.tmp` $\rightarrow$ Valida SHA-256 $\rightarrow$ Renomeia atomicamente para `/downloads/<picoId>` $\rightarrow$ Atualiza `DatasetRepository` $\rightarrow$ Transita notificação para "✓ Concluído".

### Decisão 6: Intercepção de Navegação com Guardião de Saída (`ModalConfirmacaoSaida`)
- **Abordagem**: `PicoDetailsPage` monitora o tempo de permanência e profundidade de navegação. Se o usuário navegou online por mais de 10 segundos e tenta voltar, um `PopScope` aciona o `ModalConfirmacaoSaida` alertando sobre a necessidade de download para uso na pedra.

## Riscos e Mitigações

- **[Risco] O usuário presume que navegar online já salvou tudo para a pedra** $\rightarrow$ **Mitigação**: `BannerModoOnline` em destaque constante, cores diferenciadas de badges e o modal `ModalConfirmacaoSaida`.
- **[Risco] Sistema Operacional encerrar downloads em background** $\rightarrow$ **Mitigação**: Foreground Service com notificação persistente e política nativa de reconexão e retentativas com backoff.
- **[Risco] Regressão na cobertura ou quebra de convenções em português** $\rightarrow$ **Mitigação**: Adoção estrita de TDD (Red-Green-Refactor), testes de widget para cada novo componente e verificação de 100% de cobertura.
