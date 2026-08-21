## Context

O Aresta Climb é um aplicativo de escalada desenhado para funcionar prioritariamente em campo (offline-first). Durante auditoria do fluxo offline, foram identificados dois pontos de aprimoramento:
1. O `NearbyCragsCarousel` utilizava consulta HTTP em `ip-api.com` em vez de confiar apenas em sinais de satélite e cache local de coordenadas.
2. A tela `DatabaseMigrationScreen` carecia de feedback detalhado de progresso, diagnóstico contextual e retomada automática quando a internet é restabelecida.

## Goals / Non-Goals

### Goals
- Eliminar 100% das requisições HTTP externas no módulo de geolocalização do carrossel de picos próximos.
- Salvar coordenadas GPS com sucesso no `SharedPreferences` para recuperação instantânea e precisa quando o sinal de GPS estiver instável ou indisponível.
- Aprimorar a experiência visual da `DatabaseMigrationScreen` com etapas de progresso explícitas e mensagem explicativa clara.
- Implementar auto-retry reativo na `DatabaseMigrationScreen` monitorando mudanças no `Connectivity().onConnectivityChanged`.
- Cobrir 100% do código modificado com testes automatizados (TDD com Widget Tests prioritários).

### Non-Goals
- Não alterar o algoritmo matemático de cálculo de distâncias esféricas (`Geolocator.distanceBetween`).
- Não alterar a lógica de download de croquis individuais fora do processo de migração de índice.

## Decisions

### 1. Hierarquia de Resolução de Localização sem Dependência Externa
- **Decisão**: Ao iniciar o carrossel, o app tenta GPS de alta precisão (3s), seguido de baixa precisão (2s), última posição conhecida do SO e, finalmente, as coordenadas cacheadas no `SharedPreferences` (`last_known_latitude` e `last_known_longitude`).
- **Justificativa**: Garante que o usuário nunca espere por chamadas de rede lentas ou falhas de segurança de HTTP em texto claro. Se nenhuma coordenada estiver disponível, a UI reage graciosamente sem bloquear.

### 2. Auto-Retry Reativo e Etapas de Migração na `DatabaseMigrationScreen`
- **Decisão**: A tela de migração gerencia um estado explícito com etapas (`verificando`, `baixando`, `concluido`, `erro`) e ouve o stream `Connectivity().onConnectivityChanged`.
- **Justificativa**: Quando o usuário recupera o sinal (por exemplo, ao sair do modo avião ou conectar ao Wi-Fi), o aplicativo retoma a sincronização automaticamente sem que o usuário precise ficar pressionando o botão de repetição.

## Risks / Trade-offs

- **Risco**: `SharedPreferences` pode conter coordenadas muito antigas se o usuário viajou para outro estado enquanto o app estava fechado.
  - **Mitigação**: O cache local é utilizado apenas como fallback imediato; assim que o GPS obtém nova leitura, o valor em disco e a ordenação são atualizados.
