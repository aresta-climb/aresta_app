# **Proposta de Produto: App de Croquis de Escalada Com Acesso Offline**

*(Para Diretoria e Conselho da ACEC, escaladores e associados)*

**Autor:** Renato Utsch Gonçalves, Presidente ACEC-MG

**Data:** Março de 2026

**Status:** Proposto

## **1. Visão Geral e Filosofia**

A ACEC-MG propõe a criação de um aplicativo móvel para distribuir croquis digitais de escalada, com foco de uso para as regiões cársticas de Minas Gerais e arredores, mas aberto para outras regiões no Brasil. Como o sinal de celular é quase inexistente na maioria dos picos e falésias locais, o aplicativo deve ser fundamentalmente **offline**.

Além disso, como somos uma organização sem fins lucrativos, precisamos minimizar os custos recorrentes de infraestrutura. O objetivo dessa arquitetura é construir um aplicativo colaborativo (crowdsourced) baseado em repositórios abertos no GitHub, com dados altamente compactados, navegação offline e com custos mensais de servidor próximos a zero.


### **1.1 Filosofia e Posicionamento (App Comunitário vs. Plataformas Comerciais)**

Diferente de plataformas comerciais de escalada (SaaS) que restringem recursos de segurança — como navegação GPS offline e croquis detalhados — por trás de assinaturas premium (*paywalls*) e mantêm o monopólio do banco de dados, este aplicativo é estritamente uma **ferramenta de utilidade pública**. Nossa arquitetura é guiada por três pilares inegociáveis:

1. **Acesso Universal:** 100% das funcionalidades de navegação e leitura offline devem ser gratuitas, priorizando a segurança do escalador.
2. **Descentralização Financeira (Fricção Zero):** O sistema rejeita intermediários; toda monetização ou doação flui diretamente do usuário para a conta da associação ou do mantenedor local responsável pela via.
3. **Soberania dos Dados (Open Source):** A comunidade é a detentora definitiva do seu próprio trabalho. O repositório atua como um arquivo público em formato legível por humanos, garantindo que a história e a topografia da escalada local nunca fiquem reféns de uma única empresa de tecnologia (evitando o *vendor lock-in*). O objetivo não é ser uma rede social de performance esportiva, mas sim uma ferramenta de sobrevivência digital e fomento na base da rocha.


## **2. A Experiência do Escalador (App)**

* **100% Offline:** O usuário baixa o pacote de um pico (ex: Gruta da Lapinha) em casa. Na rocha, ele tem acesso a todas as vias, mapas, fotos de setores e vídeos de beta, tudo sem precisar de internet.
* **Croqui atualizado:** O croqui se auto-atualiza com quaisquer melhorias, permitindo melhorias incrementais e constantes nos croquis por parte da equipe que mantém o pico.
* **Navegação de Aproximação:** O aplicativo exibe um mapa topográfico offline com uma linha vermelha mostrando a trilha exata do estacionamento até a base da via, junto com a localização GPS do usuário (o "ponto azul").
* **Mídia Sob Demanda:** Para economizar espaço no celular, fotos dos setores são altamente compactadas. Vídeos de beta só são baixados se o usuário solicitar explicitamente enquanto estiver no Wi-Fi.
* **Descoberta de outros picos:** O escalador pode procurar por croquis de picos próximos a onde está em um mapa, facilitando a descoberta de novos locais para escalada.


## **3. Gestão Colaborativa (Como adicionar vias)**

Para manter o aplicativo atualizado, adotamos um sistema colaborativo amigável:

* **Database colaborativa:** O aplicativo e a database serão colaborativos e de código aberto, armazenados em repositórios GitHub controlados pela ACEC-MG e que permitem a qualquer pessoa contribuir com melhoria dos croquis e adição de novos picos de escalada.
* **Revisão por curadores:** Toda sugestão de nova via ou correção cai em um painel de "Revisão". Um curador da ACEC-MG lê, aprova com um clique, e o aplicativo de todos os usuários é atualizado automaticamente.
* **Carga Inicial (Bootstrap):** O app não nascerá vazio. Com a permissão dos autores, faremos a importação automatizada de dados de sites existentes e PDFs (usando Inteligência Artificial) para garantir que o app já seja útil no dia do lançamento.
* **Painel Administrativo Visual:** Voluntários e conquistadores não precisam saber programar. Eles acessam um site da associação com uma interface simples (semelhante ao WordPress), onde preenchem os dados das vias (grau, nome, beta) e fazem upload de fotos.


