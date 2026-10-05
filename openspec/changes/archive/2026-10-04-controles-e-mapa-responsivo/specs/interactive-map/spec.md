# Spec Delta: interactive-map

## MODIFIED Requirements

### Requirement: Renderização Imediata e Não-Bloqueante do Botão de Mapa no Setor
O componente de miniatura de mapa no setor (`MapaThumbnail`) SHALL renderizar imediatamente no primeiro frame o container com a proporção da imagem limitada a uma altura máxima de 260 pixels (`maxHeight: 260px`), preenchendo a largura disponível com corte centralizado (`BoxFit.cover` e `Alignment.center`) e mantendo o botão de abertura do mapa interativo centralizado, permitindo toque e navegação instantânea para a tela cheia do mapa sem aguardar o download ou decodificação da imagem de fundo.

#### Scenario: Visualização do setor com mapa enquanto a imagem está baixando
- **WHEN** o usuário acessa um setor que possui mapas em um croqui online
- **AND** a imagem do mapa ainda não foi baixada ou está em processo de resolução
- **THEN** o card do mapa exibe imediatamente um container estilizado com cantos arredondados contido no limite máximo de 260px de altura
- **AND** o botão "Abrir Mapa Interativo" é renderizado centralizado e habilitado para toque no primeiro frame
- **AND** o término do download da miniatura exibe a imagem em segundo plano com transição suave (fade-in) sem reconstruir ou piscar o botão.

#### Scenario: Mapa em orientação vertical ou quadrada com altura superior a 260px
- **WHEN** o mapa possui proporção vertical (ex: 3:4) ou quadrada (1:1) cuja altura natural excederia 260px na tela
- **THEN** o container tem sua altura restrita a no máximo 260px
- **AND** a imagem preenche a largura horizontalmente, sendo enquadrada e centralizada verticalmente
- **AND** o botão de abertura do mapa permanece visível e perfeitamente centralizado sobre o banner.

#### Scenario: Mapa panorâmico com altura inferior a 260px
- **WHEN** o mapa possui proporção panorâmica (ex: 16:9) cuja altura natural na tela é inferior a 260px
- **THEN** o container preserva sua proporção natural sem forçar esticamento ou espaçamento vazio.

#### Scenario: Toque no botão de mapa antes do término do download da miniatura
- **WHEN** o usuário toca no botão "Abrir Mapa Interativo" no setor
- **AND** a miniatura do mapa ainda não completou seu download
- **THEN** o sistema aciona a navegação para a tela de mapas (`toMapas`) imediatamente sem reter o usuário no setor.
