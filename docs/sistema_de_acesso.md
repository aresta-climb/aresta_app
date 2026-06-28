# Design Doc: Aresta Climb - Sistema de Acesso e Pagamentos (MVP)

**Autor:** Renato Utsch **Status:** Proposto **Data:** Junho de 2026

## 1. Contexto e Objetivos

O Aresta Climb precisa de um sistema automatizado para cobrança de ingressos
(Day Use) e controle de acesso físico aos picos de escalada. O sistema atual de
fiscalização voluntária não escala e possui atritos de arrecadação. Além da
arrecadação, o sistema deve garantir o controle de segurança (busca e
salvamento) para saber exatamente quem está na montanha.

O objetivo deste MVP é validar a viabilidade técnica e comercial da cobrança
descentralizada, garantindo a emissão de seguros obrigatórios, máxima conversão
em áreas remotas e conformidade estrita com a LGPD através de uma arquitetura de
privacidade descentralizada.

### Objetivos Principais

- **Zero Store Fees:** Tratar a transação estritamente como a venda de um
  serviço físico para evitar taxas de 15% a 30% da Apple/Google.
- **Orquestração Descentralizada:** O Aresta atuará como software roteador. A
  conta mestre de pagamento pertencerá à associação local (ex: ACEC-MG),
  eliminando bitributação e riscos fiscais para os criadores do app.
- **Privacidade e Segurança de Vida:** Dados financeiros e de identificação
  sensíveis (PII) nunca serão salvos no banco de dados. Porém, dados vitais para
  resgate são armazenados sob a base legal de Proteção à Vida.
- **Arquitetura Online-First com Fallback Offline:** A catraca tira proveito do
  WiFi local para telemetria em tempo real, mas é imune a quedas de internet e
  energia para não travar a operação.

## 2. Arquitetura do Sistema

### 2.1. Frontend (Mobile App - Flutter)

A interface de pagamento será nativa (Checkout Transparente), com três vias de
cobrança: Pix, Apple/Google Pay e Cartão Manual Tokenizado. Para garantir
performance e segurança, o armazenamento de dados no dispositivo usará o padrão
**Hot/Cold Cache**:

- **Hot Storage (Uso Diário):** Uso do `flutter_secure_storage` para guardar
  Nome, CPF e Tokens de Cartão. Estes dados ficam no hardware blindado do
  celular (Keychain/Keystore). A leitura é imediata (zero requisições de rede)
  na hora de fechar a compra, ideal para o 3G instável das montanhas.
- **Cold Backup (Recuperação):** Para evitar que o usuário perca os dados ao
  trocar de celular ou reinstalar o app, utilizaremos uma **Arquitetura
  Split-Key**. O Flutter encripta os dados localmente e salva o texto cifrado no
  `shared_preferences` (que faz backup nativo no Google Drive/iCloud).

### 2.2. Backend (Supabase)

O backend atua como orquestrador efêmero e guardião de chaves, sem nunca
armazenar dados financeiros abertos.

- **Guardião de Chave (Split-Key):** Para o Cold Backup funcionar, o Supabase
  gera e armazena apenas a **Chave de Desencriptação**. Se o usuário trocar de
  celular, o aplicativo baixa a chave, junta com o backup cifrado da nuvem do
  celular, e restaura o "Hot Storage" silenciosamente.
- **Edge Functions (TypeScript):** Recebem os dados limpos do celular apenas na
  memória RAM (via HTTPS). Elas executam o split de pagamento, acionam a API da
  Roca Seguros, assinam o passe digital (Ed25519) e então morrem, limpando a
  memória.
- **Supabase Vault:** Armazena as **Chaves Secretas (Secret Keys)** das contas
  das Associações no gateway de pagamento.
- **Banco de Dados (PostgreSQL):** Funciona como "Livro Razão" e "Painel de
  Resgate", dividido em:
  - **Tabela de Tickets:** Mantém metadados transacionais imutáveis (ID
    sequencial, ID do pico, status, ID da transação no gateway) para gestão
    financeira sem expor dados pessoais reais.
  - **Tabela de Usuários (Rescue Data):** Mantém e-mails (com pgAudit), Nome,
    Telefone do Escalador, Contato de Emergência, Tipo Sanguíneo e Alergias.

