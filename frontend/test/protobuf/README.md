# Testes de Protobuf

Esta pasta contém testes de serialização e desserialização dos objetos Protobuf usados pela aplicação. O objetivo é garantir que nenhum campo seja perdido ou corrompido durante a conversão entre objetos Dart e bytes binários.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `protobuf_test.dart` | Testes de round-trip para `Indice`, `Croqui`, `Escalada`, `ResumoCroqui`, `ArquivoMarkdown` e `ArquivoExterno` |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/protobuf/

# Um arquivo específico
flutter test test/protobuf/protobuf_test.dart
```

## Mensagens cobertas

### `Indice`
- Serialização e desserialização com fidelidade total de campos
- Suporte a múltiplos `ResumoCroqui` em um mesmo índice
- `Indice` vazio sem erros
- Determinismo: dois objetos com mesmo conteúdo geram os mesmos bytes

### `Croqui`
- Campo `nome`
- Campo opcional `caminhoThumbnail` (com `hasCaminhoThumbnail()`)
- Lista de `ArquivoMarkdown` (título e conteúdo)
- Lista de `ArquivoExterno` (caminho e checksum)
- Estado vazio sem campos opcionais definidos

### `Escalada` (oneof)
- Identificação correta de `boulder`, `viaEsportiva`, `viaMovel` via `whichTipo()`
- Estado `notSet` quando criado sem tipo
- Round-trip de `Boulder` com campo `nome`
- Round-trip de `ViaEsportiva` com campo `extensao`

### `ResumoCroqui`
- Todos os campos: `id`, `nome`, `url`, `checksumSha256Croqui`
- Detecção de checksum diferente entre versões

## Notas

Os arquivos proto gerados estão em `lib/aresta_api/proto/generated/`. Nunca edite esses arquivos manualmente — eles são gerados a partir dos schemas `.proto` do submodule `aresta_api`.
