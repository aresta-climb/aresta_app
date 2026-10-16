# Proposal: Migração para UIDs Descentralizados e Normalização In-Place de Croquis

## Why

A versão v5 da API Aresta (`aresta_api`) introduziu identificadores descentralizados permanentes (UIDs NanoID de 14 caracteres) para todas as entidades estruturais do croqui (`Croqui`, `Botao`, `Grupo`, `Setor`, `Escalada` e `PontoDeInteresse`), deprecando os campos acoplados a nomes textuais e identificadores locais (`ids`, `label`, `grupo`, `setor`, `escalada`) e removendo o campo obsoleto `indice_mapa_alvo`. A adoção dessas entidades no aplicativo elimina fragilidades de integridade relacional e viabiliza um catálogo de resolução em tempo constante $O(1)$ para entidades e seus mapas associados.

## What Changes

- **Atualização do Submódulo `aresta_api`**: Avanço do submódulo Git para o commit com os bindings v5 gerados.
- **Normalizador In-Place na Carga do Croqui (`NormalizadorCroqui`)**: Na leitura/decodificação do `Croqui` ou `Pico`, qualquer dado legado é convertido in-place para o padrão v5 (gerando UIDs sintéticos para grupos, setores e escaladas sem UID, sintetizando `alvo_uid` para referências antigas, populando `pontos_uids` a partir de `ids` e `rotulo` a partir de `label`). Botões legados não requerem UIDs sintéticos.
- **Aplicação 100% Baseada em Novos Campos**: A camada de visualização, navegação e resolução (`DatasetResolver`, `mapa_interativo`, `resolvedor_rotulos_referencia`, `setor_functions`, `via_functions`) opera consumindo **exclusivamente** os campos v5 (`uid`, `rotulo`, `alvoUid`, `pontosUids`).
- **Remoção de Código Legado e de `indice_mapa_alvo`**: Remoção definitiva de chamadas a `indice_mapa_alvo` e aposentadoria completa do `CroquiMapIndex` e `ReferenceKey`.
- **Associação Direta de Mapas por Alvo**: Cada entidade no `ResolvedDataset` contém suas referências de mapas (`List<ReferenciaNoMapa>`) pré-computadas na carga em $O(1)$.
- **Teste Arquitetural de Governança**: Teste automatizado que impede a leitura de campos deprecados (`label`, `ids`, `ref.escalada`, `ref.setor`, `ref.grupo`, `indiceMapaAlvo`) em qualquer arquivo de produção fora da camada de normalização de croqui.

## Capabilities

### New Capabilities
- `croqui-uid-resolution`: Normalização in-place na carga e catálogo relacional universal em tempo constante O(1) no `DatasetResolver` para `Botao`, `Grupo`, `Setor` e `Escalada` por UIDs permanentes, associando diretamente ocorrências em mapas.

### Modified Capabilities
- `croqui-map-indexing`: Descontinuação da indexação por chaves de strings (`CroquiMapIndex`) em favor do acesso direto aos mapas referenciados em tempo constante pelo `DatasetResolver`.
- `interactive-map`: Resolução de entidades via `alvo_uid`, traçados por `pontos_uids`, rótulos por `rotulo` no escopo local do mapa e remoção de `indice_mapa_alvo`.

## Impact

- **Código Afetado**:
  - `frontend/lib/aresta_api`: Atualização do submódulo Git com os bindings gerados v5.
  - `frontend/lib/services/dataset/`: Introdução de `NormalizadorCroqui` na carga de arquivos e downloads.
  - `frontend/lib/utils/consulta_dataset.dart`: `DatasetResolver` operando 100% por UID com `TipoEntidadeResolved`.
  - `frontend/lib/utils/resolvedor_rotulos_referencia.dart`: Consumo exclusivo de `pontos_uids` e `rotulo`.
  - `frontend/lib/utils/indice_mapas_croqui.dart`: Aposentadoria de `CroquiMapIndex`.
  - `frontend/lib/pages/mapa_interativo.dart`: Operação exclusiva por UID e remoção de `indice_mapa_alvo`.
  - `frontend/lib/view/function_library/`: `setor_functions.dart` e `via_functions.dart`.
- **Testes e Governança**:
  - Novo teste arquitetural para barrar uso de getters deprecados.
  - Testes unitários para `NormalizadorCroqui` e `DatasetResolver`.
  - Atualização dos testes de widget para os campos v5 mantendo 100% de cobertura.
