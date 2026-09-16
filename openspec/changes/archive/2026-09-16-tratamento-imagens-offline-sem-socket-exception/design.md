# Design Técnico: Tratamento de Imagens Offline sem SocketException

## Context

Atualmente, o aplicativo possui uma estratégia de resolução em camadas para mídias (`ProvedorImagemAresta`):
1. Armazenamento permanente local (`/downloads` ou `$docsDir/thumbnails`);
2. Cache temporário volátil em disco (`temp_cache`);
3. Streaming remoto sob demanda via CDN HTTP (`_baixarESalvarNoCache`).

Quando o usuário está em modo avião ou perde sinal e acessa um setor ou croqui online:
- `_baixarESalvarNoCache` tenta o download via `http.Client.get`, captura `SocketException: Failed host lookup`, emite `AppLogger.instance.logError` (enviando para o Crashlytics) e no final faz `return NetworkImage(urlFinal);`.
- Os widgets consumidores (`MapaThumbnail`, `setor.dart`, `grupo.dart`) recebem essa `NetworkImage` dentro de um `FutureBuilder`. Como o dado não é nulo, eles instanciam o widget `Image(image: snapshot.data!)` sem `errorBuilder`.
- O Flutter tenta resolver a `NetworkImage` no motor gráfico, toma `SocketException` e renderiza a tela de erro de debug (`ErrorWidget` com "X" vermelho e texto cru da exceção).
- Paralelamente, o `ServicoCroquiOnline.verificarAtualizacaoEtag` executa polling a cada 30 segundos, tomando `SocketException` e emitindo `logError` incondicionalmente no console e no Crashlytics.

## Goals / Non-Goals

**Goals:**
- Garantir que `_baixarESalvarNoCache` retorne `null` (em vez de `NetworkImage`) ao encontrar falhas de download na rede.
- Adicionar `errorBuilder` defensivo em `MapaThumbnail`, `setor.dart` e `grupo.dart`, fazendo o widget degradar suavemente para o fundo do tema (`deepBasalt` ou `Container`) sem nunca renderizar o `ErrorWidget` do Flutter.
- Usar `AppLogger.isFalhaConexaoOuTimeout` no `ProvedorImagemAresta` e no `ServicoCroquiOnline`, logando como `logAviso` (breadcrumb sem abrir issue no Crashlytics) quando a falha for decorrente de desconexão, socket indisponível ou timeout.
- Manter 100% de cobertura de testes unitários e de widget em todos os módulos afetados.

**Non-Goals:**
- Não faz parte deste design implementar pré-download forçado de todas as imagens do croqui sem solicitação do usuário.
- Não faz parte deste design alterar o formato de armazenamento em disco nem os algoritmos de verificação por SHA-256 já homologados.

## Decisions

### Decisão 1: Retornar `null` em falha de download no `ProvedorImagemAresta`
- **Escolha**: Quando `_baixarESalvarNoCache` falhar (exceção capturada ou HTTP != 200), retornar `null`.
- **Racional**: Se uma requisição HTTP controlada já falhou devido a falta de sinal de rede ou indisponibilidade do servidor, delegar a mesma URL para o `NetworkImage` no Flutter é uma garantia de nova falha assíncrona. Retornar `null` informa com precisão aos componentes visuais que a imagem não pôde ser obtida.
- **Alternativas consideradas**:
  - *Retornar uma imagem de fallback local*: Rejeitada porque nem todo widget possui o mesmo aspecto dimensional; é preferível deixar a camada de UI compor o fallback nativo de seu layout.
  - *Continuar retornando `NetworkImage`*: Rejeitada pois gera a exceção não tratada na UI.

### Decisão 2: Inclusão de `errorBuilder` transparente nos widgets de UI
- **Escolha**: No `MapaThumbnail`, a camada de `Image` receberá:
  ```dart
  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  ```
  Nas capas de `setor.dart` e `grupo.dart`, a `Image` receberá o mesmo `errorBuilder`.
- **Racional**: O `MapaThumbnail` já conta com `Camada 0: Container(color: colors.deepBasalt)` e `Camada 2: Overlay escuro`. Se a imagem de satélite/mapa falhar, a camada 1 decai para `SizedBox.shrink()`, revelando o fundo sólido elegante e limpo da paleta Aresta, com o botão "Mapas Interativos" e o ícone de mapa perfeitamente utilizáveis. O mesmo vale para as capas de setores e grupos, que preservam a cor do tema e o gradiente escuro.
- **Alternativas consideradas**:
  - *Exibir um ícone de erro vermelho ou mensagem intrusiva dentro da miniatura*: Rejeitada para não poluir visualmente a navegação do escalador.

### Decisão 3: Telemetria limpa para falhas transitórias com `isFalhaConexaoOuTimeout`
- **Escolha**:
  - No `ProvedorImagemAresta`: se `AppLogger.isFalhaConexaoOuTimeout(e)`, registrar via `logAviso`. Se for erro desconhecido/anômalo de parsing/IO, registrar via `logError`.
  - No `ServicoCroquiOnline`: na captura de erro do `verificarAtualizacaoEtag`, verificar `AppLogger.isFalhaConexaoOuTimeout(e)`. Se verdadeiro, emitir `logAviso('[ServicoCroquiOnline] Verificação de ETag ignorada: sem conexão com a internet ($picoId)')`.
- **Racional**: `logAviso` imprime aviso no console em modo debug e envia apenas breadcrumbs contextuais ao Firebase Crashlytics no modo release. Não polui a lista de issues do painel de monitoramento com eventos operacionais comuns em montanha.
- **Alternativas consideradas**:
  - *Silenciar completamente sem nenhum log*: Rejeitada pois o breadcrumb é útil para entender o contexto em caso de outros crashes simultâneos.

## Risks / Trade-offs

- **[Risco]** Testes de unidade que esperavam `isA<NetworkImage>()` ao simular erro no download remoto.
  - **Mitigação**: Atualizar a suíte de testes de `provedor_imagem_aresta_test.dart` para verificar que o retorno é `isNull` quando o download falha com `SocketException` ou status 404/500, e validar que `logAviso` é acionado sem chamar `logError`.
- **[Risco]** Comportamento visual de `MapaThumbnail` caso a imagem não carregue.
  - **Mitigação**: Testes de widget em `mapa_thumbnail_test.dart` já validam que o botão central é renderizado imediatamente sobre o container `deepBasalt`. Adicionar teste cobrindo a falha assíncrona do provider garantindo que nenhum `ErrorWidget` é lançado.
