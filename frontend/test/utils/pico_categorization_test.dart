import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/pico_categorization.dart';

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
  });
}
