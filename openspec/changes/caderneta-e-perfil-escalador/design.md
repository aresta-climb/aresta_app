# Design: Caderneta Pessoal de Cadenas e Perfil do Escalador

## 1. Visão Geral e Princípios Arquiteturais

O design da Caderneta Pessoal e do Perfil do Escalador segue fielmente as diretrizes aprovadas na documentação oficial de arquitetura (`docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md`) e os princípios basilares do repositório (`AGENTS.md`):

1. **Adoção Direta do `escalada_uid` (NanoID 14c):** A caderneta associa cada realização esportiva diretamente ao identificador universal e imutável da via (`escalada_uid`), sem depender de chaves textuais voláteis ou de `croqui_uid`.
2. **Arquitetura Local-First Reativa:** A caderneta opera 100% offline através de um repositório reativo. A camada de apresentação (`ViewModels` e Widgets) consome interfaces agnósticas de persistência, facilitando a posterior transição transparente para o PowerSync SDK.
3. **Privacidade e Soberania dos Dados:** O campo `notasPrivadas` (até 200 caracteres) é estritamente pessoal e jamais trafega em feeds ou repositórios públicos.
4. **Simplicidade e Anti-Abstração (Regra VI):** Sem arquiteturas hexagonais excessivas ou camadas intermediárias dispensáveis. Modelos imutáveis com métodos diretos de cópia e serialização, e um serviço com responsabilidade única de persistência e estatísticas.
5. **Tudo em Português (Regra I) e TDD Rigoroso (Regra IV):** Nomenclatura 100% em português brasileiro em todas as classes, métodos, enums, variáveis e testes espelhados.

---

## 2. Modelagem de Dados

### 2.1. Entidade `Cadena`
Espelha o esquema da tabela física `public.cadenas`:

```dart
class Cadena {
  final String id; // UUID v4 único da cadena (16 bytes)
  final String escaladaUid; // NanoID 14c da via correspondente
  final DateTime dataAscensao; // Data da realização esportiva
  final TipoAscensao tipoAscensao; // Enum: aVista, flash, trabalhado, tentativa
  final TipoEscalada tipoEscalada; // Enum: guiado, topRope, boulder, solo
  final int tentativas; // Número de pegas (padrão 1)
  final int? grauSugerido; // Código numérico opcional de graduação
  final String notasPrivadas; // Notas técnicas pessoais (máx. 200 chars)
  final DateTime criadoEm; // Timestamp de criação
}
```

### 2.2. Enums de Domínio

#### `TipoAscensao`
* `aVista` (1): À Vista (primeira entrada sem qualquer informação prévia ou queda).
* `flash` (2): Flash (primeira entrada com informação/beta prévio, sem queda).
* `trabalhado` (3): Trabalhado / Redpoint (encadenada após tentativas prévias).
* `tentativa` (4): Tentativa / Pega (não encadenada).

Propriedades utilitárias:
* `String get rotulo`: Nome amigável em português.
* `bool get isCadena`: Retorna `true` se for `aVista`, `flash` ou `trabalhado`.
* `int get prioridadeVisual`: Define o peso de destaque (Flash = 3, À Vista = 2, Trabalhado = 1, Tentativa = 0).

#### `TipoEscalada`
* `guiado` (1): Guiado (proteção física colocada ou costurada pelo escalador).
* `topRope` (2): Top Rope (corda por cima).
* `boulder` (3): Boulder (escalada sem corda em blocos baixos).
* `solo` (4): Solo (escalada sem corda em falésia).

### 2.3. Entidade `PerfilEscalador`
```dart
class PerfilEscalador {
  final String autorIdPublico; // NanoID 14c Base62 público do atleta
  final String autorNomePublico; // Apelido público ou "Anônimo" (máx 50 chars)
  final String? userId; // UUID de autenticação se logado
}
```

---

## 3. Repositório e Motor de Estatísticas (`RepositorioCaderneta`)

O `RepositorioCaderneta` gerencia o ciclo de vida das ascensões:

```dart
abstract interface class RepositorioCaderneta {
  ValueListenable<List<Cadena>> get cadenasNotifier;

  Future<void> inicializar();
  Future<void> salvarCadena(Cadena cadena);
  Future<void> excluirCadena(String id);
  List<Cadena> obterCadenasPorEscalada(String escaladaUid);
  Cadena? obterMelhorAscensao(String escaladaUid);
  EstatisticasCaderneta calcularEstatisticas();
}
```

### Estrutura de `EstatisticasCaderneta`:
* `totalAscensoes`: Total absoluto de registros.
* `totalCadenas`: Contagem de registros com `isCadena == true`.
* `contagemPorEstilo`: Mapeamento `Map<TipoAscensao, int>`.
* `piramideVias`: Mapeamento de graduação numérica para contagem de cadenas (`Map<String, int>` ordenado por grau).
* `piramideBoulders`: Mapeamento de graduação de boulder para contagem de cadenas.
* `maiorGrauVia`: Maior grau encadenado em vias.
* `maiorGrauBoulder`: Maior grau encadenado em boulders.

---

## 4. Experiência de Consumo e Telas (UX/UI)

### 4.1. Indicador de Cadena e Ação na Tela da Via (`via.dart`)
* No topo da página da via (ao lado do grau oficial e das informações de costuras), se o atleta já possuir registros para o `escalada.uid`, renderiza um banner elegante no design Aresta:
  * *"✓ Encadenada em 14/09 (Flash)"*
* Botão de ação: **"Registrar Cadena / Tentativa"** que abre o `ModalRegistroCadena`.

### 4.2. Modal de Registro de Cadena (`ModalRegistroCadena`)
* Bottom sheet responsivo com tema dark nativo do Aresta:
  * Seletor de estilo em linha com chips visuais selecionáveis:
    `[ À Vista ]` `[ Flash ★ ]` `[ Trabalhado ]` `[ Tentativa ]`
  * Contador numérico para tentativas (`- [ 1 ] +`).
  * Botão de data (abre date picker nativo, iniciando na data atual).
  * Campo de texto com contador `0/200` para `notasPrivadas`.
  * Botão de confirmação: *"Salvar na Caderneta"*.

### 4.3. Tela de Perfil do Escalador (`PerfilPage`)
* **Cabeçalho:** Avatar estilizado com o logo Aresta, nome do atleta e chip com `autor_id_publico`.
* **Cards Resumo:** 
  * Cadenas Totais, Maior Grau, Vias à Vista / Flash.
* **Pirâmide de Graduação:** Gráfico de barras horizontais dividindo os graus encadenados (ex: 5º, 6º, 7a, 7b, 8a...) do menor para o maior, permitindo alternar entre "Vias" e "Boulders".
* **Histórico de Ascensões:** Lista cronológica reversa das cadenas com data, grau, estilo e notas privadas, permitindo exclusão com confirmação.
