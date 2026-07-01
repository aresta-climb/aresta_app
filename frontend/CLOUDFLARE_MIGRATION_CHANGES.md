# Mudanças de Migração do Renato

Este documento resume as mudanças feitas por Renato, culminando no commit `60f6d72`. Um destaque importante dessas mudanças é a migração para o Cloudflare para servir a aplicação.

## 1. Migração para Cloudflare e Sistema de Sincronização
- **Migração de CDN (Cloudflare):** Corrigido o script de deploy `update_serving.py`, que anteriormente enviava solicitações de limpeza (purge) para uma URL fictícia em vez do domínio de produção (`serving.arestaclimb.com`). Isso resolveu um problema em que o cache ficava travado no Cloudflare após as implantações (`31bab82`).
- **Fallback de Bypass de Cache:** Implementado um mecanismo de fallback no aplicativo que detecta índices de CDN obsoletos (incompatibilidades de hash) e tenta novamente automaticamente forçando um bypass de cache (parâmetro de timestamp `?t=`) (`31bab82`).
- **Atualizações Globais Atômicas:** Implementadas atualizações globais atômicas com suporte robusto a offline-first usando TDD (`60f6d72`).
- **Robustez:** Garantida a sincronização robusta após mudanças disruptivas (breaking changes) e prevenidos crashes de protobuf (`3f618f5`).
- **Fluxos de Implantação e Atualização:** Melhoria nos fluxos de atualização, travamento de versão e links de lojas beta, incluindo suporte a configuração remota para redirecionar usuários de iOS para o TestFlight (`b9921bd`).

## 2. Melhorias no Sistema de Feedback
- **Offline-First e Confiabilidade:** Implementada uma fila atômica no sistema de arquivos para envio de feedback e melhorada a estabilização de rede para suporte offline-first (`5446735`).
- **Refatoração e Correções de UI:** Movida a geração de UUID para o coletor e melhorada a legibilidade do timestamp (`9b6640e`). Otimizado o layout da caixa de feedback, removido o scroll interno indesejado (`46b1482`) e simplificado o preenchimento (padding) (`fd8b1ca`).

## 3. Navegação e Roteamento
- **Migração para Navigator 2.0:** Refatorado o roteamento para usar o Navigator 2.0 declarativo, preservando o estado (`31c6513`). Integrados os modais TextNode a este novo sistema de roteamento (`4fca1bf`).
- **Roteamento de Mapa/Modal:** Refatorado o roteamento especificamente para mapas e modais (`fb48280`).

## 4. Mapas e Melhorias de UI
- **Mapas Interativos e Esquema v3:** Integrados os "Mapas Gerais" interativos e migrado para o esquema v3 (`3f0b0d5`).
- **Atualizações de Arquitetura:** Migradas as referências de mapas para uma nova arquitetura baseada em `DatasetResolver` (`cd17f21`).
- **UI e Usability:** Corrigida uma quebra visual no badge do card de mapa interativo (`bd9b763`). Melhorado o layout, cores adaptativas e lógica inteligente de auto-zoom para mapas (`86493a9`).
- **Correções de Bugs:** Melhorada a resolução de contexto para mapas interativos para eliminar avisos (`dd854d4`) e corrigida a desmarcação de marcadores em segundo plano, adicionando scripts de cobertura (`1bb8c9f`).

## 5. Sistema de Acesso e ESP32-CAM
- **Confiabilidade:** Migrado para um sistema de leitura de imagem mais confiável para acesso (`4fdcdf6`).
- **Documentação:** Adicionado um documento de design para o sistema de acesso do aplicativo (`c4a20ae`) e instruções detalhadas para o uso do ESP32-CAM (`d6a6548`).

## 6. Recursos e Diversos
- **Botão SOS:** Adicionado um botão SOS (`2f493c1`).
- **API e Testes:** Atualizada a versão da API (`fd34795`) e corrigidos testes quebrados (`a9380e6`).
- **Limpeza:** Excluídos arquivos temporários (`1aa119d`).
