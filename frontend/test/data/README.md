# Testes de Modelos de Dados (`test/data/`)

Esta pasta contém os testes unitários dedicados à validação de modelos de dados e serialização JSON da pasta `lib/data/`, em conformidade com as diretrizes do `AGENTS.md`.

---

## Estrutura de Diretórios

```text
test/data/
└── models/
    └── feedback_metadata_test.dart - Testes de integridade e serialização de FeedbackMetadata
```

---

## 1. Testes de Modelos (`models/`)

### `feedback_metadata_test.dart`
Valida o ciclo completo de serialização e desserialização do modelo `FeedbackMetadata`:
- **Round-Trip JSON**: Garante que instâncias convertidas para `Map<String, dynamic>` via `toJson()` possam ser reconstruídas perfeitamente via `fromJson()` sem perda ou corrupção de campos.
- **Auditoria Criptográfica de Hashes**: Valida a persistência e restauração correta dos campos de integridade (`indiceSha256`, `croquiStatus`, `thumbnailStatus`, etc.).
- **Compatibilidade de Nomenclatura**: Testa a capacidade defensiva do `fromJson` de decodificar tanto chaves no formato `camelCase` quanto no formato `snake_case`.
- **Resiliência a Valores Nulos**: Assegura que propriedades opcionais ausentes no JSON decodifiquem de forma segura sem lançar exceções.

---

## Como Executar

```bash
# Executar todos os testes desta pasta
flutter test test/data/

# Executar especificamente o teste de metadados
flutter test test/data/models/feedback_metadata_test.dart
```
