# Debugging Hot Reload

Este documento foi criado para ajudar você a entender como o mecanismo de hot reload do aplicativo funciona por trás dos panos, os pontos de falha mais comuns e como debugar problemas. Embora o hot reload tenha surgido originalmente como uma necessidade do Modo Experimental (para refletir na hora as alterações feitas no editor visual), a sua arquitetura atual não é exclusiva desse modo e atualiza ativamente o aplicativo inteiro sempre que novos pacotes são baixados.

## 🔄 Como o Hot Reload Funciona?

O fluxo que faz a tela atualizar magicamente quando você salva algo no editor funciona em três etapas principais:

1. **Sincronização / Re-fetch:**
   - Para **Croquis Baixados**: O arquivo `.binarypb` (e/ou as imagens associadas) do Pico é atualizado na pasta de `downloads/` do aparelho.
   - Para **Sessões Online (Streaming sob demanda)**: O aplicativo executa um re-fetch imediato com quebra de cache HTTP (`?t=timestamp`), desserializa a nova instância do `Croqui`, atualiza o `GerenciadorSessaoOnline` e armazena uma cópia no cache volátil (`/temp_cache/`).
2. **Notificação de Repositório:** O `DatasetRepository` escuta o `EditorDeCroqui`, o `SyncService` ou o polling de ETag de `ServicoCroquiOnline`. Ao detectar a nova versão, reindexa a tabela de dispersão $O(1)$ de mídias (`notificarAtualizacaoSessaoOnline`) e notifica o `ValueNotifier<TopoDataset?> activeDataset`.
3. **Atualização Seamless da UI:** Quase todas as telas filhas do app (`PicoDetailsPage`, `SetorPage`, `ViaPage`, etc.) estão embrulhadas no `PageListenableBuilder`. Como esse builder escuta o `activeDataset`, qualquer alteração no repositório **é o suficiente para engatilhar um hot reload**. O Flutter chama o método `build()` da tela atual novamente, injetando os novos objetos. **Isso acontece de forma completamente invisível e seamless para o usuário**: ele continua na mesma tela, na mesma posição de scroll, mas vendo os dados atualizados em tempo real.

### 4. Consistência de UX: Modo Experimental vs Modo Normal
- **No Modo Experimental**: O recarregamento é 100% automático e silencioso (sem popups ou mensagens bloqueantes), acionando uma animação sutil de pulso luminoso no `BannerModoExperimental`.
- **Fora do Modo Experimental (Produção)**: Quando uma atualização remota é detectada (ex: via polling periódico com ETag), a sessão online é atualizada e a interface exibe um aviso não intrusivo via `SnackBar` informando que o guia foi atualizado, em total simetria com a notificação já existente para croquis baixados.

---

## 🛠️ Pontos Comuns de Falha

Apesar da estrutura acima reconstruir a tela seamlessly, existem alguns obstáculos que impedem as atualizações visuais.

### 1. Cache no `initState` (Widgets Stateful)
Se um widget armazena variáveis dependentes do dataset (ex: uma lista de marcadores do mapa) dentro do método `initState`, ele **NÃO** vai atualizar sozinho.
- **Como resolvemos:** Implementamos o método `didUpdateWidget(oldWidget)` no componente (como fizemos em `MapaInterativoPage`). Esse método sempre roda quando a classe-pai é reconstruída com novos parâmetros, permitindo atualizar o estado interno (como os marcadores) com `setState` sem piscar a tela.

