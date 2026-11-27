// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:fuzzy/fuzzy.dart';

import '../../services/dataset/modelos/metadados_indice.dart';
import '../../services/repositorio_dataset.dart';
import '../../widgets/carrossel_picos_proximos.dart';
import '../function_library/biblioteca_funcoes_comuns.dart';
import '../function_library/funcoes_home.dart';
import 'explorar_view_model.dart';

/// Utilitário puro e sem estado para filtragem difusa, critérios de modalidade/grau
/// e ordenação do catálogo de picos em [BrowseViewModel].
abstract final class FiltradorCatalogoExplorar {
  /// Avalia se o pico [metadados] possui ao menos uma das [modalidadesAtivas] selecionadas.
  static bool atendeModalidades(
    MetadadosIndice metadados,
    Set<ModalidadeExploracaoPico> modalidadesAtivas,
  ) {
    if (modalidadesAtivas.isEmpty) return true;
    if (!metadados.hasPrecomputados()) return false;
    final p = metadados.precomputados;
    for (final mod in modalidadesAtivas) {
      switch (mod) {
        case ModalidadeExploracaoPico.esportiva:
          if (p.totalEsportivas > 0) return true;
        case ModalidadeExploracaoPico.boulder:
          if (p.totalBoulders > 0) return true;
        case ModalidadeExploracaoPico.movel:
          if (p.totalMoveis > 0) return true;
        case ModalidadeExploracaoPico.paredao:
          if (p.totalMultiplasEnfiadas > 0) return true;
        case ModalidadeExploracaoPico.highline:
          if (p.totalHighlines > 0) return true;
      }
    }
    return false;
  }

  /// Avalia se o perfil de graduação do pico [metadados] atende às faixas de via e boulder.
  static bool atendeFaixasGrau({
    required MetadadosIndice metadados,
    required Map<String, PerfilGrauPico> perfisGrauPorPico,
    required int? minGrauVia,
    required int? maxGrauVia,
    required int? minGrauBoulder,
    required int? maxGrauBoulder,
  }) {
    final filtraVia = minGrauVia != null || maxGrauVia != null;
    final filtraBld = minGrauBoulder != null || maxGrauBoulder != null;
    if (!filtraVia && !filtraBld) return true;

    final perfil = perfisGrauPorPico[metadados.id] ??
        (metadados.croquiUid.isNotEmpty
            ? perfisGrauPorPico[metadados.croquiUid]
            : null);
    if (perfil == null) return false;

    if (filtraVia && !filtraBld) {
      return perfil.atendeIntervaloVia(minGrauVia, maxGrauVia);
    }
    if (filtraBld && !filtraVia) {
      return perfil.atendeIntervaloBoulder(minGrauBoulder, maxGrauBoulder);
    }
    return perfil.atendeIntervaloVia(minGrauVia, maxGrauVia) ||
        perfil.atendeIntervaloBoulder(minGrauBoulder, maxGrauBoulder);
  }

