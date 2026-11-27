// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/view/view_models/filtrador_catalogo_explorar.dart';
import 'package:frontend/widgets/carrossel_picos_proximos.dart';

void main() {
  MetadadosIndice criarPico({
    required String id,
    required String nome,
    String croquiUid = '',
    String pastaLocal = 'belo_horizonte',
    PrecomputadosResumoCroqui? precomputados,
  }) {
    final resumo = ResumoCroqui(
      id: id,
      nome: nome,
      croquiUid: croquiUid,
      caminhoRelativo: 'mg/$pastaLocal/compilado.binarypb',
    );
    if (precomputados != null) {
      resumo.precomputados = precomputados;
    }
    return resumo;
  }

  group('FiltradorCatalogoExplorar', () {
    test('avalia modalidades isoladas, combinadas e ausência de precomputados', () {
      final semPrecomp = criarPico(id: 'p0', nome: 'Sem Precomp');
      expect(
        FiltradorCatalogoExplorar.atendeModalidades(semPrecomp, const {}),
        isTrue,
      );
      expect(
        FiltradorCatalogoExplorar.atendeModalidades(
          semPrecomp,
          const {ModalidadeExploracaoPico.esportiva},
        ),
        isFalse,
      );

      final completo = criarPico(
        id: 'p1',
        nome: 'Completo',
        precomputados: PrecomputadosResumoCroqui(
          totalEsportivas: 4,
          totalBoulders: 2,
          totalMoveis: 1,
          totalMultiplasEnfiadas: 3,
          totalHighlines: 1,
        ),
      );
      for (final mod in ModalidadeExploracaoPico.values) {
        expect(
          FiltradorCatalogoExplorar.atendeModalidades(completo, {mod}),
          isTrue,
        );
      }

      final zerado = criarPico(
        id: 'p2',
        nome: 'Zerado',
        precomputados: PrecomputadosResumoCroqui(),
      );
      expect(
        FiltradorCatalogoExplorar.atendeModalidades(
          zerado,
          ModalidadeExploracaoPico.values.toSet(),
        ),
        isFalse,
      );
    });

    test('avalia faixas de grau de via, boulder, misto e resolução por croquiUid', () {
      final porId = criarPico(id: 'id_1', nome: 'Pico 1');
      final porUid = criarPico(
        id: 'slug_sem_chave',
        croquiUid: 'uid_2',
        nome: 'Pico 2',
      );
      final semPerfil = criarPico(id: 'orfao', nome: 'Órfão');

      const perfis = <String, PerfilGrauPico>{
        'id_1': PerfilGrauPico(contagemPorPesoVia: {760: 3}),
        'uid_2': PerfilGrauPico(contagemPorPesoBoulder: {500: 2}),
      };

      expect(
        FiltradorCatalogoExplorar.atendeFaixasGrau(
          metadados: semPerfil,
          perfisGrauPorPico: perfis,
          minGrauVia: null,
          maxGrauVia: null,
          minGrauBoulder: null,
          maxGrauBoulder: null,
        ),
        isTrue,
      );
      expect(
        FiltradorCatalogoExplorar.atendeFaixasGrau(
          metadados: semPerfil,
          perfisGrauPorPico: perfis,
          minGrauVia: 700,
          maxGrauVia: 800,
          minGrauBoulder: null,
          maxGrauBoulder: null,
        ),
        isFalse,
      );
      expect(
        FiltradorCatalogoExplorar.atendeFaixasGrau(
          metadados: porId,
          perfisGrauPorPico: perfis,
          minGrauVia: 750,
          maxGrauVia: 800,
          minGrauBoulder: null,
          maxGrauBoulder: null,
        ),
        isTrue,
      );
      expect(
        FiltradorCatalogoExplorar.atendeFaixasGrau(
          metadados: porUid,
          perfisGrauPorPico: perfis,
          minGrauVia: null,
          maxGrauVia: null,
          minGrauBoulder: 400,
          maxGrauBoulder: 600,
        ),
        isTrue,
      );
      expect(
        FiltradorCatalogoExplorar.atendeFaixasGrau(
          metadados: porUid,
          perfisGrauPorPico: perfis,
          minGrauVia: 900,
          maxGrauVia: 950,
          minGrauBoulder: 400,
          maxGrauBoulder: 600,
        ),
        isTrue,
      );
    });

    test('executa busca difusa e ordena por proximidade, alfabético e volume de escaladas', () {
      final pA = criarPico(
        id: 'a',
        nome: 'Serra do Cipó',
        pastaLocal: 'santana_do_riacho',
        precomputados: PrecomputadosResumoCroqui(totalEscaladas: 40),
      );
      final pB = criarPico(
        id: 'b',
        nome: 'Pedra Grande',
        pastaLocal: 'igarape',
        precomputados: PrecomputadosResumoCroqui(totalEscaladas: 90),
      );
      final pC = criarPico(
        id: 'c',
        nome: 'Andorinhas',
        pastaLocal: 'ouro_preto',
        precomputados: PrecomputadosResumoCroqui(totalEscaladas: 90),
      );

      final todos = [pA, pB, pC];
      expect(
        FiltradorCatalogoExplorar.filtrarPorBuscaDifusa(todos, ''),
        hasLength(3),
      );
      expect(
        FiltradorCatalogoExplorar.filtrarPorBuscaDifusa(todos, 'cipo').single.id,
        equals('a'),
      );

      expect(
        FiltradorCatalogoExplorar.ordenarPicosFiltrados(
          itens: [...todos],
          ordem: OrdemOrdenacaoPico.proximidade,
          proximidadePorId: const {},
        ).map((m) => m.id),
        equals(['c', 'b', 'a']),
      );

      final proximidades = <String, PicoProximo>{
        'b': PicoProximo(pico: pB, distanciaKm: 42.0),
        'a': PicoProximo(pico: pA, distanciaKm: 98.0),
      };
      expect(
        FiltradorCatalogoExplorar.ordenarPicosFiltrados(
          itens: [...todos],
          ordem: OrdemOrdenacaoPico.proximidade,
          proximidadePorId: proximidades,
        ).map((m) => m.id),
        equals(['b', 'a', 'c']),
      );

      expect(
        FiltradorCatalogoExplorar.ordenarPicosFiltrados(
          itens: [...todos],
          ordem: OrdemOrdenacaoPico.alfabetico,
          proximidadePorId: proximidades,
        ).map((m) => m.id),
        equals(['c', 'b', 'a']),
      );

      expect(
        FiltradorCatalogoExplorar.ordenarPicosFiltrados(
          itens: [...todos],
          ordem: OrdemOrdenacaoPico.escaladas,
          proximidadePorId: proximidades,
        ).map((m) => m.id),
        equals(['c', 'b', 'a']),
      );
    });
  });
}
