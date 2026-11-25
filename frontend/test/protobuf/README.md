# Testes de Protobuf (`test/protobuf/`)

Este diretório verifica a serialização e desserialização binária das mensagens Protobuf usadas pelo aplicativo.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `protobuf_test.dart` | Testes de round-trip (`writeToBuffer` / `fromBuffer`) para `Indice`, `Croqui`, `Escalada`, `ResumoCroqui`, `ArquivoMarkdown` e `ArquivoExterno` |

## Cenários Cobertos

- **`Indice` e `ResumoCroqui`**: Preservação de campos (`id`, `nome`, `url`, `checksumSha256Croqui`), listas com múltiplos itens, mensagem vazia e determinismo dos bytes gerados.
- **`Croqui`**: Campos opcionais (`hasCaminhoThumbnail()`), listas de `ArquivoMarkdown` e `ArquivoExterno`.
- **`Escalada` (`oneof`)**: Resolução de variante via `whichTipo()` (`boulder`, `viaEsportiva`, `viaMovel`, `notSet`) e preservação dos campos internos.

## Execução

```bash
flutter test test/protobuf/
```

## Nota

Os arquivos em `lib/aresta_api/proto/generated/` são gerados a partir dos schemas `.proto` do submódulo `aresta_api` e não devem ser editados manualmente.
