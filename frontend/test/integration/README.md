# Testes de Integração

Esta pasta contém testes de integração que verificam fluxos completos da aplicação, combinando múltiplos serviços e camadas. Os testes aqui simulam cenários reais de uso sem depender de um servidor remoto.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `download_flow_test.dart` | Testa o fluxo de download de índice e pico a partir de um `.croqui` local, incluindo persistência em disco |
| `integration_flow_test.dart` | Testa o fluxo completo: leitura de índice → extração de ID → download de pico → verificação de markdown e arquivos externos → leitura de imagem |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/integration/

# Um arquivo específico
flutter test test/integration/integration_flow_test.dart
```

## Fluxos cobertos

### `download_flow_test.dart`
- Download e parse de `indice.binarypb` de um `.croqui`
- Download e parse de pico (`Croqui`) pelo ID
- Retorno de 404 para pico inexistente no `.croqui`
- Salvamento dos bytes recebidos em arquivo local e re-leitura correta

### `integration_flow_test.dart`

**Fluxo completo de leitura (`.croqui` com múltiplos arquivos):**
1. Lê o `indice.binarypb` e extrai o ID do pico
2. Constrói a URL do pico a partir da URL do índice
3. Faz o download e parse do `Croqui` protobuf
4. Verifica os campos `ArquivoMarkdown` (título, conteúdo)
5. Verifica os campos `ArquivoExterno` (caminho, checksum)
6. Lê o arquivo de imagem (thumbnail) diretamente do `.croqui`

**Múltiplos picos:**
- Índice com 3 picos → verificação de todos os IDs

**Compatibilidade:**
- Leitura de `.zip` padrão (sem ofuscação XOR) via `aresta-zip://`

## Notas

- Todos os arquivos `.croqui` usados nos testes são criados dinamicamente em `Directory.systemTemp` e removidos após cada teste.
- Os testes **não fazem nenhuma requisição de rede real**; tudo é lido de arquivos locais via o interceptor `aresta-zip://`.
- O fluxo aqui espelha exatamente o que acontece quando o usuário importa um arquivo `.croqui` pela tela de configurações.
