# Design Técnico: Mapas Individuais de Escalada

## Context

Atualmente, o Aresta estrutura seus mapas hierarquicamente em `Pico.mapas_gerais`, `Grupo.mapas` e `Setor.mapas`. O `aresta_app` utiliza o `CroquiMapIndex` para resolver referências em $O(1)$ e abrir o `mapa_interativo.dart` dentro de um `MapasCarrosselNode`.

No entanto, escaladas individuais não possuem suporte a mapas próprios em `Escalada` (apenas um protótipo não utilizado `ViaMultiplasEnfiadas.mapas = 21`). Além disso, fotos adicionadas pelo `DialogoAdicionarMapa` no `aresta_db` utilizam o perfil fixo de 2.5 MP @ WebP Q85 (~400 KB por foto), o que tornaria o download offline insustentável caso dezenas de escaladas ganhassem fotos individuais.

## Goals / Non-Goals

**Goals:**
- Adicionar `repeated Mapa mapas = 7;` na mensagem `Escalada` em `croqui.proto` (`aresta_api`).
- Remover completamente `ViaMultiplasEnfiadas.mapas = 21` e marcar o campo 21 como reservado.
- Definir perfil de compressão para mapas de escaladas no `aresta_db`: teto de 1.0 MP e WebP Q85 (~120 KB por foto, preservando detalhes de agarras e pés).
- Adicionar ferramenta de recorte (*rubber-band crop*) opcional e banner instrutivo no `DialogoAdicionarMapa`.
- No `aresta_app`, atualizar `CroquiMapIndex`, exibir `MapaThumbnail` na `ViaPage`, abrir carrossel unificado (mapas locais seguidos por mapas do setor) e habilitar o botão "Ver mapas" no rodapé de rotas no mapa do setor.

**Non-Goals:**
- Permitir aninhamento complexo de sub-entidades (ex: vincular referências a enfiadas filhas dentro do mapa da via); o mapa de escalada é 100% autocontido.
- Alterar o perfil ou resolução dos mapas panorâmicos de setores e grupos (permanecem em 2.5 MP @ Q85).
- Adicionar filtros avançados de cor ou edição gráfica no diálogo de adição de mapas.

## Decisions

### 1. Campo `mapas` no nível do wrapper `Escalada`
- **Decisão**: Adicionar `repeated Mapa mapas = 7;` em `message Escalada`.
- **Alternativa Considerada**: Duplicar o campo dentro de cada mensagem específica (`Boulder.mapas`, `ViaEsportiva.mapas`, etc.).
- **Justificativa**: Centralizar em `Escalada` segue o Princípio VI (Simplicidade e Anti-Abstração), espelha a mesma abordagem limpa adotada por `betas` e permite tratamento polimórfico no editor e no app.

### 2. Remoção limpa de `ViaMultiplasEnfiadas.mapas`
- **Decisão**: Deletar o campo 21 e declarar `reserved 21;` em `ViaMultiplasEnfiadas`.
- **Alternativa Considerada**: Manter o campo marcado como `[deprecated = true]`.
- **Justificativa**: Nenhum croqui em todo o banco `database/` utiliza o campo 21. A remoção limpa previne acúmulo de dívida técnica e ambiguidades no código gerado.

### 3. Orçamento de Imagem: Perfil Escalada (1.0 MP @ WebP Q85)
- **Decisão**: 
  - `AREA_MAXIMA_ESCALADA = 1_000_000` (~1.0 MP) e `QUALIDADE_WEBP_ESCALADA = 85` (método 6).
  - `AREA_MAXIMA_SETOR = 2_500_000` (~2.5 MP) e `QUALIDADE_WEBP_SETOR = 85`.
- **Justificativa**: Imagens de escalada são enquadramentos aproximados (close-up) de 2m a 5m de rocha. A 1.0 MP, preenchem a tela do celular em escala quase 1:1, enquanto a qualidade 85 mantém o peso baixo (~120 KB, economia de 60% em pixels e RAM de GPU em relação a 2.5 MP) preservando nitidez máxima nas agarras e regletes ao dar zoom. O compilador e validador auditam esse teto.

### 4. Recorte Interativo (*Rubber-band Selection*) no `DialogoAdicionarMapa`
- **Decisão**: Integrar seleção retangular interativa na área de pré-visualização do `DialogoAdicionarMapa`, reaproveitando a biblioteca pura existente `cortar_imagem_bytes` de `editor/core/transformacoes_imagem.py`.
- **Justificativa**: Permite que autores fotografem com a câmera do celular em 12 MP ou 48 MP e recortem a região exata da saída ou do *sit-start* diretamente no editor, garantindo que o teto de 1.0 MP seja dedicado com máxima densidade de pixels onde realmente interessa.

### 5. Banner Contextual de Dica de Qualidade no Diálogo
- **Decisão**: Quando o diálogo for aberto no contexto de uma escalada, exibir um banner informativo instruindo: *"💡 Dica de Qualidade: Selecione a área desejada da imagem para focar (ex: saída do boulder, agarras ou crux) e preservar a maior nitidez possível dentro do limite de 1.0 MP."*
- **Justificativa**: Orienta o autor de forma proativa sobre o benefício de recortar antes de salvar.

### 6. Carrossel Unificado na `ViaPage` do Aplicativo
- **Decisão**: Quando a escalada possuir mapas próprios, exibir o `MapaThumbnail` no corpo da página. Ao tocar, abrir um `MapasCarrosselNode` que sequencia:
  1. Mapas locais da escalada (`escalada.mapas`);
  2. Mapas onde a escalada é referenciada (mapas do setor ou grupo, com o traçado pré-focado via `initialSelectedId`).
- **Justificativa**: Unifica a experiência em um fluxo único: o escalador desliza horizontalmente entre a foto de perto da saída e a foto panorâmica do bloco sem trocar de tela.

### 7. Ação "Ver Mapas" no Rodapé do Mapa do Setor
- **Decisão**: Ao clicar em uma via/boulder no `mapa_interativo.dart`, se a entidade tiver mapas próprios, o bottom sheet exibe o botão secundário "Ver mapas", reaproveitando o mesmo padrão visual de transição de grupos para setores.

## Risks / Trade-offs

- **[Risco de Inchaço de Armazenamento]** $\rightarrow$ *Mitigação*: Imposição automática de 1.0 MP @ Q85 pelo `DialogoAdicionarMapa` e emissão de avisos no script de validação de submissões (`preparar_submissao_lib.py`).
- **[Fricção no Recorte de Imagem]** $\rightarrow$ *Mitigação*: O recorte é 100% opcional; se o usuário não fizer a seleção, a imagem inteira é automaticamente convertida e redimensionada para 1.0 MP sem bloquear o fluxo.
- **[Sincronização de Tipos Protobuf]** $\rightarrow$ *Mitigação*: Execução de `python build.py` no `aresta_api` para gerar simultaneamente stubs Python para `aresta_db` e Dart para `aresta_app`.

## Migration Plan

1. **`aresta_api`**: Alterar `croqui.proto` e rodar `python build.py`.
2. **`aresta_db`**: Atualizar scripts, `DialogoAdicionarMapa`, `WidgetEditorMapas` e validador.
3. **`aresta_app`**: Atualizar stubs gerados, estender `CroquiMapIndex`, atualizar `via_functions.dart` e `mapa_interativo.dart`.
