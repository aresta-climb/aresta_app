# Invalidador de Cache de Croquis e Trajetos Obsoletos

## Why

Quando um usuário atualiza os traçados vetoriais de vias ou boulders no Aresta (painel administrativo) e sincroniza o aplicativo via Home ("Atualizar"), o aplicativo baixa os novos arquivos `.binarypb` e atualiza as caixas delimitadoras (bounding boxes) na interface. Contudo, os traçados vetoriais continuam sendo recuperados do cache estático em memória (`ConstrutorCaminhoTrajeto`), pois o cache nunca é invalidado durante o fluxo de sincronização e a chave de cache depende apenas do identificador do ponto e do arquivo de imagem do setor. 

Essa dessincronização faz com que os contêineres se reposicionem nas novas coordenadas enquanto o `CustomPaint` continua desenhando o `Path` anterior, resultando em traçados deformados e desalinhados na rocha até que o aplicativo seja completamente encerrado e reiniciado. Além disso, se o croqui tiver sido carregado sob demanda (online) sem download permanente, a instância em RAM (`GerenciadorSessaoOnline`) permanece na versão antiga após o sync. É necessário introduzir uma rotina unificada de invalidação de cache de caminhos e expurgo de croquis obsoletos em memória durante qualquer sincronização ou recarga.

## What Changes

- **Invalidação Centralizada de Croquis e Trajetos**: Criação do método `invalidarCroquisObsoletos` no `DatasetRepository` para orquestrar a limpeza de memória de traçados gráficos e de instâncias em RAM.
- **Limpeza de Paths no `syncIndex`**: Invocação automática de `ConstrutorCaminhoTrajeto.limparCache()` ao término da sincronização atômica do catálogo e croquis (cobrindo tanto o sync em segundo plano quanto o acionamento manual na Home).
- **Expurgo de Sessões Online Obsoletas**: Remoção automática de croquis armazenados no `GerenciadorSessaoOnline` cujos checksums SHA-256 divergirem do índice mestre recém-baixado (desde que o pico não esteja atualmente aberto na tela).
- **Limpeza Defensiva em Tempo Real**: Invocação da limpeza de cache de trajetos no callback de atualização via polling de ETag (`ServicoCroquiOnline`) e no encerramento de tela (`dispose` de `PicoPage`).

## Capabilities

### New Capabilities
- `invalidador-cache-croquis-obsoletos`: Define o comportamento e os contratos de invalidação reativa de instâncias de `Path`, traçados de viewport e croquis em memória RAM durante atualizações de catálogo e sincronização de dados.

### Modified Capabilities
<!-- Nenhuma especificação principal existente em openspec/specs/ tem seus requisitos alterados diretamente. -->

## Impact

- **Código Afetado**:
  - `frontend/lib/services/dataset_repository.dart`: implementação do método unificado de invalidação.
  - `frontend/lib/services/http/sync_service.dart`: chamada ao invalidador após aplicação atômica de arquivos e metadados.
  - `frontend/lib/services/http/servico_croqui_online.dart`: limpeza de cache gráfico ao detectar atualização de binário via ETag.
  - `frontend/lib/pages/pico.dart`: limpeza do cache gráfico no descarte da página.
  - Testes unitários e de integração correspondentes em `frontend/test/`.
- **Dependências & APIs**: Nenhuma nova dependência externa necessária; reutiliza a arquitetura já estabelecida no repositório.
