# Internacionalização Reativa (`lib/idioma/`)

Este módulo implementa o motor multilíngue nativo, síncrono (`O(1)`) e 100% offline do **Aresta Climb**, cobrindo toda a interface do aplicativo sem pacotes pesados de geração assíncrona nem impacto no orçamento de meio quadro (`< 4 ms`).

---

## Idiomas Suportados (`IdiomaApp`)

| Enum | Código ISO | Sigla na Bolha | Nome Autônimo | Região |
|---|---|---|---|---|
| `IdiomaApp.portugues` *(padrão)* | `pt_BR` | `PT` | Português | Brasil |
| `IdiomaApp.ingles` | `en_US` | `EN` | English | International |
| `IdiomaApp.espanhol` | `es_ES` | `ES` | Español | América Latina / España |
| `IdiomaApp.alemao` | `de_DE` | `DE` | Deutsch | Deutschland / Alpen |
| `IdiomaApp.holandes` | `nl_NL` | `NL` | Nederlands | Nederland / België |

---

## Arquitetura e Componentes

| Arquivo | Responsabilidade |
|---|---|
| `modelo_idioma_app.dart` | Define o enum `IdiomaApp` (metadados ISO, `Locale`, `localeFeedbackCompativel`, resolução `deCodigoIso` e rotação cíclica `proximoNaRotacao`) e o catálogo fortemente tipado `ChaveTexto`. |
| `controlador_idioma_app.dart` | `ControladorIdiomaApp` (gerenciador reativo com `ValueNotifier<IdiomaApp>` e persistência local em `SharedPreferences` sob a chave `'idioma_app_selecionado'`) e `EscopoIdiomaApp` (`InheritedNotifier` montado no topo de `ArestaApp` em `main.dart`). |
| `tradutor_app.dart` | Motor síncrono `TradutorApp` (`texto`, `dicionarioDe`, `formatarDataExtensoLegal`), atalho `tr(...)` para ViewModels/modelos sem `BuildContext` e extensão reativa `context.tr(...)` / `context.idiomaApp` para páginas e widgets. |
| `dicionario_pt.dart` | Dicionário completo em Português Brasileiro (`IdiomaApp.portugues`). |
| `dicionario_en.dart` | Dicionário completo em Inglês (`IdiomaApp.ingles`). |
| `dicionario_es.dart` | Dicionário completo em Espanhol (`IdiomaApp.espanhol`). |
| `dicionario_de.dart` | Dicionário completo em Alemão (`IdiomaApp.alemao`). |
| `dicionario_nl.dart` | Dicionário completo em Neerlandês / Holandês (`IdiomaApp.holandes`). |

---

## Pontos de Entrada na Interface

- **Bolha Rápida de Idioma (`BotaoBolhaIdioma` em `lib/widgets/idioma/botao_bolha_idioma.dart`)**:
  - Presente na seção de boas-vindas da `HomePage` (`Key('bolha_idioma_home')`) e na barra superior da página inicial do pico (`PicoDetailsPage`, `Key('bolha_idioma_pico')`).
  - **Toque simples**: abre o seletor flutuante animado (`exibirSeletorBolhasIdioma`) com os 5 idiomas.
  - **Toque longo**: rotaciona ciclicamente para o próximo idioma (`PT -> EN -> ES -> DE -> NL -> PT`).
- **Cartão em Configurações (`CartaoPreferenciaIdioma` em `lib/widgets/configuracoes/cartao_preferencia_idioma.dart`)**:
  - Permite alternar diretamente entre os 5 idiomas na `SettingsPage`.
