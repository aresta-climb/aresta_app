## Context

Atualmente, quando o aplicativo sincroniza informações em segundo plano, o serviço `SyncService` inicia `Isolates` que realizam downloads e processam arquivos em caminhos temporários (`.tmp`). Quando esses downloads acabam, eles são substituídos atomicamente na pasta oficial pela Main Isolate (Thread principal). No entanto, por causa de uma flag reativa genérica de download, a interface do aplicativo bloqueia (deixa cinza e não-clicável) qualquer interação com esses croquis. Como os arquivos oficiais só são removidos da pasta original na fração de milissegundo final da substituição atômica, o bloqueio do croqui durante o longo processo de download é desnecessário e prejudicial à experiência do usuário. 

Isso será ajustado. Contudo, abrir um croqui durante sua substituição requer cuidado: se as imagens que formam o mapa sumirem e o motor de mapa interno continuar rodando, haverá um erro (crash). Por conta disso, o Isolate de download precisará passar a ser não apenas melhor documentado em seus eventos, mas a UI precisará interagir e travar a conclusão desse Isolate até o momento oportuno.

## Goals / Non-Goals

**Goals:**
- **Resolver bug de estado residual**: O processo `_downloadOrUpdatePico` precisará limpar com sucesso o dicionário de progresso de download independentemente do Isolate concluir com êxito ou erro.
- **Documentação de Isolates**: Melhorar significativamente a legibilidade e a documentação via `docstrings` para o sistema de background worker de sync.
- **Desbloquear Interface Principal**: As páginas `home.dart` e `browse.dart` devem permitir o acesso ao croqui antigo funcional.
- **Gerenciamento de Estado Reativo (`pico_aberto_id`)**: Monitorar com precisão o croqui atualmente vizualizado na thread principal.
- **Garantir Testes em Primeiro Lugar (TDD e Integração)**: Seguir estritamente 100% de Test Coverage em qualquer classe impactada, e desenvolver **Testes de Integração** fim-a-fim para comprovar os fluxos com e sem o croqui aberto.

**Non-Goals:**
- Implementar cache próprio de tiles no motor do mapa (o bloqueio de fluxo na camada de UI/Sync resolve o problema).
- Mudar ou atualizar a biblioteca de background Isolate existente. 

## Decisions

1. **Rastreamento de Estado e Inexistência de Race Conditions**:
   Introduziremos um estado simples via `ValueNotifier<String?> pico_aberto_id` (em `DatasetRepository` ou no próprio `SyncService`). O ciclo de vida dos mapas alterará este valor no método `initState` e o limpará no `dispose`. 
   **Sobre a Concorrência**: Como o motor Dart utiliza o modelo de Isolates para background tasks, o SyncService roda na **Main Isolate** (mesma thread da UI Flutter). As tarefas pesadas de rede acontecem em um Background Isolate, que comunica o fim do processamento através de portas de mensagens (`ReceivePort`). Quando o evento de sucesso chega no Event Loop da Main Isolate, a leitura de `pico_aberto_id` pela função de commit ocorre de forma completamente síncrona. Assim, por design da linguagem, não há *Race Conditions* com ponteiros de UI na avaliação atômica, eliminando a necessidade de "Mutex Locks".

2. **Fluxo de Notificação e Pausa Atômica**:
   Quando a mensagem via `ReceivePort` confirmar sucesso, a rotina verificará de forma síncrona se `pico_aberto_id.value == pico_sendo_atualizado.id`.
   Se **NÃO**, o serviço executa o commit atômico (`applyAtomicFileUpdates`) imediatamente.
   Se **SIM**, o serviço adiciona este `id` em um notificador de pendência (`ValueNotifier<String?> recarga_pendente_pico_id`). A interface escuta e abre o Diálogo de bloqueio. O clique do usuário aplica a pendência e recarrega a rota.

3. **Arquitetura Orientada a Testes**:
   Dois fluxos vitais de Testes de Integração serão escritos. Um para testar o popup bloqueante com recarga e outro testando uma sincronização 100% silenciosa para um croqui fechado.

## Risks / Trade-offs

- **Risco**: Falta de sincronicidade ou "memory leaks" caso o `dispose` da página não for invocado em um fechamento abrupto, fazendo com que atualizações fiquem pendentes eternamente.
  - **Mitigação**: Todo o código referente a esses notificadores será submetido a rigorosos Widget Tests (simulando montagem, encerramento de rota) assegurando o correto funcionamento.
