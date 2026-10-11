// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

/// Utilitário de normalização in-place para modelos de dados de croqui.
///
/// Garante que instâncias de [Croqui] e [Pico] carregadas a partir de versões
/// legadas da API tenham todos os campos da especificação v5 populados
/// diretamente na memória:
/// - UIDs sintéticos canônicos para [Grupo], [Setor] e [Escalada] que não possuam UID.
/// - Cópia de `id` para `uid` e `label` para `rotulo` em [Mapa_PontoDeInteresse].
/// - Cópia de `ids` para `pontosUids` e síntese de `alvoUid` em [Mapa_Referencia].
///
/// Botões legados não recebem UID sintético pois não são alvos de referências em croquis antigos.
abstract final class NormalizadorCroqui {

  /// Desserializa um [Croqui] a partir de bytes e aplica a normalização v5 in-place.
  static Croqui deBuffer(List<int> bytes) {
    final croqui = Croqui.fromBuffer(bytes);
    normalizarCroqui(croqui);
    return croqui;
  }

  /// Normaliza um [Croqui] completo in-place.
  static void normalizarCroqui(Croqui croqui) {
    for (final pico in croqui.picos) {
      normalizarPico(pico);
    }
  }

  /// Normaliza um [Pico] e toda a sua árvore de setores, grupos, escaladas e mapas.
  static void normalizarPico(Pico pico) {
    // 1. Mapas Gerais do Pico
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo()) {
      normalizarMapas(
        pico.mapasGerais.conteudo.mapas,
        grupoNomeContexto: null,
        setorNomeContexto: null,
      );
    }

    // 2. Setores e Grupos
    for (final sg in pico.setoresOuGrupos) {
      if (sg.hasGrupo() && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        if (grupo.uid.isEmpty && grupo.nome.isNotEmpty) {
          grupo.uid = 'sintetico:grupo:${grupo.nome}';
        }

        normalizarMapas(
          grupo.mapas,
          grupoNomeContexto: grupo.nome,
          setorNomeContexto: null,
        );

        for (final s in grupo.setores) {
          if (s.hasConteudo()) {
            final setor = s.conteudo;
            if (setor.uid.isEmpty && setor.nome.isNotEmpty) {
              setor.uid = 'sintetico:setor:${grupo.nome}:${setor.nome}';
            }

            normalizarMapas(
              setor.mapas,
              grupoNomeContexto: grupo.nome,
              setorNomeContexto: setor.nome,
            );

            for (final esc in setor.escaladas) {
              final nomeVia = extrairNomeEscalada(esc);
              if (esc.uid.isEmpty && nomeVia.isNotEmpty) {
                esc.uid = 'sintetico:escalada:${grupo.nome}:${setor.nome}:$nomeVia';
              }

              normalizarMapas(
                esc.mapas,
                grupoNomeContexto: grupo.nome,
                setorNomeContexto: setor.nome,
              );
            }
          }
        }
      } else if (sg.hasSetor() && sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;
        if (setor.uid.isEmpty && setor.nome.isNotEmpty) {
          setor.uid = 'sintetico:setor::${setor.nome}';
        }

        normalizarMapas(
          setor.mapas,
          grupoNomeContexto: null,
          setorNomeContexto: setor.nome,
        );

        for (final esc in setor.escaladas) {
          final nomeVia = extrairNomeEscalada(esc);
          if (esc.uid.isEmpty && nomeVia.isNotEmpty) {
            esc.uid = 'sintetico:escalada::${setor.nome}:$nomeVia';
          }

          normalizarMapas(
            esc.mapas,
            grupoNomeContexto: null,
            setorNomeContexto: setor.nome,
          );
        }
      }
    }
  }

  /// Normaliza um único [mapa] in-place.
  static void normalizarMapa(
    Mapa mapa, {
    String? grupoNomeContexto,
    String? setorNomeContexto,
  }) {
    normalizarMapas(
      [mapa],
      grupoNomeContexto: grupoNomeContexto,
      setorNomeContexto: setorNomeContexto,
    );
  }

  /// Normaliza os pontos de interesse e referências de uma lista de [Mapa]s in-place.
  static void normalizarMapas(
    List<Mapa> mapas, {
    required String? grupoNomeContexto,
    required String? setorNomeContexto,
  }) {
    for (final mapa in mapas) {
      // Normaliza pontos de interesse
      for (final ponto in mapa.pontosDeInteresse) {
        if (ponto.uid.isEmpty && ponto.id.isNotEmpty) {
          ponto.uid = ponto.id;
        }
        if (ponto.rotulo.isEmpty && ponto.label.isNotEmpty) {
          ponto.rotulo = ponto.label;
        }
      }

      // Normaliza referências
      for (final ref in mapa.referencias) {
        if (ref.pontosUids.isEmpty && ref.ids.isNotEmpty) {
          ref.pontosUids.addAll(ref.ids);
        }

        if (ref.alvoUid.isEmpty) {
          if (ref.escalada.isNotEmpty) {
            final s = ref.setor.isNotEmpty ? ref.setor : (setorNomeContexto ?? '');
            final g = ref.grupo.isNotEmpty ? ref.grupo : (grupoNomeContexto ?? '');
            ref.alvoUid = 'sintetico:escalada:$g:$s:${ref.escalada}';
          } else if (ref.setor.isNotEmpty) {
            final g = ref.grupo.isNotEmpty ? ref.grupo : (grupoNomeContexto ?? '');
            ref.alvoUid = 'sintetico:setor:$g:${ref.setor}';
          } else if (ref.grupo.isNotEmpty) {
            ref.alvoUid = 'sintetico:grupo:${ref.grupo}';
          }
        }
      }
    }
  }

  /// Extrai o nome da via a partir do seu tipo polimórfico no Protobuf.
  static String extrairNomeEscalada(Escalada escalada) {
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return escalada.viaEsportiva.nome;
      case Escalada_Tipo.viaMovel:
        return escalada.viaMovel.nome;
      case Escalada_Tipo.boulder:
        return escalada.boulder.nome;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return escalada.viaMultiplasEnfiadas.nome;
      case Escalada_Tipo.highline:
        return escalada.highline.nome;
      default:
        return '';
    }
  }
}