## **4. Estratégia de Monetização e Sustentabilidade**

Para garantir que o aplicativo consiga cobrir seus custos de infraestrutura e, ao mesmo tempo, retornar valor financeiro real para a comunidade de escalada, o sistema adotará um modelo de monetização nativa e direta, rejeitando explicitamente redes de anúncios convencionais.

* **Rejeição de Ad Networks (Anti-Meta): **A integração de SDKs de anúncios tradicionais (como Google AdMob ou Meta Audience Network) está fora do escopo arquitetural. Esse tipo de anúncio exige comunicação constante com a internet, não teríamos volume de impressões suficiente para gerar receita significativa e SDKs de terceiros consomem bateria processando rastreadores em segundo plano e exigem pop-ups complexos de consentimento de privacidade (LGPD).
* **Patrocínios Nativos Embarcados:** Para gerar receita para manter o aplicativo e para a escalada local, o aplicativo suportará espaços de patrocínio fixos e vendidos diretamente. Um ginásio local pode patrocinar um pico específico, e sua marca aparecerá nativamente no croqui offline.
* **Botão Pix Direto:** As vias terão um botão "Apoie a manutenção". O escalador clica, copia a chave Pix do mantenedor daquele pico específico e faz a doação direta, fomentando o suporte ao mantenedor local do pico, descentralizando o financiamento da escalada local e sem taxas de 30% das lojas de aplicativos.
* **Incentivo à Filiação:** O app lembrará ativamente os usuários sobre a importância de se transformar de frequentadores casuais em membros oficiais (filiados) das associações locais que mantém o pico em que escalam através de um padrão de "Interação Salva" (*Deferred Deep Link*). Se o usuário clicar no botão offline, o app salva essa ação e, assim que o aparelho detectar uma conexão Wi-Fi/4G, exibe uma notificação amigável lembrando-o de concluir sua filiação. Esta funcionalidade cria uma máquina de aquisição de novos membros com custo de marketing zero, aproveitando o momento em que o escalador está com o maior nível de gratidão e engajamento: exatamente enquanto desfruta da rocha que a associação protege.


## **5. Estratégia de Lançamento (Rollout)**

Para garantir que o aplicativo chegue rápido às mãos dos escaladores e seja testado em condições reais na rocha, o lançamento será dividido em duas fases principais:

* **Fase 1 (Alpha Fechado): Testes do Aplicativo.** O aplicativo será lançado para um grupo seleto de testadores e conquistadores locais. O objetivo é testar exaustivamente a navegação GPS offline e a leitura dos croquis. Nesta fase, a adição de novas vias será feita internamente pela equipe técnica (sem o painel visual).
* **Fase 2 (Beta Público): Abertura para a Comunidade.** Após validar que o aplicativo não trava na rocha e os mapas funcionam sem internet, o Painel Administrativo Visual (CMS) será oficialmente lançado. A partir deste momento, qualquer escalador poderá sugerir correções e adicionar picos de forma amigável pelo site da associação.


---

# **Documento de Arquitetura: App de Croquis de Escalada com Acesso Offline**

*(Para Desenvolvedores, Engenheiros e DevOps)*

**Autor:** Renato Utsch Gonçalves, Presidente ACEC-MG

**Data:** Março de 2026

**Status:** Proposto


## **1. Visão Geral da Arquitetura**

O sistema utiliza um padrão **Manifest + Payload** offline-first, desacoplando o conteúdo do binário do aplicativo. Nossa meta é manter o custo de infraestrutura em $0.00 mensal.

