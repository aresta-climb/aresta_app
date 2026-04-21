### Plano de Implementação de atualizações de dados no Backend: Gerador Estático de Delta-Updates

**Visão Geral da Arquitetura**
O objetivo é gerar um conjunto de dados (dataset) estático e versionado que permita ao cliente mobile em Flutter realizar atualizações delta (delta updates) altamente eficientes e otimizadas para o consumo de dados. O backend consiste inteiramente em um script Python que pré-calcula o estado e gera arquivos estáticos (`.binarypb`) para serem hospedados no GitHub Pages. 

Estamos aproveitando a geração automática de `ETag` do GitHub Pages para lidar com "sondas" de atualização de forma eficiente via requisições HTTP GET Condicionais, eliminando totalmente a necessidade de um servidor de API rodando em tempo real.

#### 1. Definições de Schema do Protobuf
O backend em Python precisa serializar os dados em dois tipos principais de arquivos Protobuf:
* **Arquivos de Dados (`[id_do_croqui].binarypb`):** Os registros individuais que compõem o banco de dados (ex: croquis individuais de vias).
* **O Arquivo de Índice (`indice.binarypb`):** O manifesto que o cliente usa para determinar exatamente o que mudou na base.

**Requisito do Schema do Índice:**
O `indice.binarypb` deve seguir o padrão definido em  `proto/indice.proto`, mensagem `Indice`, contendo uma lista repetida (`repeated` no Protobuf) de entradas, onde cada entrada representa um arquivo de dados. Detalhamento de alguns dos campos:
* `nome_arquivo` (string): O nome exato do arquivo (ex: `via_123.binarypb`).
* `checksum_sha256` (string): O hash SHA-256 codificado em hexadecimal do arquivo de dados já compilado.
* `url` (string): O caminho relativo que será anexado à URL base do GitHub Pages para o download do arquivo.

#### 2. Lógica do Script Python (O Gerador)
O script de build em Python deve executar o seguinte pipeline sempre que os dados de origem (`database`) forem modificados:

* **Passo A: Compilar Arquivos de Dados**
    * Iterar pelos dados de origem (ex: arquivos YAML, registros de banco de dados ou objetos na memória).
    * Compilar cada entidade em sua respectiva representação binária Protobuf.
    * Salvar esses arquivos gerados em um diretório de saída (ex: `generated/`).
* **Passo B: Cálculo de Hash**
    * Iterar pelos arquivos de dados `.binarypb` gerados no diretório `generated/`.
    * Usar a biblioteca nativa do Python `hashlib.sha256()` para calcular o checksum de cada arquivo. *Nota técnica: Faça a leitura dos arquivos em pedaços (chunks, ex: 4096 bytes) para manter o uso da RAM baixo, mesmo que os arquivos atuais sejam leves.*
* **Passo C: Gerar o `indice.binarypb`**
    * Listar todos os croquis .binarypb gerados no diretório `generated/`.
    * Construir o objeto Protobuf de Índice utilizando os nomes de arquivo e os hashes SHA-256 calculados no Passo B.
    * Serializar esse objeto de Índice e gravá-lo como `generated/indice.binarypb`.

#### 3. Estratégia de Deploy (GitHub Pages)
* **Hospedagem:** Todo o conteúdo do diretório `generated/` (o `indice.binarypb` e todos os `.binarypb` de dados) deve ser "commitado" e receber um `push` direto para a branch servida pelo GitHub Pages (repositório `acec-mg/kmon_serving`, branch `main`). Isso idealmente seria feito por github actions.
* **Zero Configuração de Headers:** Confie inteiramente na infraestrutura de CDN do GitHub (Fastly). Quando o `indice.binarypb` for atualizado no repositório, o GitHub calculará automaticamente um novo `ETag` e o enviará nos cabeçalhos da resposta HTTP. O cliente Flutter usará esse `ETag` com o header `If-None-Match` para fazer as verificações de atualização gastando zero bytes de banda quando não houver mudanças.

#### 4. Restrições e Decisões Críticas
* **Uso Obrigatório de SHA-256:** Não utilize algoritmos como BLAKE2b ou BLAKE3. O cliente mobile (Flutter/Dart) vai depender do pacote oficial `crypto`, que tem suporte nativo, otimizado e cross-platform para SHA-256. Isso evita a imensa dor de cabeça de compilar dependências nativas em C/Rust via FFI no iOS e no Android.
* **Deploys Atômicos:** É fundamental garantir que o `indice.binarypb` e os arquivos de dados `.binarypb` que ele referencia sejam commitados e enviados para o GitHub Pages no **mesmo** commit do Git. Isso evita condições de corrida onde o cliente poderia baixar um índice novo que aponta para arquivos de dados que ainda não terminaram de subir.