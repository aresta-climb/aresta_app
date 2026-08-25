## 1. Documentação Legal e Governança

- [ ] 1.1 Substituir o arquivo `LICENSE` raiz pelo texto oficial da Mozilla Public License 2.0 (MPL 2.0)
- [ ] 1.2 Atualizar o `README.md` raiz com as cláusulas de Licença MPL 2.0, Proteção de Marca ("Aresta Climb") e Direitos sobre os Croquis
- [ ] 1.3 Criar o arquivo `CONTRIBUTING.md` com diretrizes de Developer Certificate of Origin (DCO com `git commit -s`), referências a `PRINCIPIOS.md` e fluxo de Pull Requests
- [ ] 1.4 Atualizar o `frontend/README.md` com as referências pertinentes à licença MPL 2.0 e governança

## 2. Teste Automatizado de Conformidade SPDX (TDD - Fase Vermelha / Red)

- [ ] 2.1 Criar o teste unitário inicial `frontend/test/legal/conformidade_spdx_test.dart` com docstrings explicativas em português, inspecionando recursivamente arquivos `.dart` de autoria do projeto
- [ ] 2.2 Executar o teste unitário (`flutter test test/legal/conformidade_spdx_test.dart`) e validar a falha inicial esperada (etapa Vermelho do TDD) antes da inserção dos cabeçalhos nos arquivos existentes

## 3. Inserção dos Cabeçalhos SPDX no Código-Fonte (TDD - Fase Verde / Green)

- [ ] 3.1 Adicionar o cabeçalho SPDX padrão (`// SPDX-License-Identifier: MPL-2.0` e `// Copyright (c) 2026 Aresta Climb`) em todos os arquivos `.dart` de `frontend/lib/`
- [ ] 3.2 Adicionar o cabeçalho SPDX padrão em todos os arquivos `.dart` de `frontend/test/` e scripts em `frontend/tool/`

## 4. Validação, Refatoração e Verificação Final (TDD - Fase Refatorar)

- [ ] 4.1 Reexecutar o teste de conformidade de licença (`flutter test test/legal/conformidade_spdx_test.dart`) garantindo 100% de sucesso (etapa Verde do TDD)
- [ ] 4.2 Executar a suíte completa de testes do aplicativo (`flutter test`) para assegurar 100% de integridade e cobertura contínua do projeto
