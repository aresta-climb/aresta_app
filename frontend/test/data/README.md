# Testes de Modelos de Dados (`test/data/`)

Esta pasta contém os testes unitários dedicados à validação de modelos de dados e serialização JSON da pasta `lib/data/`, com cobertura de resiliência e integridade.

---

## Estrutura de Diretórios

```text
test/data/
└── modelos/
    ├── cadena_test.dart             - Testes de criação, imutabilidade, validação e serialização JSON de Cadena
    ├── perfil_escalador_test.dart   - Testes de geração NanoID 14c, fotoUrl, accessToken, copyWith e JSON de PerfilEscalador
    ├── tipo_ascensao_test.dart      - Testes de prioridade visual e regras esportivas de TipoAscensao
    ├── tipo_escalada_test.dart      - Testes de rotulagem e conversão de TipoEscalada
    └── metadados_feedback_test.dart - Testes de integridade e serialização de FeedbackMetadata
```

---

## 1. Testes de Modelos (`modelos/`)

### `perfil_escalador_test.dart`
Valida a identidade esportiva e estado de sessão do modelo `PerfilEscalador`:
- **Geração Inicial (`PerfilEscalador.gerarInicial`)**: Verifica a geração criptográfica do `autorIdPublico` (NanoID 14c) e apelido padrão.
- **Campos de Autenticação e Foto (`userId`, `fotoUrl`, `accessToken`)**: Valida `estaAutenticado`, atualização imutável via `copyWith`, limpeza simultânea de `userId` e `accessToken` com `limparUserId: true` e preservação do NanoID 14c.
- **Serialização JSON (`toMap` / `fromMap` / `toJson` / `fromJson`)**: Garante compatibilidade com chaves `fotoUrl`, `avatar_url`, `accessToken` e `access_token`, além de regeneração segura caso o JSON contenha identificadores inválidos.

### `cadena_test.dart`
Valida o registro individual de ascensões (`Cadena`), limites de `notasPrivadas` (200 caracteres), `tentativas >= 1`, `grauSugerido` e serialização JSON.

### `metadados_feedback_test.dart`
Valida o ciclo completo de serialização e desserialização do modelo `FeedbackMetadata`:
- **Round-Trip JSON**: Garante que instâncias convertidas para `Map<String, dynamic>` via `toJson()` possam ser reconstruídas via `fromJson()` sem perda ou corrupção de campos.
- **Auditoria Criptográfica de Hashes**: Valida a persistência e restauração correta dos campos de integridade (`indiceSha256`, `croquiStatus`, `thumbnailStatus`, etc.).
- **Compatibilidade de Nomenclatura**: Testa a capacidade defensiva do `fromJson` de decodificar tanto chaves no formato `camelCase` quanto no formato `snake_case`.
- **Resiliência a Valores Nulos**: Assegura que propriedades opcionais ausentes no JSON decodifiquem de forma segura sem lançar exceções.

---

## Como Executar

```bash
# Executar todos os testes desta pasta
flutter test test/data/

# Executar especificamente o teste do perfil do escalador
flutter test test/data/modelos/perfil_escalador_test.dart
```
