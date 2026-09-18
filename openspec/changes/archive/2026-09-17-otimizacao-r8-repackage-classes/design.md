## Context

O aplicativo Aresta App utiliza compilação Android com R8 Full Mode (`android.enableR8.fullMode=true`), redução de recursos ativada (`isShrinkResources = true`) e símbolos nativos enviados via CI/CD.
Apesar das melhorias prévias que elevaram a otimização de 35% para 65%, o Google Play Console classifica o app como "Intermediários" devido a:
1. Ausência da flag de reempacotamento de classes (`-repackageclasses`), deixando uma das 4 recomendações do R8 desmarcada no painel da Play Store.
2. Manutenção de regras amplas com curinga `{ *; }` no `proguard-rules.pro` para `kotlinx.coroutines.**`, retendo desnecessariamente métodos não chamados no DEX.
3. Não autorização para ampliação de visibilidade (`-allowaccessmodification`), restringindo o *inlining* e o *class merging* pelo R8.

Ver detalhes de motivação em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Ativar o reempacotamento de classes no R8 através de `-repackageclasses 'app.escalada.croquis.r8'` para achatar o bytecode ofuscado e habilitar o 4º selo no Google Play Console.
- Permitir modificação de modificadores de acesso via `-allowaccessmodification` para maximizar inlining e fusão de classes internas no DEX.
- Eliminar a regra redundante `-keepclassmembers class kotlinx.coroutines.** { *; }`, delegando a retenção de reflexão de corrotinas às Consumer Rules oficiais do AAR.
- Reduzir o tamanho do DEX descompactado de 6.25 MB para abaixo de 6.0 MB e impulsionar a taxa de otimização/ofuscação para a faixa recomendada (> 75%).
- Validar a integridade da compilação de release e o funcionamento do app sem suprimir proteções de segurança em tempo de execução.

**Non-Goals:**
- Não utilizar diretivas de remoção de asserções nulas do Kotlin (`-assumenosideeffects` em `Intrinsics.checkNotNullParameter`), preservando a segurança defensiva contra inputs inválidos e corrupção de memória.
- Não alterar flags de compilação Dart AOT (`--obfuscate`, `--split-debug-info`), que já operam conforme a especificação.
- Não modificar configurações de build do iOS (`build_ios.yml` ou `Release.xcconfig`).

## Decisions

### Decisão 1: Namespace dedicado para reempacotamento (`app.escalada.croquis.r8`)

- **Abordagem**: Utilizar `-repackageclasses 'app.escalada.croquis.r8'` no `proguard-rules.pro`.
- **Por que?**: O R8 move todas as classes ofuscadas para este subpacote único. Isso achata a árvore de pacotes no arquivo DEX e reduz o tamanho da tabela de identificadores de strings. O uso de um subpacote nomeado evita colocar classes no pacote default/raiz (o que poderia violar convenções de ClassLoaders em ambientes Android restritivos ou gerar colisões com classes de terceiros sem namespace).
- **Alternativas descartadas**:
  - `-repackageclasses ''`: Mover para o pacote raiz absoluto pode causar colisões ou comportamentos imprevisíveis em ferramentas de análise estática.
  - Manter desativado: Deixava o 4º item do R8 desativado com pontuação intermediária no Play Console.

### Decisão 2: Remoção do keep manual de membros de Coroutines

- **Abordagem**: Excluir a linha `-keepclassmembers class kotlinx.coroutines.** { *; }`.
- **Por que?**: O artefato `kotlinx-coroutines-core` moderno já fornece seu próprio `consumer-rules.pro` embutido no arquivo `.aar`, mantendo exclusivamente os campos manipulados por `AtomicReferenceFieldUpdater` e `AtomicIntegerFieldUpdater`. A diretiva manual mantinha todos os métodos e campos de todas as classes de corrotina vivos no DEX.
- **Alternativas descartadas**:
  - Manter regras manuais detalhadas: Inútil e propenso a desatualização com novas versões do runtime Kotlin.

### Decisão 3: Habilitação de `-allowaccessmodification`

- **Abordagem**: Adicionar `-allowaccessmodification` ao bloco de otimizações do `proguard-rules.pro`.
- **Por que?**: O R8 opera com maior liberdade quando pode alterar métodos e campos privados/protegidos para públicos no bytecode final, viabilizando inlining de chamadas monomórficas e fusão de classes utilitárias que de outra forma ficariam isoladas.
- **Alternativas descartadas**:
  - Otimização conservadora padrão: Mantém classes e métodos pequenos em arquivos separados, inflando a contagem de métodos do DEX.

### Decisão 4: Rejeição da supressão de asserções (`-assumenosideeffects`)

- **Abordagem**: Não incluir regras que removam verificações de segurança do compilador Kotlin.
- **Por que?**: A integridade defensiva do código em produção é prioritária sobre micro-otimizações de bytecode. Remover validações de nulidade abre brechas para exceções silenciosas, vulnerabilidades em callbacks assíncronos e comportamento indefinido na camada JNI.

## Risks / Trade-offs

- **[Risco] Reempacotamento quebrar reflexão de classes internas de plugins**  
  *Mitigação*: O R8 **não** reempacota nenhuma classe que possua uma regra de `-keep` ativa (como Activities, Services, Receivers do AndroidManifest e classes de plugins Flutter protegidas pelas regras de consumidor). Apenas o código interno ofuscável é movido.
- **[Risco] Dificuldade em correlacionar stack traces ofuscados**  
  *Mitigação*: O pipeline de CI/CD já exporta e envia o `mapping.txt` para o Google Play Console e Firebase Crashlytics, permitindo desofuscação automática de pacotes reempacotados.
