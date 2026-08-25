# Contribuindo com o Aresta Climb App

Obrigado pelo interesse em contribuir com o Aresta! Este documento orienta como colaborar com o projeto mantendo a alta qualidade técnica, conformidade legal e respeito aos nossos princípios de engenharia.

---

## 1. Princípios de Engenharia (Obrigatório)

Antes de propor alterações ou escrever qualquer linha de código, leia atentamente nossos [Princípios de Engenharia](PRINCIPIOS.md). 
Eles são a diretriz máxima do projeto e incluem regras inegociáveis:
- **Tudo em Português Brasileiro**: Código, documentação, variáveis, nomes de widgets, commits e comentários.
- **TDD (Test-Driven Development)**: Os testes devem ser escritos e rodados (falhando inicialmente) antes de qualquer implementação.
- **100% de Cobertura de Testes**: Qualquer novo recurso ou correção deve alcançar cobertura total de testes unitários ou de widget.
- **Simplicidade e Anti-Abstração**: Prefira código claro, direto e declarativo.
- **Documentação Contínua**: Toda implementação deve conter docstrings (`///` no Dart) explicando a intenção.

---

## 2. Developer Certificate of Origin (DCO) e Sign-off

Para mantermos o projeto ágil e sem a necessidade de contratos complexos (CLA), adotamos o **Developer Certificate of Origin (DCO v1.1)**.

Ao contribuir com o projeto, você declara formalmente que:
1. A contribuição foi criada por você, no todo ou em parte, e você tem o direito de submetê-la sob a licença de código aberto indicada (MPL 2.0); ou
2. O trabalho é baseado em trabalho prévio coberto por uma licença de código aberto apropriada; e
3. Você compreende e concorda que este projeto e a sua contribuição são públicos e que um registro da contribuição (incluindo todas as informações pessoais que você enviar com ela, como nome e e-mail) é mantido indefinidamente e pode ser redistribuído.

### Como assinar seus commits
Para certificar seu commit, basta adicionar a flag `-s` ou `--signoff` ao comando de commit do Git:

```bash
git commit -s -m "feat(mapa): adiciona suporte a zoom em carrossel"
```

Isso anexará automaticamente a linha de assinatura no final da sua mensagem de commit:
```text
Signed-off-by: Seu Nome <seu.email@exemplo.com>
```

---

## 3. Identificadores SPDX nos Arquivos

Todo e qualquer novo arquivo de código-fonte Dart (`.dart`) adicionado ao projeto DEVE conter o cabeçalho padronizado de identificação SPDX nas suas duas primeiras linhas:

```dart
// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
```

Nossa suíte de testes valida automaticamente a presença e a exatidão desse cabeçalho em todos os arquivos de autoria do projeto.

---

## 4. Como Submeter um Pull Request (PR)

1. Faça um Fork do repositório.
2. Crie uma branch específica para sua funcionalidade ou correção:
   ```bash
   git checkout -b feat/minha-melhoria
   ```
3. Implemente as alterações seguindo TDD (escreva os testes primeiro).
4. Garanta que a suíte completa de testes passe com 100% de sucesso:
   ```bash
   cd frontend
   flutter test --coverage
   ```
5. Envie seus commits assinados com `-s`:
   ```bash
   git commit -s -m "feat: implementa nova funcionalidade"
   git push origin feat/minha-melhoria
   ```
6. Abra o Pull Request descrevendo claramente o objetivo, os testes incluídos e as motivações da mudança.
