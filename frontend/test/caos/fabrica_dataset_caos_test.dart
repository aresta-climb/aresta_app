// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'fabrica_dataset_caos.dart';
import 'receita_crash_robo.dart';

void main() {
  group('FabricaDatasetCaos', () {
    test(
      'Constrói estado determinístico para TipoDatasetCaos.normal com picos baixados, online e cadenas válidas',
      () {
        final estado = FabricaDatasetCaos.construir(TipoDatasetCaos.normal);

        expect(estado.conjuntoDados.picosBaixados, isNotEmpty);
        expect(estado.conjuntoDados.picosDisponiveis, isNotEmpty);
        expect(estado.cadenasIniciais, isNotEmpty);

        final primeiroPico = estado.conjuntoDados.picosBaixados.first;
        expect(primeiroPico.pico, isNotNull);
        expect(primeiroPico.croqui, isNotNull);
        expect(primeiroPico.pico!.setoresOuGrupos, isNotEmpty);
      },
    );

    test(
      'Constrói estado de estresse para TipoDatasetCaos.toxico com picos vazios, textos de 300+ caracteres, Markdown limite, alto volume de vias e cadenas órfãs',
      () {
        final estado = FabricaDatasetCaos.construir(TipoDatasetCaos.toxico);

        final todosPicos = [
          ...estado.conjuntoDados.picosBaixados,
          ...estado.conjuntoDados.picosDisponiveis,
        ];
        expect(todosPicos.length, greaterThanOrEqualTo(4));

        // 1. Pico degenerado sem setores e sem vias
        final picoVazio = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_vazio',
        );
        expect(picoVazio.pico!.setoresOuGrupos, isEmpty);

        // 2. Pico com textos gigantes (300+ caracteres), emojis e tags <small>
        final picoTextoExtremo = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_texto_extremo',
        );
        expect(picoTextoExtremo.nome.length, greaterThanOrEqualTo(300));
        expect(picoTextoExtremo.descricao, contains('<small>'));

        // 3. Pico de alto volume com dezenas de vias e graus exóticos/vazios
        final picoVolume = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_alto_volume',
        );
        final setorVolume =
            picoVolume.pico!.setoresOuGrupos.first.setor.conteudo;
        expect(setorVolume.escaladas.length, greaterThanOrEqualTo(50));

        // 4. Cadenas órfãs apontando para UID inexistente no catálogo
        expect(
          estado.cadenasIniciais.any(
            (c) => c.escaladaUid == 'uid_orfao_4040',
          ),
          isTrue,
        );
      },
    );
  });
}
