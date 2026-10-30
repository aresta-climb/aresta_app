# exibicao-ponta-a-ponta-insets Specification

## Purpose
Padronizar a inicialização da interface em modo de ponta a ponta (*edge-to-edge*) com barras do sistema transparentes em todas as versões do Android e garantir que todas as telas do aplicativo respeitem os recuos físicos e de navegação do sistema operacional (*window insets*).

## Requirements

### Requirement: Ativação Unificada do Modo Ponta a Ponta na Inicialização
O aplicativo DEVE (MUST) ativar o modo de interface do sistema de ponta a ponta (`edge-to-edge`) durante sua inicialização e configurar o estilo das barras de status e de navegação como totalmente transparentes e sem contraste forçado pelo sistema operacional.

#### Scenario: Inicialização do aplicativo configurando barras do sistema
- **WHEN** a rotina de inicialização de interface do aplicativo é executada
- **THEN** o modo `SystemUiMode.edgeToEdge` é habilitado na plataforma e o estilo de sobreposição das barras do sistema define `statusBarColor`, `systemNavigationBarColor` e `systemNavigationBarDividerColor` como transparentes, com `systemStatusBarContrastEnforced` e `systemNavigationBarContrastEnforced` desativados (`false`)

### Requirement: Respeito ao Recuo Inferior do Sistema no Leitor de QR Code
A tela de leitura de QR Code DEVE (MUST) posicionar a instrução visual inferior somando o recuo inferior da área segura do sistema operacional (`padding.bottom`) à margem base de 40 dp, evitando sobreposição com barras de navegação de 3 botões ou gestos.

#### Scenario: Renderização da tela de QR Code com barra de navegação de 3 botões
- **WHEN** a tela de leitura de QR Code é exibida em um dispositivo com recuo inferior do sistema de 48 dp
- **THEN** o indicador textual de instrução na parte inferior é posicionado a 88 dp da borda física inferior da tela (`40 + 48`)

### Requirement: Respeito ao Recuo Inferior do Sistema na Lista de Configurações
A tela de Configurações DEVE (MUST) incluir o recuo inferior do sistema operacional (`padding.bottom`) no preenchimento inferior de sua lista rolável, garantindo que o rodapé de versão permaneça integralmente visível acima da barra de navegação do sistema.

#### Scenario: Rolagem até o final da tela de Configurações com recuo inferior ativo
- **WHEN** a tela de Configurações é renderizada com um recuo inferior de sistema de 48 dp
- **THEN** o `ListView` aplica preenchimento inferior de `64` dp (`16 + 48`), mantendo os cartões e o rodapé de versão desobstruídos

### Requirement: Respeito ao Recuo Inferior do Sistema no Mapa Global
A tela do Mapa Global DEVE (MUST) repassar o recuo inferior do sistema operacional (`padding.bottom`) ao componente de mapa para deslocar o logotipo do provedor e os avisos legais acima da barra de navegação do sistema.

#### Scenario: Renderização do Mapa Global em modo ponta a ponta
- **WHEN** a tela do Mapa Global é exibida em um dispositivo com recuo inferior do sistema de 34 dp
- **THEN** o widget de mapa recebe `EdgeInsets.only(bottom: 34)` em sua propriedade `padding`
