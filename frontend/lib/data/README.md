# Modelos de Dados (`lib/data/`)

Este diretório contém os modelos de domínio que não vêm dos arquivos Protobuf gerados em `lib/aresta_api/`. Não possui dependências de `services/`, `view/`, `widgets/` ou `pages/`.

---

## Estrutura

```text
lib/data/
└── modelos/
    ├── cadena.dart                  - Registro individual de ascensão ou tentativa
    ├── estatisticas_caderneta.dart  - Agregado de métricas e pirâmides de grau da caderneta
    ├── interacao_via.dart           - Modelos de alertas de segurança, consenso de grau e comentários
    ├── item_fila_interacao.dart     - Item da tabela `public.fila_interacoes` e funções de consolidação
    ├── metadados_feedback.dart      - Metadados de dispositivo, navegação e hashes para feedback
    ├── modelos_clima_pico.dart      - Eventos de chuva, cotas altimétricas DEM 30m, estado de umidade e snapshot consolidado
    ├── modelos_fenomenos_clima.dart - Isoietas de tempestades (4 níveis), rastros passados e perímetros orbitais de incêndios florestais (4 níveis)
    ├── modelos_rede_viaria_aresta.dart - Polígonos geográficos, localidades IBGE, rodovias, referências DEM e modelo imutável da rede viária Aresta
    ├── perfil_escalador.dart        - Dados do perfil, identificador público e tokens de sessão
    ├── tipo_ascensao.dart           - Enum de estilos (À Vista, Flash, Trabalhado, Tentativa)
    └── tipo_escalada.dart           - Enum de modalidades (Guiado, Top Rope, Boulder, Solo)
```

---

## Modelos

### `Cadena` (`modelos/cadena.dart`)
Registro de ascensão ou tentativa em uma via ou boulder:
- Chave primária UUID v4 (`id`) e referência à via por `escaladaUid` (NanoID 14c).
- Campos: `tipoAscensao`, `tipoEscalada`, `tentativas` ($\ge 1$), `dataAscensao`, `grauSugerido` (opcional) e `notasPrivadas` (até 200 caracteres).
- Métodos de serialização `toMap`/`fromMap` e `toJson`/`fromJson`.

### `PerfilEscalador` (`modelos/perfil_escalador.dart`)
Dados de identificação e sessão do usuário:
- `autorIdPublico`: NanoID de 14 caracteres mantido ao criar ou vincular conta.
- `autorNomePublico`: Nome exibido nas interações públicas, sincronizado com `public.perfis`.
- `userId`: UUID da conta no Supabase Auth (`auth.users`), quando autenticado.
- `fotoUrl`: URL no bucket `avatars` ou Data URI WebP em base64 (`data:image/webp;base64,...`).
- `accessToken` e `refreshToken`: Credenciais da sessão Supabase Auth.
- `estaAutenticado`: Retorna `true` quando `userId` não está vazio. `copyWith(limparUserId: true)` limpa `userId`, `accessToken` e `refreshToken` preservando `autorIdPublico`.

### `TipoAscensao` e `TipoEscalada` (`modelos/tipo_ascensao.dart`, `modelos/tipo_escalada.dart`)
- `TipoAscensao`: Indica se houve cadena (`isCadena`) e define a ordem de prioridade (`prioridadeVisual`: À Vista > Flash > Trabalhado > Tentativa).
- `TipoEscalada`: Rótulos em português e conversão para códigos persistidos.

### Comunidade e Segurança (`modelos/interacao_via.dart` e `modelos/item_fila_interacao.dart`)
- `CategoriaAlertaSeguranca`: Enum alinhado à constraint `chk_fila_categoria_alerta` do Supabase:
  - `fauna` (`FAUNA`, `🐝`, `"Fauna"`)
  - `rochaAgarraInstavel` (`ROCHA_AGARRA_INSTAVEL`, `🪨`, `"Rocha ou Agarra Instável"`)
  - `protecaoPrecaria` (`PROTECAO_PRECARIA`, `🔩`, `"Proteção Precária"`)
  - `exposicaoE4Mais` (`EXPOSICAO_E4_MAIS`, `⚠️`, `"Exposição E4+"`)
- `AlertaSegurancaVia`: Alerta identificado por NanoID 14c (`uid`), associado a `escaladaUid`, com detalhe opcional de até 100 caracteres, contagem `confirmacoesAtivas` e conjunto `confirmadoresUids` (máximo de 1 confirmação positiva por `autorIdPublico`).
- `AlertaContribuidoCaderneta` e `PapelContribuicaoAlerta`: Representam alertas criados (`CRIADO POR VOCÊ`) ou confirmados (`CONFIRMADO (+1)`) pelo usuário para listagem na `CadernetaPage`.
- `ConsensoGrauVia`: Agregado de votos de grau (`grauSugerido`, `totalVotos`, `distribuicaoDeltas` de `-2` a `+2` e `resumoTendencia`).
- `ComentarioComunidadeVia`: Comentário público de até 280 caracteres com `autorIdPublico`, `autorNomePublico` e `estiloAscensao` opcional.
- `DadosComunidadeVia`: Agrupa `consensoGrau`, `alertasAtivos` e `comentarios` de uma via.
- `ItemFilaInteracao`: Representa eventos de `public.fila_interacoes` (`VOTO_GRAU`, `COMENTARIO`, `ALERTA_SEGURANCA`, `CONFIRMACAO_ALERTA`) e expõe `consolidarItensFilaEmDadosComunidade` e `consolidarAlertasContribuidosPeloAutor`.

### `FeedbackMetadata` (`modelos/metadados_feedback.dart`)
Dados anexados a envios de feedback in-app:
- Modelo do aparelho, sistema operacional, dimensões de tela, conectividade e tema.
- `feedbackId`, `appInstanceId`, versão do app e caminho atual da árvore de navegação (`navigationTree`).
- Hashes SHA-256 e status (`INTEGRO`, `DIVERGENTE`, `NAO_BAIXADO`) de `indice.binarypb`, do croqui aberto e da miniatura.
