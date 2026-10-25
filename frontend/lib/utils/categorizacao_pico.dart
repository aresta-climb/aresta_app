// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';

/// Categorias semânticas atribuídas aos botões e seções textuais de um croqui.
enum TextCategory {
  capa,
  explorarSobre,
  explorarComoChegar,
  regras,
  comunidadeParceiros,
  comunidadeComercio,
  comunidadeInfo,
  apoioProdutos,
  creditos,
  introducao,
  outros,
}

/// Categoriza um botão do croqui com base no texto do seu rótulo.
TextCategory categorizeBotao(Botao b) {
  final text = b.texto.toLowerCase();

  if (text.contains('capa')) {
    return TextCategory.capa;
  }
  if (text.contains('introdução') ||
      text.contains('introducao') ||
      text.contains('apresentação') ||
      text.contains('apresentacao')) {
    return TextCategory.introducao;
  }
  if (text.contains('sobre') ||
      text.contains('história') ||
      text.contains('historia')) {
    return TextCategory.explorarSobre;
  }
  if (text.contains('chegar') ||
      text.contains('acesso') ||
      text.contains('trilha')) {
    return TextCategory.explorarComoChegar;
  }
  if (text.contains('regras') ||
      text.contains('preservação') ||
      text.contains('ética') ||
      text.contains('etica') ||
      text.contains('conduta')) {
    return TextCategory.regras;
  }
  if (text.contains('parceir') ||
      text.contains('parceri') ||
      text.contains('patrocinador') ||
      text.contains('apoio') ||
      text.contains('apoiador')) {
    return TextCategory.comunidadeParceiros;
  }
  if (text.contains('comércio') ||
      text.contains('comercio') ||
      text.contains('hospedagem') ||
      text.contains('pousada')) {
    return TextCategory.comunidadeComercio;
  }
  if (text.contains('notícia') ||
      text.contains('noticia') ||
      text.contains('associação') ||
      text.contains('comunidade') ||
      text.contains('contato')) {
    return TextCategory.comunidadeInfo;
  }
  if (text.contains('produto') ||
      text.contains('camisa') ||
      text.contains('guia físico')) {
    return TextCategory.apoioProdutos;
  }
  if (text.contains('crédito') ||
      text.contains('credito') ||
      text.contains('autor') ||
      text.contains('agradecimento')) {
    return TextCategory.creditos;
  }

  return TextCategory.outros;
}

/// Resolve o link de navegação para o Google Maps a partir do pico.
///
/// Prioriza [Pico.urlGoogleMaps] quando preenchido e não-vazio. Como fallback,
/// caso o pico possua coordenadas geográficas válidas em [Pico.localizacao],
/// converte os inteiros no formato E7 para graus decimais e constrói a URL universal
/// da API de busca do Google Maps (`https://www.google.com/maps/search/?api=1&query=lat,lon`).
/// Retorna `null` caso nenhum link ou coordenada válida esteja disponível.
String? resolverUrlGoogleMapsPico(Pico pico) {
  if (pico.urlGoogleMaps.trim().isNotEmpty) {
    return pico.urlGoogleMaps.trim();
  }

  if (pico.hasLocalizacao()) {
    final latE7 = pico.localizacao.latitude;
    final lonE7 = pico.localizacao.longitude;
    if (latE7 != 0 || lonE7 != 0) {
      final lat = latE7 / 10000000.0;
      final lon = lonE7 / 10000000.0;
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    }
  }

  return null;
}

/// Estrutura agregadora dos botões do croqui separados por categoria de apresentação.
class PicoCategorizedData {
  final List<Botao> capa = [];
  final List<Botao> sobre = [];
  final List<Botao> comoChegar = [];
  final List<Botao> regras = [];
  final List<Botao> comunidadeParceiros = [];
  final List<Botao> comunidadeComercio = [];
  final List<Botao> comunidadeInfo = [];
  final List<Botao> apoioProdutos = [];
  final List<Botao> creditos = [];
  final List<Botao> introducao = [];
  final List<Botao> outros = [];

  PicoCategorizedData(Croqui croqui) {
    final botoes = croqui.botoes
        .where((b) => b.hasDestino() && b.destino.hasSecaoTextual())
        .toList();

    for (var b in botoes) {
      final cat = categorizeBotao(b);
      switch (cat) {
        case TextCategory.capa:
          capa.add(b);
          break;
        case TextCategory.explorarSobre:
          sobre.add(b);
          break;
        case TextCategory.explorarComoChegar:
          comoChegar.add(b);
          break;
        case TextCategory.regras:
          regras.add(b);
          break;
        case TextCategory.comunidadeParceiros:
          comunidadeParceiros.add(b);
          break;
        case TextCategory.comunidadeComercio:
          comunidadeComercio.add(b);
          break;
        case TextCategory.comunidadeInfo:
          comunidadeInfo.add(b);
          break;
        case TextCategory.apoioProdutos:
          apoioProdutos.add(b);
          break;
        case TextCategory.creditos:
          creditos.add(b);
          break;
        case TextCategory.introducao:
          introducao.add(b);
          break;
        case TextCategory.outros:
          outros.add(b);
          break;
      }
    }
  }

  /// Indica se a subpágina Explorar Local possui ao menos um elemento para exibição.
  bool temConteudoExplorarLocal(Pico pico) {
    return capa.isNotEmpty ||
        introducao.isNotEmpty ||
        sobre.isNotEmpty ||
        pico.descricao.trim().isNotEmpty ||
        comoChegar.isNotEmpty ||
        resolverUrlGoogleMapsPico(pico) != null ||
        outros.isNotEmpty;
  }

  /// Indica se a subpágina Comunidade possui ao menos um elemento para exibição.
  bool temConteudoComunidade(Pico pico) {
    final temAssociacao =
        pico.nomeAssociacao.trim().isNotEmpty &&
        pico.urlFiliacaoAssociacao.trim().isNotEmpty;

    return comunidadeInfo.isNotEmpty ||
        temAssociacao ||
        comunidadeParceiros.isNotEmpty ||
        comunidadeComercio.isNotEmpty;
  }
}
