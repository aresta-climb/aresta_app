# Princípios de Engenharia Aresta App

Para garantir que o nosso código, seja ele escrito por humanos ou por agentes autônomos de IA (como Google Antigravity e OPSX), se mantenha coeso, testável, sustentável e simples, adotamos princípios basilares e inegociáveis. 

Estes princípios devem guiar toda e qualquer nova implementação ou alteração no repositório do aplicativo.

## I. Tudo em Português
Todo o repositório deve **OBRIGATORIAMENTE** ser em português brasileiro. Isso inclui, mas não se limita a: documentação, especificações, comentários de código, nomes de funções, nomes de classes, widgets e até nomes de variáveis.

## II. Componentes Independentes (Feature-First)
Toda funcionalidade DEVE ser construída de forma modular. 
- Os componentes e widgets devem ser autossuficientes, testáveis de forma independente e documentados. 
- Evite criar classes ou widgets que sirvam apenas para fins puramente organizacionais; cada componente deve ter um propósito funcional claro.
- Não misture regras de negócios em grandes monólitos de UI. Mantenha a separação de responsabilidades limpa.

## III. 100% de Test Coverage
Qualquer alteração submetida deve buscar ou exigir 100% de test coverage (cobertura de testes unitários e de widget). Isso é inegociável.

## IV. Imperativo do Teste em Primeiro Lugar (TDD)
O Desenvolvimento Orientado a Testes (Test-Driven Development) é **obrigatório** e inegociável. 
- QUALQUER arquivo `.dart` de lógica ou UI DEVE ter um `_test.dart` correspondente na pasta `test/` (espelhando a mesma estrutura de diretórios do `lib/`).
- Os testes DEVEM ser escritos e rodados (devem inicialmente falhar) antes do início de qualquer implementação do código de produção. 
- O ciclo Red-Green-Refactor (Vermelho-Verde-Refatorar) deve ser estritamente seguido para cada nova tarefa e unidade lógica introduzida.

## V. Testes de Widget em Primeiro Lugar
Priorize testar as fronteiras e a interface (Widget Tests) do sistema antes de descer para unidades puras irrelevantes. 
- Os testes de Widget e Integração DEVEM ser priorizados para validar os fluxos reais do usuário de ponta a ponta.
- Isso garante a integridade da UI como um todo e assegura que os requisitos visuais e funcionais sejam atendidos logo no início do desenvolvimento.

## VI. Simplicidade e Anti-Abstração
O código DEVE ser simples, declarativo e fácil de compreender. 
- Evite abstrações prematuras e códigos "espertos" (complexidade desnecessária). 
- Siga a regra de ouro: *"Melhor um pouco de duplicação do que a abstração errada."*
- Ao mesmo tempo, pratique o DRY (Don't Repeat Yourself) de forma prudente: evite código repetitivo se ele pode ser abstraído de forma óbvia e simples para fácil reutilização.

## VII. Documentação Contínua e Abrangente
O código limpo não substitui a documentação técnica.
- Toda a implementação DEVE ser muito bem documentada através de **docstrings** (comentários em blocos `///` no Dart) em métodos, classes e widgets, explicando *o porquê* (intenção) e não apenas *o quê* (ação).
- Todo novo módulo, funcionalidade ou alteração arquitetural DEVE ser refletido com melhorias e atualizações nos arquivos `README.md` pertinentes.
- A documentação é um artefato vivo e parte inseparável da entrega de valor.

---
> **Nota para Agentes Autônomos**: Vocês estão estritamente obrigados a considerar este documento como diretriz de mais alta prioridade ao planejar arquitetura, sugerir refatorações, ou implementar novas rotinas (incluindo o uso do `opsx-apply`).
