# Proposta: Tratamento de Imagens Offline sem SocketException

## Why

Durante a exploração de croquis em modo online (streaming sob demanda), quando o usuário entra no modo avião ou perde o sinal de internet e tenta visualizar uma mídia ou mapa ainda não baixado, o aplicativo dispara múltiplos erros graves no console e envia exceções desnecessárias para o Firebase Crashlytics (`SocketException: Failed host lookup`). 

Além disso, na interface gráfica, o Flutter desenha uma tela de erro (`ErrorWidget` com linhas diagonais vermelhas em "X" e o texto cru da exceção) sobreposta ao componente `MapaThumbnail`. Em ambientes externos de montanha e escalada, a perda de sinal ou o uso do modo avião para economia de bateria é uma condição operacional comum e esperada. O aplicativo deve ser resiliente a esse cenário, exibindo um visual limpo e consistente com a paleta do tema (fundo sólido escuro), sem expor erros técnicos na UI e sem poluir o painel do Crashlytics com falsos-positivos.

## What Changes

- **Eliminação do fallback incorreto para `NetworkImage` no `ProvedorImagemAresta`**: Ao falhar o download da mídia para o cache volátil por indisponibilidade de rede ou erro HTTP, o método `_baixarESalvarNoCache` deve retornar `null` em vez de repassar a URL para uma instância de `NetworkImage`, evitando que o pipeline de rendering do Flutter tente uma nova conexão fadada ao fracasso.
- **Tratamento defensivo na UI com `errorBuilder`**: Adicionar `errorBuilder` na renderização de `Image` dentro do `MapaThumbnail`, em `setor.dart` e em `grupo.dart`, garantindo que qualquer falha assíncrona na decodificação ou resolução de streams retorne `SizedBox.shrink()`, permitindo que o fundo do tema (`deepBasalt`) permaneça visível de forma elegante e limpa, sem pintar caixas de erro do Flutter.
- **Higiene de telemetria no `ProvedorImagemAresta`**: Utilizar `AppLogger.isFalhaConexaoOuTimeout` nas capturas de erro de download e resolução de imagens, registrando falhas de conectividade esperadas via `AppLogger.instance.logAviso` (breadcrumb contextual) em vez de `logError`, prevenindo a abertura de tickets indevidos no Crashlytics.
- **Higiene de telemetria no `ServicoCroquiOnline` (Polling de ETag)**: Filtrar exceções de rede durante a verificação periódica de ETag com `isFalhaConexaoOuTimeout` e emitir `logAviso`, cessando o spam de erros a cada 30 segundos quando o dispositivo estiver offline.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade necessária; as alterações estendem e aprimoram contratos existentes. -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Resolução de mídia com retorno `null` em falhas de rede e telemetria resiliente sem emissão de `logError` para falhas de conexão/timeout.
- `interactive-map`: Salvaguarda visual contra falhas de carregamento em `MapaThumbnail` e capas de setores/grupos com `errorBuilder` defensivo.
- `transmissao-croqui-online`: Classificação de falhas transitórias de conexão durante o polling periódico de ETag utilizando `logAviso`.

## Impact

- **Código Afetado**:
  - `frontend/lib/widgets/provedor_imagem_aresta.dart`
  - `frontend/lib/widgets/mapa_thumbnail.dart`
  - `frontend/lib/pages/setor.dart`
  - `frontend/lib/pages/grupo.dart`
  - `frontend/lib/services/http/servico_croqui_online.dart`
- **Testes Afetados**:
  - `frontend/test/widgets/provedor_imagem_aresta_test.dart`
  - `frontend/test/widgets/mapa_thumbnail_test.dart`
  - `frontend/test/pages/setor_test.dart`
  - `frontend/test/services/http/servico_croqui_online_test.dart`
- **APIs e Dependências**: Nenhuma nova dependência externa necessária. Utilização de mecanismos padrão do Flutter (`errorBuilder`) e do `AppLogger` existente.
