# telemetria-performance-aplicativo Specification

## Purpose

Medir e monitorar a performance ponta a ponta do aplicativo até a interatividade real das telas (*Time to Interactive*), emitindo métricas simultaneamente para o Firebase Performance (percentis P50/P90/P99) e para o Google Analytics 4 (`duracao_ms` com dimensões de fatiamento para o Looker Studio), com garantia estrita de desativação em modo debug.

## ADDED Requirements

### Requirement: Bloqueio Estrito de Telemetria de Performance em Modo Debug
O sistema DEVE (MUST) desativar explicitamente a coleta do Firebase Performance e o envio de eventos de performance ao Google Analytics quando executado em modo de depuração (`kDebugMode == true`), registrando os tempos medidos apenas no log local de diagnóstico (`AppLogger`). Em builds de perfil ou produção (`kDebugMode == false`), a coleta DEVE estar ativa.

#### Scenario: Execução do aplicativo em modo debug
- **WHEN** o aplicativo é inicializado e utilizado em modo de depuração (`kDebugMode == true`)
- **THEN** a coleta do SDK de performance é desativada (`setPerformanceCollectionEnabled(false)`) e nenhuma trace ou evento de performance é enviado para os servidores de telemetria, exibindo os tempos apenas no console local

#### Scenario: Execução do aplicativo fora do modo debug
- **WHEN** o aplicativo é inicializado em modo release ou profile (`kDebugMode == false`)
- **THEN** a coleta do SDK de performance é habilitada (`setPerformanceCollectionEnabled(true)`) e as métricas são transmitidas normalmente

### Requirement: Dupla Emissão com Atributos de Fatiamento (Firebase Performance + GA4 / Looker Studio)
Para cada fluxo crítico monitorado, o sistema DEVE (MUST) emitir simultaneamente uma trace customizada no Firebase Performance (contendo atributos e métricas numéricas para análise de percentis P50, P90 e P99) e um evento no Google Analytics 4 contendo o parâmetro numérico `duracao_ms` acompanhado das dimensões de fatiamento (*slicing*), permitindo agregação e filtragem cruzada no Looker Studio. Todo o código de integração com pacotes `firebase_*` DEVE residir exclusivamente dentro de `lib/services/firebase/`.

#### Scenario: Emissão simultânea de trace e evento analítico com duração e dimensões
- **WHEN** uma operação monitorada conclui sua medição até o frame interativo
- **THEN** o sistema finaliza a trace correspondente com seus atributos anexados e despacha o evento analítico contendo `duracao_ms` e os mesmos atributos de fatiamento

### Requirement: Medição de Inicialização até a Interatividade Real (Cold Start e Warm Start)
O sistema DEVE (MUST) medir o tempo de abertura do aplicativo até o momento em que a tela de destino está efetivamente renderizada e pronta para interação do usuário (`addPostFrameCallback` do frame pós-transição):
1. **Cold Start ➔ Home (`cold_start_home` / `performance_abertura_app`)**: desde o início da execução em `main()` até o primeiro frame renderizado da `HomePage` após a saída da splash screen, com atributos `tipo_start: 'cold_start'` e `destino: 'home'`.
2. **Cold Start ➔ Deep Link (`cold_start_deep_link` / `deep_link_aberto`)**: desde o início da execução em `main()` até o primeiro frame renderizado da tela da entidade (`pico`, `grupo`, `setor`, `via` ou `mapa`), fatiado por `destino`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`), `abrir_mapa` e `sucesso`.
3. **Warm Start ➔ Deep Link (`warm_start_deep_link` / `deep_link_aberto`)**: desde a recepção da URI com o aplicativo em segundo plano até o primeiro frame renderizado da tela de destino, fatiado por `destino`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`), `abrir_mapa` e `sucesso`.

#### Scenario: Medição de Cold Start até a Home pronta para uso
- **WHEN** o aplicativo inicia do zero sem deep link e conclui a saída da splash screen renderizando a `HomePage`
- **THEN** o sistema registra a trace `cold_start_home` e o evento `performance_abertura_app` com `duracao_ms`, `tipo_start: 'cold_start'` e `destino: 'home'` apenas após o `addPostFrameCallback` da tela inicial

#### Scenario: Medição de Cold Start ou Warm Start para Deep Link até a página da entidade estar interativa
- **WHEN** o aplicativo abre um deep link (em Cold Start ou Warm Start) e a página de destino termina de renderizar seu primeiro frame
- **THEN** o sistema registra a trace correspondente (`cold_start_deep_link` ou `warm_start_deep_link`) e inclui `duracao_ms` e `modo_acesso` no evento `deep_link_aberto`

