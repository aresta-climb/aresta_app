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
      matchedGrupo = pico.setoresOuGrupos
          .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo())
          .map<Grupo?>((sg) => sg.grupo.conteudo)
          .firstWhere((g) => g?.nome == grupoNome, orElse: () => null);
    }

    if (setorNome != null) {
      if (matchedGrupo != null) {
        matchedSetor = matchedGrupo.setores
            .where((s) => s.hasConteudo())
            .map<Setor?>((s) => s.conteudo)
            .firstWhere((s) => s?.nome == setorNome, orElse: () => null);
      } else {
        matchedSetor = pico.setoresOuGrupos
            .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
            .map<Setor?>((sg) => sg.setor.conteudo)
            .firstWhere((s) => s?.nome == setorNome, orElse: () => null);

        // Fallback: search in all groups if no group was specified and setor was not found globally
        if (matchedSetor == null && grupoNome == null) {
          for (var sg in pico.setoresOuGrupos) {
            if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
              matchedSetor = sg.grupo.conteudo.setores
                  .where((s) => s.hasConteudo())
                  .map<Setor?>((s) => s.conteudo)
                  .firstWhere((s) => s?.nome == setorNome, orElse: () => null);
              
              if (matchedSetor != null) {
                matchedGrupo = sg.grupo.conteudo;
                break;
              }
            }
          }
        }
      }
    }

    if (grupoNome != null && matchedGrupo == null) {
      throw Exception('Grupo not found: "$grupoNome"');
    }

    if (setorNome != null && matchedSetor == null) {
      throw Exception('Setor not found: "$setorNome" (in grupo: "${grupoNome ?? 'global/all'}")');
    }

    if (escaladaNome != null && matchedSetor != null) {
      matchedEscalada = matchedSetor.escaladas.map<Escalada?>((e) => e).firstWhere((e) {
        if (e == null) return false;
        switch (e.whichTipo()) {
          case Escalada_Tipo.viaEsportiva:
            return e.viaEsportiva.nome == escaladaNome;
          case Escalada_Tipo.viaMovel:
            return e.viaMovel.nome == escaladaNome;
          case Escalada_Tipo.boulder:
            return e.boulder.nome == escaladaNome;
          case Escalada_Tipo.viaMultiplasEnfiadas:
            return e.viaMultiplasEnfiadas.nome == escaladaNome;
          case Escalada_Tipo.highline:
            return e.highline.nome == escaladaNome;
          default:
            return false;
        }
      }, orElse: () => null);
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