### 2.3. Integrações Externas

- **Gateway de Pagamento:** Processa os tokens (Apple/Google Pay ou Cartão) e
  executa o Split de Pagamento automático.
- **Seguradora (Roca Seguros):** Recebe via API (acionada pela Edge Function) os
  dados pessoais para emissão da apólice obrigatória no exato momento da
  transação.

## 3. Modelo de Operação Financeira e Retenção

1. A **Associação (ex: ACEC-MG)** possui a conta jurídica no gateway. O dinheiro
   da venda cai diretamente no ecossistema dela.
2. **Isolamento de Tokens:** Como o usuário salva cartões em um sistema
   descentralizado, o aplicativo armazena no celular a relação
   `[Associação ID + Token do Cartão]`.
3. Quando o escalador retorna a um pico da mesma Associação, o Flutter utiliza o
   Token salvo no "Hot Storage" (1-Click). Se for uma nova associação, solicita
   a digitação do cartão para gerar um novo token.

## 4. Fluxo de Execução (User Journey)

1. O escalador seleciona "Comprar Day Use". O Flutter acessa instantaneamente o
   "Hot Storage" para preencher CPF e Token de Cartão. _(Caso o Hot Storage
   esteja vazio por troca de aparelho, o Flutter faz a restauração via Cold
   Backup antes de prosseguir)._
2. O usuário confirma a compra. O Flutter faz um único POST para a Edge
   Function, enviando o payload.
3. A Edge Function orquestra o Gateway e a Roca Seguros.
4. O Gateway dispara o Webhook de confirmação.
5. A Edge Function assina criptograficamente o ingresso e salva os metadados da
   transação no Supabase. O app sincroniza via Realtime e exibe o QR Code de
   acesso na tela.

## 5. Controle de Acesso Físico (Catracas e IoT)

A validação de entrada e saída na base da montanha será feita por
microcontroladores (ESP32-CAM) embarcados nas catracas. A escolha tecnológica é
o **QR Code Visual**, por ser universal (independente do bloqueio de NFC da
Apple e das instabilidades do Bluetooth no Android).

### 5.1. Online-First e Resiliência (Eventual Consistency)

A infraestrutura usará roteadores locais, mas não dependerá deles para autorizar
o acesso:

- **Telemetria em Tempo Real:** Conectado ao WiFi, o ESP32 envia um _ping_
  imediato ao Supabase a cada acesso validado localmente, alimentando o
  "Dashboard de Resgate" da Associação (Entradas e Saídas).
- **Fallback Offline (SPIFFS):** Se a internet cair, a validação do QR Code
  (criptográfica) continua inalterada. Os acessos são salvos em uma fila na
  memória Flash do ESP32 (SPIFFS/LittleFS) e sincronizados em lote assim que o
  WiFi retornar.
- **Independência Energética:** O sistema é alimentado por uma bateria 12V
  recarregada pela rede da concessionária. Em caso de apagão, a catraca opera de
  forma autônoma por dias.

### 5.2. Engenharia do QR Code (Alta Performance e Compressão Base62)

Para evitar atritos de UX (fila no sol, telas trincadas), o payload abolirá
JSONs, adotando compressão **Base62** para os campos e o **Modo Byte (UTF-8)**
no gerador do QR Code (garantindo o _Case Sensitivity_ e gerando quadradões
legíveis).

O payload (separado por `|`) terá a seguinte anatomia:

- **CragID:** Convertido para Base62 (ex: `2x`).
- **Data (Epoch Days):** Dias contados desde 1970, em Base62 (ex: `fwg`).
- **TicketID (Sqids / Base62):** O ID sequencial do banco ofuscado via `Sqids`
  usando um **Alfabeto Customizado secreto**. Isso comprime o ID (ex: `pX4`) e
  impede engenharia reversa por terceiros, protegendo a inteligência de negócios
  (BI) da associação.
- **Assinatura Digital:** Gerada via curva elíptica (Ed25519). Resulta em 64
  bytes brutos, codificados em Base64.
- **Formato Final:** `2x|fwg|pX4|MEQCIDK...[assinatura]` _(Total: ~100
  caracteres)_.

