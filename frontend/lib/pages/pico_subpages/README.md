# Subpáginas do Pico (`lib/pages/pico_subpages/`)

Este diretório contém as subpáginas abertas a partir de `PicoDetailsPage`. Todas utilizam `buildCommonAppBar` com `BotaoVoltarComRetornoInicio`.

---

## 1. `SetoresPage` (`setores_page.dart`)

Tela de consulta de setores e escaladas de um pico (atende `SetoresNode` e `IndiceEscaladasNode`):

1. **Abas e Contadores**:
   - Primeira aba fixa `Setores`, seguida pelas abas das modalidades existentes no pico (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`, `Highlines`).
   - Os títulos das abas exibem `(total)` sem filtro ativo ou `(filtradas/total)` com filtro ativo.
2. **Filtros (`PainelFiltrosIndice`)**:
   - Compartilha uma instância de `EstadoFiltrosUnificado` no escopo do croqui (`GerenciadorFiltrosCroqui`).
   - Na aba `Setores`, filtra modalidades, faixas de grau por modalidade, grupos, conquistadores e vias clássicas.
   - Nas abas de modalidade, aplica o intervalo de grau da modalidade ativa, setores, grupos, conquistadores e clássicas.
3. **Ordenação (`BarraOrdenacaoExploracao`)**:
   - Opções `[ PADRÃO | GRAU | ALFABÉTICO ]` com inversão `[ ▲ / ▼ ]`.
   - Na aba `Setores`, a ordenação por grau usa a mediana dos pesos das escaladas filtradas de cada setor.
4. **Ocultação Contextual**:
   - Setores sem escaladas compatíveis com o filtro ativo são omitidos da lista.

---

## 2. Demais Subpáginas

| Arquivo | Responsabilidade |
|---|---|
| `explorar_local_page.dart` | Acesso, infraestrutura, época de escalada, mapas de aproximação e botão `"Abrir no Google Maps"` (usando `urlGoogleMaps` ou coordenadas `localizacao`). |
| `comunidade_pico_page.dart` | Contatos locais, associações, guias e canais de comunicação do pico. |
| `apoie_pico_page.dart` | Chaves Pix e informações de manutenção de vias e acessos do pico. |
