## Why

Atualmente, quando uma imagem de croqui (seja mapa interativo, capa de setor ou foto embutida em markdown) é alterada ou desenhada no Editor Desktop e salva, a notificação de Live Reload chega ao aplicativo via WebSocket, mas a imagem exibida na tela não é atualizada automaticamente. O usuário é obrigado a voltar de tela e abrir a aba/página novamente para ver a nova imagem.

Isso ocorre devido a três causas identificadas:
1. **Falha na resolução de SHA-256 para croquis online**: O repositório (`DatasetRepository`) continha uma trava condicional em `obterSha256DaMidia` que impedia a indexação sob demanda dos arquivos externos de croquis em sessão online ativa, retornando `null` e impedindo a injeção do parâmetro de cache-busting (`?v=<hash>`).
2. **Retenção de Textura na GPU pelo Cache de Imagens**: O cache em memória do Flutter (`PaintingBinding.instance.imageCache`) não era purgado no momento do Live Reload, mantendo as texturas anteriores ativas na GPU.
3. **Inércia no Ciclo de Vida do Carrossel**: A página `MapasCarrosselPage` não executava `setState()` no método `didUpdateWidget`, impedindo que os widgets filhos (`MapaInterativoPage`) fossem notificados para re-resolver a imagem na tela.

Corrigir isso é indispensável para que a experiência de edição e visualização ao vivo funcione de forma reativa e instantânea, tanto para croquis baixados no armazenamento local quanto para croquis navegados em sessão online.

## What Changes

- **Indexação Imediata e Sob Demanda de Hashes para Croquis Online**: Remoção da trava indevida em `obterSha256DaMidia` que impedia a indexação de `arquivosExternos` para croquis em sessão online; garantia de indexação proativa no momento do registro e recarga de croquis online (`registrarCroquiOnline` e `recarregarCroquiOnline`).
- **Normalização Robusta de Caminhos de Mídia**: Normalização consistente de caminhos removendo prefixos relativos (`./`), barras iniciais (`/`) e unificando separadores de diretório do Windows (`\`) para barras padrão (`/`), assegurando casamento $O(1)$ exato na tabela de dispersão de hashes.
- **Invalidação Ativa do Cache de Imagens no Live Reload**: Expulso explícito de memória com `PaintingBinding.instance.imageCache.clear()` e `PaintingBinding.instance.imageCache.clearLiveImages()` no recebimento do evento de Live Reload em `registrarOuvintesLiveReload`.
- **Reatividade Visual em `MapasCarrosselPage`**: Inclusão de `setState()` no método `didUpdateWidget` e injeção de chave reativa nos filhos `MapaInterativoPage` para forçar a re-resolução imediata da imagem na tela.
- **Conformidade Estrita com PRINCIPIOS.md**:
  - *I. Tudo em Português*: Todo o código, nomes de métodos, variáveis, testes e documentação integralmente em português brasileiro.
  - *II. Componentes Independentes*: Solução modular sem acoplamento indevido entre camadas.
  - *III. 100% de Test Coverage*: Cobertura integral das rotinas criadas e modificadas.
  - *IV. Imperativo do Teste em Primeiro Lugar (TDD)*: Escrever os testes em falha (Red) antes de qualquer código de produção (Green), seguido de refatoração.
  - *V. Testes de Widget em Primeiro Lugar*: Priorizar testes de widget validando a atualização da tela aberta ponta a ponta antes de descer para unidades.
  - *VI. Simplicidade e Anti-Abstração*: Uso direto dos mecanismos nativos do Flutter sem camadas intermediárias supérfluas.
  - *VII. Documentação Contínua*: Inclusão de docstrings `///` explicativas e atualização dos arquivos `README.md` pertinentes.

## Capabilities

### New Capabilities
<!-- Nenhuma capacidade inteiramente nova foi introduzida; aprimoram-se as capacidades existentes -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Aprimorar a resolução de hashes SHA-256 para croquis online, suporte a caminhos normalizados, e expurgar o cache de imagens ativo na GPU durante Live Reload.
- `transmissao-croqui-online`: Garantir que os croquis transmitidos em sessão online tenham seus arquivos externos indexados imediatamente na tabela de SHA-256 do repositório no momento do carregamento e recarga.
- `hot-reload-experiencia-usuario`: Garantir a troca visual imediata de imagens na tela aberta ao receber eventos de Live Reload, sem exigir navegação de retorno.

## Impact

- `frontend/lib/services/dataset_repository.dart`: Correção em `obterSha256DaMidia` e `indexarMidiasDoCroqui` para suportar indexação reativa de croquis online e caminhos normalizados.
- `frontend/lib/main.dart`: Adição de expurgo de `imageCache` em `registrarOuvintesLiveReload`.
- `frontend/lib/pages/mapas_carrossel.dart`: Reatividade via `setState()` no `didUpdateWidget`.
- `frontend/lib/widgets/provedor_imagem_aresta.dart`: Suporte a caminhos normalizados e fallback dinâmico de timestamp para arquivos locais.
- Testes de widget e de unidade em `frontend/test/` espelhando a estrutura de `lib/`.
- Documentação técnica nos arquivos `README.md` pertinentes.
