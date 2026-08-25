## 1. Documentação Legal e Governança

- [x] 1.1 Substituir o arquivo `LICENSE` raiz pelo texto oficial da Mozilla Public License 2.0 (MPL 2.0)
- [x] 1.2 Atualizar o `README.md` raiz com as cláusulas de Licença MPL 2.0, Proteção de Marca ("Aresta Climb") e Direitos sobre os Croquis
- [x] 1.3 Criar o arquivo `CONTRIBUTING.md` com diretrizes de Developer Certificate of Origin (DCO com `git commit -s`), referências a `PRINCIPIOS.md` e fluxo de Pull Requests
- [x] 1.4 Atualizar o `frontend/README.md` com as referências pertinentes à licença MPL 2.0 e governança


## 2. Teste Automatizado de Conformidade SPDX (TDD - Fase Vermelha / Red)

- [x] 2.1 Criar o teste unitário inicial `frontend/test/legal/conformidade_spdx_test.dart` com docstrings explicativas em português, validando que todos os arquivos `.dart` de autoria do projeto contêm exatamente `// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Authors` e `// SPDX-License-Identifier: MPL-2.0`
- [x] 2.2 Executar o teste unitário (`flutter test test/legal/conformidade_spdx_test.dart`) e validar a falha inicial esperada (etapa Vermelho do TDD) antes da inserção dos cabeçalhos nos arquivos existentes


## 3. Inserção dos Cabeçalhos SPDX no Código-Fonte (TDD - Fase Verde / Green)

- [x] 3.1 Adicionar o cabeçalho SPDX padrão (`// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Authors` e `// SPDX-License-Identifier: MPL-2.0`) em todos os arquivos `.dart` de `frontend/lib/`
- [x] 3.2 Adicionar o cabeçalho SPDX padrão em todos os arquivos `.dart` de `frontend/test/` e scripts em `frontend/tool/`

## 4. Validação, Refatoração e Verificação Final (TDD - Fase Refatorar)

- [x] 4.1 Reexecutar o teste de conformidade de licença (`flutter test test/legal/conformidade_spdx_test.dart`) garantindo 100% de sucesso (etapa Verde do TDD)
- [x] 4.2 Executar a suíte completa de testes do aplicativo (`flutter test`) para assegurar 100% de integridade e cobertura contínua do projeto

