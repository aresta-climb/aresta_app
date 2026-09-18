## Why

O Google Play Console sinalizou o aplicativo Aresta com status de otimização "Intermediários", apontando taxas de 65% de otimização, 66% de ofuscação e 66% de redução de bytecode, mantendo um tamanho de DEX descompactado de 6.25 MB.
A auditoria do console revelou que a diretiva de R8 "Classes de reempacotamento" está desativada no arquivo `proguard-rules.pro`. Além disso, a regra de preservação ampla para `kotlinx.coroutines.**` impede a eliminação de código morto no runtime do Kotlin, enquanto a ausência de `-allowaccessmodification` limita a capacidade do R8 de realizar inlining profundo e mesclagem de classes internas.

Esta mudança visa habilitar o reempacotamento de classes (`-repackageclasses`), ativar `-allowaccessmodification` e remover a regra redundante de corrotinas, elevando a taxa de otimização para o patamar "Avançado", encolhendo o arquivo DEX e fechando os 4 selos de otimização do R8 no Google Play Console com total segurança (rejeitando supressão de asserções nulas).

## What Changes

- **Habilitação de Reempacotamento de Classes (`-repackageclasses`)**:
  - Configura `-repackageclasses 'app.escalada.croquis.r8'` no `proguard-rules.pro` para achatar a estrutura de pacotes das classes ofuscadas em um namespace dedicado e seguro da aplicação, eliminando caminhos longos redundantes na tabela de strings do DEX.
- **Ativação de Modificação de Acesso (`-allowaccessmodification`)**:
  - Permite que o R8 amplie o escopo de visibilidade de classes e métodos privados para públicos durante a otimização de release, facilitando o inlining e a mesclagem de classes internas.
- **Poda de Membros Não Invocados de Kotlin Coroutines**:
  - Remove a regra genérica `-keepclassmembers class kotlinx.coroutines.** { *; }` do `proguard-rules.pro`, delegando a retenção de campos reflexivos (`Atomic*FieldUpdater`) às regras oficiais de consumidor (*consumer-rules.pro*) já embutidas no AAR do `kotlinx-coroutines-core`.
- **Preservação das Asserções de Segurança**:
  - Não utiliza `-assumenosideeffects` nem suprime asserções de integridade nula do Kotlin (`Intrinsics.checkNotNullParameter`), prevenindo vulnerabilidades e mantendo a resiliência defensiva em tempo de execução.

## Capabilities

### New Capabilities

*(Nenhuma nova capacidade introduzida)*

### Modified Capabilities

- `otimizacao-compilacao-build`: Atualiza os requisitos de otimização de compilação Android R8 para exigir o reempacotamento de classes (`-repackageclasses`), a permissão de modificação de acesso (`-allowaccessmodification`) e a delegação da otimização de Coroutines às consumer rules nativas.

## Impact

- **Configuração de ProGuard / R8 (`frontend/android/app/proguard-rules.pro`)**: Adição de `-allowaccessmodification` e `-repackageclasses`, além da remoção de `-keepclassmembers class kotlinx.coroutines.** { *; }`.
- **Tamanho do Artefato e Performance**: Redução estimada de 300 KB a 700 KB no arquivo `classes.dex`, achatamento da hierarquia de pacotes e aumento da taxa de ofuscação/redução no Google Play Console para o nível "Avançado".
