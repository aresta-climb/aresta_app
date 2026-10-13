# Proposal: Restaurar Marcadores no Mapa Global e Desduplicação de Feedback

## Why

Na versão recente do aplicativo, ao navegar para o "Mapa Global" a partir da aba Explorar (botão "VER NO MAPA"), o mapa do Google Maps é aberto centralizado na localização do usuário sem exibir nenhum marcador ou pino dos picos de escalada catalogados. Esse problema foi introduzido pela migração da `BrowsePage` para o modelo desacoplado `CardCroquiViewModel`, que não contém coordenadas geográficas e não é reconhecido pelo `MapaGlobalViewModel.picosNoMapa`, fazendo com que todos os picos recebidos sejam convertidos em `null` e suprimindo o fallback para os metadados do catálogo. Além disso, a tela do Mapa Global exibe indevidamente dois botões idênticos de alerta/feedback na barra superior (`AppBar`).

Restaurar a exibição correta dos marcadores é crítico para permitir que os usuários encontrem locais de escalada geograficamente, enquanto a limpeza do botão duplicado na AppBar restabelece a consistência visual.

## What Changes

- **Resolução de Marcadores e Coordenadas no `MapaGlobalViewModel`**:
  - Habilitar o `MapaGlobalViewModel` a resolver picos a partir de `CardCroquiViewModel`, identificadores (`String` IDs), instâncias de `MapaPicoViewModel` ou `ResumoCroqui`.
  - Cruzar os IDs recebidos com o repositório (`datasetRepo.activeDataset`) para extrair coordenadas geográficas (`latitude`/`longitude`) mesmo quando o nó de navegação transportar instâncias leves de cartões.
  - Implementar fallback seguro: caso a lista inicial de picos fornecida resulte em zero marcadores com coordenadas válidas, o ViewModel deve recorrer automaticamente a todos os picos com coordenadas em `dataset.metadadosDisponiveis`.
- **Conformidade Arquitetural do `MapaGlobalNode` e `AppNav.toMapaGlobal`**:
  - Permitir passagem de identificadores de texto (`picoIds: List<String>`) e objetos de card na navegação, mantendo retrocompatibilidade e respeitando o princípio de `NavNode` guardar identificadores em texto.
- **Remoção do Botão Duplicado de Feedback na AppBar**:
  - Remover a inclusão redundante de `actions: [buildFeedbackButton(context)]` em `mapa_global.dart`, aproveitando a injeção automática já realizada por `buildCommonAppBar`.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida -->

### Modified Capabilities
- `estabilidade-mapa-marcadores`: Adiciona requisitos para resolução e mapeamento de coordenadas a partir de identificadores e ViewModels de cards desacoplados, garantindo que o Mapa Global plote com sucesso os picos catalogados e realize fallback transparente.

## Impact

- **Código afetado**:
  - `frontend/lib/view/view_models/mapa_global_view_model.dart`: Tratamento de `CardCroquiViewModel`, extração de IDs e fallback resiliente.
  - `frontend/lib/pages/mapa_global.dart`: Limpeza do botão duplicado de feedback na AppBar.
  - `frontend/lib/navigation/arvore/nos_globais.dart` e `frontend/lib/navigation/funcoes_navegacao.dart`: Normalização de IDs no `MapaGlobalNode`.
  - `frontend/test/pages/mapa_global_test.dart` e `frontend/test/view/view_models/mapa_global_view_model_test.dart`: Testes unitários e de widget cobrindo o fluxo com `CardCroquiViewModel` e validação da AppBar.
- **APIs/Dependências**: Nenhuma alteração externa. Compatibilidade total com `GoogleMap` e a arquitetura MVVM existente.