### 2. Invalidação Reativa do Cache de Imagens (`ImagemArquivoAresta` & SHA-256)
Quando você carrega uma imagem (`FileImage` padrão do Flutter), o framework armazena a textura em `PaintingBinding.instance.imageCache` indexando unicamente pelo caminho e escala do arquivo:
- Se o arquivo no disco for sobrescrito (seja no modo experimental via Hot Reload ou na sincronização de uma atualização de croqui), o caminho físico permanece inalterado (`/downloads/.../mapa.webp`).
- Com o `FileImage` comum, o Flutter detecta `widget.image == oldWidget.image` e nem sequer consulta o disco, reutilizando a textura antiga em memória.
- Além disso, objetos de modelo Protobuf como `Mapa`, `Pico` e `Setor` não possuem hash de arquivo embutido, fazendo com que comparações como `widget.mapa != oldWidget.mapa` avaliem falso quando apenas a imagem em disco muda.
- **Como resolvemos de forma reativa e autoritativa:**
  1. **`ImagemArquivoAresta`:** Substitui o `FileImage` em todo o aplicativo. Incorpora o `checksumSha256` na `ChaveImagemArquivoAresta`, garantindo que qualquer alteração de conteúdo altere a chave de cache e force o Flutter a decodificar o novo arquivo imediatamente sem piscar telas inalteradas.
  2. **Tabela de Dispersão $O(1)$ no `DatasetRepository`:** O repositório pré-indexa o hash de todas as mídias (`Croqui.arquivosExternos`) e miniaturas (`Indice.checksumSha256Thumbnail`), permitindo que `obterSha256DaMidia(picoId, caminho)` consulte o hash em tempo constante sem varreduras lineares.
  3. **Auto-resolução no `ProvedorImagemAresta`:** Se a UI não passar o hash explicitamente, o provedor consulta o repositório e aplica o hash tanto localmente (`ImagemArquivoAresta`) quanto remotamente para URLs de streaming (`NetworkImage(url?v=<sha256>)`).
  4. **Ciclo de vida sem `.evict()` manual:** Widgets de tela (`SetorPage`, `GrupoPage`, `MapaInterativoPage`, `MapaThumbnail`) re-executam a resolução do seu futuro de imagem diretamente em `didUpdateWidget` com `setState()`, sem gambiarras assíncronas de `provider.evict()`.

### 3. Alterações de Nome (Id Visual)
Como o app salva o estado de navegação baseado no nome das coisas (ex: você está na página do `Setor Principal`), se você alterar o **nome** desse setor no editor e o repositório atualizar, o `DatasetResolver` não vai conseguir achar o setor com o nome antigo na nova árvore de dados!
- **Sintoma:** Ao receber o hot reload, a tela pode ficar branca ou automaticamente voltar para a página anterior (o Pico).
- **Diagnóstico:** Isso é o comportamento correto (já que o "Setor Principal" tecnicamente deixou de existir para dar lugar ao "Novo Setor"), mas não se assuste se a tela "sumir" após você renomear a entidade principal em exibição.

---

## 🐞 Passo a Passo: Como Debugar um Hot Reload Falho?

Se você tentar fazer um hot reload e a tela não atualizar, siga este fluxo:

1. **Os arquivos chegaram no app?**
   > Verifique nos logs do terminal do celular/emulador se a sincronização salvou os novos binários e imagens na pasta de downloads.

2. **O Repositório notificou os ouvintes?**
   > Coloque um `debugPrint` no `ValueListenableBuilder` dentro de `PageListenableBuilder` (no arquivo `main.dart`). Se o log não aparecer, o `DatasetRepository` não atualizou o `activeDataset.value`.

3. **O Widget foi reconstruído (`didUpdateWidget`)?**
   > Se o `PageListenableBuilder` rodou, o problema está dentro do seu widget da tela. Se for um *StatefulWidget*, verifique se você não está retendo estados antigos apenas no `initState`. Certifique-se de que o `didUpdateWidget` está re-resolvendo futuros ou marcadores com `setState()`.

4. **A UI não mudou mesmo chamando o build?**
   > Se é uma **Imagem**: Verifique se o `checksumSha256` foi atualizado no Protobuf e pré-indexado no `DatasetRepository` para que o `ImagemArquivoAresta` / `NetworkImage` detecte a nova chave de cache.
   > Se é um **Texto/Layout**: Verifique se você não está passando parâmetros "mortos" (ex: variáveis que não vieram do widget construído diretamente).