* **Repositório (Fonte da Verdade):** GitHub, utilizando Markdown + YAML Frontmatter. Qualquer escalador pode contribuir para o repositório.
* **Estrutura estática: **Protobuf para representar a estrutura dos dados armazenados no repositório
* **Pipeline CI/CD:** GitHub Actions para otimização de mídia e compilação de dados, compilando automaticamente as submissões legíveis por humanos em binários Protobuf (`.pb`) estritamente tipados.
* **Rede de Distribuição (CDN):** GitHub Pages (para arquivos `.pb` e `manifest.json`) e Cloudflare R2 (Tier gratuito de 10GB, Zero Egress) para imagens WebP, `.mbtiles` e vídeos `.mp4`.
* **Mobile Client:** Um aplicativo em Flutter que verifica um manifesto mestre, baixa atualizações incrementais em `.pb` e as armazena em cache para uso offline.
* **Git CMS:** Decap CMS (ou Sveltia) hospedado no GitHub Pages para interface de contribuição não-técnica por escaladores que não se sentem confortáveis em editar o repositório diretamente.


## **2. Fluxo de Dados e Pipeline de Contribuição**


### **2.1 A Experiência do Contribuidor**

Os escaladores não precisam saber programar para contribuir. Eles abrem um *Pull Request* (PR) contendo um arquivo Markdown para um pico ou setor específico.

* **Dados Estruturados (YAML Frontmatter):** Contém campos rígidos (ex: `nome`, `tempo_aproximacao`, `grau`).
* **Dados Não Estruturados (Markdown):** O corpo do texto contém informações longas, como o beta da via, avisos de segurança ou contexto histórico.
* **Mídia:** Os contribuidores podem enviar arquivos `.jpg`, `.png`, `.mp4` e trilhas `.gpx` junto com o texto.


### **2.2 CI/CD Automatizado (GitHub Actions)**

Quando um *Pull Request* é aprovado e mesclado (merged) na branch `main`, uma série de automações (Actions) é executada:

1. **Otimização de Imagens:** Localiza novos arquivos `.jpg`/`.png`, comprime para `.webp` (usando `cwebp`), atualiza as referências no Markdown e remove os arquivos originais pesados.
2. **Processamento de Vídeo:** Localiza arquivos `.mp4`, usa o FFmpeg para comprimir para 720p/30fps, faz o upload para o Cloudflare R2, atualiza as URLs no Markdown e deleta os vídeos locais.
3. **Compilação Protobuf:** Um script em Python lê o Markdown/YAML e trilhas `.gpx`, preenche nosso schema estrito `.proto` e serializa os dados em arquivos `.pb` altamente compactados.
4. **Geração do Manifesto:** Atualiza o arquivo `manifest.json` com as novas *hashes* de versão para os croquis modificados.
5. **Deploy:** Envia a pasta `build/` compilada para a branch `gh-pages`, garantindo hospedagem CDN rápida e gratuita.


## **3. Estratégia de Armazenamento e Mídia**

Para evitar o inchaço do repositório (bloat) e fugir das caras taxas de transferência de saída (egress fees) da AWS/Google Cloud:

* **Texto e Dados (<code>.pb</code>, <code>manifest.json</code>):** Hospedados no GitHub Pages (Gratuito, limite flexível de 100GB de banda).
* **Mídia Pesada (Vídeos, Imagens de Alta Resolução, Futuros Modelos 3D):** Hospedados no Cloudflare R2. O plano gratuito oferece 10GB de armazenamento e **taxa zero de transferência de saída**, garantindo que picos de downloads do app não gerem surpresas no cartão de crédito da associação.
* **Entrega de Vídeo:** Os vídeos são estritamente **Sob Demanda (On-Demand)**. Eles nunca vêm embutidos no download padrão do croqui. O usuário deve clicar explicitamente em "Baixar Vídeo do Beta" enquanto estiver no Wi-Fi para salvar o `.mp4` localmente no celular.


## **4. Mapeamento e Navegação Offline**

O aplicativo fornecerá um mapa interativo e offline feito sob medida para a aproximação dos picos, evitando APIs pagas como Google Maps ou os paywalls do Wikiloc.

