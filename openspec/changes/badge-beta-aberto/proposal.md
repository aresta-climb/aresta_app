## Why

Embora o Aresta Climb já esteja publicado nas lojas (Google Play Store e Apple App Store), o aplicativo encontra-se em estágio de MVP com desenvolvimento ativo e muitas funcionalidades essenciais ainda no roadmap. Para alinhar as expectativas dos usuários, prevenir avaliações negativas precipitadas sobre ausência de recursos e transformar os escaladores em co-criadores engajados, é fundamental evidenciar de forma transparente e harmoniosa que o aplicativo opera em fase de "Beta Aberto".

## What Changes

- **Splash Screen Nativa**: Atualização do asset `assets/logo_splash.png` para incluir a inscrição `CLIMB • BETA` e regeneração das telas de inicialização nativas Android e iOS via `flutter_native_splash`.
- **Micro-Badge de Beta na Home**: Adição de um chip compacto `BETA` no cabeçalho da Home ao lado da marca `ARESTA`, com tom verde musgo (`dryMoss`), preservando o layout contra quebras ou `RenderFlex overflow` em telas de menor resolução.
- **BottomSheet Informativo Interativo**: Implementação de modal explicativo acionado pelo toque no badge de beta, contextualizando o estágio atual do aplicativo e oferecendo um botão direto de ação para o fluxo de feedback (`BetterFeedback`).
- **Identificação de Versão em Configurações**: Adição de rodapé na página de Configurações exibindo a versão do aplicativo acompanhada do sufixo `(Beta Aberto)` e atalho para o modal informativo.
- **Identificação de Versão na Comunidade**: Atualização do rodapé da tela de Comunidade para exibir `Aresta Climb vX.X.X • Beta Aberto`.

## Capabilities

### New Capabilities
- `comunicacao-beta-aberto`: Gerencia a identificação visual e a comunicação interativa do estágio de "Beta Aberto" no aplicativo, englobando a sinalização na Splash Screen, micro-badge na Home, modal informativo com atalho de feedback e detalhamento de versão nas telas de apoio (Configurações e Comunidade).

### Modified Capabilities
<!-- Nenhuma especificação anterior teve seus requisitos de domínio modificados. -->

## Impact

- **Assets e Configuração**: `frontend/assets/logo_splash.png` e execução da ferramenta `flutter_native_splash`.
- **UI / Frontend**:
  - `frontend/lib/view_functions/home_functions.dart` (Header da Home com o micro-badge e modal).
  - `frontend/lib/pages/settings.dart` e `frontend/lib/view_functions/settings_functions.dart` (Rodapé de versão com status de beta).
  - `frontend/lib/view_functions/comunidade_functions.dart` (Rodapé de versão com sufixo beta).
  - Novo widget/modal em `frontend/lib/widgets/` para o BottomSheet explicativo do Beta.
- **Testes**: Testes de widget e de regressão visual para garantir layout responsivo livre de overflow e 100% de cobertura (TDD).
