# Módulo de Caderneta Pessoal e Estatísticas de Escalada

Este módulo implementa a gestão local-first da **Caderneta do Escalador** e do **Perfil do Atleta** no aplicativo Aresta Climb, em estrita conformidade com a especificação arquitetural `docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md` e os princípios de engenharia definidos no `AGENTS.md`.

---

## 1. Visão Geral e Princípios Arquiteturais

A caderneta do escalador é concebida com arquitetura **offline-first reativa**:
- **Privacidade por Padrão**: As anotações do atleta (`notasPrivadas`) e o histórico individual de cadenas residem primariamente no armazenamento local do dispositivo.
- **Identificadores Descentralizados**:
  - Cada ascensão (`Cadena`) possui chave primária UUID v4 (`id`) e faz referência à via escalada via `escaladaUid` (NanoID 14c em formato Base62).
  - O perfil do atleta (`PerfilEscalador`) possui um `autorIdPublico` (NanoID 14c) único e legível para compartilhamento seguro e futuras funcionalidades comunitárias (ex.: beta de vias, croquis colaborativos).
- **Reatividade com `ValueListenable`**:
  O repositório expõe listeners reativos (`cadenasNotifier` e `perfilNotifier`) permitindo que a interface do usuário (ex.: `PerfilPage`, `ViaPage`) reaja imediatamente a inserções, edições e exclusões sem requisições síncronas de rede.
- **Preparação para Sincronização PowerSync**:
  O esquema de dados em memória e em cache persistente reflete a estrutura relacional mapeada para futuras tabelas SQLite locais (`cadenas`, `perfis`) integradas com o PowerSync.

---

## 2. Componentes Principais

### `RepositorioCaderneta`, `RepositorioCadernetaLocal` e `ArmazenamentoLocalCaderneta`
Interface abstrata, implementação concreta de repositório reativo e adaptador modular de persistência local:
- `ArmazenamentoLocalCaderneta` (`armazenamento_local_caderneta.dart`): Isola a serialização JSON, as chaves `aresta_cadenas_v1` / `aresta_perfil_escalador_v1` em `SharedPreferences` e a recuperação resiliente contra payloads corrompidos (`carregarOuCriarPerfil`, `carregarCadenas`, `salvarCadenas`, `salvarPerfil`), mantendo `RepositorioCadernetaLocal` dedicado exclusivamente ao estado reativo em memória e às consultas de domínio.
- `salvarCadena(Cadena cadena)`: Insere uma nova cadena ou atualiza uma ascensão existente, salvando no storage persistente e emitindo atualização nos notifiers.
- `excluirCadena(String id)`: Exclui a cadena pelo ID e notifica os ouvintes.
- `obterCadenasPorEscalada(String escaladaUid)`: Retorna todas as tentativas e cadenas vinculadas a uma via específica, ordenadas cronologicamente da mais recente para a mais antiga.
- `obterMelhorAscensao(String escaladaUid)`: Identifica a melhor cadena alcançada pelo atleta para exibição em destaque no cabeçalho da via (priorizando: À Vista > Flash > Trabalhado > Tentativa).
- `obterEstatisticas()` / `calcularEstatisticas()`: Agrega e compila as métricas para a pirâmide e cartões do perfil.

### `EstatisticasCaderneta` e `CompiladorEstatisticasCaderneta`
Classe de valor imutável e compilador puro que agregam métricas consolidadas:
- **Pirâmides de Graus**: Mapeia distribuições de vias (`piramideVias`) e boulders (`piramideBoulders`), agrupando por grau canônico e contabilizando o total de ascensões e cadenas limpas.
- **Fallback Oficial por `grauSugerido`**: Quando o metadado textual da via ainda não estiver disponível no catálogo local, `CompiladorEstatisticasCaderneta` decodifica automaticamente o código numérico oficial do enum Protobuf persistido em `Cadena.grauSugerido` (`GrauVia_GrauVia` com `.value >= 2` ou `GrauBoulder_GrauBoulder` com `.value >= 1`), garantindo que a pirâmide esportiva e o recorde pessoal reflitam ascensões registradas imediatamente.
- **Recordes Pessoais**: Identifica o maior grau de via e o maior grau de boulder encadenados.
- **Índices de Estilo**: Contabiliza totais por estilo esportivo (`aVista`, `flash`, `trabalhado`, `tentativas`) e taxa de cadenas à vista/flash (*onsight/flash rate*).

