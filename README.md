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

Isso previne o uso excessivo de *Mapas* genéricos (mock data) e garante uma comunicação transparente entre a lógica de serviços (como downloads atômicos do `SyncService`) e as interfaces (Views). As funcionalidades de rede, persistência no disco e tratamento HTTP foram unificadas no módulo isolado `services/http`.

Adicionalmente, a navegação principal foge da tradicional pilha (Push/Pop) em favor de uma **Árvore de Navegação** baseada em IDs de nós. Em conjunto com o `PageListenableBuilder`, o aplicativo possui uma arquitetura reativa que injeta passivamente as versões em memória dos objetos na UI sempre que os dados sofrerem um update invisível no background (garantindo um **Hot-Reload de dados em tempo real** sem piscar a tela).

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
