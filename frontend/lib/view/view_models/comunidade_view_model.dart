// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../services/firebase/remote_config.dart';
import '../function_library/comunidade_functions.dart';

/// Representa um canal de comunicação oficial ou link social da comunidade Aresta.
class ItemCanalComunidade {
  /// Título em caixa alta para exibição no card de ação.
  final String titulo;

  /// Descrição detalhada da finalidade do canal.
  final String subtitulo;

  /// URL de destino para abertura externa.
  final String url;

  /// Rótulo identificador do serviço (ex: 'WhatsApp', 'Instagram', 'Discord').
  final String rotulo;

  const ItemCanalComunidade({
    required this.titulo,
    required this.subtitulo,
    required this.url,
    required this.rotulo,
  });

  /// Dispara a navegação para o link externo com rastreamento e tratamento de erros.
  void executar() => abrirLinkExterno(url, rotulo);
}

/// Modelo de apresentação para a página de comunidade ([ComunidadePage]).
///
/// Encapsula a recuperação das configurações dinâmicas de URLs externas e expõe
/// itens de canais sociais prontos para consumo por widgets passivos (Dumb UI).
class ComunidadeViewModel {
  /// Canal oficial de conversas no WhatsApp.
  final ItemCanalComunidade whatsapp;

  /// Perfil oficial do projeto no Instagram.
  final ItemCanalComunidade instagram;

  /// Perfil institucional no LinkedIn.
  final ItemCanalComunidade linkedin;

  /// Servidor dos desenvolvedores e comunidade no Discord.
  final ItemCanalComunidade discord;

  /// Organização e repositórios de código aberto no GitHub.
  final ItemCanalComunidade github;

  const ComunidadeViewModel({
    required this.whatsapp,
    required this.instagram,
    required this.linkedin,
    required this.discord,
    required this.github,
  });

  /// Cria uma instância padrão obtendo as URLs dinâmicas via [RemoteConfigService].
  factory ComunidadeViewModel.doServico({RemoteConfigService? servico}) {
    final config = servico ?? RemoteConfigService.instance;
    return ComunidadeViewModel(
      whatsapp: ItemCanalComunidade(
        titulo: 'GRUPO DO WHATSAPP',
        subtitulo:
            'Participe para tirar dúvidas, dar ideias e receber avisos do Aresta.',
        url: config.whatsappCommunityUrl,
        rotulo: 'WhatsApp',
      ),
      instagram: const ItemCanalComunidade(
        titulo: 'INSTAGRAM OFICIAL',
        subtitulo:
            'Acompanhe as últimas novidades, atualizações e bastidores do aplicativo.',
        url: 'https://www.instagram.com/arestaclimb/',
        rotulo: 'Instagram',
      ),
      linkedin: const ItemCanalComunidade(
        titulo: 'LINKEDIN DO PROJETO',
        subtitulo:
            'Acompanhe novidades, nosso crescimento e o lado corporativo do Aresta.',
        url: 'https://www.linkedin.com/company/arestaclimb/',
        rotulo: 'LinkedIn',
      ),
      discord: ItemCanalComunidade(
        titulo: 'DISCORD DOS DESENVOLVEDORES',
        subtitulo:
            'Converse com a equipe, acompanhe o código e colabore com o futuro do Aresta.',
        url: config.discordCommunityUrl,
        rotulo: 'Discord',
      ),
      github: const ItemCanalComunidade(
        titulo: 'GITHUB DO ARESTA',
        subtitulo: 'Acesse o perfil com os repositórios do github.',
        url: 'https://github.com/aresta-climb',
        rotulo: 'GitHub',
      ),
    );
  }
}