* **Motor do Mapa:** `flutter_map` (Open-source, suporte nativo offline).
* **Terreno Base:** Arquivos topográficos `.mbtiles` pré-gerados para os parques e regiões de escalada, baixados diretamente para o dispositivo.
* **Trilhas de Aproximação:** Os contribuidores enviam tracks `.gpx` padrão. O script de compilação embute essas coordenadas diretamente no payload Protobuf do pico. O app renderiza isso como uma linha poligonal estática (a "linha vermelha") sobre o mapa offline.
* **Navegação do Usuário:** Usando o pacote `geolocator`, o app exibe a posição GPS atual do usuário (o "ponto azul") em relação à trilha de aproximação, permitindo uma navegação visual e de "somente leitura".


## **5. Aplicativo Cliente (Flutter)**

O aplicativo móvel atuará como um motor de sincronização offline.

* **Lógica de Sincronização:** Ao iniciar (se houver internet), o app baixa o `manifest.json`. Ele compara as versões remotas com as salvas localmente. Indicadores na interface avisam o usuário sobre atualizações disponíveis para os croquis já baixados.
* **Parsing (Interpretação de Dados):** O app lê os binários `.pb` diretamente em classes Dart geradas automaticamente (usando `protobuf` e `protoc_plugin`), garantindo segurança de tipagem e lidando com graciosidade caso faltem campos.
* **Armazenamento Local:** Usa o `path_provider` para armazenar com segurança os arquivos `.pb`, mapas de setores em `.webp`, vídeos `.mp4` e pacotes de mapas `.mbtiles` no diretório de documentos do aplicativo no dispositivo.


## **6. Estratégia de Carga Inicial (Bootstrapping)**

Para resolver o problema de "arranque a frio" (um aplicativo vazio no lançamento não atrai utilizadores), o sistema será pré-carregado com uma base de dados inicial robusta. Esta carga será feita através da extração automatizada de fontes existentes (mediante permissão dos autores) e conversão para o nosso formato padrão.


### **6.1 Métodos de Extração e Conversão**

Dada a diversidade de formatos das fontes de dados atuais, utilizaremos três abordagens distintas de extração:

* **Sites Estruturados em HTML (ex: escaladas.com.br):** * **Método:** Utilização de scripts locais em Python (com bibliotecas como `requests` e `BeautifulSoup`).
    * **Processo:** O script raspa (scrapes) as tabelas das páginas web, extraindo metadados como Nome do Setor, Nome da Via e Grau, e gera automaticamente os ficheiros `.md` com o cabeçalho YAML estruturado.
* **Croquis em PDF (Não estruturados):**
    * **Método:** Extração de texto aliada a Inteligência Artificial (LLMs).
    * **Processo:** Como os PDFs não possuem dados tabulares consistentes, um script extrai o texto bruto (via `pdfplumber`) e envia-o para uma API de IA (ex: OpenAI ou Gemini) com um *prompt* estrito para estruturar o texto lido e devolvê-lo num formato YAML limpo. As imagens das paredes são recortadas e inseridas no repositório.
* **Bases de Dados Internacionais (ex: thecrag.com, 8a.nu):**
    * **Método:** Exportação e conversão de CSV.
    * **Processo:** Solicitação de exportações em massa via API ou ferramentas de exportação das plataformas. Um script simples converte as linhas do CSV diretamente para os nossos ficheiros Markdown.


### **6.2 Fluxo de Inserção Segura (O "Seed PR")**

Os dados gerados de forma automatizada (especialmente via IA) são propensos a pequenos erros de formatação. Para garantir a estabilidade do aplicativo, os dados raspados **não** serão injetados diretamente na base de dados principal.

1. **Geração Local:** Os scripts correm localmente e geram a estrutura de pastas e milhares de ficheiros `.md`.
2. **Branch de Isolamento:** Os ficheiros são submetidos para o GitHub numa branch dedicada (ex: `bootstrap-dados-iniciais`).
3. **Pull Request (PR) Semente:** Um *Pull Request* massivo é aberto.
4. **Revisão Humana (Human-in-the-loop):** A comunidade e os engenheiros da ACEC-MG fazem uma auditoria visual aos dados no próprio GitHub.
5. **Merge e Compilação:** Após a aprovação e correção de eventuais erros no YAML, o PR é aceite (merged). O nosso pipeline de CI/CD assume o controlo, compila estes dados para binários Protobuf (`.pb`) e publica-os na CDN, disponibilizando os picos imediatamente no aplicativo.

