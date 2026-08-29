## Why

Em croquis com imagens de grandes dimensões (alta resolução ou fotos panorâmicas de grandes paredes de escalada), os usuários com frequência precisam aplicar zoom manual elevado (ex: 4.5x) para conseguir visualizar com clareza e tocar com precisão em pontos de interesse (vias, paradas ou boulders). Atualmente, ao selecionar um marcador de ponto único, o mecanismo de zoom automático força uma escala fixa arbitrária de 2.5x, provocando uma redução involuntária de zoom ("zoom out"). Isso quebra a fluidez de navegação do usuário, obrigando-o a reaplicar o zoom manual a cada elemento selecionado.

Além disso, em croquis panorâmicos extensos, o limite de escala máxima atual de 6.0x pode ser insuficiente para inspecionar detalhes milimétricos, o valor fixo de 2.5x não se adapta a geometrias com dimensões muito pequenas na tela física, e não há suporte a gestos de duplo toque para aproximação rápida.

## What Changes

### Fase 1: Zoom Monotônico para Pontos Únicos (Imediato)
- **Zoom Monotônico em Ponto Único**: Ao tocar em um marcador de ponto único (ou rota sem múltiplos marcadores de traçado), o zoom automático nunca reduzirá o nível de zoom atual. Se a escala atual for superior à escala alvo padrão (2.5x), a câmera apenas transladará suavemente para centralizar o ponto, preservando a ampliação escolhida pelo usuário (`escalaAlvo = max(escalaAtual, escalaPadrao)`).
- **Preservação de Múltiplos Pontos**: Vias com múltiplos pontos (início e cume/parada) continuam utilizando a lógica de enquadramento global (caixa delimitadora) para garantir que a extensão completa da via permaneça visível na tela.

### Fase 2: Zoom Dinâmico e Experiência Avançada para Mapas Gigantes (Evolução)
- **Zoom Dinâmico por Dimensão Confortável na Tela (~40-48dp)**: Cálculo de escala alvo adaptativa para pontos únicos baseado no tamanho do elemento na tela física, garantindo tamanho de toque e visualização confortável, com a garantia estrita de nunca reduzir a escala atual (`max(escalaAtual, escalaDinamica)`).
- **Expansão da Escala Máxima para 10.0x**: Aumento do limite `maxScale` do visualizador interativo de 6.0x para 10.0x para suportar imagens de altíssima definição.
- **Preservação da Intenção de Zoom Manual (Memória de Zoom)**: Quando o usuário ajusta manualmente o zoom via gesto de pinça, o mapa passa a preservar a escala definida pelo usuário para os próximos toques em pontos únicos, aplicando apenas translação de câmera.
- **Gesto de Toque Duplo para Zoom**: Suporte a duplo toque rápido para alternar suavemente entre a visão panorâmica geral (1.0x) e o zoom confortável de leitura focado no local tocado.

## Capacidades

### Novas Capacidades
*(Nenhuma nova capacidade isolada; trata-se de evolução do mapa interativo).*

### Capacidades Modificadas
- `interactive-map`: Aprimoramento das regras de zoom automático para pontos únicos (zoom monotônico e dinâmico), suporte a escala máxima de 10.0x, retenção da escala manual do usuário e suporte a gesto de duplo toque.

## Conformidade com PRINCIPIOS.md
- **Tudo em Português**: Toda a nomenclatura de classes, métodos, variáveis, comentários e testes será estritamente em português brasileiro (ex: `escalaAtual`, `escalaAlvoPadrao`, `escalaAlvoDinamica`, `obterEscalaMonotonica`, `usuarioAjustouZoomManualmente`).
- **TDD Rigoroso (Test-Driven Development)**: Os testes de widget serão escritos e validados no estado vermelho (falha) antes de qualquer implementação no código de produção.
- **100% de Cobertura de Testes**: Todos os novos fluxos e casos de borda serão cobertos por testes de widget e unidade.
- **Documentação Abrangente**: Todos os métodos e lógica matemática serão documentados com docstrings `///` em português explicando a intenção e motivação.

## Impacto
- **Código Frontend**: `frontend/lib/pages/mapa_interativo.dart` (cálculo de posicionamento de câmera, visualizador interativo e controladores de gestos).
- **Testes**: `frontend/test/pages/mapa_interativo_test.dart` (testes de widget para zoom monotônico, preservação de escala alta, rotas com múltiplos pontos e gestos).
- **Sem impacto em contratos de API ou Protobuf**.
