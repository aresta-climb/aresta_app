## Por que esta mudança é necessária? (Why)

A validação visual comparativa entre o aplicativo móvel (`aresta_app`) e o editor desktop (`aresta_db`) revelou divergências substanciais de renderização nos traçados vetoriais:
1. O tracejado (`TRACEJADO`) se funde em uma linha contínua devido à aplicação do `dashPath` em coordenadas absolutas do SVG antes da matriz de escala do viewport de tela.
2. A espessura do traço e seus halos são aplicados em unidades físicas fixas de densidade de tela (`6.0 dp`), resultando em uma linha aproximadamente 6 vezes mais grossa e pesada do que no editor.
3. O círculo identificador da base ("1") apresenta cores invertidas (fundo branco chapado com texto preto, em vez do fundo ciano com texto branco e borda dupla de alto contraste do editor).
4. O raio do círculo identificador cobre uma proporção exagerada da rocha quando o mapa está sem zoom.
5. Linhas vetoriais recém-desenhadas ou caminhos de acesso sem vínculo em `mapa.referencias` são ocultados pelo aplicativo (`SizedBox.shrink()`).

Esta mudança adequa a renderização visual do aplicativo para 100% de fidelidade ao editor desktop, aderindo estritamente aos 7 princípios de engenharia do repositório (`PRINCIPIOS.md`).

## O que muda? (What Changes)

- **Fidelidade Cromática dos Marcadores de Base**: O círculo identificador adota a mesma composição visual do editor: fundo na cor da via (`corLinha`), rótulo textual centralizado em branco em negrito, borda intermediária branca e casing externo escuro de alto contraste.
- **Espessura Proporcional da Linha e dos Halos**: A espessura do traço, do casing e do halo de seleção é calculada proporcionalmente à escala da imagem no viewport, preservando a delicadeza e legibilidade do editor.
- **Tracejado Dinâmico em Coordenadas de Tela**: A decomposição do caminho tracejado é aplicada no espaço métrico da tela (viewport local em dp), garantindo que traços e vãos sejam perfeitamente visíveis em qualquer tela ou resolução de imagem.
- **Dimensionamento Adaptativo do Círculo Identificador**: O raio do círculo e a tipografia adaptam-se à escala da imagem com limites seguros (clamp) para ergonomia de toque e nitidez.
- **Renderização Incondicional de Traçados de Linha**: Traçados vetoriais são desenhados mesmo sem entrada correspondente em `mapa.referencias`, permitindo pré-visualização imediata no Live Reload e suporte a trilhas/acessos.

## Capacidades (Capabilities)

### Capacidades Modificadas (Modified Capabilities)
- `tracados-vetoriais-app`: Ajusta os requisitos normativos de espessura proporcional, tracejado no viewport e fidelidade cromática e geométrica do círculo identificador.
- `interactive-map`: Adiciona o requisito de renderização incondicional de traçados de linha independentemente de vínculo prévio em `mapa.referencias`.

## Impacto (Impact)

- **Arquivos Afetados**:
  - `frontend/lib/pages/mapa_interativo.dart`
  - `frontend/lib/utils/construtor_caminho_trajeto.dart`
  - `frontend/test/pages/mapa_interativo_test.dart`
  - `frontend/test/utils/construtor_caminho_trajeto_test.dart`
- **Aderência aos Princípios (`PRINCIPIOS.md`)**:
  - **Tudo em Português**: Nomes de métodos, parâmetros, variáveis e comentários em português brasileiro.
  - **Widget Tests First**: Testes de widget priorizados sobre as fronteiras do `MapaInterativoPage`.
  - **TDD Rigoroso**: Ciclo Vermelho-Verde-Refatorar em todas as fases.
  - **100% de Cobertura**: Exigência inegociável nos arquivos modificados.
  - **Simplicidade e Anti-Abstração**: Cálculos diretos e declarativos sem complexidade desnecessária.
  - **Documentação Contínua**: Docstrings explicativas em `///` e atualização dos `README.md`.
