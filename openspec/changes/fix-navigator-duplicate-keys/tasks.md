## 1. Setup de Testes (TDD)

- [ ] 1.1 Criar estrutura de testes em `test/navigation/navigation_tree_test.dart` (se não existir).
- [ ] 1.2 Escrever testes unitários verificando a unicidade de `toString()` para `ViaNode` com contextos diferentes (ex: mesmo `escaladaNome`, mas `setorNome` distinto).
- [ ] 1.3 Escrever testes unitários para `SetorNode`, `GrupoNode` e `MapaInterativoNode` assegurando que os campos utilizados pelo `_isSameNode` refletem-se perfeitamente nas saídas de `toString()`.
- [ ] 1.4 Executar os testes e certificar-se de que falham com a implementação atual (Red phase).

## 2. Implementação com Docstrings

- [ ] 2.1 Adicionar docstrings bem detalhadas em cada método `toString()` a ser modificado no `navigation_tree.dart`, explicando que ele deve gerar uma chave única para o Flutter Navigator com base na sua igualdade estrutural.
- [ ] 2.2 Atualizar a implementação de `ViaNode.toString()` para incluir `$cragId, $setorNome, $grupoNome, $escaladaNome`.
- [ ] 2.3 Atualizar a implementação de `SetorNode.toString()` para incluir `$cragId, $setorNome, $grupoNome`.
- [ ] 2.4 Atualizar a implementação de `GrupoNode.toString()` para incluir `$cragId, $grupoNome`.
- [ ] 2.5 Atualizar a implementação de `MapaInterativoNode.toString()` para incluir `$cragId, ${mapaCaminhoImagem.split('/').last}, $setorContextNome, $grupoContextNome`.

## 3. Validação e Test Coverage

- [ ] 3.1 Executar a suíte de testes unitários escrita no Passo 1 e confirmar que todos passam com sucesso (Green phase).
- [ ] 3.2 Executar o relatório de cobertura de testes (coverage) no arquivo `navigation_tree.dart` e garantir 100% de cobertura nos métodos modificados e testados.
- [ ] 3.3 Validar interativamente no app o fluxo original do bug (Busca -> Via -> Ver no Mapa -> Via) e confirmar a resolução do crash `!keyReservation.contains(key)`.
