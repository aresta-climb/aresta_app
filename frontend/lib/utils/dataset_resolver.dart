import '../aresta_api/proto/generated/croqui.pb.dart';

class ResolvedDataset {
  final Grupo? grupo;
  final Setor? setor;
  final Escalada? escalada;

  ResolvedDataset({this.grupo, this.setor, this.escalada});
}

extension MapaReferenciaExtension on Mapa_Referencia {
  String get nome {
    if (escalada.isNotEmpty) return escalada;
    if (setor.isNotEmpty) return setor;
    if (grupo.isNotEmpty) return grupo;
    return '';
  }
}

class DatasetResolver {
  static ResolvedDataset resolve({
    required Pico pico,
    String? grupoNome,
    String? setorNome,
    String? escaladaNome,
  }) {
    Grupo? matchedGrupo;
    Setor? matchedSetor;
    Escalada? matchedEscalada;

    if (grupoNome != null) {
      try {
        matchedGrupo = pico.setoresOuGrupos
            .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo())
            .map((sg) => sg.grupo.conteudo)
            .firstWhere((g) => g.nome == grupoNome);
      } catch (_) {}
    }

    if (setorNome != null) {
      if (matchedGrupo != null) {
        try {
          matchedSetor = matchedGrupo.setores
              .where((s) => s.hasConteudo())
              .map((s) => s.conteudo)
              .firstWhere((s) => s.nome == setorNome);
        } catch (_) {}
      } else {
        try {
          matchedSetor = pico.setoresOuGrupos
              .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
              .map((sg) => sg.setor.conteudo)
              .firstWhere((s) => s.nome == setorNome);
        } catch (_) {
          // Fallback: search in all groups if no group was specified
          for (var sg in pico.setoresOuGrupos) {
            if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
              try {
                matchedSetor = sg.grupo.conteudo.setores
                    .where((s) => s.hasConteudo())
                    .map((s) => s.conteudo)
                    .firstWhere((s) => s.nome == setorNome);
                if (matchedSetor != null) break;
              } catch (_) {}
            }
          }
        }
      }
    }

    if (escaladaNome != null && matchedSetor != null) {
      try {
        matchedEscalada = matchedSetor.escaladas.firstWhere((e) {
          if (e.hasViaEsportiva()) return e.viaEsportiva.nome == escaladaNome;
          if (e.hasViaMovel()) return e.viaMovel.nome == escaladaNome;
          if (e.hasBoulder()) return e.boulder.nome == escaladaNome;
          if (e.hasViaMultiplasEnfiadas()) return e.viaMultiplasEnfiadas.nome == escaladaNome;
          if (e.hasHighline()) return e.highline.nome == escaladaNome;
          return false;
        });
      } catch (_) {}
    }

    // If a target was requested but not found, we throw to signal an invalid reference
    if (grupoNome != null && matchedGrupo == null) {
      throw Exception('Grupo not found');
    }
    if (setorNome != null && matchedSetor == null) {
      throw Exception('Setor not found');
    }
    if (escaladaNome != null && matchedEscalada == null) {
      throw Exception('Escalada not found');
    }

    return ResolvedDataset(
      grupo: matchedGrupo,
      setor: matchedSetor,
      escalada: matchedEscalada,
    );
  }

  static ResolvedDataset resolveReferencia({
    required Pico pico,
    required Mapa_Referencia referencia,
    String? defaultGrupoNome,
    String? defaultSetorNome,
  }) {
    String? resolveGrupo = referencia.grupo.isNotEmpty ? referencia.grupo : null;
    String? resolveSetor = referencia.setor.isNotEmpty ? referencia.setor : null;
    String? resolveEscalada = referencia.escalada.isNotEmpty ? referencia.escalada : null;

    if (resolveEscalada != null && resolveSetor == null) {
      resolveSetor = defaultSetorNome;
      if (resolveGrupo == null) {
        resolveGrupo = defaultGrupoNome;
      }
    } else if (resolveSetor != null && resolveGrupo == null) {
       resolveGrupo = defaultGrupoNome;
    }

    if (resolveGrupo == null && resolveSetor == null && resolveEscalada == null) {
      throw Exception('Reference is empty');
    }

    return resolve(
      pico: pico,
      grupoNome: resolveGrupo,
      setorNome: resolveSetor,
      escaladaNome: resolveEscalada,
    );
  }
}
