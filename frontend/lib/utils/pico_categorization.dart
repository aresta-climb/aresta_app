import '../aresta_api/proto/generated/croqui.pb.dart';

enum TextCategory {
  explorarSobre,
  explorarComoChegar,
  regras,
  comunidadeParceiros,
  comunidadeComercio,
  comunidadeInfo,
  apoioProdutos,
  outros
}

TextCategory categorizeBotao(Botao b) {
  final text = b.texto.toLowerCase();
  
  if (text.contains('sobre') || text.contains('história') || text.contains('historia')) {
    return TextCategory.explorarSobre;
  }
  if (text.contains('chegar') || text.contains('acesso') || text.contains('trilha')) {
    return TextCategory.explorarComoChegar;
  }
  if (text.contains('regras') || text.contains('preservação') || text.contains('ética') || text.contains('etica') || text.contains('conduta')) {
    return TextCategory.regras;
  }
  if (text.contains('parceiros') || text.contains('patrocinador')) {
    return TextCategory.comunidadeParceiros;
  }
  if (text.contains('comércio') || text.contains('comercio') || text.contains('hospedagem') || text.contains('pousada')) {
    return TextCategory.comunidadeComercio;
  }
  if (text.contains('notícia') || text.contains('noticia') || text.contains('associação')) {
    return TextCategory.comunidadeInfo;
  }
  if (text.contains('produto') || text.contains('camisa') || text.contains('guia físico')) {
    return TextCategory.apoioProdutos;
  }
  
  return TextCategory.outros;
}

class PicoCategorizedData {
  final List<Botao> sobre = [];
  final List<Botao> comoChegar = [];
  final List<Botao> regras = [];
  final List<Botao> comunidadeParceiros = [];
  final List<Botao> comunidadeComercio = [];
  final List<Botao> comunidadeInfo = [];
  final List<Botao> apoioProdutos = [];
  final List<Botao> outros = [];
  
  PicoCategorizedData(Croqui croqui) {
    final botoes = croqui.botoes.where((b) => b.hasDestino() && b.destino.hasSecaoTextual()).toList();
    
    for (var b in botoes) {
      final cat = categorizeBotao(b);
      switch (cat) {
        case TextCategory.explorarSobre: sobre.add(b); break;
        case TextCategory.explorarComoChegar: comoChegar.add(b); break;
        case TextCategory.regras: regras.add(b); break;
        case TextCategory.comunidadeParceiros: comunidadeParceiros.add(b); break;
        case TextCategory.comunidadeComercio: comunidadeComercio.add(b); break;
        case TextCategory.comunidadeInfo: comunidadeInfo.add(b); break;
        case TextCategory.apoioProdutos: apoioProdutos.add(b); break;
        case TextCategory.outros: outros.add(b); break;
      }
    }
  }
}
