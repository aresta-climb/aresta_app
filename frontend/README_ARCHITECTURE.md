# Arquitetura Reativa do Aresta App (Hot-Reload)

Este documento explica como o Aresta App garante o "hot-reload" em tempo real dos mapas e dados (croquis) sem travar a interface de usuário (UI) e seguindo as melhores práticas de arquitetura em Flutter (Separação de Preocupações).

## O Padrão Ouro: Separação entre UI e Serviços

A atualização de dados no aplicativo é feita dividindo o trabalho pesado em duas camadas distintas que conversam entre si usando **Estado Reativo**:

1. **Camada de Serviço (Background):** `SyncService` e `_checkForUpdates`
2. **Camada de Apresentação (UI):** `PageListenableBuilder`

---

### 1. O Motor (Background): `_checkForUpdates`

A função `_checkForUpdates` (localizada dentro de `SyncService`) atua como o "trabalhador invisível". O trabalho exclusivo dela é lidar com a infraestrutura pesada:

- **Requisições de Rede (HTTP):** Buscar o índice (`indice.binarypb`) no servidor.
- **Processamento:** Comparar o código `sha256` antigo com o novo para detectar mudanças (por exemplo, quando o editor do croqui for atualizado em tempo real).
- **Acesso a Disco (I/O):** Fazer o download dos novos arquivos binários (`.binarypb`) e sobrescrever as versões antigas no armazenamento interno do celular.

**Por que ele roda separado?**
Ler arquivos no disco e esperar respostas da internet demoram milissegundos a segundos. Se a tela (UI) precisasse esperar a internet responder a cada frame para desenhar o botão de voltar, o aplicativo iria congelar completamente (famoso erro de "App Not Responding" - ANR). 

Quando o `_checkForUpdates` finaliza seu trabalho, ele apenas avisa o estado central (`DatasetRepository.activeDataset`) dizendo: *"O banco de dados mudou, aqui está a nova versão!"*

---

### 2. A Cola Visual (UI): `PageListenableBuilder`

O `PageListenableBuilder` (localizado em `lib/navigation/page_listenable_builder.dart`) é um `Widget` visual. Diferente do serviço, ele não sabe como baixar coisas da internet nem acessar discos; ele apenas desenha pixels na tela a impressionantes 60 frames por segundo.

O trabalho dele é:
- **Ouvir:** Ficar escutando passivamente a variável na memória do `DatasetRepository.activeDataset`.
- **Reagir (O Hot-reload):** Assim que a variável grita *"Mudei!"* (acionada pelo término do `_checkForUpdates`), o Builder acorda imediatamente.
- **Injetar:** Ele busca os dados mais atualizados do `cragId` correspondente na memória recém-atualizada e redesenha a página inteira (seja a view do Setor, da Via, ou do Mapa).

**Resiliência e Identificadores (Nós da Árvore):**
Para que isso funcione sem crashar o aplicativo, os nós da nossa árvore de roteamento (`NavNode`) não guardam a *versão velha* do objeto do mapa em si. Eles guardam apenas os **IDs em formato de texto** (ex: `cragId = "pico_coruja"`, `mapaCaminhoImagem = "mapa_1.webp"`). 

Assim, quando o `PageListenableBuilder` decide recarregar a tela após o download, ele usa os IDs de texto para "pescar" os objetos novinhos e atualizados que o `_checkForUpdates` acabou de colocar na memória, resultando em um update imperceptível na tela do usuário.

---

## Conclusão: Por que não fundir os dois?

Tentar colocar a lógica do `_checkForUpdates` dentro do `PageListenableBuilder` faria o aplicativo disparar uma nova requisição de rede ou leitura de disco *todas as vezes* que o usuário fizesse um simples scroll ou ativasse uma animação. 

Manter o `_checkForUpdates` (Serviço) puxando a alavanca do estado, e o `PageListenableBuilder` (UI) observando o estado para se redesenhar é o segredo de uma Arquitetura Reativa saudável e eficiente. Essa é a razão de conseguirmos atualizações na hora sem perdas de desempenho!
