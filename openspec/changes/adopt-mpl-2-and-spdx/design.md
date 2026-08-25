## Contexto

O Aresta Climb App está se preparando para abertura de código no GitHub. Anteriormente, o repositório possuía um arquivo de licença GPLv3 enquanto ainda em desenvolvimento fechado. Após exploração detalhada das necessidades do negócio (distribuição em App Stores da Apple/Google, futuras assinaturas e croquis pagos validados via backend com RevenueCat, prevenção contra concorrentes criando forks fechados e simplificação do processo de contribuição sem burocracia de CLA), decidiu-se pela adoção da Mozilla Public License 2.0 (MPL 2.0) de forma unificada no ecossistema Aresta.

Toda a concepção e implementação desta proposta seguem estritamente os preceitos inegociáveis de `PRINCIPIOS.md`.

## Objetivos / Não-Objetivos

**Objetivos:**
- Substituir o arquivo `LICENSE` existente pela íntegra oficial da Mozilla Public License 2.0 (MPL 2.0).
- Adicionar no `README.md` raiz cláusulas de governança separando código-fonte (MPL 2.0), marcas registradas ("Aresta", "Aresta Climb" e logotipos) e direitos autorais dos dados/croquis.
- Criar o `CONTRIBUTING.md` oficial documentando o Developer Certificate of Origin (DCO) via `git commit -s` e integrando com o `PRINCIPIOS.md`.
- Inserir o cabeçalho padronizado SPDX (`// SPDX-License-Identifier: MPL-2.0` / `// Copyright (c) 2026 Aresta Climb`) em todos os arquivos de código Dart (`frontend/lib/`, `frontend/test/`, `frontend/tool/`).
- Implementar um teste de unidade automatizado em `frontend/test/legal/conformidade_spdx_test.dart` (seguindo rigorosamente o TDD e 100% de cobertura) para auditar recursivamente todos os arquivos Dart e impedir regressões de conformidade no CI/CD.

**Não-Objetivos:**
- Reescrita do histórico antigo do Git com `git-filter-repo` (esta etapa de reescrita retroativa do histórico será executada pelo mantenedor do projeto em seu ambiente local antes da publicação).
- Alteração da lógica de negócios do aplicativo, DRM ou integração de pagamentos (que permanecem desacoplados na arquitetura de backend).

## Decisões Arquiteturais e Conformidade com PRINCIPIOS.md

### 1. Tudo em Português Brasileiro (Princípio I)
- Todos os documentos (`CONTRIBUTING.md`, `README.md`, especificações), nomes de arquivos de teste (`conformidade_spdx_test.dart`), classes auxiliares, funções e comentários explicativos em docstrings (`///`) serão escritos 100% em português brasileiro.

### 2. Escolha da Licença MPL 2.0 em vez de GPLv3 pura ou MIT
- **Decisão**: Adotar MPL 2.0.
- **Justificativa**: A MPL 2.0 é copyleft por arquivo. Impede que concorrentes apropriem-se dos arquivos existentes do Aresta para criar versões proprietárias fechadas, ao mesmo tempo em que elimina conflitos de linking com SDKs de terceiros (Firebase, RevenueCat) e termos restritivos de App Stores.
- **Alternativas consideradas**:
  - *GPLv3 pura*: Incompatível com SDKs proprietários fechados e termos da Apple App Store sem exceções complexas.
  - *MIT / Apache 2.0*: Permissivas demais; permitiriam a um concorrente fechar o código do app e criar um produto proprietário concorrente.

### 3. Governança via DCO (Developer Certificate of Origin) em vez de CLA
- **Decisão**: Adotar DCO v1.1 com sign-off (`git commit -s`).
- **Justificativa**: A MPL 2.0 foi desenhada para aceitar contribuições diretas sem necessidade de cessão de direitos autorais (CLA). O DCO simplifica o onboarding de desenvolvedores da comunidade de escalada e pode ser validado automaticamente por bots de CI no GitHub.

### 4. Padrão de Cabeçalho SPDX e TDD (Princípios III, IV e VI)
- **Decisão**: Adicionar o formato padrão SPDX no topo dos arquivos:
  ```dart
  // SPDX-License-Identifier: MPL-2.0
  // Copyright (c) 2026 Aresta Climb
  ```
- **Ciclo TDD**:
  1. *Red*: Escrever `frontend/test/legal/conformidade_spdx_test.dart` e rodar `flutter test test/legal/conformidade_spdx_test.dart`, constatando a falha antes da modificação dos arquivos de código.
  2. *Green*: Aplicar o cabeçalho SPDX a todos os arquivos Dart e reexecutar o teste até obter 100% de sucesso.
  3. *Refactor*: Garantir docstrings explicativas e código limpo sem abstrações prematuras ou complexidade desnecessária.
- **Implementação do Teste**: O teste inspeciona os diretórios `lib/`, `test/` e `tool/`, ignorando arquivos autogerados (`.g.dart`, `.pb.dart`, submódulos como `aresta_api` e `.dart_tool`), e assevera que todos os arquivos `.dart` de autoria do projeto contêm a linha `SPDX-License-Identifier: MPL-2.0`.

## Riscos / Trade-offs

- **[Risco] Arquivos autogerados pelo Protobuf ou FlutterFire quebrarem o teste de SPDX**:
  - *Mitigação*: A lógica do teste de conformidade filtra explicitamente arquivos e diretórios autogerados (`.g.dart`, `.pb.dart`, submodules como `aresta_api`, `frontend/legal/repo` e `.dart_tool`), focando apenas nos arquivos de autoria do projeto.
- **[Risco] Esquecimento de inclusão do cabeçalho em novos arquivos futuros**:
  - *Mitigação*: O teste de conformidade roda no `flutter test` padrão e falhará o build caso qualquer novo arquivo seja adicionado sem o cabeçalho.
