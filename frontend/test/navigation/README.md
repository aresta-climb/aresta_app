# Testes de Navegação (`test/navigation/`)

Este diretório contém os testes da arquitetura de navegação em árvore (`lib/navigation/`).

## Arquivos Principais

- `arvore/modelo_arvore_navegacao_test.dart`: Regras de domínio de `ArvoreNavegacao` (transição, retorno, prevenção de loops, salto de `PerfilNode` quando deslogado, retorno à raiz e poda de nós de perfil/caderneta).
- `arvore/navegador_arvore_test.dart`: Notificações de `NavegadorArvore` (`TreeNavigationController`) e `onBackInterceptor`.
- `arvore/no_navegacao_test.dart`: Igualdade, `rotuloAmigavel` e `obterCaminhoCurto()` dos nós.
- `funcoes_navegacao_test.dart`: Métodos estáticos de `AppNav` (`toPico`, `toSetor`, `toVia`, `toViaPorUid`, `toLogin`, `abrirPerfilOuLogin`, `toSettings`, `back`, `home` com desempilhamento de rotas imperativas, `minimizarAplicativo`).
- `construtor_reativo_pagina_test.dart`: Atualização reativa de `PageListenableBuilder` quando croquis mudam em memória e retorno automático caso uma entidade deixe de existir após atualização.
- `analisador_rotas_deep_link_test.dart`, `localizador_destino_uid_test.dart` e `servico_navegacao_deep_link_test.dart`: Parsing de URLs `aresta.cc` e `/croquis`, localização de NanoID 14c em cascata, tratamento offline (`ModalCroquiSemConexao`) e separação de callbacks OAuth.
- `navigation_test.dart` e `arvore_navegacao_test.dart`: Fluxos integrados de navegação entre páginas e carrosséis de mapas.

## Comportamentos Verificados

1. **Estado Inicial**: Início em `HomeNode` com `parent == null` e retorno `false` ao chamar `goBack()` na raiz.
2. **Prevenção de Loops (Rewind)**: No ciclo `Setor -> Via -> Setor -> Via`, abrir um ancestral já presente na linhagem recua para o nó original em vez de empilhar duplicatas, mesclando parâmetros de destino (`scrollToMapaGeral`, `returnToSetorNome`, `initialSelectedId`).
3. **Retorno ao Início (`AppNav.home`)**: Desempilha rotas imperativas sobrepostas nos `Navigator`s local e raiz e redefine a árvore para `HomeNode`.
4. **Salto e Poda de Perfil**: Usuários não autenticados que abrem `Configurações` a partir do `Login` não passam por `PerfilNode` nem na ida nem ao voltar; desativar interações nas configurações remove nós de login, perfil e caderneta da linhagem ativa.

## Execução

```bash
flutter test test/navigation/
```
