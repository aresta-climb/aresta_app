# Princípios de Engenharia Aresta (`aresta_app`)

Para garantir que o nosso código, seja ele escrito por humanos ou por agentes autônomos de IA (como Google Antigravity e OPSX), se mantenha coeso, testável, sustentável e simples, adotamos oito princípios basilares e inegociáveis.

Estes princípios devem guiar toda e qualquer nova implementação, revisão ou refatoração no repositório do aplicativo.

## I. Tudo em Português
Todo o repositório deve **OBRIGATORIAMENTE** ser em português brasileiro. Isso inclui, mas não se limita a: documentação, especificações (OpenSpec), comentários de código, docstrings (`///`), mensagens de erro, nomes de bibliotecas, classes, widgets, funções, métodos e variáveis.
*Exceções:* Nomes de pacotes de terceiros, APIs nativas do Flutter/Dart, termos técnicos consolidados do ecossistema e títulos de seção exigidos em inglês pelo schema do OpenSpec.

## II. Modularidade e Desacoplamento (Library-First / Feature-First)
Toda funcionalidade DEVE começar e ser estruturada como uma biblioteca ou componente modular independente.
- Os serviços, utilitários e widgets devem ser autossuficientes, testáveis de forma isolada e claramente documentados.
- Evite criar arquivos, classes ou widgets que sirvam apenas para fins puramente organizacionais; cada módulo separado deve ter um propósito funcional claro e uma interface pública coesa.
- Não misture regras de negócios em grandes monólitos de UI. Mantenha a separação de responsabilidades (MVVM) limpa.

## III. Testes Orientados a Comportamento e Espelhamento 1:1
Os testes devem validar **o que** o código ou widget faz (comportamento), e nunca **como** ele foi implementado internamente.
- **Espelhamento 1:1 Obrigatório**: QUALQUER arquivo `.dart` de lógica ou UI em `lib/` DEVE possuir um arquivo `_test.dart` correspondente na pasta `test/` (espelhando a mesma estrutura de diretórios do `lib/`). Se decidimos separar código em um arquivo próprio, ele possui por definição uma interface pública que deve ser testada.
- **Um Teste por Comportamento (Behavior-Driven Testing)**: Cada bloco `test()` ou `testWidgets()` deve verificar um único comportamento ou fluxo observável através da API pública ou interação de UI (seguindo a estrutura *Dado/Quando/Então* ou *Preparar/Agir/Verificar*).
- **Proibição de Change-Detector Tests**: É estritamente proibido escrever testes acoplados à implementação interna (inspecionar estado privado, verificar chamadas de métodos auxiliares internos ou replicar a lógica de produção no asserto). Uma refatoração interna que preserve o comportamento observável nunca deve quebrar os testes.

## IV. 100% de Cobertura Comportamental e TDD (Red-Green-Refactor)
O Desenvolvimento Orientado a Testes (Test-Driven Development) e a cobertura integral são **obrigatórios** e inegociáveis.
- **Ciclo Red-Green-Refactor**: Os testes DEVEM ser escritos e vistos falhar (*Red*) antes do início de qualquer implementação de código de produção (*Green*), seguidos de refatoração (*Refactor*).
- **100% de Test Coverage via Comportamento**: Qualquer alteração submetida deve manter 100% de cobertura de testes (unitários e de widget) atingida exclusivamente exercitando comportamentos reais pela interface pública.
- **Resolução de Cobertura pelo Design**: Se uma linha ou ramificação (`if/else`, `try/catch`) não puder ser alcançada por um teste de comportamento público, **o defeito está no código de produção** (código morto, validação defensiva redundante ou acoplamento direto de I/O). A solução obrigatória é simplificar o código de produção ou remover a ramificação inalcançável — sendo proibido usar mocks internos ou expor métodos privados para forçar cobertura artificial.

## V. Fidelidade de Produção, Anti-Mocking e Testes de Integração em Primeiro Lugar
A suíte de testes deve ser representativa do comportamento real do aplicativo em produção.
- **Testes de Integração e Fronteira em Primeiro Lugar**: Priorize testar as fronteiras, contratos e interações de componentes antes de descer para detalhes isolados.
- **Proibição de Mocks para Código Interno**: É proibido usar `mocktail`, `mockito` ou classes `extends Mock` para isolar classes, modelos Protobuf, `ValueNotifier`, árvore de navegação ou serviços internos do próprio projeto. Use sempre instâncias reais, Protobufs reais e diretórios temporários reais (`Directory.systemTemp`).
- **Bibliotecas `test-only` de Fakes Determinísticos**: Para fronteiras externas (rede HTTP, Firebase, armazenamento seguro, banco local ou plugins nativos), devem ser utilizadas **bibliotecas `test-only` de Fakes determinísticos** em memória ou micro-servidores locais (configuráveis inclusive para simular falhas determinísticas de I/O), evitando reimplementar stubs ad-hoc em cada arquivo de teste.
- **Fakes Também São Bibliotecas Testadas**: Toda biblioteca de Fake (`*_fake.dart`) é uma biblioteca de primeira classe e DEVE obrigatoriamente possuir seu próprio arquivo de teste espelhado (`*_fake_test.dart`) garantindo que o Fake cumpre fielmente o contrato real.

## VI. Simplicidade, Anti-Abstração e Documentação Contínua
O código DEVE ser simples, declarativo, bem documentado e fácil de compreender.
- Evite abstrações prematuras e códigos "espertos" (complexidade desnecessária). Siga a regra de ouro: *"Melhor um pouco de duplicação do que a abstração errada."*
- Pratique o DRY (Don't Repeat Yourself) de forma prudente: extraia apenas o que for óbvio e simples para reutilização clara.
- Toda implementação DEVE ser documentada através de **docstrings** (`///` no Dart) explicando *o porquê* (intenção) e não apenas *o quê* (ação), e toda nova funcionalidade ou mudança arquitetural DEVE atualizar os arquivos `README.md` pertinentes.

## VII. Inegociabilidade Perante Código Legado (Regra do Escoteiro)
A existência de código ou testes legados no repositório que ainda não sigam integralmente estes padrões **NÃO é desculpa nem precedente** para violá-los.
- Agentes autônomos e desenvolvedores estão proibidos de imitar antipadrões presentes em arquivos vizinhos (como uso de `mocktail`/`mockito`, *change-detector tests* ou identificadores em inglês).
- Sempre que tocar em um arquivo ou módulo existente que viole este `AGENTS.md`, você DEVE refatorar o trecho e os testes afetados para que passem a seguir integralmente estes princípios.

## VIII. Testes de Widget, Isolates Reais e Arquitetura Reativa
- **Testes de Widget em Primeiro Lugar na UI**: Priorize `testWidgets` para validar os fluxos visuais e interações reais do usuário de ponta a ponta na interface.
- **Fidelidade em Isolates e Sincronização**: Testes de sincronização em background (`SyncService` / `SyncIsolate`) devem utilizar micro-servidores HTTP locais em `localhost` e arquivos temporários reais para atravessar fronteiras de memória de `Isolate` com fidelidade de produção.
- **Navegação em Árvore e Estado Reativo**: Respeite a arquitetura de navegação baseada em árvore de nós (`AppNav` / `PageListenableBuilder`) e modelos Protobuf imutáveis/reativos sem introduzir estado global acoplado.

---
> **Nota para Agentes Autônomos**: Vocês estão estritamente obrigados a considerar este documento como diretriz de mais alta prioridade ao planejar arquitetura, sugerir refatorações, ou implementar novas rotinas (incluindo o uso do OpenSpec).
