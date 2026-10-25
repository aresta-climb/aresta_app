// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/categorizacao_pico.dart';

void main() {
  group('PicoCategorization', () {
    test('Categories are correctly populated based on texto and destino', () {
      final croqui = Croqui()
        ..botoes.addAll([
          Botao(
            texto: 'Sobre o Pico',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Como chegar na montanha',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Regras e Ética',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Patrocinador Oficial',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Pousada da Montanha',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Associação de Escalada',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Comprar Guia Físico',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Outro Botão Qualquer',
            destino: DestinoBotao(secaoTextual: ArquivoMarkdown()),
          ),
          Botao(
            texto: 'Botão Sem Destino Textual', // Should be ignored
          ),
        ]);

      final categorizedData = PicoCategorizedData(croqui);

      expect(categorizedData.sobre.length, 1);
      expect(categorizedData.sobre.first.texto, 'Sobre o Pico');

      expect(categorizedData.comoChegar.length, 1);
      expect(categorizedData.comoChegar.first.texto, 'Como chegar na montanha');

      expect(categorizedData.regras.length, 1);
      expect(categorizedData.regras.first.texto, 'Regras e Ética');

      expect(categorizedData.comunidadeParceiros.length, 1);
      expect(
        categorizedData.comunidadeParceiros.first.texto,
        'Patrocinador Oficial',
      );

      expect(categorizedData.comunidadeComercio.length, 1);
      expect(
        categorizedData.comunidadeComercio.first.texto,
        'Pousada da Montanha',
      );

      expect(categorizedData.comunidadeInfo.length, 1);
      expect(
        categorizedData.comunidadeInfo.first.texto,
        'Associação de Escalada',
      );

      expect(categorizedData.apoioProdutos.length, 1);
      expect(categorizedData.apoioProdutos.first.texto, 'Comprar Guia Físico');

      expect(categorizedData.outros.length, 1);
      expect(categorizedData.outros.first.texto, 'Outro Botão Qualquer');
    });

    test('Handles empty croqui gracefully', () {
      final croqui = Croqui();
      final categorizedData = PicoCategorizedData(croqui);

      expect(categorizedData.sobre, isEmpty);
      expect(categorizedData.comoChegar, isEmpty);
      expect(categorizedData.regras, isEmpty);
      expect(categorizedData.comunidadeParceiros, isEmpty);
      expect(categorizedData.comunidadeComercio, isEmpty);
      expect(categorizedData.comunidadeInfo, isEmpty);
      expect(categorizedData.apoioProdutos, isEmpty);
      expect(categorizedData.outros, isEmpty);
    });

    test('categorizeBotao categoriza termos reais de comunidade como comunidade, parceria e contato', () {
      final croqui = Croqui()
        ..botoes.addAll([
          Botao(texto: 'Comunidade', destino: DestinoBotao(secaoTextual: ArquivoMarkdown())),
          Botao(texto: 'Parcerias e Contato', destino: DestinoBotao(secaoTextual: ArquivoMarkdown())),
          Botao(texto: 'Apoio e Patrocinadores', destino: DestinoBotao(secaoTextual: ArquivoMarkdown())),
        ]);

      final categorizedData = PicoCategorizedData(croqui);
      expect(categorizedData.comunidadeInfo.length, 1);
      expect(categorizedData.comunidadeInfo.first.texto, 'Comunidade');
      expect(categorizedData.comunidadeParceiros.length, 2);
    });
  });

  group('resolverUrlGoogleMapsPico', () {
    test('prioriza urlGoogleMaps quando preenchida mesmo se houver coordenadas', () {
      final pico = Pico()
        ..urlGoogleMaps = 'https://maps.app.goo.gl/exemplo123'
        ..localizacao = (Coordenada()
          ..latitude = -198960870
          ..longitude = -436547850);

      final url = resolverUrlGoogleMapsPico(pico);
      expect(url, 'https://maps.app.goo.gl/exemplo123');
    });

    test('converte coordenadas E7 em URL universal do Google Maps como fallback', () {
      final pico = Pico()
        ..localizacao = (Coordenada()
          ..latitude = -198960870
          ..longitude = -436547850);

      final url = resolverUrlGoogleMapsPico(pico);
      expect(url, 'https://www.google.com/maps/search/?api=1&query=-19.896087,-43.654785');
    });

    test('retorna nulo quando urlGoogleMaps e coordenadas estao ausentes ou zeradas', () {
      final picoVazio = Pico();
      expect(resolverUrlGoogleMapsPico(picoVazio), isNull);

      final picoZerado = Pico()
        ..localizacao = (Coordenada()
          ..latitude = 0
          ..longitude = 0);
      expect(resolverUrlGoogleMapsPico(picoZerado), isNull);

      final picoUrlEspacos = Pico()..urlGoogleMaps = '   ';
      expect(resolverUrlGoogleMapsPico(picoUrlEspacos), isNull);
    });
  });

  group('PicoCategorizedData - temConteudoExplorarLocal e temConteudoComunidade', () {
    test('temConteudoExplorarLocal retorna verdadeiro quando ha botoes de exploracao', () {
      final croqui = Croqui()
        ..botoes.add(
          Botao(texto: 'Como chegar', destino: DestinoBotao(secaoTextual: ArquivoMarkdown())),
        );
      final dados = PicoCategorizedData(croqui);
      expect(dados.temConteudoExplorarLocal(Pico()), isTrue);
    });

    test('temConteudoExplorarLocal retorna verdadeiro quando ha descricao do pico', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      final pico = Pico()..descricao = 'Historia do local de escalada';
      expect(dados.temConteudoExplorarLocal(pico), isTrue);
    });

    test('temConteudoExplorarLocal retorna verdadeiro quando ha apenas coordenadas ou link maps', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      final pico = Pico()
        ..localizacao = (Coordenada()
          ..latitude = -198960870
          ..longitude = -436547850);
      expect(dados.temConteudoExplorarLocal(pico), isTrue);
    });

    test('temConteudoExplorarLocal retorna falso quando nao ha texto nem localizacao', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      expect(dados.temConteudoExplorarLocal(Pico()), isFalse);
    });

    test('temConteudoComunidade retorna verdadeiro quando ha botoes de comunidade', () {
      final croqui = Croqui()
        ..botoes.add(
          Botao(texto: 'Patrocinadores', destino: DestinoBotao(secaoTextual: ArquivoMarkdown())),
        );
      final dados = PicoCategorizedData(croqui);
      expect(dados.temConteudoComunidade(Pico()), isTrue);
    });

    test('temConteudoComunidade retorna verdadeiro quando ha associacao local com URL', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      final pico = Pico()
        ..nomeAssociacao = 'AME'
        ..urlFiliacaoAssociacao = 'https://ame.org.br/filiar';
      expect(dados.temConteudoComunidade(pico), isTrue);
    });

    test('temConteudoComunidade retorna falso quando associacao nao tem URL ou nome', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      final pico = Pico()..nomeAssociacao = 'AME'; // sem urlFiliacaoAssociacao
      expect(dados.temConteudoComunidade(pico), isFalse);
    });

    test('temConteudoComunidade retorna falso quando croqui e pico nao tem dados de comunidade', () {
      final croqui = Croqui();
      final dados = PicoCategorizedData(croqui);
      expect(dados.temConteudoComunidade(Pico()), isFalse);
    });
  });
}