### 5.3. A Engenharia Física: Kissing Gate (Passa-Um) e Fail-Safe

Para baratear custos e aumentar a resiliência mecânica, as roletas de 3 braços
serão substituídas por uma infraestrutura baseada no modelo "Kissing Gate".

- **O Cercado em V:** Um portão de madeira ou metal que abre para o interior de
  um cercado em formato de "V". A geometria obriga a passagem em fila indiana,
  pois o escalador precisa passar o portão ao redor do próprio corpo, impedindo
  a passagem simultânea de múltiplas pessoas ("caronas").
- **Hardware Simplificado:** O controle será feito por uma Fechadura Eletroímã
  IP68 (sem rolamentos ou engrenagens para enferrujar), auxiliada por uma mola
  mecânica ou dobradiça de gravidade que força o retorno automático do portão à
  posição fechada.
- **Protocolo Fail-Safe (Falha Aberta):** Fundamental para a segurança. Na
  ausência total de energia (esgotamento de baterias), a fechadura
  eletromagnética desatraca automaticamente, deixando o portão livre. Isso
  garante a evacuação em caso de emergências ambientais ou falha no
  microcontrolador.
- **Portão de Emergência e Serviço (Bypass):** Imediatamente ao lado da
  estrutura do Passa-Um, será instalado um portão tradicional de folha larga.
  Ele permanecerá travado mecanicamente (cadeado com senha em um Lockbox). Sua
  função é vital para garantir o acesso rápido de macas de resgate, entrada de
  maquinário/materiais para a manutenção do parque e servir como rota de
  evacuação de alto fluxo.

### 5.4. Prevenção de Fraudes e Anti-Passback Universal (15 Minutos)

Para impedir o "Ataque do WhatsApp" (repasse de print) e a "Fraude do Giro
Falso" (fingir que saiu), a catraca de entrada e a de saída operam sob a regra
de **Anti-Passback Temporal Universal**:

1. **Nonce Criptográfico:** O `TicketID` (único) atrelado à assinatura garante
   que nenhum ingresso gere um QR Code igual.
2. **Registro Efêmero:** Ao ler um ingresso válido (na entrada ou na saída), o
   ESP32 salva o `TicketID` em sua memória RAM e aplica um **bloqueio absoluto
   de 15 minutos**.
3. **Resultado Prático:** Se o usuário tentar "burlar" o sistema passando o
   celular pelo muro após entrar ou "fingir" que saiu, o próximo uso é
   sumariamente negado por 15 minutos. Caso seja uma reentrada legítima (ex: ir
   ao carro pegar um equipamento), o tempo de deslocamento naturalmente excede a
   carência, e o acesso é permitido (renovando o timer).

### 5.5. Sensor de Giro (Feedback Loop)

O ingresso só é gravado na RAM e bloqueado nos 15 minutos após a placa receber o
pulso físico do **Sensor de Abertura** (confirmando que a pessoa de fato
passou).

- Se o usuário ler o código ("moscar") e não manter o sensor branquinho de alarm
  de R$10 pra avisar ao ESP32 se o portão está aberto ou fechado, o acesso é
  descartado da RAM e a roleta tranca, permitindo que ele leia o código
  novamente sem ser punido pelo timer de fraude.

### 5.6. Otimizações Visuais e de Hardware

- **Brilho Forçado:** Ao abrir a tela do ingresso, o aplicativo força 100% de
  brilho na tela (via pacote Flutter), eliminando reflexos da luz solar no visor
  da catraca.
- **High-Contrast Light Mode:** O QR Code será renderizado estritamente em Preto
  no fundo Branco, ignorando o "Modo Escuro" do celular do usuário. Sensores
  óticos processam muito melhor o contraste tradicional.
- **Foco Macro (Hardware):** A lente de fábrica (OV2640) do ESP32-CAM (padrão
  CFTV) terá seu lacre rompido e será calibrada manualmente para o modo **Macro
  (foco a 10-15 cm)**.

### 5.7. Resiliência e Conciliação (O Paradoxo Offline)

Embora a catraca valide os ingressos independentemente de internet, o sistema
exige a persistência dos **metadados transacionais** no Supabase (seção 2.2).
Isso garante:

