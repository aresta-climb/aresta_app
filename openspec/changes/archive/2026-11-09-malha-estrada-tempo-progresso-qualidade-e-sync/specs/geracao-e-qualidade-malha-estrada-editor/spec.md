# geracao-e-qualidade-malha-estrada-editor Specification

## Purpose
Define o fluxo de geração da malha viária de picos no Editor Desktop e via MCP (com feedback de progresso em streaming e confirmação manual), a validação de malha no deploy e a integração da malha de pontos no Painel de Qualidade e no relatório `STATUS_CROQUIS.md`.

## ADDED Requirements

### Requirement: Progresso em Streaming na Consulta Overpass e Confirmação Manual no Diálogo
Durante a geração da malha viária no Editor Desktop, o cliente Overpass DEVE (MUST) ler a resposta HTTP em blocos (*streaming*), reportando continuamente o espelho consultado, o tempo decorrido e os megabytes baixados (permitindo cancelamento imediato entre blocos), e o diálogo de progresso DEVE (MUST) permanecer aberto ao atingir 100%, exibindo um botão `Concluir` para o usuário inspecionar o log antes de fechar.

#### Scenario: Exibição de megabytes recebidos e cancelamento durante download no Overpass
- **WHEN** o servidor Overpass inicia o envio do JSON da malha viária de um pico
- **THEN** o diálogo atualiza a barra de progresso (`15%` a `42%`) informando os MB recebidos do espelho ativo e interrompe imediatamente a leitura caso o usuário acione `Cancelar`.

#### Scenario: Permanência do diálogo ao finalizar 100% até clique em Concluir
- **WHEN** todas as etapas de geração da malha viária terminam com sucesso (`100%`)
- **THEN** o diálogo não fecha automaticamente, mantém o histórico completo de mensagens visível e habilita o botão `Concluir` para fechamento pelo usuário.

### Requirement: Verificação Fiel do Conteúdo da Malha Viária no Deploy
O script de deploy (`deploy_generated.py`) DEVE (MUST) validar se a malha viária de cada pico está presente e sincronizada com a coordenada do pico inspecionando a mensagem interna `malha_estrada.conteudo` (`malha_estrada_pico_atualizada`), sem emitir falso aviso quando a malha já está atualizada.

#### Scenario: Pico com malha_estrada atualizada dentro do wrapper ArquivoMalhaEstrada
- **WHEN** um croqui compilado possui `pico.malha_estrada.conteudo` com `nos` não vazios e coordenadas de referência idênticas às do pico
- **THEN** `verificar_malha_estrada_pico` retorna `True` e nenhum aviso de falta de mapa de pontos é emitido no console de compilação/publicação.

### Requirement: 8ª Tarefa Essencial de 1.000 Pontos no Painel de Qualidade
O avaliador de nota de qualidade (`avaliador_nota_qualidade.py`) DEVE (MUST) incluir na Etapa 1 ("Pronto para Publicar") uma 8ª tarefa essencial (`etapa1_malha_estrada_picos`) valendo `1000` pontos (elevando o máximo da Etapa 1 para `8000` e a nota máxima total para `8770`), exigindo que todos os picos do croqui possuam malha viária gerada e atualizada para sua coordenada.

#### Scenario: Croqui com pico sem malha viária atualizada
- **WHEN** um croqui possui ao menos um pico sem malha viária ou com coordenada divergente da malha gerada
- **THEN** a tarefa `etapa1_malha_estrada_picos` pontua proporcionalmente aos picos atualizados, fica marcada como pendente (`concluida = False`), bloqueia `pronto_para_publicar` e lista uma ação de navegação para o pico pendente.

### Requirement: Ferramentas MCP para Geração de Malha e Diagnóstico de Qualidade e Relatório STATUS_CROQUIS
O servidor MCP do Editor DEVE (MUST) disponibilizar as ferramentas `aresta_gerar_malha_estrada` (para gerar a malha viária de um pico ou de todos os picos do croqui aberto) e `aresta_avaliar_qualidade` (retornando o diagnóstico estruturado completo do Painel de Qualidade), e o script `medir_saude_croquis.py` DEVE (MUST) gerar `STATUS_CROQUIS.md` como um espelho direto do resultado de `avaliar_nota_qualidade_croqui`.

#### Scenario: Consulta MCP de qualidade e geração de malha pelo agente
- **WHEN** um agente invoca `aresta_avaliar_qualidade` em um croqui sem malha viária e em seguida executa `aresta_gerar_malha_estrada`
- **THEN** `aresta_avaliar_qualidade` aponta inicialmente a pendência em `etapa1_malha_estrada_picos`, `aresta_gerar_malha_estrada` gera e vincula `malha_estrada.yaml`, e uma nova chamada a `aresta_avaliar_qualidade` confirma a tarefa concluída (`1000/1000` pts).

#### Scenario: Geração do STATUS_CROQUIS.md refletindo o Painel de Qualidade
- **WHEN** `medir_saude_croquis.py` é executado sobre a base de croquis
- **THEN** `STATUS_CROQUIS.md` exibe para cada croqui sua nota total (`X / 8770`), status de prontidão para publicação, pontuação por etapa (Etapas 1, 2 e 3) e a lista de tarefas pendentes do Painel de Qualidade.
