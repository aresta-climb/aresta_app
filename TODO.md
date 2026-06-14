# TODO

## Melhorias Técnicas (Débitos Técnicos)

- [ ] **Migrar Fila de Feedbacks para SQLite (`sqflite` ou `isar`)**:
  - **Problema Atual:** A persistência da fila de envio de feedbacks no background (`feedback_queue_service.dart` e `background_worker.dart`) usa o pacote `shared_preferences`. Embora tenhamos mitigado problemas de concorrência com chamadas a `await prefs.reload()`, o SharedPreferences não foi projetado para acesso concorrente real (multi-isolate). Uma condição de corrida (TOCTOU - Time Of Check To Time Of Use) ainda pode ocorrer se a interface gráfica do app (UI) tentar gravar um novo feedback no mesmo milissegundo em que a thread em background (Workmanager) estiver limpando a fila, possivelmente resultando na perda de um feedback não enviado ou no envio de mensagens duplicadas.
  - **Solução Proposta:** Migrar a lista (fila) de `feedback_queue` para uma tabela no SQLite usando `sqflite` (ou um banco de dados desenhado para acessos multi-threads como o `isar`). Bancos de dados relacionais possuem mecanismos nativos de *file lock* a nível de SO (Sistema Operacional) que lidam perfeitamente com acessos simultâneos de produtores/consumidores, garantindo 100% de integridade (ACID) na manipulação das mensagens de feedback em background.
