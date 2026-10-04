# Módulo de Páginas — Aresta Climb

Este diretório contém as telas e páginas principais de interação do usuário no aplicativo Aresta Climb, seguindo os princípios de **Componentes Independentes**, **100% de Cobertura de Testes**, **TDD** e **Tudo em Português**.

---

## 1. Visão Geral das Páginas Principais

| Página | Arquivo | Responsabilidade |
|---|---|---|
| `PicoDetailsPage` | `pico.dart` | Hub principal de detalhes de um pico (guia), exibindo banner de status (online/offline), ações rápidas, visualização de setores e acesso ao catálogo. |
| `SetoresPage` | `pico_subpages/setores_page.dart` | Tela unificada de exploração de setores e escaladas com abas por modalidade, filtros reativos e ordenações contextuais. |
| `ExplorarLocalPage` | `pico_subpages/explorar_local_page.dart` | Informações práticas de acesso, melhor época para escalar e croquis gerais de aproximação. |
| `ComunidadePicoPage` | `pico_subpages/comunidade_pico_page.dart` | Guia de contatos locais, grupos e canais comunitários de escalada. |
| `ApoiePicoPage` | `pico_subpages/apoie_pico_page.dart` | Chaves PIX e informações para suporte financeiro e manutenção de vias e trilhas. |
| `TermosDeUsoPage` | `termos_de_uso.dart` | Apresentação e aceite formal dos termos legais de uso do aplicativo. |
| `DatabaseMigrationScreen` | `tela_migracao_banco.dart` | Tela de bloqueio e progresso exibida durante migrações estruturais do banco de dados local. |

---

## 2. Ciclo de Vida e Gestão de Recursos no Hub do Pico (`PicoDetailsPage`)

A tela de detalhes do pico gerencia conexões e dados online/offline através do seu `PicoViewModel`. Para garantir alta performance e evitar vazamentos de memória e de requisições de rede:

### Injeção de Singleton Gerenciado
- O `PicoViewModel` recebe por injeção de dependência a instância singleton do `ServicoCroquiOnline` gerenciada por `DatasetRepository.servicoCroquiOnline`.
- Isso evita a instanciação acidental de múltiplos serviços isolados e garante que o estado do polling seja centralizado.

### Ciclo de Vida Determinístico no `_PicoDetailsPageState`
- **`initState`**: Inicializa o `_viewModel`, registra o ouvinte para sincronizar a UI e inicia o polling de ETag (caso o pico não esteja baixado offline).
- **`didUpdateWidget`**: Quando a rota é atualizada pelo `PageListenableBuilder` (por exemplo, ao mudar o dataset ativo ou receber eventos de navegação), o estado descarta o `_viewModel` anterior deterministamente:
  1. Remove o listener do ViewModel antigo.
  2. Cancela qualquer polling de ETag em andamento no serviço.
  3. Invoca `_viewModel.dispose()`.
  4. Atribui a nova instância do ViewModel vinda de `widget.viewModel` e anexa o novo listener.
- **`dispose`**: Cancela o polling de ETag e remove ouvintes antes de desmontar o componente.

Essa disciplina de ciclo de vida impede a proliferação de timers fantasmas (*orphan polling timers*) que anteriormente multiplicavam requisições desnecessárias contra a infraestrutura de relay.
