# Testes da Árvore de Navegação (Tree Navigation)

Este diretório contém os testes de unidade dedicados a validar o comportamento do sistema de navegação baseado em árvore (Tree Navigation) do aplicativo.

## O que está sendo testado?

Os testes estão concentrados nos arquivos [navigation_test.dart](file:///c:/Users/utsch/flutter_stuff/repositories/aresta/dev/aresta_app/frontend/test/navigation/navigation_test.dart) e [navigation_tree_test.dart](file:///c:/Users/utsch/flutter_stuff/repositories/aresta/dev/aresta_app/frontend/test/navigation/navigation_tree_test.dart) e validam as seguintes capacidades e comportamentos do `TreeNavigationController`:

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
* Por exemplo, garante que o `MapaoGlobalNode` (o mapa-múndi) atue estritamente como um nó folha descendente do `BrowseNode` quando acionado a partir da aba Explorar, preservando a linha do tempo do usuário ao recuar.

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
