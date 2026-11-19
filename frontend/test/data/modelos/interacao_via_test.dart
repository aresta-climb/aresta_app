// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';

void main() {
  group('CategoriaAlertaSeguranca', () {
    test('mapeia códigos canônicos do banco de dados, emojis e rótulos em português', () {
      expect(CategoriaAlertaSeguranca.abelhasInsetos.codigoBanco, 'ABELHAS_INSETOS');
      expect(CategoriaAlertaSeguranca.abelhasInsetos.emoji, '🐝');
      expect(CategoriaAlertaSeguranca.abelhasInsetos.rotulo, 'Abelhas ou Insetos');

      expect(
        CategoriaAlertaSeguranca.rochaAgarraInstavel.codigoBanco,
        'ROCHA_AGARRA_INSTAVEL',
      );
      expect(CategoriaAlertaSeguranca.rochaAgarraInstavel.emoji, '🪨');

      expect(
        CategoriaAlertaSeguranca.protecaoPrecaria.codigoBanco,
        'PROTECAO_PRECARIA',
      );
      expect(CategoriaAlertaSeguranca.protecaoPrecaria.emoji, '🔩');

      expect(CategoriaAlertaSeguranca.viaMolhada.codigoBanco, 'VIA_MOLHADA');
      expect(CategoriaAlertaSeguranca.viaMolhada.emoji, '💧');

      expect(
        CategoriaAlertaSeguranca.riscoExposicao.codigoBanco,
        'RISCO_EXPOSICAO',
      );
      expect(CategoriaAlertaSeguranca.riscoExposicao.emoji, '⚠️');

      for (final cat in CategoriaAlertaSeguranca.values) {
        expect(
          CategoriaAlertaSeguranca.deCodigoBanco(cat.codigoBanco),
          equals(cat),
        );
        expect(cat.descricaoCurta, isNotEmpty);
      }

      expect(
        () => CategoriaAlertaSeguranca.deCodigoBanco('CODIGO_DESCONHECIDO'),
        throwsArgumentError,
      );
    });
  });

  group('AlertaSegurancaVia', () {
    test('cria alerta validando NanoID 14c, normaliza detalhe e suporta copyWith', () {
      final agora = DateTime.utc(2026, 11, 19, 12, 0);
      final alerta = AlertaSegurancaVia.criar(
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.abelhasInsetos,
        detalhe: '  Enxame próximo à terceira chapeleta  ',
        autorNomePublico: 'Mariana Silva',
        criadoEm: agora,
      );

      expect(alerta.uid.length, 14);
      expect(alerta.escaladaUid, 'x8siJek3FiG3aB');
      expect(alerta.categoria, CategoriaAlertaSeguranca.abelhasInsetos);
      expect(alerta.detalhe, 'Enxame próximo à terceira chapeleta');
      expect(alerta.autorNomePublico, 'Mariana Silva');
      expect(alerta.criadoEm, agora);
      expect(alerta.confirmacoesAtivas, 1);

      final confirmado = alerta.copyWith(
        confirmacoesAtivas: 3,
        detalhe: 'Atualizado',
      );
      expect(confirmado.uid, alerta.uid);
      expect(confirmado.confirmacoesAtivas, 3);
      expect(confirmado.detalhe, 'Atualizado');

      final apenasDetalhe = confirmado.copyWith(detalhe: 'Novo detalhe');
      expect(apenasDetalhe.confirmacoesAtivas, 3);
      expect(apenasDetalhe.detalhe, 'Novo detalhe');

      final semDetalhe = AlertaSegurancaVia.criar(
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.viaMolhada,
        detalhe: '   ',
      );
      expect(semDetalhe.detalhe, isNull);
      expect(semDetalhe.autorNomePublico, 'Escalador Aresta');
    });

    test('rejeita detalhe de alerta acima de 100 caracteres', () {
      expect(
        () => AlertaSegurancaVia.criar(
          escaladaUid: 'x8siJek3FiG3aB',
          categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
          detalhe: 'a' * 101,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ConsensoGrauVia', () {
    test('calcula resumo percentual dominante para deltas positivos, negativos e grau justo', () {
      const consensoMaisDificil = ConsensoGrauVia(
        grauSugerido: '7b',
        totalVotos: 20,
        distribuicaoDeltas: {-1: 1, 0: 4, 1: 15},
      );
      expect(consensoMaisDificil.possuiVotos, isTrue);
      expect(consensoMaisDificil.resumoTendencia, '75% sugerem +1');

      const consensoMaisFacil = ConsensoGrauVia(
        grauSugerido: '6ºsup',
        totalVotos: 10,
        distribuicaoDeltas: {-1: 6, 0: 4},
      );
      expect(consensoMaisFacil.resumoTendencia, '60% sugerem -1');

      const consensoJusto = ConsensoGrauVia(
        grauSugerido: '7a',
        totalVotos: 8,
        distribuicaoDeltas: {0: 6, 1: 2},
      );
      expect(consensoJusto.resumoTendencia, '75% confirmam o grau');

      const semVotos = ConsensoGrauVia.vazio();
      expect(semVotos.possuiVotos, isFalse);
      expect(semVotos.resumoTendencia, isNull);
    });
  });

  group('ComentarioComunidadeVia e DadosComunidadeVia', () {
    test('armazena metadados públicos imutáveis e agrega estado comunitário da via', () {
      final data = DateTime.utc(2026, 11, 18, 9, 30);
      final comentario = ComentarioComunidadeVia(
        uid: 'm8Kq2L1x9Y7zWq',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Carlos Lagartixa',
        criadoEm: data,
        estiloAscensao: TipoAscensao.flash,
        texto: 'Costura 4 fica tranquila se clipar da orelha à esquerda.',
      );

      expect(comentario.rotuloEstilo, 'FLASH ★');

      final comentarioTrabalhado = ComentarioComunidadeVia(
        uid: 'n9Lr3M2y8Z6xVp',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Ana',
        criadoEm: data,
        estiloAscensao: TipoAscensao.trabalhado,
        texto: 'Crux técnico de pé.',
      );
      expect(comentarioTrabalhado.rotuloEstilo, 'TRABALHADO');

      final comentarioSemEstilo = ComentarioComunidadeVia(
        uid: 'p1Ms4N3z7A5wUo',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Pedro',
        criadoEm: data,
        texto: ' Boa sombra à tarde. ',
      );
      expect(comentarioSemEstilo.rotuloEstilo, isNull);
      expect(comentarioSemEstilo.texto, 'Boa sombra à tarde.');

      expect(
        () => ComentarioComunidadeVia(
          uid: 'p1Ms4N3z7A5wUo',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          autorNomePublico: 'Pedro',
          criadoEm: data,
          texto: '   ',
        ),
        throwsArgumentError,
      );

      const vazio = DadosComunidadeVia.vazio();
      expect(vazio.alertasAtivos, isEmpty);
      expect(vazio.comentarios, isEmpty);
      expect(vazio.consensoGrau.possuiVotos, isFalse);

      final preenchido = vazio.copyWith(comentarios: [comentario]);
      expect(preenchido.comentarios, hasLength(1));
      expect(preenchido.consensoGrau.possuiVotos, isFalse);
    });
  });
}
