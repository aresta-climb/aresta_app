# Arquitetura Unificada: Aba Explorar, Globo Vetorial em 4 LODs, Altimetria NASA e RainTracker

**Ecossistema Aresta Climb (`aresta_app`)**  
*Consolidação Técnica da Fusão Explorar + Mapa Global, Motor Gráfico Offline em 4 LODs, Filtragem Nacional por Grau, Altimetria Externa (NASA NASADEM/SRTM 30m), Malhas IBGE e Sistema Contextual de Umidade Regional com Rotação de Cópia de Segurança*  
**Data:** Novembro de 2026 • **Status:** Especificação Arquitetural Consolidada • **Mudança OpenSpec:** `unificar-explorar-globo-clima`

---

## 1. Resumo Executivo e Motivação

Historicamente, a descoberta de picos no **Aresta Climb** esteve dividida em duas superfícies desconectadas:
1. **`BrowsePage` (`Explorar`)**: uma listagem vertical simples com busca por nome/localidade e ordenação básica, incapaz de filtrar o catálogo nacional por faixa de graduação (`6ºsup–8a`, `V2–V6`) antes do download individual de cada arquivo `.binarypb`.
2. **`MapaGlobalPage`**: uma tela secundária pouco utilizada, acoplada ao plugin nativo `google_maps_flutter` (`PlatformView`), dependente de download contínuo de *tiles* online, pesada em memória RAM em aparelhos modestos e desprovida de contexto climático ou topográfico.

Esta arquitetura unifica as duas frentes em uma **única superfície na aba `Explorar`**, eliminando integralmente a rota legada `MapaGlobalPage` e introduzindo quatro capacidades coordenadas:

1. **Globo 3D Giratório e Terreno Contínuo em 4 LODs (`100% Offline`, `< 4ms`/frame)**: Um motor vetorial leve sobre `CustomPainter` / `Canvas.drawVertices` (com chave instantânea `3D <-> 2D`), que parte do planeta inteiro (`LOD 0`), passa pelas divisas estaduais do IBGE e manchas de chuva (`LOD 1`), inclina sobre serras e vales com curvas de nível de `250m` (`LOD 2`) e chega ao maciço 3D local escalonado pela altitude real do pico com trilha de aproximação animada (`LOD 3`).
2. **Gaveta Deslizante Sincronizada e Busca com Filtro Nacional de Dificuldade**: Uma gaveta em 3 estágios (`Mapa`, `Dividir`, `Lista`) acoplada ao centro óptico da câmera, com auto-scroll animado ao tocar em pinos no mapa, voo parabólico (`Fly-To`), seletor rápido `Grau` ao lado da barra de busca, tag `Paredão` e modal completo de filtros alimentado offline pelo `catalogo.db`.
3. **Sistema Contextual de Chuva Regional (`RainTracker`) em Curva de 5 Dias**: Cruzamento entre células regionais de precipitação e coordenadas dos picos, seguindo a progressão `Muito molhado (2d) -> Molhado (2d) -> Levemente molhado (1d) -> Seco`. Picos secos permanecem limpos (sem selos climáticos); apenas picos sob efeito de chuva exibem o indicador em tons azuis/musgo, a data da chuva (`Chuva DD/MM`) e a estimativa de secagem.
4. **Resiliência contra Quedas de Serviços Externos (Cópia Única de Segurança Rotativa)**: Como APIs governamentais e científicas (**IBGE** e **NASA**) sofrem indisponibilidades periódicas, toda camada de ingestão e armazenamento mantém **exatamente dois slots (`atual` e `copia_seguranca`)**. A cada coleta nova íntegra, o dado anterior substitui a cópia de segurança e versões mais antigas são descartadas, garantindo continuidade operacional sem acúmulo de armazenamento.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                     NOVA ARQUITETURA DA ABA EXPLORAR (OFFLINE-FIRST)             │
└──────────────────────────────────────────────────────────────────────────────────┘
         │                                 │                                │
         ▼                                 ▼                                ▼
┌─────────────────────────┐   ┌──────────────────────────┐   ┌─────────────────────────┐
│  GEOMETRIA & RELEVO     │   │  CATÁLOGO & FILTROS      │   │  CLIMA & ALTIMETRIA     │
│  - Malha IBGE (<400 KB) │   │  - SQLite catalogo.db    │   │  - NASA SRTM/NASADEM 30m│
│  - Projeção Contínua    │   │  - Graus Via (1º–12a)    │   │  - Open-Meteo (Cron 3h) │
│  - 4 LODs + Chave 3D/2D │   │  - Graus Boulder (V0–V15)│   │  - Bolhas + Curva 5 dias│
│  - Cópia de Segurança   │   │  - Tag Paredão / Modalid.│   │  - Slots: Atual + Segur.│
└────────────┬────────────┘   └────────────┬─────────────┘   └────────────┬────────────┘
             │                             │                              │
             └─────────────────────────────┼──────────────────────────────┘
                                           ▼
                      ┌─────────────────────────────────────────┐
                      │     BrowseViewModel (MVVM Reativo)      │
                      │  + SuperficieGloboExplorar (<4ms/frame) │
                      │  + GavetaDeslizanteExplorar (3 Snaps)   │
                      └─────────────────────────────────────────┘
