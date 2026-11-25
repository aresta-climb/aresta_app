# Testes de Modelos de Dados (`test/data/`)

Este diretório contém os testes unitários dos modelos em `lib/data/modelos/`.

---

## Arquivos

```text
test/data/
└── modelos/
    ├── cadena_test.dart                  - Criação, limites de campos e JSON de Cadena
    ├── estatisticas_caderneta_test.dart  - Estrutura imutável de EstatisticasCaderneta
    ├── interacao_via_test.dart           - CategoriaAlertaSeguranca, AlertaSegurancaVia, ConsensoGrauVia e ComentarioComunidadeVia
    ├── item_fila_interacao_test.dart     - Serialização de ItemFilaInteracao, consolidação de fila/alertas e verificação do script SQL
    ├── metadados_feedback_test.dart      - Serialização JSON e campos de hash de FeedbackMetadata
    ├── perfil_escalador_test.dart        - NanoID 14c, sessão, fotoUrl, copyWith e JSON de PerfilEscalador
    ├── tipo_ascensao_test.dart           - Prioridade e regras de TipoAscensao
    └── tipo_escalada_test.dart           - Rótulos e códigos de TipoEscalada
```

---

## Cobertura Principal

- **`perfil_escalador_test.dart`**: Geração inicial de `autorIdPublico` (NanoID 14c), estado `estaAutenticado`, limpeza de sessão (`limparUserId: true`) e leitura/escrita JSON (`camelCase` e `snake_case`).
- **`cadena_test.dart` e `estatisticas_caderneta_test.dart`**: Validação de `tentativas >= 1`, limite de 200 caracteres em `notasPrivadas`, `grauSugerido` e agregados da pirâmide de graus.
- **`interacao_via_test.dart` e `item_fila_interacao_test.dart`**: Mapeamento das 4 categorias de alerta (`FAUNA`, `ROCHA_AGARRA_INSTAVEL`, `PROTECAO_PRECARIA`, `EXPOSICAO_E4_MAIS`), deduplicação de confirmações `+1` por `autorIdPublico`, consolidação de alertas contribuídos na Caderneta e verificação das regras em `supabase_contas_cadenas_interacoes.sql`.
- **`metadados_feedback_test.dart`**: Conversão `toJson`/`fromJson`, compatibilidade de chaves e campos opcionais nulos.

---

## Execução

```bash
flutter test test/data/
```
