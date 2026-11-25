# Aresta Climb App

Aplicativo móvel da **ARESTA** para consulta offline e online de guias de escalada, registro de caderneta e alertas de segurança.

## Estrutura do Repositório

```text
aresta_app/
├── docs/              Especificações técnicas, scripts SQL e documentos de arquitetura
│   ├── arquitetura/   Modelagem de UIDs, Supabase, PowerSync, contas e documentos PDF
│   └── sistema_de_acesso.md
├── frontend/          Aplicativo Flutter (Android e iOS)
├── openspec/          Especificações e propostas de mudança (OpenSpec)
├── CONTRIBUTING.md    Guia de contribuição (DCO)
└── README.md
```

> O submódulo `aresta_api` (definições `.proto` e código Protobuf gerado) fica em `frontend/lib/aresta_api/`.

---

## Visão Geral

O Aresta Climb distribui croquis, betas, mapas de setores, coordenadas GPS e descrições de picos para uso sem conexão de rede em campo. O aplicativo também inclui perfil de escalador, caderneta de ascensões, votação de consenso de grau e alertas de risco nas vias, com sincronização em nuvem via Supabase.

Os dados dos guias usam arquivos `.binarypb` (Protocol Buffers) e imagens WebP, distribuídos pela CDN ou por sessão WebSocket do Editor Desktop.

## Arquitetura

O aplicativo segue o padrão **MVVM (Model-View-ViewModel)** e utiliza mensagens **Protobuf** (`Indice`, `ResumoCroqui`, `Croqui`) e modelos em `lib/data/modelos/` como camada de dados.

A sincronização de croquis executa cálculo de hashes SHA-256 e gravação em disco em `Isolate` separado (`SyncService` / `SyncIsolate`) para não bloquear o Isolate de interface. O download atualiza apenas os arquivos cujo hash mudou em relação à versão armazenada no aparelho.

O roteamento utiliza uma **Árvore de Navegação** (`NavNode` / `TreeNavigationController`) indexada por identificadores de texto. O `PageListenableBuilder` reconstrói as páginas quando o dataset em memória muda. Nos botões de retorno das páginas, um toque recua um nível na árvore (`AppNav.back`) e manter pressionado retorna à tela inicial (`AppNav.home`).

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`frontend/README.md`](frontend/README.md) | Funcionalidades, dependências, estrutura de pastas, execução e release |
| [`frontend/lib/README.md`](frontend/lib/README.md) | Arquitetura de `lib/`: serviços, páginas, navegação, `view`, `widgets` e `utils` |
| [`frontend/lib/view/README.md`](frontend/lib/view/README.md) | Camada de apresentação: `function_library` e `view_models` |
| [`frontend/lib/services/README.md`](frontend/lib/services/README.md) | Serviços de dados, autenticação Supabase, interações e Modo Experimental |
| [`frontend/lib/services/caderneta/README.md`](frontend/lib/services/caderneta/README.md) | Repositório da caderneta, estatísticas e sincronização de ascensões |
| [`frontend/lib/services/http/README.md`](frontend/lib/services/http/README.md) | Cliente HTTP, sincronização em duas fases e leitura sob demanda |
| [`frontend/lib/services/firebase/README.md`](frontend/lib/services/firebase/README.md) | Isolamento do SDK Firebase, telemetria e logs (Crashlytics e Sentry) |
| [`frontend/test/README.md`](frontend/test/README.md) | Estrutura da suíte de testes e comandos de execução |
| [`docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md`](docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md) | Especificação de NanoID 14c, Supabase, PowerSync, contas e licença ODbL |
| [`docs/arquitetura/sql/README.md`](docs/arquitetura/sql/README.md) | Scripts SQL e políticas RLS para `perfis`, `cadenas`, `fila_interacoes` e `avatars` |
| [`docs/arquitetura/pdfs/oficial/`](docs/arquitetura/pdfs/oficial/) | Documentos de arquitetura em PDF |
| [`docs/sistema_de_acesso.md`](docs/sistema_de_acesso.md) | Regras e fluxos de acesso a croquis |
| [`docs/guia_configuracao_observabilidade_e_alertas.md`](docs/guia_configuracao_observabilidade_e_alertas.md) | Configuração de Sentry, GitHub Issues, WAHA e Resend |

---

## Referências

- [Protocol Buffers — Especificando tipos](https://protobuf.dev/programming-guides/proto3/#specifying-types)
- [Protocol Buffers — Tipos escalares](https://protobuf.dev/programming-guides/proto3/#scalar)
- [flutter.dev — Instalação](https://flutter.dev/docs/get-started/install)

---

## Licença, Marca e Termos de Uso

### Código-Fonte
O código-fonte deste projeto é distribuído sob a licença **Mozilla Public License 2.0 (MPL 2.0)**. Consulte [LICENSE](LICENSE) para o texto integral.

### Marca e Identidade Visual
Os nomes **"Aresta"** e **"Aresta Climb"**, logotipos, ícones e elementos de marca pertencem aos mantenedores do projeto. A licença MPL 2.0 aplica-se somente ao código-fonte e não concede direito de uso das marcas ou logotipos em produtos derivados. Em forks ou distribuições independentes, altere o nome e os ativos visuais.

### Conteúdo dos Guias e Croquis
Os dados de escalada, croquis, betas, imagens e traçados distribuídos pelos servidores do projeto pertencem aos seus autores/conquistadores e à Aresta, protegidos pela legislação de direitos autorais. O acesso ao código-fonte não concede licença sobre a base de croquis.

---

## Apoio Open Source — Sentry

[![Monitorado com Sentry](https://img.shields.io/badge/Monitorado_com-Sentry-362D59?style=for-the-badge&logo=sentry&logoColor=white)](https://sentry.io/?utm_source=github&utm_medium=referral)

O projeto utiliza o **[Sentry](https://sentry.io/?utm_source=github&utm_medium=referral)** pelo programa para projetos Open Source (**Sponsored Business Plan**) para monitoramento de erros e releases no aplicativo móvel, no Editor Desktop e nos serviços de backend.

---

## Contribuindo

Adotamos o **Developer Certificate of Origin (DCO v1.1)**. Ao abrir um Pull Request, assine seus commits com `-s` (`Signed-off-by`) atestando o direito de licenciar o código sob MPL 2.0. Consulte [CONTRIBUTING.md](CONTRIBUTING.md).
