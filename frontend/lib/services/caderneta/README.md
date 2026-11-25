# Serviço de Caderneta (`lib/services/caderneta/`)

Este diretório gerencia o armazenamento local, a sincronização remota e o cálculo de estatísticas da caderneta de ascensões e do perfil do escalador.

---

## 1. Funcionamento

- **Armazenamento Local Primário**: Ascensões (`Cadena`, identificadas por UUID v4 e vinculadas a `escaladaUid` NanoID 14c) e perfil (`PerfilEscalador`) são gravados localmente em `SharedPreferences` e expostos por `ValueListenable` (`cadenasNotifier` e `perfilNotifier`).
- **Sincronização com Supabase**:
  - Perfil e avatar sincronizam com `public.perfis` e com o bucket `avatars` via `ServicoAutenticacaoLocal`.
  - Ascensões e `notasPrivadas` sincronizam com `public.cadenas` via `ClienteCadenasSupabase` (`/rest/v1/cadenas?on_conflict=id`), mantendo conjuntos locais de upserts e exclusões pendentes quando sem rede e renovando o JWT em respostas `HTTP 401`.

---

## 2. Componentes

### `RepositorioCaderneta`, `RepositorioCadernetaLocal` e `ArmazenamentoLocalCaderneta`
- `ArmazenamentoLocalCaderneta`: Lê e grava as chaves JSON `aresta_cadenas_v1` e `aresta_perfil_escalador_v1` em `SharedPreferences`.
- `salvarCadena(Cadena)` / `excluirCadena(String id)`: Persiste alterações localmente, enfileira sincronização remota se autenticado e notifica ouvintes.
- `obterCadenasPorEscalada(String escaladaUid)`: Lista registros da via ordenados do mais recente ao mais antigo.
- `obterMelhorAscensao(String escaladaUid)`: Retorna o registro de maior prioridade (`À Vista > Flash > Trabalhado > Tentativa`).
- `obterEstatisticas()`: Retorna `EstatisticasCaderneta` compilada.

### `CompiladorEstatisticasCaderneta` (`compilador_estatisticas.dart`)
- Agrupa ascensões e tentativas em `piramideVias` e `piramideBoulders`.
- Quando o grau textual ainda não consta no catálogo carregado, utiliza o código numérico do enum Protobuf salvo em `Cadena.grauSugerido`.
- Calcula maior grau encadenado de via e de boulder e contagens por estilo (`aVista`, `flash`, `trabalhado`, `tentativas`).

### `CatalogoViasCaderneta` (`catalogo_vias_caderneta.dart`)
- Escuta `cadenasNotifier`, `RepositorioCatalogo.versaoNotificador` (`catalogo.db`) e `DatasetRepository.activeDataset`.
- Resolve nomes de vias (`obterNomeDaVia`), graus (`obterGrauDaVia`) e total de picos distintos (`obterTotalPicosDistintos`) consultando `catalogo.db` e os croquis em memória (`lib/utils/formatador_escalada.dart`).

---

## 3. Testes Relacionados

- `test/services/caderneta/armazenamento_local_caderneta_test.dart`
- `test/services/caderneta/repositorio_caderneta_test.dart`
- `test/services/caderneta/cliente_cadenas_supabase_test.dart`
- `test/services/caderneta/compilador_estatisticas_test.dart`
- `test/services/caderneta/catalogo_vias_caderneta_test.dart`
- `test/data/modelos/estatisticas_caderneta_test.dart`
