## Por que

Atualmente, os usuários precisam baixar compulsoriamente todo o pacote do pico (dados binários e todas as imagens/mapas em alta resolução) antes de poderem visualizar seus setores, vias e croquis. Isso cria fricção desnecessária na exploração, desperdiça armazenamento e franquia de dados móveis, além de frustrar quem deseja apenas consultar o grau de uma via ou comparar picos em casa.

Permitir a navegação instantânea online viabiliza uma exploração fluida e sem atritos, mantendo inalterada a promessa fundamental do Aresta: acesso 100% garantido e confiável na rocha, sem qualquer sinal de internet.

## O que muda

- **Navegação Direta Online**: Tocar em um pico no Explorar, Mapa Global ou Busca abre `PicoDetailsPage` imediatamente em modo online sem exigir download prévio.
- **Transmissão Sob Demanda e Cache Volátil**: O `.binarypb` do croqui (~dezenas de KB) é baixado sob demanda e processado em memória/cache temporário volátil. Imagens e mapas são carregados sob demanda com parâmetros de quebra de cache SHA-256 (`?v=hash`) e armazenados no cache volátil do sistema operacional (`getTemporaryDirectory()`).
- **Verificação Periódica de ETag**: Durante a visualização de um croqui online ativo, requisições leves periódicas (`If-None-Match: <etag>`) a cada 30-60 segundos verificam atualizações remotas, exibindo um aviso não intrusivo para recarga caso uma versão mais recente seja publicada.
- **Tamanho de Download Pré-Computado no Protobuf**: Extensão do `ResumoCroqui`/`PrecomputadosResumoCroqui` no `indice.proto` com o campo `tamanho_download_bytes` (calculado pelo `aresta_db`) para exibição imediata do tamanho formatado na interface.
- **Conscientização Visual (Banner e Guardião de Saída)**: Exibição de um banner flutuante indicando "Modo Online" com ação direta "Salvar pra Pedra", acompanhado do Guardião de Saída (modal de confirmação antes de sair do croqui explorado sem salvar).
- **Download Resiliente em Segundo Plano**: Ao acionar o salvamento, o download é executado através de um serviço em primeiro plano no Android com notificação contínua do sistema operacional (`ongoing: true`) e `URLSession` em segundo plano no iOS, garantindo que o download termine mesmo se o app for minimizado ou encerrado.

## Capacidades

### Novas Capacidades
- `transmissao-croqui-online`: Carregamento sob demanda do `.binarypb`, cache volátil de mídias com quebra de cache e verificação periódica de ETag para atualizações em tempo real.
- `guardiao-navegacao-online`: Componentes de conscientização visual (banner flutuante de modo online, exibição do tamanho pré-computado e modal de confirmação ao sair sem salvar).
- `download-segundo-plano-persistente`: Serviço de download em segundo plano acoplado a notificações persistentes do sistema operacional, garantindo integridade e conclusão das transferências.

### Capacidades Modificadas
- `navigation`: Atualização dos fluxos de seleção de picos no Explorar (`browse.dart`), Home e Mapa Global para navegar imediatamente para `PicoContextNode` em modo online sem exibir modais de bloqueio de download.

## Impacto

- **Protobuf e Modelos de Dados**: Adição do campo `tamanho_download_bytes` no `indice.proto` e geração dos arquivos Dart correspondentes.
- **Arquitetura Frontend**:
  - `DatasetRepository`: Suporte a croquis em sessão online juntamente com os picos baixados.
  - Resolução de Mídia: `ProvedorImagemAresta` unificando `/downloads` permanente, cache volátil `/temp_cache` e streaming da CDN.
  - Serviços de Rede: `ServicoCroquiOnline` (ETag) e `ServicoDownloadSegundoPlano` (Foreground Service).
- **Princípios e Qualidade**:
  - Nomenclatura 100% em português brasileiro em todas as classes, métodos, widgets, variáveis e testes.
  - TDD estrito com testes de widget e unidade espelhados em `test/`, visando 100% de cobertura.
  - Documentação contínua com docstrings (`///`) em todos os componentes e atualização dos arquivos `README.md`.
