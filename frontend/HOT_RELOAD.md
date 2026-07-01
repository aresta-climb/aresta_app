# Debugging Hot Reload

Este documento foi criado para ajudar você a entender como o mecanismo de hot reload do aplicativo funciona por trás dos panos, os pontos de falha mais comuns e como debugar problemas. Embora o hot reload tenha surgido originalmente como uma necessidade do Modo Experimental (para refletir na hora as alterações feitas no editor visual), a sua arquitetura atual não é exclusiva desse modo e atualiza ativamente o aplicativo inteiro sempre que novos pacotes são baixados.

## 🔄 Como o Hot Reload Funciona?

O fluxo que faz a tela atualizar magicamente quando você salva algo no editor funciona em três etapas principais:

1. **Sincronização:** O arquivo `.binarypb` (e/ou as imagens associadas) do Pico é atualizado na pasta de `downloads/` do aparelho.
2. **Notificação de Repositório:** O `DatasetRepository` escuta o `EditorDeCroqui` ou o serviço de sincronização. Quando um pacote novo chega, o repositório processa o novo arquivo binário e atualiza o `ValueNotifier<TopoDataset?> activeDataset`.
3. **Atualização Seamless da UI:** Quase todas as telas filhas do app (`PicoDetailsPage`, `SetorPage`, `ViaPage`, etc.) estão embrulhadas no `PageListenableBuilder`. Como esse builder escuta o `activeDataset`, qualquer alteração no repositório **é o suficiente para engatilhar um hot reload**. O Flutter chama o método `build()` da tela atual novamente, injetando os novos objetos. **Isso acontece de forma completamente invisível e seamless para o usuário**: ele continua na mesma tela, na mesma posição de scroll, mas vendo os dados atualizados em tempo real.

---

## 🛠️ Pontos Comuns de Falha

Apesar da estrutura acima reconstruir a tela seamlessly, existem alguns obstáculos que impedem as atualizações visuais.

### 1. Cache no `initState` (Widgets Stateful)
Se um widget armazena variáveis dependentes do dataset (ex: uma lista de marcadores do mapa) dentro do método `initState`, ele **NÃO** vai atualizar sozinho.
- **Como resolvemos:** Implementamos o método `didUpdateWidget(oldWidget)` no componente (como fizemos em `MapaInterativoPage`). Esse método sempre roda quando a classe-pai é reconstruída com novos parâmetros, permitindo atualizar o estado interno (como os marcadores) com `setState` sem piscar a tela.

### 2. Cache de Imagens do Flutter (`ImageCache`)
Quando você carrega uma imagem (`FileImage` ou `NetworkImage`), o Flutter a armazena no cache nativo (`PaintingBinding.instance.imageCache`) para otimizar desempenho.
- Se o arquivo na mesma pasta for sobrescrito (seja no modo experimental, ou quando o usuário faz o download de uma atualização de um pico na versão oficial), o caminho da imagem continua o mesmo (`/downloads/.../capa.webp`).
- Como o caminho não mudou, o Flutter usa a **imagem antiga do cache** e não lê o arquivo recém-baixado/atualizado.
- **Como resolvemos:** Identificamos os lugares onde imagens são carregadas (`OfflineMarkdown`, `MapaThumbnail`, etc.) e forçamos o `ImageProvider.evict()` dentro do `didUpdateWidget` se o widget receber novos dados. Isso limpa o cache e força a releitura do arquivo, garantindo que o app sempre exiba a imagem mais recente.

### 3. Alterações de Nome (Id Visual)
Como o app salva o estado de navegação baseado no nome das coisas (ex: você está na página do `Setor Principal`), se você alterar o **nome** desse setor no editor e o repositório atualizar, o `DatasetResolver` não vai conseguir achar o setor com o nome antigo na nova árvore de dados!
- **Sintoma:** Ao receber o hot reload, a tela pode ficar branca ou automaticamente voltar para a página anterior (o Pico).
- **Diagnóstico:** Isso é o comportamento correto (já que o "Setor Principal" tecnicamente deixou de existir para dar lugar ao "Novo Setor"), mas não se assuste se a tela "sumir" após você renomear a entidade principal em exibição.

---

## 🐞 Passo a Passo: Como Debugar um Hot Reload Falho?

Se você tentar fazer um hot reload e a tela não atualizar, siga este fluxo:

1. **Os arquivos chegaram no app?**
   > Verifique nos logs do terminal do celular/emulador se a sincronização salvou os novos binários.

2. **O Repositório notificou os ouvintes?**
   > Coloque um `debugPrint` no `ValueListenableBuilder` dentro de `PageListenableBuilder` (no arquivo `main.dart`). Se o log não aparecer, o `DatasetRepository` não atualizou o `activeDataset.value`.

3. **O Widget foi reconstruído (`didUpdateWidget`)?**
   > Se o `PageListenableBuilder` rodou, o problema está dentro do seu widget da tela. Se for um *StatefulWidget*, verifique se você não está preenchendo as coisas apenas no `initState`. Coloque um `print` no `didUpdateWidget`. Se ele não tem um `didUpdateWidget`, adicione um e verifique se as propriedades do `oldWidget` e `widget` estão diferentes.

4. **A UI não mudou mesmo chamando o build?**
   > Se é uma **Imagem**: Você esqueceu de chamar `evict()`!
   > Se é um **Texto/Layout**: Verifique se você não está passando parâmetros "mortos" (ex: variáveis que não vieram do widget construído diretamente).