### `ResolvedorMetadadosCaderneta` e `formatador_escalada.dart`
Ponte reativa (`ChangeNotifier`) entre a `RepositorioCaderneta` e o catálogo local de escaladas:
- **Hidratação via SQLite + Fallback em Memória**: Escuta simultaneamente `cadenasNotifier`, `RepositorioCatalogo.versaoNotificador` (`catalogo.db`) e `DatasetRepository.activeDataset`. Resolve de forma assíncrona os nomes de vias (`obterNomeDaVia`), graduações normalizadas (`obterGrauDaVia`) e a contagem real de picos/croquis distintos (`obterTotalPicosDistintos`), utilizando os `Croqui` carregados em memória (`gerenciadorSessaoOnline` e `activeDataset`) como fallback síncrono imediato.
- **Utilitários Puros de Domínio (`lib/utils/formatador_escalada.dart`)**: Concentra as funções puras `obterNomeEscalada`, `formatarTextoGrau`, `obterTextoGrauEscalada`, `obterCodigoGrauOficial`, `normalizarGrauEscalada` e `iterarEscaladasDoCroqui`, sem qualquer dependência reversa de `lib/services/` para `lib/view/`.
- **Clean Architecture, MVVM (Dumb UI) e Componentes Modulares**:
  - `HubPerfilCadernetaViewModel.comCatalogo`, `PerfilViewModel.comCatalogo` e `SecaoCadernetaViaViewModel` encapsulam integralmente os repositórios e resolvedores.
  - `lib/widgets/caderneta/controles_formulario_cadena.dart` fornece controles Dumb UI reutilizáveis (`SeletorEstiloAscensao`, `ContadorTentativasAscensao`, `SeletorDataAscensao`, `CampoNotasPrivadasAscensao`) compostos por `ModalRegistroCadena`.
  - `lib/widgets/perfil/dialogos_hub_perfil.dart` isola os fluxos modais e diálogos do Hub (`DialogoEditarPerfil`, `ModalDadosPrivacidade`, `DialogoConfirmarSaida`) com descarte seguro de `TextEditingController`.
  - `lib/widgets/configuracoes/cartao_preferencia_caderneta.dart` encapsula o cartão declarativo `CartaoPreferenciaCaderneta` consumido pela `SettingsPage`.

---

## 3. Testes e Qualidade

O módulo foi integralmente desenvolvido através de **TDD estrito (Red-Green-Refactor)**, **Espelhamento 1:1** e **Anti-Mocking** (utilizando instâncias reais de Protobufs e SQLite FFI real):
- Testes unitários do adaptador de persistência: `test/services/caderneta/armazenamento_local_caderneta_test.dart`
- Testes unitários do repositório: `test/services/caderneta/repositorio_caderneta_test.dart`
- Testes unitários da entidade estatística: `test/services/caderneta/estatisticas_caderneta_test.dart`
- Testes unitários do compilador estatístico e fallback `grauSugerido`: `test/services/caderneta/compilador_estatisticas_test.dart`
- Testes de integração com `catalogo.db` real e croquis em memória: `test/services/caderneta/resolvedor_metadados_caderneta_test.dart`
- Testes unitários de formatação e domínio de escaladas: `test/utils/formatador_escalada_test.dart`
- Testes de widgets modulares: `test/widgets/caderneta/controles_formulario_cadena_test.dart`, `test/widgets/perfil/dialogos_hub_perfil_test.dart` e `test/widgets/configuracoes/cartao_preferencia_caderneta_test.dart`
- 100% de cobertura comportamental em língua portuguesa.
