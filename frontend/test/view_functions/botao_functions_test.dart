import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/view_functions/mapa_geral_pico_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('Botao/Secao Textual helper functions', () {
    test('getSecaoBotoes deve filtrar apenas botões com destino de seção textual', () {
      final b1 = Botao()
        ..texto = 'Capa'
        ..destino = (DestinoBotao()..secaoTextual = ArquivoMarkdown());
      
      final b2 = Botao()
        ..texto = 'Sem destino';
      
      final croqui = Croqui()..botoes.addAll([b1, b2]);
      
      final result = getSecaoBotoes(croqui);
      expect(result.length, 1);
      expect(result.first.texto, 'Capa');
    });

    test('getCapaBotoes deve filtrar apenas botões com "capa" no texto (case-insensitive)', () {
      final b1 = Botao()..texto = 'Capa do Pico';
      final b2 = Botao()..texto = 'capa principal';
      final b3 = Botao()..texto = 'Outro botão';
      
      final result = getCapaBotoes([b1, b2, b3]);
      expect(result.length, 2);
      expect(result, containsAll([b1, b2]));
    });

    test('getOtherBotoes deve retornar apenas botões que não são de capa', () {
      final b1 = Botao()..texto = 'Capa do Pico';
      final b2 = Botao()..texto = 'Regras de Acesso';
      final b3 = Botao()..texto = 'Outro botão';
      
      final result = getOtherBotoes([b1, b2, b3]);
      expect(result.length, 2);
      expect(result, containsAll([b2, b3]));
    });
  });

  group('getMapaGeralMarkdown', () {
    test('deve retornar "Mapa não encontrado." se croqui não tem botões', () {
      final croqui = Croqui();
      final result = getMapaGeralMarkdown(croqui);
      expect(result.conteudo, 'Mapa não encontrado.');
    });

    test('deve retornar capa com palavra "mapa" no texto do botão', () {
      final mdCapa = ArquivoMarkdown()..conteudo = 'Este é o conteúdo da capa';
      final mdInfo = ArquivoMarkdown()..conteudo = 'Este é o conteúdo informativo';
      
      final croqui = Croqui()
        ..botoes.addAll([
          Botao()
            ..texto = 'Capa e Mapa Geral'
            ..destino = (DestinoBotao()..secaoTextual = mdCapa),
          Botao()
            ..texto = 'Informações'
            ..destino = (DestinoBotao()..secaoTextual = mdInfo),
        ]);

      final result = getMapaGeralMarkdown(croqui);
      expect(result, mdCapa);
    });

    test('deve retornar capa com palavra "mapa" no conteúdo do markdown', () {
      final mdCapa = ArquivoMarkdown()..conteudo = 'Aqui temos o mapa do local';
      final mdInfo = ArquivoMarkdown()..conteudo = 'Outro texto qualquer';
      
      final croqui = Croqui()
        ..botoes.addAll([
          Botao()
            ..texto = 'Capa'
            ..destino = (DestinoBotao()..secaoTextual = mdCapa),
          Botao()
            ..texto = 'Informações'
            ..destino = (DestinoBotao()..secaoTextual = mdInfo),
        ]);

      final result = getMapaGeralMarkdown(croqui);
      expect(result, mdCapa);
    });

    test('deve retornar outro botão com palavra "mapa" se capa não tiver', () {
      final mdCapa = ArquivoMarkdown()..conteudo = 'Capa simples';
      final mdMapa = ArquivoMarkdown()..conteudo = 'Mapa de acesso e setores';
      
      final croqui = Croqui()
        ..botoes.addAll([
          Botao()
            ..texto = 'Capa'
            ..destino = (DestinoBotao()..secaoTextual = mdCapa),
          Botao()
            ..texto = 'Como Chegar (Mapa)'
            ..destino = (DestinoBotao()..secaoTextual = mdMapa),
        ]);

      final result = getMapaGeralMarkdown(croqui);
      expect(result, mdMapa);
    });

    test('deve retornar "Mapa não encontrado." se nenhum botão tiver a palavra "mapa"', () {
      final mdCapa = ArquivoMarkdown()..conteudo = 'Capa simples';
      final mdInfo = ArquivoMarkdown()..conteudo = 'Informações gerais';
      
      final croqui = Croqui()
        ..botoes.addAll([
          Botao()
            ..texto = 'Capa'
            ..destino = (DestinoBotao()..secaoTextual = mdCapa),
          Botao()
            ..texto = 'Regras'
            ..destino = (DestinoBotao()..secaoTextual = mdInfo),
        ]);

      final result = getMapaGeralMarkdown(croqui);
      expect(result.conteudo, 'Mapa não encontrado.');
    });
  });
}