## **7. Estrutura de Dados (Protobuf)**

A comunicação entre o repositório e o app é feita via Protocol Buffers para garantir tipagem estrita e payloads na casa dos kilobytes.


```
syntax = "proto3";
package acecmg.topo;

message Crag {
  string id = 1;
  string name = 2;
  string description = 3;
  double lat = 4;
  double lng = 5;
  string association_name = 6;
  string association_join_url = 7;
  string maintenance_pix_key = 8;
  Sponsor sponsor = 9;
  repeated Sector sectors = 10;
}

message Sector {
  string name = 1;
  string description = 2;
  string approach_time = 3;
  string map_image_url = 4;
  repeated Coordinate approach_trail = 5; 
  repeated Route routes = 6;
}

message Route {
  string name = 1;
  string grade = 2;
  string description = 3;
  string conqueror = 4;
  int32 bolts_count = 5;
  string anchor_type = 6;
  string beta_video_url = 7;
  string maintenance_pix_key = 8;    
}

message Coordinate { double lat = 1; double lng = 2; }
message Sponsor { string name = 1; string message = 2; string logo_url = 3; string link_url = 4; }
```

## **8. Estratégia de Licenciamento Open Source e Proteção de Marca**

A arquitetura de dados e o modelo de negócios deste aplicativo baseiam-se na colaboração da comunidade. Esconder o código-fonte limitaria a adoção por desenvolvedores voluntários e reduziria a transparência financeira do projeto. No entanto, para mitigar o risco de "clonagem predatória" (empresas copiando o app para monetização própria), o projeto adotará uma estratégia jurídica em duas frentes:


### **8.1 Licenciamento de Software (GNU GPLv3)**

O código-fonte do aplicativo Flutter e os scripts de compilação Python serão licenciados sob a **GNU General Public License v3.0 (GPLv3)**.

* **A Proteção "Copyleft":** Esta é uma licença protetora forte. Ela permite que qualquer pessoa copie, estude e modifique o código livremente. No entanto, ela **exige** que qualquer aplicativo derivado também tenha seu código-fonte totalmente aberto e seja distribuído sob os mesmos termos gratuitos.
* **Bloqueio Comercial:** Isso destrói o incentivo financeiro para a clonagem maliciosa. Nenhuma empresa comercial poderá pegar o nosso código, fechá-lo, colocar um *paywall* ou anúncios e vendê-lo nas lojas de aplicativos, pois estariam violando a licença GPLv3 e sujeitos a processos de violação de direitos autorais.


### **8.2 Proteção de Marca e Identidade Visual (Trademark)**

Enquanto o código (a lógica de programação) é livre, a identidade da associação é estritamente privada.

* **Reserva de Direitos:** O nome do aplicativo, a sigla "ACEC-MG", as logos, a paleta de cores oficial e os assets visuais não fazem parte do licenciamento de código aberto.
* **Defesa contra Impostores:** Se um terceiro decidir "fazer um *fork*" (copiar o repositório) do nosso aplicativo sob as regras da GPLv3, ele será legalmente obrigado a remover toda e qualquer menção à ACEC-MG, alterar a logo e mudar o nome do aplicativo. Um clone genérico e sem o selo de confiança institucional da associação não representa uma ameaça ao ecossistema oficial.


## **9. Estratégia de Monetização e Sustentabilidade**

Para garantir que o aplicativo consiga cobrir seus custos de infraestrutura e, ao mesmo tempo, retornar valor financeiro para a comunidade de escalada (manutenção de vias), o sistema adotará um modelo de monetização nativa e direta, rejeitando explicitamente redes de anúncios convencionais.


### **9.1 Rejeição de Ad Networks (Anti-Meta)**