```

---

## 2. Conformidade com os Princípios de Engenharia (`AGENTS.md`)

| Princípio | Aplicação Direta nesta Arquitetura |
|---|---|
| **I. Tudo em Português** | Todos os nomes de classes, métodos, variáveis, tabelas SQL, slots (`atual`, `copia_seguranca`), enums (`NivelUmidadePico`, `EstagioGavetaExplorar`) e documentação em português brasileiro. |
| **II. Modularidade (Feature-First)** | Separação clara entre motor matemático de projeção (`controlador_camera_globo.dart`), gerador de relevo (`malha_relevo_lod.dart`), calculadora pura de secagem (`calculadora_umidade_pico.dart`), serviço de rede/cache com rotação (`servico_clima_altimetria.dart`) e widgets de UI passiva. |
| **III & IV. TDD e 100% de Cobertura 1:1** | Cada arquivo `.dart` em `lib/` possui seu `_test.dart` espelhado em `test/`, escrito no ciclo *Red-Green-Refactor*, validando comportamentos observáveis sem inspecionar campos privados. |
| **V. Anti-Mocking e Fakes Testados** | Zero uso de `mocktail`/`mockito`. Testes usam instâncias reais, `catalogo.db` SQLite temporário real, `Directory.systemTemp` real, `HttpServer` local em `127.0.0.1` e `ClienteClimaAltimetriaFake` validado por `cliente_clima_altimetria_fake_test.dart`. |
| **VIII. Fail-Fast + Exceção Explícita** | Remoção integral de `MapaGlobalPage`/`MapaGlobalNode` sem código morto legado. A rotação para `copia_seguranca` diante de queda das APIs do IBGE/NASA é implementada como requisito explícito de domínio documentado e auditado via `AppLogger`. |
| **IX. Orçamento de Meio Frame (`< 4ms`)** | Decodificação de JSON/binários geográficos e agregação inicial de graus ocorrem fora do frame de pintura (`Isolate.run` / pré-cálculo assíncrono). O `CustomPainter` opera sobre buffers planos pré-alocados e só repinta quando há gesto ou `Ticker` ativo (`0%` CPU parado). |

---

## 3. Experiência Visual, Hierarquia Limpa e Motor de 4 LODs

### 3.1. Fusão de Tela e Remoção de Poluição Visual
A aba `Explorar` abandona a antiga separação lista/mapa e adota uma composição em três camadas sobrepostas:

1. **Superfície de Fundo (Tela Cheia)**: `SuperficieGloboExplorar` ocupando 100% da área útil, sem botões de zoom `+`/`−` redundantes (o usuário usa pinça ou duplo-toque). Apenas uma cápsula compacta `3D/2D | 🌍` flutua discretamente no canto superior direito.
2. **Barra Superior Unificada (`BarraBuscaFiltrosExplorar`)**:
   * Campo de busca difusa (`Pico, cidade, via ou serra...`) com botão de limpeza `✕`.
   * Botão rápido **`Grau`** imediatamente ao lado da busca: abre um popover enxuto com dois controles deslizantes duplos (`RangeSlider`) — **Vias (`1º` a `12a`)** e **Boulder (`V0` a `V15`)**. Quando ativo, o próprio botão exibe o recorte (ex.: `7a–8b`).
   * Botão **`Filtros e Ordenação`** (`Icons.tune_rounded`) com contador numérico de filtros ativos, abrindo o modal completo alinhado ao `PainelFiltrosIndice`.
   * Linha horizontal opcional de chips ativos removíveis (`Via 7a–8b ✕`, `Paredão ✕`, `< 150 km ✕`) que só ocupa espaço quando há filtro aplicado.
3. **Gaveta Inferior em 3 Posições (`GavetaDeslizanteExplorar`)**:
   * **Estágio `Mapa` (~66px)**: recolhe a lista exibindo apenas a alça, contagem de picos encontrados e seletor rápido de estágio, liberando quase toda a tela para girar o globo e inspecionar bolhas de chuva.
   * **Estágio `Dividir` (~36% da tela)**: visão padrão equilibrada entre mapa acima e cards abaixo, acompanhada das pílulas rápidas de modalidade (`Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão`).
   * **Estágio `Lista` (~80% da tela)**: imersão de catálogo para leitura comparativa rápida.

### 3.2. Projeção Matemática Contínua (Câmera Única sem Cortes)
Para eliminar qualquer corte brusco ou *crossfade* artificial entre o globo e a montanha local, todos os 4 LODs compartilham **uma única equação de projeção** controlada pela variável contínua `lod` $\in [0{,}0,\; 3{,}2]$.

O raio aparente do planeta escala exponencialmente com `lod`:

$$R(\text{lod}) = R_0 \cdot b^{\text{lod}} \quad \text{com } R_0 = 142\text{ px},\; b = 7{,}6$$

* Em `lod = 0,0`, $R = 142\text{ px}$ (o hemisfério inteiro cabe na largura do celular).
* Em `lod = 3,0`, $R \approx 62.300\text{ px}$ (uma janela de `~20 km` ao redor do pico preenche a tela).

Dada uma coordenada geográfica $(\phi, \lambda)$ e elevação $h$ (em metros acima do nível do mar), centrada no foco da câmera $(\phi_0, \lambda_0)$:

