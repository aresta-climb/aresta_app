## Purpose

Unifica a descoberta geográfica e catalográfica de picos na aba `Explorar` através de um globo e relevo vetorial offline em 4 níveis de detalhe (LODs), gaveta deslizante sincronizada, filtragem nacional por faixa de dificuldade e modalidade, altimetria externa e indicadores contextuais de chuva e secagem regional (`RainTracker`).

## ADDED Requirements

### Requirement: Fusão da Aba Explorar com Globo e Relevo em 4 LODs Contínuos
A aba `Explorar` (`BrowsePage`) SHALL apresentar o mapa vetorial interativo como superfície principal em tela cheia, suportando alternância instantânea entre os modos `3D` e `2D`, sem depender de tiles externos de mapa para operar offline, e transicionando continuamente por uma única projeção matemática através de 4 níveis de detalhe (`LOD 0` Globo com clusters por estado, `LOD 1` Região com divisas estaduais e bolhas de chuva, `LOD 2` Serra e Vale com curvas de `250m` e `LOD 3` Maciço 3D com relevo escalonado pela altitude do pico, curvas de `80m` e trilha animada). A rota separada `MapaGlobalPage` (`MapaGlobalNode` e `AppNav.toMapaGlobal`) SHALL ser integralmente removida.

#### Scenario: Navegação offline do Globo até o Maciço 3D sem cortes de cena
- **WHEN** o usuário está sem conexão à internet na aba `Explorar` e amplia o zoom continuamente do `LOD 0` até o `LOD 3` sobre um pico
- **THEN** o mapa renderiza os contornos continentais e estaduais a partir dos vetores locais embutidos, inclina suavemente a câmera no modo `3D` e eleva o relevo local proporcional à altitude do pico sem cortes de cena nem falhas de rede.

#### Scenario: Alternância entre modo 3D e modo 2D
- **WHEN** o usuário aciona o botão de alternância `3D / 2D` no mapa da aba `Explorar`
- **THEN** a visualização alterna entre a projeção esférica/perspectiva inclinada (`3D`) e a projeção topográfica plana (`2D`) preservando a coordenada central, o nível de zoom e o pico selecionado.

### Requirement: Gaveta Deslizante em 3 Estágios e Auto-Scroll Sincronizado com o Mapa
A aba `Explorar` SHALL exibir uma gaveta inferior deslizante ajustável em 3 posições (`Mapa` recolhida, `Dividir` intermediária e `Lista` expandida), acoplando sua altura atual ao centro óptico do mapa para não encobrir o pico focado. Ao tocar em um marcador de pico no mapa, o sistema SHALL selecionar o pico, expandir a gaveta para `Dividir` caso esteja recolhida em `Mapa`, rolar animadamente a lista até o card correspondente mantendo a ordenação ativa, aplicar destaque visual temporário no card e emitir pulso sonar no pino selecionado. Ao selecionar um pico distante pela lista ou busca, a câmera SHALL executar transição em arco parabólico (`Fly-To`).

#### Scenario: Toque em pico no mapa aciona auto-scroll na lista
- **WHEN** a lista possui múltiplos picos ordenados por proximidade e o usuário toca no marcador de um pico posicionado fora da área visível atual da lista (ou com a gaveta recolhida em `Mapa`)
- **THEN** a gaveta ajusta-se para `Dividir` (se estava em `Mapa`), rola suavemente até exibir o card daquele pico e aplica o pulso de seleção tanto no pino quanto no card.

#### Scenario: Voo parabólico ao selecionar pico em outro estado pela lista
- **WHEN** a câmera está focada em um pico em Minas Gerais no `LOD 2` e o usuário seleciona um pico em Goiás ou no Rio de Janeiro
- **THEN** a câmera executa um voo suave com recuo intermediário de zoom antes de aproximar nas coordenadas do novo pico.

### Requirement: Filtro Rápido de Grau, Tag Paredão e Modal Completo na Busca
A barra superior da aba `Explorar` SHALL disponibilizar busca textual difusa, um botão rápido `Grau` imediatamente ao lado da barra de busca (com seletores de intervalo para Vias `1º–12a` e Boulder `V0–V15`) e o botão `Filtros e Ordenação` com contador de filtros ativos, além de atalhos de modalidade (`Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão` e `Highline`). A filtragem por faixa de grau SHALL operar offline sobre todos os picos do catálogo (inclusive não baixados) utilizando os dados locais de `catalogo.db`.

#### Scenario: Filtragem de picos não baixados por faixa de dificuldade
- **WHEN** o usuário define a faixa de grau de vias para `7a – 8a` no seletor `Grau` ao lado da barra de busca
- **THEN** tanto os marcadores do mapa quanto os cards da gaveta restringem-se imediatamente aos picos que possuem vias dentro do intervalo `7a – 8a`, mesmo que seus pacotes `.binarypb` completos não estejam baixados.

