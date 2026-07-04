## Context

Recentemente, duas novas funcionalidades (navegação "up" no mapa hierárquico e o badge de feedback sem atualizações) foram adicionadas ao aplicativo. Precisamos garantir que elas emitam eventos de telemetria específicos no Firebase Analytics, via `TelemetryService`, ao invés de reutilizar eventos antigos de forma imprecisa.

## Goals / Non-Goals

**Goals:**
- Instrumentar as novas interações com eventos claros e com a nomenclatura correta (`logNavegacaoHierarquica` e `logResultadoSincronizacao`).
- Permitir testes unitários precisos que atestem o envio correto de cada telemetria.

**Non-Goals:**
- Nenhuma refatoração pesada de telemetria legada, focaremos apenas nos eventos dessas duas novas interações.

## Decisions

- **Evento de Sincronização:** Será feito dentro do `SyncService`, injetando o status diretamente após o retorno das requisições (não na UI), garantindo que seja centralizado e seguro.
- **Evento do Mapa:** Será adicionado ao `mapa_interativo.dart` diretamente no callback do `onPressed` do `ActionChip` de subida hierárquica. Substituiremos o uso de `logAcaoEscalada`.

## Risks / Trade-offs

- **Testabilidade:** Mocks desatualizados podem causar falsos positivos ou quebrar build.
  - *Mitigation*: Vamos atualizar as assinaturas de mocks e os testes existentes (`sync_service_test.dart` e `mapa_interativo_test.dart`) de acordo com a implementação, rodando os testes após a alteração.
