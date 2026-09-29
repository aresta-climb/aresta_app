# Camada de Modelos de Dados (`lib/data/`)

Este diretório contém os modelos de dados internos não derivados de mensagens Protobuf do ecossistema Aresta Climb.

A principal responsabilidade deste módulo é fornecer estruturas tipadas, seguras e com serialização direta (JSON) para funcionalidades complementares da aplicação, como a telemetria diagnóstica e relatórios de feedback.

---

## Estrutura de Diretórios

```text
lib/data/
└── models/
    └── metadados_feedback.dart    - Modelo de domínio dos metadados de diagnóstico de feedback
```

---

## 1. Modelos de Domínio (`models/`)

### `FeedbackMetadata` (`modelos/metadados_feedback.dart`)
Representa o pacote completo de informações contextuais do dispositivo capturadas no momento em que um usuário abre ou submete um reporte de in-app feedback:
- **Telemetria do Aparelho**: Modelo, versão do sistema operacional, orientação da tela, dimensões do viewport, conectividade ativa (Wi-Fi, móvel, offline) e tema visual (Claro/Escuro).
- **Contexto de Navegação**: Identificador único do reporte (`feedbackId`), UUID da instalação (`appInstanceId`), versão do app e caminho canônico completo da árvore de navegação ativa (`navigationTree`).
- **Auditoria Criptográfica de Hashes**:
  - `indiceSha256`: Hash SHA-256 do arquivo `indice.binarypb` local.
  - `croquiId`, `croquiSha256Esperado`, `croquiSha256Real`, `croquiStatus`: Status de integridade do croqui em visualização (`INTEGRO`, `DIVERGENTE`, `NAO_BAIXADO`).
  - `thumbnailSha256Esperado`, `thumbnailSha256Real`, `thumbnailStatus`: Status de integridade da miniatura do pico ativo.
- **Serialização Direta**: Possui construtor de fábrica `fromJson` e método `toJson` diretos na própria classe, eliminando a necessidade de DTOs intermediários (Princípio VI de Simplicidade e Anti-Abstração do `AGENTS.md`).
