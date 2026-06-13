# Navegação do App (Tree Navigation)

Este diretório contém a lógica principal de navegação do aplicativo, que foi desenhada usando uma estrutura baseada em **árvore de nós** (Tree Navigation) em vez do tradicional sistema de pilha (Stack/Push-Pop) do Flutter.

## Por que usar navegação em árvore?

Em aplicativos complexos com múltiplas camadas de informações hierárquicas (como Picos -> Setores -> Vias), a navegação padrão em pilha pode gerar problemas de "stacking infinito". 
Por exemplo, se o usuário abrir o mapa de um setor, clicar em uma via, voltar para o mapa, clicar em outra via e assim por diante, as páginas começarão a se empilhar umas sobre as outras repetidamente. Isso não apenas consome memória, mas torna o comportamento do botão de "Voltar" imprevisível, exigindo que o usuário desfaça cada passo.

Com a navegação em árvore, nós declaramos um **estado atual** na hierarquia (`currentNode`). Ao avançar, criamos um nó filho. Ao recuar, nós simplesmente apontamos para o pai do nó atual. Independentemente de quantos atalhos transversais o usuário pegue (por exemplo, ir de uma via diretamente para o mapa e depois para outra via), a estrutura em árvore garante que o aplicativo saiba exatamente o contexto e o "caminho de volta" correto.

## Arquivos

### `navigation_tree.dart`
Contém a definição dos nós (`NavNode`) e o controlador central de estado da navegação (`TreeNavigationController`).
- **NavNode**: A classe base de todos os nós de navegação. Cada nó guarda uma referência para o seu `parent` (pai) e, o mais importante, **armazena apenas IDs em formato de texto** (como `cragId`, `setorNome`, `mapaCaminhoImagem`), nunca os objetos complexos do Protobuf instanciados na memória.
- Nós implementados: `HomeNode`, `SettingsNode`, `BrowseNode`, `PicoNode`, `SetorNode`, `GrupoNode`, `ViaNode`, `GPSNode`, `MapaInterativoNode` e `MapaGeralPicoNode`.

### `page_listenable_builder.dart`
É o elo de **Hot-Reload** da UI. 
A árvore de navegação fornece o ID do que deve ser renderizado (ex: a Via "Escadaria"), mas é o `PageListenableBuilder` quem consome esse ID e busca o dado atualizado diretamente da memória (`DatasetRepository.activeDataset`). Se um croqui for atualizado em background, o builder notará a alteração e redesenhará a página perfeitamente injetando os objetos novinhos, mantendo a tela do aplicativo em sincronia com arquivos locais.

### `navigation_functions.dart`
Contém a classe estática `AppNav`, que funciona como uma interface limpa (API) para acessar e modificar a árvore de navegação sem precisar lidar diretamente com o `BuildContext` complexo do controlador.
Sempre que precisar navegar para uma nova tela, prefira utilizar os métodos definidos aqui em vez de `Navigator.push` ou `Navigator.pop`. A API aceita objetos complexos por comodidade (ex: `AppNav.toSetor(context, setor: meuSetor)`), mas descarta os objetos nos bastidores e salva apenas o `nome` do setor na árvore.

## Como usar (A API `AppNav`)

Substitua chamadas manuais como `Navigator.push` por:

```dart
// Para navegar para a página de um Pico:
AppNav.toPico(context, pico: meuPico, croqui: meuCroqui, cragId: id);

// Para navegar para um Setor (herda contexto do pai automaticamente):
AppNav.toSetor(context, setor: meuSetor);

// Para navegar para uma Via:
AppNav.toVia(context, escalada: minhaVia, setor: meuSetor);

// Para abrir o Mapa de forma integrada à árvore:
AppNav.toMapaInterativo(context, mapa: mapa, cragId: id, escaladas: vias, setores: setores);
```

Para voltar para a página anterior:

```dart
AppNav.back(context);
```

Para retornar à página inicial instantaneamente:

```dart
AppNav.home(context);
```

> **Nota sobre sobreposições hierárquicas (Mapas):** Telas de tela cheia que fazem parte da exploração da escalada (como Mapas Interativos) estão perfeitamente integradas na árvore como `MapaInterativoNode` para manter o contexto. Não utilize `Navigator.push` para mapas.

> **Exceção - Popups Utilitários e Dialogs:** O `Navigator.push` e `Navigator.pop` PADRÃO DO FLUTTER DEVEM SER USADOS para overlays utilitários isolados que não fazem parte do fluxo contínuo de navegação ou que precisam retornar dados via `await` (Exemplos: Scanner de QR Code, modais de "Termos de Uso", caixas de diálogo e indicadores de carregamento). A Navegação em Árvore destina-se estritamente à hierarquia principal de conteúdo (Home -> Pico -> Setor -> Via).
## Hierarquia Lógica da UI vs Herança de Classes

Ao ler o código (`navigation_tree.dart`), é importante não confundir a **Hierarquia Lógica da Interface (UI)** com a **Hierarquia de Herança de Classes no Código**.

### 1. Hierarquia Lógica da UI (Árvore de Telas)
Na navegação do aplicativo, o fluxo lógico acontece de cima para baixo: `Pico -> Setor -> Via`.
Quando o usuário está na tela de um Setor, o atributo `parent` desse nó é a tela do Pico que ele visitou anteriormente. Isso determina para onde o botão "Voltar" aponta.

### 2. Hierarquia de Herança (Código Orientado a Objetos)
No código físico em Dart, a classe `SetorNode` **não herda** da classe `PicoNode`. Na verdade, ambas são classes irmãs que herdam do mesmo modelo base abstrato: `PicoContextNode`.

```text
       PicoContextNode (Molde Abstrato)
        /          |          \
PicoNode       SetorNode       ViaNode
```

O `PicoContextNode` não representa uma tela do app; ele é apenas um molde que obriga as classes filhas a carregarem sempre o ID do contexto atual: o `cragId`. Os nós **não armazenam os dados instanciados** (o objeto `Setor` ou `Pico`), apenas seus identificadores em string. Isso garante que a árvore não trave a memória retendo versões velhas e dessincronizadas de informações caso o usuário edite o croqui ativamente. O `PageListenableBuilder` cuida de traduzir o identificador salvo no nó (como `setorNome`) para a versão em memória correta no instante do frame visual.
