# Módulo de Caderneta Pessoal e Estatísticas de Escalada

Este módulo implementa a gestão local-first da **Caderneta do Escalador** e do **Perfil do Atleta** no aplicativo Aresta Climb, em conformidade com a especificação arquitetural `docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md`.

---

## 1. Visão Geral e Princípios Arquiteturais

A caderneta do escalador é concebida com arquitetura **offline-first reativa**:
- **Privacidade por Padrão**: As anotações do atleta (`notasPrivadas`) e o histórico individual de cadenas residem primariamente no armazenamento local do dispositivo.
- **Identificadores Descentralizados e Vínculo com Supabase**:
  - Cada ascensão (`Cadena`) possui chave primária UUID v4 (`id`) e faz referência à via escalada via `escaladaUid` (NanoID 14c em formato Base62).
  - O perfil do atleta (`PerfilEscalador`) possui um `autorIdPublico` (NanoID 14c) único e legível para compartilhamento seguro e contribuições comunitárias, além de `fotoUrl`, `userId` e `accessToken` quando autenticado no Supabase.
- **Reatividade com `ValueListenable`**:
  O repositório expõe listeners reativos (`cadenasNotifier` e `perfilNotifier`) permitindo que a interface do usuário (ex.: `HubPerfilCadernetaPage`, `CadernetaPage`, `ViaPage`) reaja imediatamente a inserções, edições, mudanças de foto e exclusões sem requisições síncronas bloqueantes.
- **Sincronização de Perfil e Preparação para PowerSync**:
  - O nome esportivo (`autorNomePublico`), o identificador público (`autorIdPublico`) e a foto (`fotoUrl`) são sincronizados com o Supabase Auth, o bucket `avatars` no Supabase Storage e a tabela `public.perfis` por meio de `ServicoAutenticacaoLocal` e `ClienteSupabaseAutenticacao`.
  - O esquema de dados em memória e em cache persistente reflete a estrutura relacional mapeada para as tabelas (`cadenas`, `perfis`) integradas com o PowerSync.

---

## 2. Componentes Principais

### `RepositorioCaderneta`, `RepositorioCadernetaLocal` e `ArmazenamentoLocalCaderneta`
Interface abstrata, implementação concreta de repositório reativo e adaptador modular de persistência local:
- `ArmazenamentoLocalCaderneta` (`armazenamento_local_caderneta.dart`): Isola a serialização JSON, as chaves `aresta_cadenas_v1` / `aresta_perfil_escalador_v1` em `SharedPreferences` e a recuperação resiliente contra payloads corrompidos (`carregarOuCriarPerfil`, `carregarCadenas`, `salvarCadenas`, `salvarPerfil`), mantendo `RepositorioCadernetaLocal` dedicado ao estado reativo em memória e às consultas de domínio.
- `salvarCadena(Cadena cadena)`: Insere uma nova cadena ou atualiza uma ascensão existente, salvando no storage persistente e emitindo atualização nos notifiers.
- `excluirCadena(String id)`: Exclui a cadena pelo ID e notifica os ouvintes.
- `obterCadenasPorEscalada(String escaladaUid)`: Retorna todas as tentativas e cadenas vinculadas a uma via específica, ordenadas cronologicamente da mais recente para a mais antiga.
- `obterMelhorAscensao(String escaladaUid)`: Identifica a melhor cadena alcançada pelo atleta para exibição em destaque no cabeçalho da via (priorizando: À Vista > Flash > Trabalhado > Tentativa).
- `obterEstatisticas()` / `calcularEstatisticas()`: Agrega e compila as métricas para a pirâmide e cartões do perfil.

### `EstatisticasCaderneta` e `CompiladorEstatisticasCaderneta`
Classe de valor imutável e compilador que agregam métricas consolidadas:
- **Pirâmides de Graus**: Mapeia distribuições de vias (`piramideVias`) e boulders (`piramideBoulders`), agrupando por grau canônico e contabilizando o total de ascensões e cadenas limpas.
- **Fallback Oficial por `grauSugerido`**: Quando o metadado textual da via ainda não estiver disponível no catálogo local, `CompiladorEstatisticasCaderneta` decodifica automaticamente o código numérico oficial do enum Protobuf persistido em `Cadena.grauSugerido` (`GrauVia_GrauVia` com `.value >= 2` ou `GrauBoulder_GrauBoulder` com `.value >= 1`), garantindo que a pirâmide esportiva e o recorde pessoal reflitam ascensões registradas imediatamente.
- **Recordes Pessoais**: Identifica o maior grau de via e o maior grau de boulder encadenados.
- **Índices de Estilo**: Contabiliza totais por estilo esportivo (`aVista`, `flash`, `trabalhado`, `tentativas`) e taxa de cadenas à vista/flash (*onsight/flash rate*).

