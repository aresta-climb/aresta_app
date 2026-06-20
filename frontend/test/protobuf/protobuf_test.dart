/// Testes de serialização e desserialização Protobuf.
/// Verifica que os objetos podem ser convertidos em bytes e recuperados com fidelidade.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Indice protobuf
  // ---------------------------------------------------------------------------

  group('Indice protobuf', () {
    test('deve serializar e desserializar sem perda de dados', () {
      final resumo = ResumoCroqui()
        ..id = 'pedra_bonita'
        ..nome = 'Pedra Bonita'
        ..caminhoRelativo = 'downloads/pedra_bonita/pedra_bonita.binarypb'
        ..checksumSha256Croqui = 'abc123checksum';

      final indice = Indice()..croquis.add(resumo);
      final bytes = indice.writeToBuffer();

      final restored = Indice.fromBuffer(bytes);

      expect(restored.croquis.length, 1);
      expect(restored.croquis.first.id, 'pedra_bonita');
      expect(restored.croquis.first.nome, 'Pedra Bonita');
      expect(restored.croquis.first.caminhoRelativo, 'downloads/pedra_bonita/pedra_bonita.binarypb');
      expect(restored.croquis.first.checksumSha256Croqui, 'abc123checksum');
    });

    test('deve suportar múltiplos croquis no índice', () {
      final indice = Indice();
      for (int i = 0; i < 5; i++) {
        indice.croquis.add(ResumoCroqui()
          ..id = 'pico_$i'
          ..nome = 'Pico $i');
      }

      final restored = Indice.fromBuffer(indice.writeToBuffer());
      expect(restored.croquis.length, 5);
      expect(restored.croquis[2].id, 'pico_2');
    });

    test('deve criar Indice vazio sem erros', () {
      final indice = Indice();
      final bytes = indice.writeToBuffer();
      final restored = Indice.fromBuffer(bytes);
      expect(restored.croquis, isEmpty);
    });

    test('dois Indice com o mesmo conteúdo devem ter bytes iguais', () {
      ResumoCroqui makeResumo() => ResumoCroqui()
        ..id = 'id_teste'
        ..nome = 'Teste';

      final a = Indice()..croquis.add(makeResumo());
      final b = Indice()..croquis.add(makeResumo());

      expect(a.writeToBuffer(), b.writeToBuffer());
    });
  });

  // ---------------------------------------------------------------------------
  // Croqui protobuf
  // ---------------------------------------------------------------------------

  group('Croqui protobuf', () {
    test('deve serializar e desserializar nome corretamente', () {
      final croqui = Croqui()..nome = 'Pedra da Gávea';
      final restored = Croqui.fromBuffer(croqui.writeToBuffer());
      expect(restored.nome, 'Pedra da Gávea');
    });

    test('deve serializar caminhoThumbnail corretamente', () {
      final croqui = Croqui()
        ..nome = 'Teste'
        ..caminhoThumbnail = 'imagens/thumb.webp';

      final restored = Croqui.fromBuffer(croqui.writeToBuffer());
      expect(restored.hasCaminhoThumbnail(), isTrue);
      expect(restored.caminhoThumbnail, 'imagens/thumb.webp');
    });

    test('hasCaminhoThumbnail deve ser false quando não definido', () {
      final croqui = Croqui()..nome = 'Sem Thumb';
      expect(croqui.hasCaminhoThumbnail(), isFalse);
    });

    test('deve serializar arquivo markdown corretamente', () {
      final md = ArquivoMarkdown()
        ..conteudo = '![foto](imagens/capa.webp)';
      final botao = Botao()
        ..texto = 'Capa'
        ..destino = (DestinoBotao()..secaoTextual = md);

      final croqui = Croqui()..botoes.add(botao);
      final restored = Croqui.fromBuffer(croqui.writeToBuffer());

      expect(restored.botoes.length, 1);
      expect(restored.botoes.first.texto, 'Capa');
      expect(restored.botoes.first.destino.secaoTextual.conteudo, '![foto](imagens/capa.webp)');
    });

    test('deve serializar arquivo externo corretamente', () {
      final ext = ArquivoExterno()
        ..caminho = 'imagens/foto.webp'
        ..checksumSha256 = 'sha256abc';

      final croqui = Croqui()..arquivosExternos.add(ext);
      final restored = Croqui.fromBuffer(croqui.writeToBuffer());

      expect(restored.arquivosExternos.length, 1);
      expect(restored.arquivosExternos.first.caminho, 'imagens/foto.webp');
      expect(restored.arquivosExternos.first.checksumSha256, 'sha256abc');
    });

    test('Croqui vazio não deve ter campos opcionais definidos', () {
      final croqui = Croqui();
      expect(croqui.hasCaminhoThumbnail(), isFalse);
      expect(croqui.botoes, isEmpty);
      expect(croqui.arquivosExternos, isEmpty);
      expect(croqui.picos, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Escalada enum
  // ---------------------------------------------------------------------------

  group('Escalada oneof tipo', () {
    test('deve identificar boulder corretamente via whichTipo()', () {
      final escalada = Escalada()..boulder = Boulder();
      expect(escalada.whichTipo(), Escalada_Tipo.boulder);
    });

    test('deve identificar viaEsportiva corretamente via whichTipo()', () {
      final escalada = Escalada()..viaEsportiva = ViaEsportiva();
      expect(escalada.whichTipo(), Escalada_Tipo.viaEsportiva);
    });

    test('deve identificar viaMovel corretamente via whichTipo()', () {
      final escalada = Escalada()..viaMovel = ViaMovel();
      expect(escalada.whichTipo(), Escalada_Tipo.viaMovel);
    });

    test('deve ser notSet quando criado sem tipo', () {
      final escalada = Escalada();
      expect(escalada.whichTipo(), Escalada_Tipo.notSet);
    });

    test('boulder deve serializar e desserializar corretamente', () {
      final escalada = Escalada()..boulder = (Boulder()..nome = 'Problemão');
      final restored = Escalada.fromBuffer(escalada.writeToBuffer());

      expect(restored.whichTipo(), Escalada_Tipo.boulder);
      expect(restored.boulder.nome, 'Problemão');
    });

    test('viaEsportiva deve serializar extensão em metros', () {
      final via = ViaEsportiva()
        ..nome = 'Via do Teste'
        ..extensao = 25;

      final escalada = Escalada()..viaEsportiva = via;
      final restored = Escalada.fromBuffer(escalada.writeToBuffer());

      expect(restored.viaEsportiva.nome, 'Via do Teste');
      expect(restored.viaEsportiva.extensao, 25);
    });
  });

  // ---------------------------------------------------------------------------
  // ResumoCroqui campos
  // ---------------------------------------------------------------------------

  group('ResumoCroqui', () {
    test('deve ter todos os campos após serialização', () {
      final resumo = ResumoCroqui()
        ..id = 'meu_pico'
        ..nome = 'Meu Pico'
        ..caminhoRelativo = 'picos/meu_pico/meu_pico.binarypb'
        ..checksumSha256Croqui = 'checksum123';

      final restored = ResumoCroqui.fromBuffer(resumo.writeToBuffer());

      expect(restored.id, 'meu_pico');
      expect(restored.nome, 'Meu Pico');
      expect(restored.caminhoRelativo, 'picos/meu_pico/meu_pico.binarypb');
      expect(restored.checksumSha256Croqui, 'checksum123');
    });

    test('checksum diferente após alteração deve ser detectado', () {
      final original = ResumoCroqui()
        ..id = 'pico'
        ..checksumSha256Croqui = 'versao1';

      final atualizado = ResumoCroqui()
        ..id = 'pico'
        ..checksumSha256Croqui = 'versao2';

      expect(original.checksumSha256Croqui, isNot(atualizado.checksumSha256Croqui));
    });
  });
}