### Requirement: Medição Fatiada de Sincronização em Duas Fases (`sync_index_fase1` e `sync_index_fase2`)
O sistema DEVE (MUST) medir separadamente as duas fases da sincronização do catálogo (`syncIndex`):
1. **Fase 1 (`sync_index_fase1` / `performance_sync_index`)**: tempo de verificação do `indice.binarypb` e aplicação do delta do `catalogo.db`, fatiado obrigatoriamente por `fase: 'fase1_indice_catalogo'`, `status_http` (`304`, `200`, `offline`, `erro`), `origem` (`auto`, `manual`) e `modo` (`oficial`, `experimental`).
2. **Fase 2 (`sync_index_fase2` / `performance_sync_index`)**: tempo da tarefa em segundo plano de atualização de thumbnails e croquis baixados até o commit atômico dos arquivos `.tmp`, fatiado por `fase: 'fase2_midias_background'` e `teve_atualizacao` (`true`/`false`), incluindo as métricas `qtd_picos_atualizados` e `qtd_thumbs`.

#### Scenario: Diferenciação entre resposta 304 Not Modified, 200 OK e Offline na Fase 1
- **WHEN** `syncIndex()` executa a Fase 1 e recebe `304`, `200` ou falha por ausência de rede
- **THEN** o sistema registra `sync_index_fase1` e `performance_sync_index` com `duracao_ms` e o atributo `status_http` preenchido com `'304'`, `'200'` ou `'offline'`, permitindo separar os tempos no Firebase e no Looker Studio

#### Scenario: Medição da Fase 2 de mídias em segundo plano com contadores de volume
- **WHEN** a etapa em segundo plano do `syncIndex` finaliza o download e renomeação atômica de thumbnails e croquis
- **THEN** o sistema registra `sync_index_fase2` e `performance_sync_index` com `duracao_ms`, `teve_atualizacao`, `qtd_picos_atualizados` e `qtd_thumbs`

### Requirement: Medição de Abertura de Croqui, Navegação Interna e Mapa Interativo
O sistema DEVE (MUST) medir a latência percebida pelo usuário ao explorar croquis e mapas até que o componente visual esteja pronto para uso:
1. **Abrir Croqui (`abrir_croqui` / `acao_croqui`)**: do toque no card do pico até a resolução do `compilado.binarypb` e renderização do primeiro frame da página do pico, fatiado por `id_croqui`, `modo_acesso` (`memoria`, `offline`, `temp_cache`, `cdn_online`) e `origem` (`home`, `explorar`, `meus_croquis`, `mapa_global`).
2. **Navegação Interna do Croqui (`navegacao_interna_croqui` / `abrir_setor`, `abrir_grupo`, `acao_escalada`)**: do clique em um setor, grupo ou via até o `addPostFrameCallback` da página de destino, fatiado por `id_croqui`, `destino` (`setor`, `grupo`, `via`) e `modo_acesso` (`offline`, `online`).
3. **Abrir Mapa Interativo (`abrir_mapa_interativo` / `abrir_mapa`)**: da abertura da `MapaInterativoPage` (ou troca de mapa no carrossel) até a resolução da imagem por `ProvedorImagemAresta.resolver` **e** a decodificação efetiva do primeiro frame da imagem `.webp` na tela (`frame != null` em `Image.frameBuilder`), fatiado por `id_croqui`, `modo_acesso` (`offline`, `online`) e `origem_imagem` (`downloads`, `temp_cache`, `cdn_remoto`).

#### Scenario: Abertura de croqui fatiada pela camada real do cache
- **WHEN** o usuário seleciona um pico e a página do croqui termina de renderizar seu primeiro frame
- **THEN** o sistema registra a trace `abrir_croqui` e o evento `acao_croqui` com `duracao_ms` e `modo_acesso` refletindo a camada exata que atendeu a leitura (`memoria`, `offline`, `temp_cache` ou `cdn_online`)

#### Scenario: Abertura de setor, grupo ou via dentro de um croqui
- **WHEN** o usuário toca em um setor, grupo ou via e a tela correspondente renderiza seu primeiro frame
- **THEN** o sistema registra a trace `navegacao_interna_croqui` e adiciona `duracao_ms` e `modo_acesso` (`offline` ou `online`) ao evento analítico correspondente (`abrir_setor`, `abrir_grupo` ou `acao_escalada`)

#### Scenario: Abertura de mapa interativo medida até a decodificação da imagem na tela
- **WHEN** o usuário abre o mapa interativo de um pico, grupo ou setor e o widget `Image` decodifica o primeiro frame da imagem `.webp` (`frame != null`)
- **THEN** o sistema encerra a medição `abrir_mapa_interativo` e registra `duracao_ms`, `modo_acesso` (`offline` ou `online`) e `origem_imagem` (`downloads`, `temp_cache` ou `cdn_remoto`) no evento `abrir_mapa`