### `CatalogoViasCaderneta` e `formatador_escalada.dart`
Ponte reativa (`ChangeNotifier`) entre a `RepositorioCaderneta` e o catálogo local de escaladas:
- **Hidratação via SQLite + Fallback em Memória**: Escuta simultaneamente `cadenasNotifier`, `RepositorioCatalogo.versaoNotificador` (`catalogo.db`) e `DatasetRepository.activeDataset`. Busca de forma assíncrona os nomes de vias (`obterNomeDaVia`), graduações normalizadas (`obterGrauDaVia`) e a contagem real de picos/croquis distintos (`obterTotalPicosDistintos`), utilizando os `Croqui` carregados em memória (`gerenciadorSessaoOnline` e `activeDataset`) como fallback síncrono imediato.
- **Utilitários de Domínio (`lib/utils/formatador_escalada.dart`)**: Concentra as funções `obterNomeEscalada`, `formatarTextoGrau`, `obterTextoGrauEscalada`, `obterCodigoGrauOficial`, `normalizarGrauEscalada`, `iterarEscaladasDoCroqui`, a classe `LocalizacaoEscaladaCroqui` e `localizarEscaladaPorUidEmCroquis` (compartilhada entre `CatalogoViasCaderneta` e `AppNav.toViaPorUid`), sem qualquer dependência reversa de `lib/services/` para `lib/view/`.
- **Integração MVVM e Componentes Modulares**:
  - `HubPerfilCadernetaViewModel.comCatalogo`, `PerfilViewModel.comCatalogo`, `RegistroCadenaViewModel.paraEdicao` e `SecaoCadernetaViaViewModel` encapsulam os repositórios, a sincronização remota do perfil via `ServicoAutenticacao`, a seleção nativa de foto via `SeletorFotoPerfil`, a formatação de strings de apresentação (`formatarSubtituloAscensao`, `formatarCitacaoNotas`, `tituloSecaoHistorico`) e as consultas ao catálogo.
  - `PainelResumoEstatisticasCaderneta` (`lib/widgets/caderneta/card_estatistica.dart`) compõe em grade 2×2 os 4 cartões de resumo estatístico (`CardEstatistica`).
  - `SecaoHistoricoCadenas`, `EstadoVazioHistoricoCaderneta`, `ItemHistoricoCadena` e `DialogoConfirmarExclusaoCadena` (`lib/view/function_library/funcoes_caderneta.dart`) são `StatelessWidget`s modulares consumidos por `CadernetaPage`.
  - `lib/widgets/caderneta/controles_formulario_cadena.dart` fornece controles reutilizáveis (`SeletorEstiloAscensao`, `ContadorTentativasAscensao`, `SeletorDataAscensao`, `CampoNotasPrivadasAscensao`) compostos por `ModalRegistroCadena`.
  - `lib/widgets/perfil/dialogos_hub_perfil.dart` isola os fluxos modais e diálogos do Hub (`DialogoEditarPerfil` com prévia e alteração de foto de perfil, `ModalDadosPrivacidade`, `DialogoConfirmarSaida`) com descarte seguro de `TextEditingController`.
  - `lib/widgets/configuracoes/cartao_preferencia_caderneta.dart` encapsula o cartão declarativo `CartaoPreferenciaCaderneta` consumido pela `SettingsPage`.

---

## 3. Testes Automatizados

O módulo conta com cobertura completa de testes unitários e de widget (utilizando instâncias reais de Protobufs e SQLite FFI):
- Testes unitários do adaptador de persistência: `test/services/caderneta/armazenamento_local_caderneta_test.dart`
- Testes unitários do repositório: `test/services/caderneta/repositorio_caderneta_test.dart`
- Testes unitários da entidade estatística: `test/services/caderneta/estatisticas_caderneta_test.dart`
- Testes unitários do compilador estatístico e fallback `grauSugerido`: `test/services/caderneta/compilador_estatisticas_test.dart`
- Testes de integração com `catalogo.db` e croquis em memória: `test/services/caderneta/catalogo_vias_caderneta_test.dart`
- Testes unitários de autenticação e sincronização Supabase: `test/services/autenticacao/servico_autenticacao_test.dart` e `test/services/autenticacao/cliente_supabase_autenticacao_test.dart`
- Testes unitários do seletor nativo de foto de perfil: `test/services/midia/seletor_foto_perfil_test.dart`
- Testes unitários de formatação e domínio de escaladas: `test/utils/formatador_escalada_test.dart`
- Testes de widgets modulares: `test/widgets/caderneta/card_estatistica_test.dart`, `test/widgets/caderneta/controles_formulario_cadena_test.dart`, `test/view/function_library/funcoes_caderneta_test.dart`, `test/pages/caderneta_test.dart`, `test/widgets/perfil/dialogos_hub_perfil_test.dart` e `test/widgets/configuracoes/cartao_preferencia_caderneta_test.dart`
