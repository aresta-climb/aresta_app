# Subpáginas do Pico — Aresta Climb

Este diretório reúne as subpáginas especializadas acessíveis a partir do Hub do Pico (`PicoDetailsPage`), projetadas com base nos princípios de **Componentes Independentes** e **Tudo em Português**.

---

## 1. `SetoresPage` (`setores_page.dart`) — Exploração Unificada de Setores & Escaladas

A `SetoresPage` é a tela central e única de exploração do catálogo de um pico, substituindo a antiga separação fragmentada entre "Setores" e "Índice de Escaladas".

### Características Arquiteturais:

1. **Ponto de Entrada Unificado no Hub**:
   - No Hub (`PicoDetailsPage`), um card hero de largura total denominado **"Setores & Escaladas"** substitui os antigos botões lado a lado.
   - Navega diretamente para o nó declarativo `SetoresNode`.

2. **Abas Dinâmicas Integradas com Contadores**:
   - **Aba Setores (fixa)**: Renderizada sempre como a primeira aba, listando os setores do pico acompanhados de miniaturas cartográficas (`MapaThumbnail`).
   - **Abas de Modalidade**: Geradas dinamicamente com base nas modalidades cadastradas no pico (ex: `Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`).
   - **Contadores Reativos**: Exibem a contagem no formato `(total)` quando não há filtros aplicados, ou `(filtradas/total)` mediante filtragem ativa (ex: `Setores (4/13)` e `Esportivas (12/95)`).

3. **Painel de Filtros Reativo e Compartilhado (`PainelFiltrosIndice`)**:
   - Opera sobre uma única instância de `EstadoFiltrosUnificado`.
   - **Modo Superset (Aba Setores)**: Permite ativar/desativar modalidades inteiras e ajustar múltiplos sliders de grau simultaneamente, além de grupos, conquistadores e clássicas.
   - **Modo Contextual (Abas de Modalidade)**: Exibe slider dedicado daquela modalidade, seletor de setores, grupos, conquistadores e clássicas.

4. **Tríade de Ordenação Padronizada (`BarraOrdenacaoExploracao`)**:
   - Disponibiliza botões seletores `[ PADRÃO | GRAU | ALFABÉTICO ]` acompanhados do botão de inversão de sentido `[ ▲ / ▼ ]`.
   - **Ordenação por Grau na Aba Setores**: Classifica os setores pela **mediana de dificuldade** normalizada das vias que atendem ao filtro ativo, tornando a visualização imune a outliers.

5. **Enriquecimento e Ocultação Contextual de Setores**:
   - Setores que não contenham vias correspondentes aos filtros ativos são automaticamente ocultados da listagem.
   - Os cartões de setor exibem a faixa formatada de graus (ex: `"4º a 7b"`) e a quantidade de vias aprovadas no filtro (ex: `"3 vias no filtro (de 10)"`).

6. **Navegação Declarativa e Retrocompatibilidade**:
   - O construtor de rotas (`construtor_view_arvore.dart`) mapeia tanto `SetoresNode` quanto `IndiceEscaladasNode` para a `SetoresPage`.
   - O parâmetro opcional `modalidadeInicial` permite que links externos ou históricos abram diretamente na aba correspondente, preservando total integridade de deep links.

---

## 2. Demais Subpáginas do Pico

| Subpágina | Responsabilidade |
|---|---|
| `explorar_local_page.dart` | Informações práticas de acesso, infraestrutura, melhor época para escalar e croquis gerais de aproximação. |
| `comunidade_pico_page.dart` | Links e contatos da comunidade local, guias cadastrados, canais de comunicação e fóruns. |
| `apoie_pico_page.dart` | Informações e dados PIX para contribuição financeira e manutenção das trilhas e vias do pico. |