- **Disaster Recovery:** Se o celular descarregar ou quebrar na montanha, o
  usuário loga em outro aparelho e reconstrói o QR Code perfeitamente.
- **Gestão Financeira:** Viabiliza automação de estorno/chargeback vinculando o
  ID do Gateway ao Ticket.

### 5.8. Botão SOS e Telemetria de Resgate (Background Queue)

Para maximizar a utilidade do sistema em ambientes de risco e reforçar a base
legal de Proteção à Vida (LGPD), o frontend contará com um módulo de SOS
otimizado para conectividade intermitente (redes 2G/EDGE ou sombra de
cobertura).

- **Coleta de Dados:** Uma interface simples (um botão de pânico + campo de
  texto curto) aciona o pacote `geolocator` do Flutter para capturar a Latitude
  e Longitude (High Accuracy) do dispositivo.
- **Payload Minimalista:** O alerta é estruturado em um JSON extremamente leve
  (< 2 KB), contendo apenas `TicketID`, `Timestamp`, `Lat/Lon` e a `Mensagem` do
  usuário, maximizando a chance de transmissão em conexões com alta perda de
  pacotes (Packet Loss).
- **Retry Pattern e Fila de Background:** A requisição não falha silenciosamente
  caso o dispositivo esteja offline. O Flutter salva o payload localmente
  (utilizando banco local como SQFlite ou Hive) e inicia um _Background Worker_.
  O sistema entra em um _loop_ agressivo de retentativas (Retry Queue) e
  despacha o POST HTTP no exato instante em que o sistema operacional reportar
  qualquer alteração no _Network State_ (recuperação momentânea de sinal).
- **Integração com o Dashboard:** Ao atingir o Supabase (via Edge Function ou
  RPC), o banco de dados insere o registro em uma tabela de `emergencies`. O
  Supabase Realtime escuta essa tabela e emite um alerta sonoro e visual
  imediato no Dashboard do fiscal da Associação, fornecendo as coordenadas
  exatas para a equipe de busca e salvamento.

### 5.9. Auditoria de Fim de Dia e Alertas de Resgate (Admin Sync)

Para mitigar falhas de conexão prolongadas ou perdas de sinal que impeçam a
telemetria em tempo real, o sistema de segurança do parque conta com uma rotina
de varredura física:

- **QR Code de Admin:** No fim do dia (ex: 18h00), um fiscal da Associação
  apresenta um QR Code de Administrador na câmera do ESP32.
- **Dumping de Dados (Local Sync):** Ao ler a credencial, o ESP32 ativa seu
  próprio Access Point WiFi ou Bluetooth e transfere para o celular do fiscal a
  lista de todos os `TicketID` que estão com status `IN` (entraram, mas não
  registraram saída) na memória RAM.
- **Alerta de Segurança Militar:** O app do fiscal cruza essa lista local com o
  Supabase. Se houver divergência ou se constatar que alguém ainda não deixou o
  pico, o Dashboard emite um **Alerta Vermelho**, exibindo o Nome, Telefone e o
  Contato de Emergência do escalador faltante, permitindo o acionamento imediato
  de equipes de busca antes do anoitecer completo.

## 6. Riscos, Conformidade Legal e Mitigações

- **Ameaça Interna (Insider Risk):** Desenvolvedores não possuem acesso a dados
  pessoais. O uso da tabela de `auth.users` é auditado nativamente (pgAudit).
- **Risco de PCI Compliance:** Mitigado pelo Checkout Transparente. O aplicativo
  apenas intermedeia Tokens inofensivos gerados pelo gateway e/ou Apple/Google
  Pay.
- **Proteção à Vida (Art. 7º, Inciso VII da LGPD):** O armazenamento
  centralizado de Nome Completo, Telefone, Contatos de Emergência, Tipagem
  Sanguínea e Alergias é feito **exclusivamente sob a base legal de Proteção à
  Vida**. Esses dados são essenciais para os painéis de Busca e Salvamento em
  ambiente de risco, justificando integralmente sua retenção.

### 6.1. Adições à Política de Privacidade (Conformidade LGPD)

Para formalizar a isenção de responsabilidade do Aresta Climb sobre o
armazenamento de dados financeiros e o uso efêmero dos dados, a Política de
Privacidade deverá incorporar três cláusulas específicas:

