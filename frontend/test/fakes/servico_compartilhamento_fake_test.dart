// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/dados_cartao_compartilhamento.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../mocks/mock_telemetria.dart';
import 'servico_compartilhamento_fake.dart';

void main() {
  group('ServicoCompartilhamentoFake', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    test('registra deterministicamente links, imagens PNG e entradas do clipboard', () async {
      final fake = ServicoCompartilhamentoFake();
      const dados = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.via,
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        titulo: 'Aresta Clássica',
        subtituloLocalizacao: 'Pedra Grande • Setor Principal',
        etiquetaCategoria: 'ESPORTIVA',
        nomePico: 'Pedra Grande',
        nomeSetor: 'Setor Principal',
        grauDestaque: '6ºsup',
      );

      await fake.compartilharLinkPorDados(dados);
      expect(fake.textosCompartilhados, hasLength(1));
      expect(
        fake.textosCompartilhados.single,
        contains('https://aresta.cc/s/x8siJek3FiG3aB'),
      );

      final bytes = await fake.capturarCartaoFake(GlobalKey());
      final urlRetornada = await fake.compartilharImagemStories(
        dados: dados,
        bytesPng: bytes,
      );

      expect(urlRetornada, 'https://aresta.cc/s/x8siJek3FiG3aB');
      expect(
        fake.textosCopiadosClipboard,
        equals(['https://aresta.cc/s/x8siJek3FiG3aB']),
      );
      expect(fake.imagensCompartilhadas, hasLength(1));
      expect(
        fake.imagensCompartilhadas.single.nomeArquivo,
        'aresta_via_x8siJek3FiG3aB.png',
      );
      expect(fake.imagensCompartilhadas.single.bytesPng, equals(bytes));
    });

    test('simula falha determinística quando simularErroCompartilhamento está ativo', () async {
      final fake = ServicoCompartilhamentoFake(
        simularErroCompartilhamento: true,
      );
      const dados = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.pico,
        idCroqui: 'crag1',
        uid: 'uidPico1234567',
        titulo: 'Pico Teste',
        subtituloLocalizacao: 'MG',
        etiquetaCategoria: 'PICO DE ESCALADA',
        nomePico: 'Pico Teste',
      );

      await expectLater(
        () => fake.compartilharLinkPorDados(dados),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => fake.compartilharImagemStories(
          dados: dados,
          bytesPng: ServicoCompartilhamentoFake.pngMinimoValido,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