#### Scenario: Filtro rápido pela tag Paredão
- **WHEN** o usuário ativa a tag `Paredão` na gaveta ou no modal de filtros
- **THEN** apenas picos com escaladas de múltiplas enfiadas (`totalMultiplasEnfiadas > 0`) permanecem visíveis no mapa e na listagem.

### Requirement: Sistema Contextual de Chuva Regional (RainTracker) e Curva de Secagem de 5 Dias
O sistema SHALL sincronizar em segundo plano (com cache local e sem bloquear a interface) o resumo de precipitação regional e bolhas de chuva agregado no Supabase, aplicando localmente a curva determinística de secagem de 5 dias:
- Chuva `>= 15.0 mm`: `Muito molhado` por 2 dias -> `Molhado` por 2 dias -> `Levemente molhado` por 1 dia -> `Seco` (5 dias totais);
- Chuva de `5.0 mm` a `< 15.0 mm`: `Molhado` por 2 dias -> `Levemente molhado` por 1 dia -> `Seco` (3 dias totais);
- Chuva de `1.0 mm` a `< 5.0 mm`: `Levemente molhado` por 1 dia -> `Seco` (1 dia total);
- Chuva `< 1.0 mm`: `Seco`.

A interface SHALL tratar `Seco` como estado neutro padrão, omitindo qualquer selo ou aviso meteorológico em picos secos, e exibindo bolhas regionais translúcidas em tons azuis/musgo, data da chuva (`Chuva DD/MM`) e estimativa de secagem exclusivamente quando e onde houver umidade ativa impactando o pico.

#### Scenario: Progressão diária offline de um evento de chuva forte (15mm+)
- **WHEN** um pico recebeu `20 mm` de chuva no dia `25/11` salvo no cache local e o usuário consulta a aba `Explorar` offline nos dias subsequentes
- **THEN** o pico aparece como `Muito molhado` nos dias `25/11` e `26/11`, evolui para `Molhado` em `27/11` e `28/11`, passa para `Levemente molhado` em `29/11` e torna-se `Seco` (sem qualquer badge meteorológico) a partir de `30/11`.

#### Scenario: Pico seco fora da bolha de chuva permanece limpo
- **WHEN** um pico está fora do perímetro das bolhas de chuva ativas (ou já completou o ciclo de secagem)
- **THEN** seu card e seu marcador exibem apenas metadados de escalada e deslocamento (distância/tempo, altitude e vias), sem exibir rótulo "Seco" ou ícone climático.

### Requirement: Exibição de Altitude Obtida Externamente
Cada pico com coordenadas válidas SHALL exibir sua altitude estimada em metros (`Alt. <N>m`) nos cards da gaveta e nos rótulos de aproximação (`LOD 2` e `LOD 3`), proveniente da base de altimetria externa de 30m (`NASA NASADEM / SRTM GL1`) sincronizada/embarcada, sem depender de preenchimento manual dentro dos arquivos de croqui.

#### Scenario: Exibição offline da altitude de um pico
- **WHEN** o usuário visualiza o card de um pico na gaveta ou aproxima o zoom até o `LOD 2`/`LOD 3`
- **THEN** a interface exibe a altitude em metros (`Alt. <N>m`) e utiliza esse valor para escalonar a proeminência vertical da malha no `LOD 3`.

### Requirement: Rotação Atômica com Cópia Única de Segurança para Dados Externos (IBGE, NASA e Clima)
O sistema SHALL manter exatamente uma cópia de segurança anterior (`copia_seguranca`) além da versão ativa (`atual`) para os dados externos sujeitos a indisponibilidade (malhas geográficas do IBGE, altimetria da NASA e estado climático). Sempre que uma nova coleta completa e validada for obtida, o sistema SHALL sobrescrever `copia_seguranca` com o conteúdo anterior de `atual` (descartando versões mais antigas) antes de atualizar `atual`. Caso o serviço externo esteja offline ou retorne dados incompletos/inválidos, o sistema SHALL abortar a sobrescrita, preservar `atual` e `copia_seguranca` intactos (ou restaurar a partir de `copia_seguranca` em caso de leitura corrompida de `atual`) e registrar o evento via `AppLogger`.

#### Scenario: Serviço do IBGE ou da NASA indisponível durante atualização
- **WHEN** a rotina de coleta tenta atualizar malhas do IBGE ou altimetria da NASA e o provedor responde com falha de rede, timeout ou payload inválido
- **THEN** a rotina descarta a resposta inválida sem sobrescrever `atual` nem `copia_seguranca`, mantendo o sistema operacional com os últimos dados válidos.

#### Scenario: Nova coleta válida atualiza a cópia de segurança e descarta dados antigos
- **WHEN** uma nova carga completa e íntegra de dados externos é recebida
- **THEN** o registro anterior de `atual` substitui `copia_seguranca` (eliminando a versão anterior mais velha) e o novo payload assume `atual`, mantendo estritamente duas versões armazenadas.
