# Capability: capas-setores-e-grupos

## Purpose

Permite a exibição visual de fotos de capa nativas nos cabeçalhos das páginas de setores e grupos do aplicativo móvel, adaptando a altura do cabeçalho de forma limpa entre visualizações com e sem foto.

## Requirements

### Requirement: Resolução Nativa de Foto de Capa de Setores e Grupos
O sistema SHALL resolver a foto de capa para páginas de exibição de `Setor` e `Grupo` a partir do campo estruturado `caminhoImagemCapa` do Protobuf, sem recorrer a varredura por expressão regular no Markdown.

#### Scenario: Setor com foto de capa definida
- **WHEN** a página de um setor é aberta e o setor possui `caminhoImagemCapa` preenchido
- **THEN** o sistema carrega o provedor de imagem apontando para o caminho relativo informado com resolução otimizada

#### Scenario: Grupo com foto de capa definida
- **WHEN** a página de um grupo é aberta e o grupo possui `caminhoImagemCapa` preenchido
- **THEN** o sistema carrega o provedor de imagem apontando para o caminho relativo informado com resolução otimizada

### Requirement: Cabeçalho Adaptativo e Compacto para Entidades sem Capa
O sistema SHALL renderizar um `SliverAppBar` expandido com altura de 300px quando o setor ou grupo possuir imagem de capa, e SHALL manter o cabeçalho compacto na altura padrão da barra de navegação quando nenhuma foto de capa estiver definida, sem utilizar fotos gerais do pico como substituto.

#### Scenario: Exibição de cabeçalho expandido para setor com capa
- **WHEN** a `SetorPage` é renderizada para um setor que possui `caminhoImagemCapa`
- **THEN** a barra exibe altura expandida de 300px contendo a imagem em tela cheia, gradientes de sombra e animação do título durante a rolagem

#### Scenario: Exibição de cabeçalho compacto para setor sem capa
- **WHEN** a `SetorPage` é renderizada para um setor sem `caminhoImagemCapa`
- **THEN** a barra permanece na altura compacta padrão, renderizando o nome do setor diretamente na AppBar e iniciando imediatamente o conteúdo descritivo abaixo da barra

#### Scenario: Exibição de cabeçalho compacto para grupo sem capa
- **WHEN** a `GrupoPage` é renderizada para um grupo sem `caminhoImagemCapa`
- **THEN** a barra permanece na altura compacta padrão sem exibir imagem de fundo do pico, renderizando o nome do grupo diretamente na AppBar
