## ADDED Requirements

### Requirement: Download em Segundo Plano para Cache em Disco de Mapas em Carrossel
O sistema DEVE (MUST) disparar o download assíncrono em segundo plano de todas as páginas subsequentes de um carrossel de mapas (`MapasCarrosselPage`) diretamente para o cache em disco local (`temp_cache`) assim que o mapa interativo for aberto, garantindo disponibilidade local e navegação fluida mesmo sem conectividade na rocha.

#### Scenario: Download em segundo plano das páginas ao abrir o carrossel
- **QUANDO** o usuário abre a visualização de um carrossel contendo múltiplos mapas interativos
- **THEN** a primeira imagem é renderizada na tela normalmente
- **THEN** o sistema agenda em segundo plano o download de todas as demais imagens do carrossel da internet para o cache em disco (`temp_cache`) sem bloquear a interação na tela

#### Scenario: Navegação com imagens persistidas no cache em disco
- **QUANDO** o usuário avança para as páginas subsequentes do carrossel após o término dos downloads de segundo plano
- **THEN** o sistema obtém as imagens diretamente do armazenamento local em disco (`temp_cache` ou downloads), sem necessidade de novas requisições de rede
- **THEN** a transição entre as páginas ocorre de maneira imediata

