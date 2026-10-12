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

### `RepositorioCaderneta` e `RepositorioCadernetaLocal`
Interface abstrata e implementação concreta de repositório atômico:
- `salvarCadena(Cadena cadena)`: Insere uma nova cadena ou atualiza uma ascensão existente, salvando no storage persistente e emitindo atualização nos notifiers.
- `excluirCadena(String id)`: Exclui a cadena pelo ID e notifica os ouvintes.
- `obterCadenasPorEscalada(String escaladaUid)`: Retorna todas as tentativas e cadenas vinculadas a uma via específica, ordenadas cronologicamente da mais recente para a mais antiga.
- `obterMelhorAscensao(String escaladaUid)`: Identifica a melhor cadena alcançada pelo atleta para exibição em destaque no cabeçalho da via (priorizando: À Vista > Flash > Trabalhado > Tentativa).
- `obterEstatisticas()` / `calcularEstatisticas()`: Agrega e compila as métricas para a pirâmide e cartões do perfil.

### `EstatisticasCaderneta`
Classe de valor imutável que agrega métricas consolidadas:
- **Pirâmides de Graus**: Mapeia distribuições de vias (`piramideVias`) e boulders (`piramideBoulders`), agrupando por grau e contabilizando o total de ascensões e cadenas limpas.
- **Recordes Pessoais**: Identifica o maior grau de via e o maior grau de boulder encadenados.
- **Índices de Estilo**: Contabiliza totais por estilo esportivo (`aVista`, `flash`, `trabalhado`, `tentativas`) e taxa de cadenas à vista/flash (*onsight/flash rate*).

---

## 3. Testes e Qualidade

O módulo foi integralmente desenvolvido através de **TDD estrito (Red-Green-Refactor)**:
- Testes unitários do repositório: `test/services/caderneta/repositorio_caderneta_test.dart`
- Testes unitários do compilador estatístico: `test/services/caderneta/estatisticas_caderneta_test.dart`
- 100% de cobertura de código em língua portuguesa.
