# Proposta: Simplificação do Modo Experimental

## Why

Atualmente, o Modo Experimental impõe um temporizador rígido de 20 minutos com auto-destruição compulsória dos dados ao zerar, forçando atualizações de estado a cada segundo na UI e interrompendo testes em andamento de forma abrupta. Além disso, o aplicativo carrega resquícios de suporte a arquivos `.croqui` e `.zip` locais (como o scheme `aresta-zip://` e avisos em tela), que não fazem mais sentido frente ao ecossistema moderno e estável de conexão remota (Cloudflare Relay, Direct LAN e WebSocket Live Reload).

Esta mudança remove o limite de tempo durante a sessão do aplicativo, consolida o fluxo experimental exclusivamente através de conexão remota e elimina códigos mortos e menções a arquivos locais no `aresta_app` (preservando o submódulo `aresta_api`).

## What Changes

- **Remoção do Limite de Tempo**:
  - Elimina o cronômetro regressivo de 20 minutos (`_countdownTimer`, `timeRemaining`, `_expirationTime`) em `EditorDeCroqui`.
  - Remove as reconstruções periódicas de 1s na UI em `BannerModoExperimental`, exibindo apenas o rótulo limpo `MODO EXPERIMENTAL ATIVO` junto com a ação de saída `[ SAIR ]`.
  - Adota a **Opção A (Sessão Volátil)**: a conexão experimental permanece ativa enquanto o aplicativo estiver aberto; ao reiniciar o aplicativo (boot), o sistema limpa os dados temporários e restaura com segurança o Modo Oficial.
- **Foco Exclusivo em Conexão Remota**:
  - Descontinua e remove guardas residuais de arquivos locais `.croqui`, `.zip` e o scheme `aresta-zip://` em `EditorDeCroqui` e `settings_functions.dart`.
  - Ajusta textos e descrições na interface de configurações e documentações (`README.md`), explicitando a conexão em tempo real com o Editor Desktop.
  - Mantém o submódulo `frontend/lib/aresta_api` intocado (necessário para o `aresta_db`), mas remove referências e imports legados no código da aplicação `aresta_app`.
- **Atualização de Testes**:
  - Atualiza a suíte de testes de `banner_modo_experimental_test.dart` e `experimental_mode_test.dart` para refletir o comportamento sem expiração por temporizador.

## Capabilities

### New Capabilities

### Modified Capabilities
- `hot-reload-experiencia-usuario`: Remove a expiração por temporizador do modo experimental, simplificando a exibição do `BannerModoExperimental` para um indicador limpo sem contagem regressiva e definindo a sessão como volátil (ativa enquanto aberto, restaurando modo oficial no boot).

## Impact

- `frontend/lib/services/editor_croqui.dart`: Remoção de `timeRemaining`, `_expirationTime`, `_countdownTimer`, `forceResetTimer` e `aresta-zip://`.
- `frontend/lib/widgets/banner_modo_experimental.dart`: Remoção do `ValueListenableBuilder<Duration?>` e do texto de contagem regressiva.
- `frontend/lib/view_functions/settings_functions.dart`: Remoção de validações de extensão `.croqui`/`.zip` e atualização do texto descritivo do card do editor.
- `frontend/lib/services/README.md` e `frontend/README.md`: Atualização da documentação sobre o ciclo de vida do modo experimental.
- `frontend/test/widgets/banner_modo_experimental_test.dart` e `frontend/test/services/experimental_mode_test.dart`: Atualização e adequação dos testes.
- Submódulo `frontend/lib/aresta_api`: Intocado, preservando arquivos e compatibilidade com `aresta_db`.