- **Armazenamento Local (Isenção):** _"Para garantir a sua máxima segurança e
  privacidade, o Aresta Climb **não armazena** seus dados sensíveis de
  identificação (CPF, Nome Completo, Endereço e Tokens de Cartão de Crédito) em
  nossos servidores. Esses dados são mantidos exclusivamente de forma
  criptografada no seu próprio dispositivo móvel, utilizando os padrões de
  segurança do seu sistema operacional."_
- **Processamento Efêmero (Transparência):** _"Durante a aquisição de um acesso,
  seus dados são enviados aos nossos servidores de forma segura e processados
  **estritamente na memória RAM**, sendo descartados imediatamente após a
  comunicação com a Seguradora e o Gateway de Pagamento, sem jamais serem
  gravados em nosso banco de dados."_
- **Compartilhamento com Terceiros:** _"Para executar o serviço contratado, seus
  dados transientes são repassados aos nossos parceiros (ex: Roca Seguros e
  Gateway de Pagamento), que assumem o papel de Controladores desses dados após
  o recebimento para o cumprimento de suas obrigações legais, fiscais e emissão
  de apólice."_

## 7. Resiliência de Hardware

A premissa da engenharia IoT para áreas naturais e remotas é assumir que o
hardware eventualmente falhará. O sistema deve ser projetado considerando
extremos de temperatura, umidade, poeira e insetos, garantindo que, quando a
falha ocorrer, ela não comprometa a segurança ou o direito de ir e vir dos
escaladores.

### 7.1. Blindagem Física (Weatherproofing)

O microcontrolador (ESP32-CAM) opera em condições hostis e exigirá preparo de
proteção superior:

- **Conformal Coating:** A placa eletrônica (excluindo a lente da câmera)
  receberá aplicação de verniz acrílico ou de silicone próprio para circuitos,
  impermeabilizando as trilhas contra a condensação noturna e oxidação.
- **Encapsulamento Hermético (IP67):** A montagem será feita em uma caixa selada
  padrão IP67. O orifício de leitura não será vazado, mas sim fechado com um
  visor de vidro temperado ou acrílico colado com silicone P.U.
- **Controle de Umidade Interna:** Inclusão permanente de sachês de sílica gel
  no interior da caixa para absorver qualquer umidade residual aprisionada
  durante a montagem.
- **Pestana de Sombreamento:** A estrutura da caixa incluirá uma aba superior
  ("marquise") projetada sobre o visor. Isso previne o ofuscamento da câmera
  pelo sol direto de meio-dia, reduz o superaquecimento do acrílico e diminui a
  incidência de sujeira e teias de aranha diretamente na lente.

### 7.2. Saída de Emergência e Botoeira "Dedo-Duro" (Edge Case de Bateria)

Para conformidade com normas de segurança de evacuação e para mitigar o cenário
de dispositivos móveis descarregados, a infraestrutura possuirá uma botoeira
física de saída ("Aperte para Sair"). O fluxo contorna a vulnerabilidade
clássica de fraudes de acesso da seguinte forma:

- **Geometria Antifraude:** A botoeira será instalada estritamente _no interior_
  do cercado em "V" do Passa-Um. O usuário precisa obrigatoriamente entrar no
  espaço restrito para acionar a liberação, impossibilitando que a porta seja
  mantida aberta confortavelmente pelo lado de fora.
- **Conciliação Assíncrona (App-Side Check-out):** A saída via botoeira é
  anônima. Logo, o `TicketID` do usuário permanece com status `IN` no _Dashboard
  de Resgate_. Para normalizar o status, temos duas opções:

1. Uma placa ao lado do botão avisando que em caso de uso é preciso avisar o
   fiscal / recepção do parque, e eles poderiam fazer a baixa eles mesmos.
2. O frontend (Flutter) implementará uma rotina de checagem de tickets ativos no
   _Cold Start_. Caso exista um Day Use pendente, a UI exibirá um _Call to
   Action_ persistente de **"Check-out Manual"**, permitindo que o usuário envie
   o _ping_ de saída (via requisição HTTPS) assim que reconectar o aparelho a
   uma fonte de energia no veículo.