A integração de SDKs de anúncios tradicionais (como Google AdMob ou Meta Audience Network) está fora do escopo arquitetural pelos seguintes motivos:

* **Incompatibilidade Offline:** Redes de anúncios exigem comunicação constante com a internet para contabilizar impressões e renovar o inventário.
* **Baixo Retorno Financeiro (CPM):** Em um aplicativo de nicho focado em uma região específica, o volume de impressões não seria suficiente para gerar receita significativa, resultando em poucos reais por mês.
* **Degradação da Experiência:** SDKs de terceiros aumentam o tamanho do binário do aplicativo, consomem bateria processando rastreadores em segundo plano e exigem pop-ups complexos de consentimento de privacidade (LGPD).


### **9.2 Patrocínios Nativos Embarcados (Sponsorships)**

Para gerar receita para a ACEC-MG (visando cobrir custos de domínio, contas de desenvolvedor Apple/Google, etc.), o aplicativo suportará espaços de patrocínio fixos e vendidos diretamente.

* **Arquitetura de Dados:** O schema Protobuf (`.proto`) do Pico/Setor incluirá campos opcionais como `sponsor_name`, `sponsor_message` e `sponsor_logo_url`.
* **Fluxo de Publicação:** Quando a associação fecha uma parceria (ex: um ginásio local patrocina o croqui da Serra do Cipó), um administrador atualiza o arquivo YAML daquele pico com os dados do patrocinador.
* **Vantagem Técnica:** O anúncio é compilado e embutido diretamente no arquivo `.pb`. Ele funciona 100% offline, tem carregamento instantâneo, não é bloqueado por AdBlocks e não rastreia o usuário.


### **9.3 Fundo de Manutenção de Vias (Pix Direto)**

Como ferramenta de fomento ao esporte, o aplicativo atuará como um facilitador de doações com fricção zero para a manutenção dos picos, sem intermediar as transações.

* **O Modelo de Dados:** Os contribuidores podem adicionar um campo `chave_pix_manutencao` no Frontmatter YAML do setor ou pico.
* **Interface do Usuário (UI):** A interface do aplicativo renderizará um botão nativo de "Apoie a Manutenção Deste Pico". Ao ser acionado, o app utiliza as funções nativas de área de transferência (Clipboard) do iOS/Android para gerar um "Pix Copia e Cola".
* **Impacto:** O valor doado vai integralmente (sem taxas de 30% das lojas de aplicativos) para o mantenedor local ou para o fundo do pico específico, descentralizando o financiamento da escalada local.


### **9.4 Incentivo à Filiação e Fortalecimento Comunitário**

Doações pontuais são cruciais para manutenções urgentes, mas a sustentabilidade de longo prazo das áreas de escalada depende de associações locais fortes e representativas. O aplicativo funcionará como uma ferramenta ativa de conversão, transformando frequentadores casuais em membros oficiais (filiados) das associações responsáveis.

* **O Modelo de Dados:** O schema Protobuf e o YAML Frontmatter incluirão metadados sobre a governança do pico, com campos como `association_name` (ex: ACEC-MG) e `association_join_url` (o link para a página de filiação).
* **Interface do Usuário (UI):** Na mesma tela de informações do pico ou setor, adjacente ao botão de doação (Pix), o aplicativo exibirá um *Call to Action* (CTA) de alto contraste: **"Filie-se à [Nome da Associação] e proteja este pico"**.
* **Tratamento Offline:** Como o usuário provavelmente estará sem internet ao ver o botão na base da via, o aplicativo pode adotar um padrão de "Intenção Salva" (*Deferred Deep Link*). Se o usuário clicar no botão offline, o app salva essa ação e, assim que o aparelho detectar uma conexão Wi-Fi/4G, exibe uma notificação amigável lembrando-o de concluir sua filiação.
* **Impacto Estratégico:** Esta funcionalidade cria uma máquina de aquisição de novos membros com custo de marketing zero, aproveitando o momento em que o escalador está com o maior nível de gratidão e engajamento: exatamente enquanto desfruta da rocha que a associação protege.


## **10. Fora de Escopo (Anti-Metas)**

