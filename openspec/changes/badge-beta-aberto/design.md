## Context

Ver `proposal.md` para motivação e justificativa de produto.

O aplicativo Aresta Climb utiliza `flutter_native_splash` para geração de splash screens nativas no Android e iOS, garantindo inicialização limpa sem retenção artificial de frames. No cabeçalho da tela inicial (`HomePage`), há uma `Row` contendo o logo, o bloco de texto `ARESTA`, um `Spacer` e três `IconButton` (sincronização, feedback e configurações). Em telas de menor resolução (como 360dp de largura), o espaço horizontal remanescente é de aproximadamente 40dp a 45dp. Além disso, o aplicativo já possui infraestrutura pronta para coleta e envio offline/online de feedback com anotações de tela (`BetterFeedback` e `FeedbackOrchestrator`).

## Goals / Non-Goals

**Goals:**
- Implementar um micro-badge responsivo `BETA` no cabeçalho da Home com dimensões ultra compactas e paleta musgo (`dryMoss`), imune a `RenderFlex overflow`.
- Criar o componente modular `ModalBetaAberto` em `frontend/lib/widgets/modal_beta_aberto.dart`, exibindo informações sobre o estágio de desenvolvimento do projeto e provendo atalho direto para acionar o `BetterFeedback`.
- Atualizar o asset `frontend/assets/logo_splash.png` com o lettering `CLIMB • BETA` e regerar os artefatos nativos de splash para Android e iOS.
- Padronizar a identificação da versão instalada com o rótulo de "Beta Aberto" no rodapé das telas de Configurações e Comunidade.

**Non-Goals:**
- Não criar telas intermediárias de splash em Flutter (mantendo 100% da inicialização nativa).
- Não alterar a saudação ou o texto explicativo de boas-vindas existente no corpo da Home.
- Não modificar regras de negócio ou contratos de telemetria do `BetterFeedback`.

## Decisions

### 1. Micro-Badge Compacto no Header com Paleta Musgo (`dryMoss`)
* **Decisão**: Criar o micro-badge com `padding` horizontal de 6px e vertical de 2px, tipografia `Montserrat` Bold de 9.5px com `letterSpacing: 1.0`, utilizando fundo `darkPine` e borda/texto em `dryMoss`. Toda a área do chip é envolta por `InkWell` (ou `GestureDetector`) para toque.
* **Alternativas consideradas**:
  - *Badge com ícone `ℹ️` integrado*: Descartado devido ao consumo horizontal extra (~24dp adicionais), o que causaria quebra de layout em telas de 360dp ou menos.
  - *Banner horizontal no corpo da tela*: Descartado para não empurrar os carrosséis de picos e vias para baixo.

### 2. Componente Modular Desacoplado `ModalBetaAberto`
* **Decisão**: Desenvolver o widget `ModalBetaAberto` (e função auxiliar `exibirModalBetaAberto(BuildContext context)`) em arquivo isolado na camada de widgets (`frontend/lib/widgets/modal_beta_aberto.dart`), seguindo rigorosamente os Princípios de Engenharia (Feature-First e tudo em português). O modal utiliza `showModalBottomSheet` com cantos superiores arredondados e fundo `deepBasalt`.
* **Ação de Feedback**: O botão primário "Enviar Sugestão" fecha o bottom sheet e aciona imediatamente `BetterFeedback.of(context).show(...)`.

### 3. Splash Screen com Lettering no Asset Central
* **Decisão**: Atualizar `frontend/assets/logo_splash.png` substituindo `CLIMB` por `CLIMB • BETA` na composição gráfica e executar `dart run flutter_native_splash:create`.
* **Alternativas consideradas**:
  - *Uso de branding no rodapé nativo*: Descartado devido a inconsistências de recorte e posicionamento impostas pelo Android 12+ Splash API em telas com proporções variadas.

### 4. Integração de Versão em Configurações e Comunidade
* **Decisão**:
  - Na tela de Comunidade ([`comunidade_functions.dart`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/view_functions/comunidade_functions.dart)), atualizar a linha de texto para `Aresta Climb v$version • Beta Aberto`.
  - Na tela de Configurações ([`settings.dart`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/pages/settings.dart) e [`settings_functions.dart`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/view_functions/settings_functions.dart)), adicionar rodapé com `Aresta Climb v$version (Beta Aberto)` e toque para abrir o `ModalBetaAberto`.

## Risks / Trade-offs

- **[Risco de quebra de layout em telas ultra compactas (ex: 320dp de largura)]** → *Mitigação*: Uso de `Flexible`/`FittedBox` protetivo no cabeçalho e validação obrigatória via testes de widget com dimensões estritas de 320x640 e 360x800.
- **[Aparelhos sem conexão ao clicar em Feedback pelo modal]** → *Mitigação*: Nenhuma ação necessária, pois a fila offline do `FeedbackOrchestrator` armazena feedbacks localmente e despacha quando a conectividade é restabelecida via `NetworkFeedbackTrigger`.
