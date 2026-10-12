# Camada de Modelos de Dados (`lib/data/`)

Este diretório contém os modelos de dados internos não derivados de mensagens Protobuf do ecossistema Aresta Climb.

A principal responsabilidade deste módulo é fornecer estruturas tipadas, seguras e com serialização direta (JSON) para funcionalidades complementares da aplicação, como a telemetria diagnóstica e relatórios de feedback.

---

## Estrutura de Diretórios

```text
lib/data/
└── modelos/
    ├── metadados_feedback.dart    - Modelo de domínio dos metadados de diagnóstico de feedback
    ├── tipo_ascensao.dart         - Enum esportivo de tipos de ascensão (À Vista, Flash, Trabalhado, Tentativa)
    ├── tipo_escalada.dart         - Enum de modalidades (Guiado, Top Rope, Boulder, Solo)
    ├── cadena.dart                - Entidade imutável de registro de ascensão na caderneta
    └── perfil_escalador.dart      - Entidade do perfil e identificador público do atleta
```

---

## 1. Modelos de Domínio (`modelos/`)

### `Cadena` (`modelos/cadena.dart`)
Representa o registro individual de ascensão de uma via ou boulder:
- Identificador primário UUID v4 (`id`) e vínculo com a via via `escaladaUid` (NanoID 14c Base62).
- Contém estilo esportivo (`tipoAscensao`), modalidade (`tipoEscalada`), quantidade de tentativas (`tentativas`, >= 1), data de realização (`data`) e notas íntimas com limite rígido de 200 caracteres (`notasPrivadas`).
- Suporta serialização `toMap`/`fromMap` e `toJson`/`fromJson`.

### `PerfilEscalador` (`modelos/perfil_escalador.dart`)
Representa a identidade esportiva pública do usuário:
- `autorIdPublico`: NanoID de 14 caracteres criptograficamente gerado, estável e compartilhável.
- `autorNomePublico`: Nome ou apelido esportivo exibido nas telas e no ranking/estatísticas.
- `userId`: Opcional, reservado para pareamento com contas de autenticação do backend.

### `TipoAscensao` e `TipoEscalada` (`modelos/tipo_ascensao.dart`, `modelos/tipo_escalada.dart`)
Enums com rotulagem amigável em português e métodos utilitários:
- `TipoAscensao`: define se a ascensão foi encadenada com sucesso (`isCadena`) e estabelece a prioridade esportiva visual (`prioridadeVisual`) para eleger o selo de melhor cadena alcançada em uma via.

### `FeedbackMetadata` (`modelos/metadados_feedback.dart`)
Representa o pacote completo de informações contextuais do dispositivo capturadas no momento em que um usuário abre ou submete um reporte de in-app feedback:
- **Telemetria do Aparelho**: Modelo, versão do sistema operacional, orientação da tela, dimensões do viewport, conectividade ativa (Wi-Fi, móvel, offline) e tema visual (Claro/Escuro).
- **Contexto de Navegação**: Identificador único do reporte (`feedbackId`), UUID da instalação (`appInstanceId`), versão do app e caminho canônico completo da árvore de navegação ativa (`navigationTree`).
- **Auditoria Criptográfica de Hashes**:
  - `indiceSha256`: Hash SHA-256 do arquivo `indice.binarypb` local.
  - `croquiId`, `croquiSha256Esperado`, `croquiSha256Real`, `croquiStatus`: Status de integridade do croqui em visualização (`INTEGRO`, `DIVERGENTE`, `NAO_BAIXADO`).
  - `thumbnailSha256Esperado`, `thumbnailSha256Real`, `thumbnailStatus`: Status de integridade da miniatura do pico ativo.
- **Serialização Direta**: Possui construtor de fábrica `fromJson` e método `toJson` diretos na própria classe, eliminando a necessidade de DTOs intermediários (Princípio de Simplicidade e Anti-Abstração).