Para garantir que o projeto continue viável para uma equipe de engenharia voluntária, as seguintes funcionalidades estão estritamente excluídas do MVP (Produto Mínimo Viável):

* **Gravação de GPS no App:** O aplicativo não gravará trilhas de aproximação. Os contribuidores devem usar hardware dedicado (Garmin) ou apps externos (Strava) para gerar os arquivos `.gpx`.
* **Navegação Curva-a-Curva (Turn-by-Turn):** Sem roteamento dinâmico ou comandos de voz. A navegação é estritamente visual (localização do usuário vs. linha estática da trilha).
* **Criação de Conteúdo In-App:** Os usuários não podem criar ou editar croquis por dentro do aplicativo. Toda a entrada de dados flui através do processo de PR no GitHub para garantir revisão por pares e integridade dos dados.


## **11. Interface de Administração e Contribuição (Git CMS)**

Para que o aplicativo seja um sucesso comunitário, o processo de adicionar e editar croquis deve ser acessível para escaladores sem qualquer conhecimento técnico de programação, Git ou Markdown. Ao mesmo tempo, o sistema não pode depender de formulários estáticos de mão única (como o Google Forms), que impossibilitam a edição fácil de picos já existentes.

Para resolver este problema, a arquitetura adotará um **Git-based CMS** (Sistema de Gerenciamento de Conteúdo baseado em Git), especificamente o **Decap CMS** (ou alternativamente o Sveltia CMS).


### **11.1 A Camada Visual (O Painel de Controle)**

O CMS funcionará como uma aplicação web estática, hospedada gratuitamente no próprio domínio da associação (ex: `acecmg.org/admin`).

* **Abstração de Código:** O painel traduzirá os arquivos brutos em Markdown e YAML Frontmatter para uma interface gráfica amigável, semelhante à de plataformas como WordPress.
* **Leitura Bidirecional:** O CMS lê diretamente o estado atual do repositório no GitHub. Se um escalador quiser corrigir o grau de uma via na *Lapa do Seu Antão*, o CMS carregará a página do pico com todos os dados atuais já preenchidos em caixas de texto limpas e prontas para edição.


### **11.2 Automação de Pull Requests (O Fluxo Invisível)**

O CMS atua como um tradutor entre o usuário leigo e o repositório técnico:

1. O usuário voluntário faz login no painel (usando a autenticação segura do GitHub ou Netlify Identity).
2. Ele preenche os campos do novo pico ou altera os dados de uma via existente.
3. Ao clicar em **"Salvar"**, o CMS automaticamente formata o código YAML/Markdown perfeito nos bastidores e abre um *Pull Request* no GitHub, sem que o usuário sequer saiba o que é um PR.


### **11.3 Fluxo de Trabalho Editorial (Workflow)**

O CMS nativamente suporta um sistema de aprovação visual (Kanban) crucial para manter a qualidade e a segurança das informações do aplicativo:

* **Colunas de Status:** O painel possui colunas como "Rascunhos", "Em Revisão" e "Pronto para Publicar".
* **Revisão da Diretoria:** Quando um escalador sugere uma alteração ou cadastra um pico novo, o card da alteração cai na coluna "Em Revisão". Um diretor da ACEC-MG ou curador local do pico pode abrir o card, conferir as informações de forma visual, e arrastar para "Pronto para Publicar".
* O simples ato de arrastar o card no painel visual aciona a aprovação (*merge*) no GitHub, disparando o GitHub Actions para compilar os dados para o aplicativo móvel.


### **11.4 Gerenciamento de Mídia Integrado**

O CMS também resolve o problema de submissão de arquivos pesados de mídia:

* O painel possui uma galeria de mídia visual com função de "arrastar e soltar" (*drag-and-drop*).
* Quando o usuário solta a foto de um setor na página de edição, o CMS faz o upload seguro do arquivo para a pasta correta dentro do repositório GitHub.
* Em seguida, nosso pipeline de CI/CD (GitHub Actions) assume, comprimindo essa imagem para WebP e enviando-a para a CDN do Cloudflare R2, mantendo todo o fluxo livre de intervenção técnica manual.