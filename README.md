# Aresta Climb App

Aplicativo de escalada da **ARESTA** — guia digital offline para centralizar e distribuir informações de picos.

## Estrutura do Repositório

```
Aresta Climb_App/
├── frontend/          Aplicativo Flutter (Android / iOS)
└── README.md
```

> O submodule `aresta_api` (definições `.proto` e código Protobuf gerado) fica em `frontend/lib/aresta_api/`.

---

## O que é o Aresta Climb?

O Aresta Climb é um guia de escalada digital. O app permite que alpinistas baixem informações completas de picos — croquis, betas, mapas GPS e descrições — para acesso **completamente offline** no campo, sem depender de sinal de celular.

Os dados são distribuídos no formato `.croqui` (um ZIP com ofuscação XOR), consumido tanto do servidor remoto quanto de repositórios locais de editores via o **Ghost Protocol** (`aresta-zip://`).

## Arquitetura e Padrões

O aplicativo é desenvolvido com uma arquitetura **MVVM (Model-View-ViewModel)** robusta e utiliza classes **Protobuf** geradas automaticamente (`ResumoCroqui`, `Indice`, `Croqui`) como seus **Models** centrais, fortemente tipados de ponta a ponta.

A sincronização de picos com a nuvem é de última geração: o `SyncService` utiliza **Isolates em background** para realizar cálculos de criptografia (SHA256) e persistência de arquivos sem travar a interface (`Main Thread`). Os downloads são do tipo **Delta Syncs (Atômicos)** — o aplicativo só baixa imagens e arquivos que sofreram mutação na nova versão, economizando banda e validando integridade bit a bit.

Adicionalmente, a navegação principal foge da tradicional pilha (Push/Pop) em favor de uma **Árvore de Navegação** baseada em IDs de nós. Isso se estende para **Navegação em Carrossel** para múltiplos mapas de forma horizontal (swiping). Em conjunto com o `PageListenableBuilder` e o `ValueNotifier` de progresso, o aplicativo possui uma arquitetura reativa que injeta passivamente as versões em memória dos objetos na UI e exibe o andamento do download através de barras de progresso lineares, tudo em **tempo real** e sem piscar a tela.

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`frontend/README.md`](frontend/README.md) | Ponto de entrada para desenvolvedores: tecnologias, funcionalidades, estrutura e como rodar |
| [`frontend/lib/README.md`](frontend/lib/README.md) | Arquitetura interna: MVVM, serviços, páginas, funções e widgets |
| [`frontend/lib/services/README.md`](frontend/lib/services/README.md) | Descrição dos serviços centrais, Modo Experimental e ciclo de importação |
| [`frontend/lib/services/http/README.md`](frontend/lib/services/http/README.md) | Módulo HTTP: Sincronização, downloads atômicos e Ghost Protocol |
| [`frontend/lib/services/firebase/README.md`](frontend/lib/services/firebase/README.md) | Isolamento e integração com Firebase (Analytics, Crashlytics, Remote Config) |
| [`frontend/test/README.md`](frontend/test/README.md) | Suíte de testes: estrutura, como executar e convenções |

---

## Referências

- [Protocol Buffers — Especificando tipos](https://protobuf.dev/programming-guides/proto3/#specifying-types)
- [Protocol Buffers — Tipos escalares](https://protobuf.dev/programming-guides/proto3/#scalar)
- [flutter.dev — Instalação](https://flutter.dev/docs/get-started/install)
