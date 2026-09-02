# Testes da Árvore de Navegação (Tree Navigation)

Este diretório contém os testes de unidade dedicados a validar o comportamento do sistema de navegação baseado em árvore (Tree Navigation) do aplicativo.

## O que está sendo testado?

Os testes estão organizados em testes de integração de navegação e testes de domínio modular em `test/navigation/arvore/`:
- `navigation_test.dart` e `navigation_tree_test.dart`: Testes de integração de roteamento e fluxos de tela.
- `arvore/navigation_tree_model_test.dart`: Testes unitários puros das regras de domínio da árvore (push, pop, rewind, reset, canonical path).
- `arvore/tree_navigation_controller_test.dart`: Testes do controlador reativo e notificações do `ChangeNotifier`.
- `arvore/nav_nodes_test.dart`: Testes unitários dos nós (`NavNode`, rótulos amigáveis e caminhos canônicos curtos).

Validam as seguintes capacidades e comportamentos da Árvore de Navegação:

### 1. Inicialização e Estado Inicial
* Garante que a navegação sempre inicie de forma íntegra a partir do nó raiz `HomeNode`.
* Valida que o nó inicial não possui nenhum nó pai (`parent == null`).

### 2. Navegação Linear Padrão
* Simula a progressão típica do usuário pelas camadas do aplicativo (ex: `Home` -> `Pico` -> `Setor`).
* Verifica se o controlador atualiza corretamente o `currentNode` e estabelece a referência correta do nó `parent` (pai) para cada nova página.

### 3. Histórico de Retorno (Pilha de Voltar)
* Testa a função `goBack()` garantindo que o usuário retroceda de forma precisa pelas páginas da hierarquia até atingir a raiz (`HomeNode`).
* Confirma que a navegação de retorno retorna `false` ao tentar voltar a partir da raiz, permitindo que a plataforma decida a saída do aplicativo.

### 4. Resete da Navegação (Ir para a Home)
* Valida que o método `goHome()` redefine o estado de navegação de volta para o `HomeNode` de forma segura, independentemente de quão profundo o usuário esteja na hierarquia de nós.

### 5. Prevenção de Loops e Históricos Redundantes (Ancestor Rewinding)
Esta é a funcionalidade crítica do sistema baseada em árvore, projetada para evitar problemas de "stacking infinito".
* **O Problema:** Em navegadores clássicos de pilha, se o usuário estiver em uma `Via`, abrir o `Mapa (Setor)`, clicar em outra `Via`, abrir o `Mapa` de novo, o aplicativo empilhará indefinidamente as mesmas telas, exigindo muitos cliques no botão "Voltar" para sair.
* **A Solução:** Nossa árvore de navegação intercepta a navegação. Se o usuário estiver na `Via` e tentar abrir o `Setor` correspondente (que já é um ancestral dele no histórico original), o controlador realiza um **retrocesso (rewind)** para a instância original do `Setor` em vez de criar uma duplicata.
* **O Teste:** Simula exatamente o ciclo de navegação cruzada `Setor -> Via -> Setor -> Via` e valida se o histórico permanece limpo e linear. Garante que, ao clicar no botão "Voltar" a partir da via mais recente, o usuário retorna ao setor original e, com apenas mais um clique, retorna à página do Pico (ignorando qualquer redundância de saltos paralelos).

### 6. Rewind com Preservação de Estado (State Preservation)
* O sistema não apenas impede loops ao voltar para um nó ancestral, mas também **mescla propriedades mutáveis** (estado da UI) no processo.
* Se um retrocesso (rewind) for feito para um `PicoNode`, atributos de intenção da tela destino como `scrollToMapaGeral` ou `returnToSetor` são herdados na volta, atualizando a visualização sem que a página perca seu histórico raiz original. Isso vale para `MapaInterativoNode` preservando `initialSelectedId`, e afins.

### 7. Hierarquia Específica de Contexto
* Certifica que sub-nós específicos injetem corretamente a herança lógica de navegação. 
* Por exemplo, garante que o `MapaGlobalNode` (o mapa-múndi) atue estritamente como um nó folha descendente do `BrowseNode` quando acionado a partir da aba Explorar, preservando a linha do tempo do usuário ao recuar.

### 8. Hot-Reload Reativo (PageListenableBuilder)
* **`page_listenable_builder_test.dart`**: Garante o core da funcionalidade de atualizações em tempo real do modo de edição de croquis.
* Valida a inserção dinâmica de novos dados injetados via `DatasetRepository.activeDataset`, verificando se a UI acorda passivamente e se redesenha de forma silenciosa e instantânea com os novos dados sem piscar.
* Confirma o comportamento de segurança perante exclusões de dados (Resiliência): se um croqui for atualizado em background e o subnível em que o usuário está atualmente (ex: um setor) não existir mais na nova versão baixada, a view reage de forma segura chamando `AppNav.back()` automaticamente, evitando vazamentos e erros de renderização.

---

## Como executar os testes?

Para rodar especificamente a suíte de testes de navegação, execute o seguinte comando no terminal na raiz do projeto `frontend`:

```bash
flutter test test/navigation/
```

Para rodar todos os testes do projeto e certificar que não há nenhuma regressão geral:

```bash
flutter test
```
