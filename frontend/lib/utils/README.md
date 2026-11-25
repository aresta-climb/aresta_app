# Utilitários (`lib/utils/`)

Este diretório reúne cálculos geométricos, formatação de escaladas, geração de identificadores e filtros de catálogo.

---

## 1. Traçados Vetoriais (`construtor_caminho_trajeto.dart` e `pincel_destaque_mapa.dart`)

Converte strings SVG Path Data (`M ... C ...`) em objetos `ui.Path` e avalia toques nas linhas do mapa interativo:
- **Isolamento**: Apenas `lib/utils/construtor_caminho_trajeto.dart` pode importar `package:path_drawing/` (verificado por `test/architecture/path_drawing_isolation_test.dart`).
- **Cache**: Armazena em memória os `Path` compilados por `"$chaveCache-$estilo"` e os `TextPainter` dos marcadores (`obterTextPainterMarcador`), com limpeza via `ConstrutorCaminhoTrajeto.limparCache()`.
- **Toque em Linhas (`calcularDistanciaAoCaminho`)**: Amostra a curva a cada ~15 unidades e calcula a menor distância euclidiana até os segmentos; toques a até `16.0dp` selecionam a via.
- **Renderização**: Aplica tracejado/pontilhado em coordenadas de viewport (`aplicarEstiloNoViewport`), espessura limitada a `2.0..4.0dp`, contorno escuro de contraste, traço na cor da modalidade/via, halo de seleção e círculos numerados de base (`CIRCULO_IDENTIFICADOR` e `INICIO_AGACHADO`).

---

## 2. Consulta e Rótulos de Mapas (`consulta_dataset.dart` e `extrator_rotulos_referencia.dart`)

- **`DatasetResolver` (`consulta_dataset.dart`)**: Indexa por `uid` todos os botões, grupos, setores, escaladas e referências de mapas de um `Pico` (armazenado via `Expando` por instância de `Pico`) e monta a lista de itens do carrossel de mapas (`resolverCarrosselUnificado`).
- **`extrator_rotulos_referencia.dart`**: Extrai o rótulo numérico ou textual associado a `ref.pontosUids` nos pontos de interesse de um mapa.

---

## 3. Identificadores, Créditos e Graus

- **`gerador_uid.dart`**: Gera e valida `NanoID 14c` Base62 (`[0-9a-zA-Z]`) e `UUID v4`.
- **`formatador_creditos.dart`**: Filtra placeholders genéricos (`"Desconhecido"`, `"Sem autor"`, etc.) e formata listas de autores (`"Croqui por ..."`).
- **`formatador_escalada.dart`**: Formata graus brasileiros e escala V, extrai nomes e códigos numéricos oficiais e localiza escaladas por `uid` em coleções de `Croqui`.
- **`calculadora_delta_grau.dart`**: Desloca códigos de grau por deltas inteiros (`-2` a `+2`), gera rótulos de votação e agrega votos em `ConsensoGrauVia`.
- **`extrator_detalhes_tecnicos_via.dart` e `modelos_apresentacao_via.dart`**: Extraem atributos técnicos, enfiadas, mídias e dados de consenso das cinco modalidades Protobuf para consumo declarativo na `ViaPage`.

---

## 4. Filtros e Ordenação (`filtro_grau_escalada.dart` e `consolidador_modalidades.dart`)

- **`obterPesoDificuldadeUnificado`**: Converte graus de vias e boulders para uma escala numérica comum (`0..2000`) usada em filtros e comparações.
- **`calcularMedianaGrauSetor`**: Calcula a mediana dos pesos das escaladas filtradas de um setor para ordenação por dificuldade.
- **`EstadoFiltrosUnificado`**: Estrutura imutável com modalidades ativas, faixas de grau por modalidade, setores, grupos, conquistadores, filtro de clássicas e direção de ordenação (`padrao`, `grau`, `alfabetico`).
- **`ConsolidadorModalidades`**: Contabiliza vias por modalidade em setores e grupos, tratando singular/plural e faixas de grau exibidas nos cartões.
