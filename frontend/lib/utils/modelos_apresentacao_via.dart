// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../data/modelos/interacao_via.dart';
import '../navigation/arvore_navegacao.dart';
import 'calculadora_delta_grau.dart';
import 'consulta_dataset.dart';
import 'formatador_escalada.dart';

/// Identificadores semânticos de ícones técnicos desacoplados de `Icons` concretos no ViewModel.
enum TipoIconeAtributoVia {
  extensao,
  protecoes,
  parede,
  exposicao,
  enfiadas,
  duracao,
  modalidade,
  distancia,
}

/// Par rótulo/valor exibido nos chips compactos de especificações técnicas da escalada.
@immutable
class AtributoTecnicoVia {
  /// Categoria visual do ícone associado ao atributo.
  final TipoIconeAtributoVia icone;

  /// Rótulo curto em caixa alta (ex.: `'EXTENSÃO'`, `'PROTEÇÕES'`).
  final String rotulo;

  /// Valor formatado pronto para exibição (ex.: `'28m'`, `'11+2'`).
  final String valor;

  /// Cria uma instância imutável de [AtributoTecnicoVia].
  const AtributoTecnicoVia({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });
}

/// Bloco textual estruturado da escalada (descrição oficial em Markdown, rack móvel, acesso, etc.).
@immutable
class SecaoTextoVia {
  /// Título da seção exibido acima do conteúdo.
  final String titulo;

  /// Conteúdo textual bruto ou em sintaxe Markdown.
  final String conteudo;

  /// Indica se o conteúdo deve ser renderizado via `OfflineMarkdown`.
  final bool ehMarkdown;

  /// Cria uma instância imutável de [SecaoTextoVia].
  const SecaoTextoVia({
    required this.titulo,
    required this.conteudo,
    required this.ehMarkdown,
  });
}

/// Resumo limpo e estruturado de uma enfiada individual em uma `ViaMultiplasEnfiadas`.
@immutable
class ResumoEnfiadaVia {
  /// Índice sequencial da enfiada (iniciando em 1).
  final int numero;

  /// Título combinando o número e o nome opcional da enfiada.
  final String titulo;

  /// Grau formatado da enfiada, quando definido.
  final String? grau;

  /// Extensão formatada em metros, quando definida.
  final String? extensao;

  /// Proteções fixas no formato `X+Y`, quando presentes.
  final String? protecoes;

  /// Recomendação de peças móveis da enfiada, quando presente.
  final String? equipamentoMovel;

  /// Descrição específica da enfiada, quando presente.
  final String? descricao;

  /// Cria uma instância imutável de [ResumoEnfiadaVia].
  const ResumoEnfiadaVia({
    required this.numero,
    required this.titulo,
    this.grau,
    this.extensao,
    this.protecoes,
    this.equipamentoMovel,
    this.descricao,
  });
}

/// Item clicável de mídia externa ou vídeo demonstrativo de beta da via.
@immutable
class ItemMidiaBetaVia {
  /// Título descritivo do vídeo, postagem ou artigo.
  final String titulo;

  /// URL de destino validada.
  final String url;

  /// Rótulo amigável da plataforma de origem (`'YouTube'`, `'Instagram'`, `'Blog'`, `'Vídeo'`).
  final String origemRotulo;

  /// Cria uma instância imutável de [ItemMidiaBetaVia].
  const ItemMidiaBetaVia({
    required this.titulo,
    required this.url,
    required this.origemRotulo,
  });
}

/// Modelo imutável de apresentação de um beta público da comunidade pronto para Dumb UI.
@immutable
class NotaComunidadeApresentacao {
  /// Cabeçalho pré-formatado contendo autor e data (`'Mariana • 19/11/2026'`).
  final String cabecalhoAutorData;

  /// Rótulo opcional do estilo esportivo (`'FLASH ★'`, `'À VISTA ★'`, etc.).
  final String? rotuloEstilo;

  /// Corpo textual do beta público.
  final String texto;

  /// Cria uma instância constante de [NotaComunidadeApresentacao].
  const NotaComunidadeApresentacao({
    required this.cabecalhoAutorData,
    this.rotuloEstilo,
    required this.texto,
  });
}

/// Modelo imutável de uma faixa individual (`-2` a `+2`) do gráfico de consenso para Dumb UI.
@immutable
class FaixaDistribuicaoGrauApresentacao {
  /// Deslocamento em relação ao grau oficial (`-2` a `+2`).
  final int delta;

  /// Rótulo resolvido pronto para exibição (ex.: `'7b (+1)'` ou `'Justo (0)'`).
  final String rotulo;

  /// Quantidade absoluta de votos registrados nesta faixa.
  final int contagem;

  /// Fração de preenchimento horizontal normalizada (`0.0` a `1.0`).
  final double fatorLargura;

  /// Indica se esta faixa empatou ou venceu como moda estatística dos votos.
  final bool ehModa;

  /// Cria uma instância constante de [FaixaDistribuicaoGrauApresentacao].
  const FaixaDistribuicaoGrauApresentacao({
    required this.delta,
    required this.rotulo,
    required this.contagem,
    required this.fatorLargura,
    required this.ehModa,
  });
}

/// Modelo imutável de uma pílula interativa (`-2` a `+2`) para votação direta no grau comunitário.
@immutable
class OpcaoPilulaVotoGrauVia {
  /// Deslocamento relativo ao grau oficial (`-2` a `+2`).
  final int delta;

  /// Grau principal exibido no topo da pílula (ex.: `'7b'`, ou `'+1'` sem grau oficial).
  final String grauExibicao;

  /// Subtítulo curto do deslocamento (`'-2'`, `'-1'`, `'Justo'`, `'+1'`, `'+2'`).
  final String subtituloDelta;

  /// Indica se esta pílula corresponde ao voto ativo do escalador.
  final bool selecionada;

  /// Cria uma instância constante de [OpcaoPilulaVotoGrauVia].
  const OpcaoPilulaVotoGrauVia({
    required this.delta,
    required this.grauExibicao,
    required this.subtituloDelta,
    required this.selecionada,
  });
}

/// Estado visual pré-calculado do bloco, gráfico e pílulas de Consenso da Comunidade na `ViaPage`.
@immutable
class ApresentacaoConsensoGrauVia {
  static const List<int> _deltasOrdenados = [-2, -1, 0, 1, 2];

  /// Indica se já há votos contabilizados na escalada.
  final bool possuiVotos;

  /// Grau sugerido consolidado (quando [possuiVotos] for `true`).
  final String? grauSugerido;

  /// Subtítulo contextual de tendência ou convite inicial para votação.
  final String subtituloTendencia;

  /// Título pré-formatado do gráfico de barras (`'DISTRIBUIÇÃO DE VOTOS (10)'`).
  final String tituloDistribuicao;

  /// Total de votos mais suaves (`delta < 0`) para o anel vetorial.
  final int votosSuaves;

  /// Total de votos justos (`delta == 0`) para o anel vetorial.
  final int votosJustos;

  /// Total de votos mais duros (`delta > 0`) para o anel vetorial.
  final int votosDuros;

  /// Delta atualmente votado pelo escalador (`-2` a `+2`), ou `null` quando ainda não votou.
  final int? deltaVotoUsuario;

  /// Faixas ordenadas (`-2` a `+2`) prontas para renderização do gráfico.
  final List<FaixaDistribuicaoGrauApresentacao> faixasDistribuicao;

  /// Cinco pílulas explícitas (`-2` a `+2`) para votação direta em 1 toque no cartão.
  final List<OpcaoPilulaVotoGrauVia> pilulasVoto;

  /// Cria uma instância constante de [ApresentacaoConsensoGrauVia].
  const ApresentacaoConsensoGrauVia({
    required this.possuiVotos,
    required this.grauSugerido,
    required this.subtituloTendencia,
    required this.tituloDistribuicao,
    required this.votosSuaves,
    required this.votosJustos,
    required this.votosDuros,
    required this.faixasDistribuicao,
    this.deltaVotoUsuario,
    this.pilulasVoto = const [],
  });

  /// Cria o estado inicial constante sem votos para vias ainda não avaliadas.
  const ApresentacaoConsensoGrauVia.semVotos()
    : possuiVotos = false,
      grauSugerido = null,
      subtituloTendencia = 'Registre sua ascensão para avaliar',
      tituloDistribuicao = '',
      votosSuaves = 0,
      votosJustos = 0,
      votosDuros = 0,
      deltaVotoUsuario = null,
      faixasDistribuicao = const [],
      pilulasVoto = const [];

  /// Constrói a apresentação completa (gráfico + 5 pílulas de voto) a partir de [ConsensoGrauVia].
  factory ApresentacaoConsensoGrauVia.deConsenso(
    ConsensoGrauVia consenso, {
    required int? codigoGrauOficial,
    required bool ehBoulder,
    int? deltaVotoUsuario,
  }) {
    final pilulas = List<OpcaoPilulaVotoGrauVia>.unmodifiable(
      _deltasOrdenados.map(
        (delta) => _construirPilula(
          delta,
          codigoGrauOficial: codigoGrauOficial,
          ehBoulder: ehBoulder,
          deltaVotoUsuario: deltaVotoUsuario,
        ),
      ),
    );

    if (!consenso.possuiVotos) {
      return ApresentacaoConsensoGrauVia(
        possuiVotos: false,
        grauSugerido: null,
        subtituloTendencia: 'Registre sua ascensão para avaliar',
        tituloDistribuicao: '',
        votosSuaves: 0,
        votosJustos: 0,
        votosDuros: 0,
        deltaVotoUsuario: deltaVotoUsuario,
        faixasDistribuicao: const [],
        pilulasVoto: pilulas,
      );
    }

    var votosSuaves = 0;
    var votosJustos = 0;
    var votosDuros = 0;
    consenso.distribuicaoDeltas.forEach((delta, contagem) {
      if (delta < 0) {
        votosSuaves += contagem;
      } else if (delta == 0) {
        votosJustos += contagem;
      } else {
        votosDuros += contagem;
      }
    });

    final faixas = <FaixaDistribuicaoGrauApresentacao>[];
    if (consenso.distribuicaoDeltas.isNotEmpty) {
      var maiorContagem = 1;
      for (final delta in _deltasOrdenados) {
        final qtd = consenso.distribuicaoDeltas[delta] ?? 0;
        if (qtd > maiorContagem) maiorContagem = qtd;
      }

      for (final delta in _deltasOrdenados) {
        final contagem = consenso.distribuicaoDeltas[delta] ?? 0;
        faixas.add(
          FaixaDistribuicaoGrauApresentacao(
            delta: delta,
            rotulo: _formatarRotuloFaixa(
              delta,
              codigoGrauOficial: codigoGrauOficial,
              ehBoulder: ehBoulder,
            ),
            contagem: contagem,
            fatorLargura: contagem / maiorContagem,
            ehModa: contagem == maiorContagem && contagem > 0,
          ),
        );
      }
    }

    return ApresentacaoConsensoGrauVia(
      possuiVotos: true,
      grauSugerido: consenso.grauSugerido,
      subtituloTendencia:
          consenso.resumoTendencia ?? '${consenso.totalVotos} avaliações',
      tituloDistribuicao: 'DISTRIBUIÇÃO DE VOTOS (${consenso.totalVotos})',
      votosSuaves: votosSuaves,
      votosJustos: votosJustos,
      votosDuros: votosDuros,
      deltaVotoUsuario: deltaVotoUsuario,
      faixasDistribuicao: List.unmodifiable(faixas),
      pilulasVoto: pilulas,
    );
  }

  static OpcaoPilulaVotoGrauVia _construirPilula(
    int delta, {
    required int? codigoGrauOficial,
    required bool ehBoulder,
    required int? deltaVotoUsuario,
  }) {
    final textoDelta = delta == 0 ? 'Justo' : (delta > 0 ? '+$delta' : '$delta');
    final codigo = deslocarCodigoGrau(
      codigoGrauOficial,
      delta,
      ehBoulder: ehBoulder,
    );
    final grau = formatarGrauPorCodigo(codigo, ehBoulder: ehBoulder);
    return OpcaoPilulaVotoGrauVia(
      delta: delta,
      grauExibicao: grau ?? (delta == 0 ? '0' : textoDelta),
      subtituloDelta: textoDelta,
      selecionada: deltaVotoUsuario == delta,
    );
  }

  static String _formatarRotuloFaixa(
    int delta, {
    required int? codigoGrauOficial,
    required bool ehBoulder,
  }) {
    final textoDelta = delta > 0 ? '+$delta' : '$delta';
    final codigo = deslocarCodigoGrau(
      codigoGrauOficial,
      delta,
      ehBoulder: ehBoulder,
    );
    final grau = formatarGrauPorCodigo(codigo, ehBoulder: ehBoulder);
    if (grau != null) return '$grau ($textoDelta)';
    return delta == 0 ? 'Justo (0)' : textoDelta;
  }
}

/// Estado imutável resolvido para a seção de miniatura/botão de croqui interativo da `ViaPage`.
@immutable
class EstadoCroquiVia {
  /// Mapas válidos embutidos diretamente na escalada para `MapaThumbnail`.
  final List<Mapa> mapasMiniatura;

  /// Proporção largura/altura do primeiro mapa de miniatura.
  final double aspectRatioMiniatura;

  /// Itens de carrossel pré-resolvidos para `MapaThumbnail`.
  final List<CarrosselItemData> itensCarrosselMiniatura;

  /// Itens de carrossel referenciados no setor/pico para o botão `'VER NO CROQUI INTERATIVO'`.
  final List<CarrosselItemData> itensNavegacaoCroqui;

  /// Cria uma instância constante de [EstadoCroquiVia].
  const EstadoCroquiVia({
    this.mapasMiniatura = const [],
    this.aspectRatioMiniatura = 1.0,
    this.itensCarrosselMiniatura = const [],
    this.itensNavegacaoCroqui = const [],
  });

  /// Resolve a miniatura ou itens de carrossel de croqui para a [escalada] sem lógica na UI.
  factory EstadoCroquiVia.resolver({
    required Escalada escalada,
    Pico? pico,
    Setor? setor,
    Grupo? grupo,
    DatasetResolver? resolvedorExterno,
  }) {
    final nome = obterNomeEscalada(escalada);
    ResolvedDataset? resolved;
    if (pico != null) {
      final resolver = resolvedorExterno ?? DatasetResolver(pico: pico);
      resolved = escalada.uid.isNotEmpty
          ? resolver.obterPorUid(escalada.uid)
          : resolver.buscarPorNome(
              grupoNome: grupo?.nome,
              setorNome: setor?.nome,
              escaladaNome: nome,
            );
    }

    final mapasValidos = escalada.mapas
        .where(
          (m) =>
              m.caminhoImagemMapa.isNotEmpty &&
              m.larguraMapa > 0 &&
              m.alturaMapa > 0,
        )
        .toList(growable: false);

    if (mapasValidos.isNotEmpty) {
      final itensMiniatura = resolved != null
          ? resolved.resolverCarrosselUnificado()
          : mapasValidos
                .map(
                  (m) => CarrosselItemData(
                    mapaCaminhoImagem: m.caminhoImagemMapa,
                    setorContextNome: setor?.nome,
                    grupoContextNome: grupo?.nome,
                    escaladaContextNome: nome,
                  ),
                )
                .toList(growable: false);

      return EstadoCroquiVia(
        mapasMiniatura: mapasValidos,
        aspectRatioMiniatura:
            mapasValidos.first.larguraMapa / mapasValidos.first.alturaMapa,
        itensCarrosselMiniatura: itensMiniatura,
      );
    }

    final referencias = resolved?.referencias ?? const [];
    if (referencias.isEmpty) return const EstadoCroquiVia();

    final itensNavegacao = referencias
        .map(
          (refNoMapa) => CarrosselItemData(
            mapaCaminhoImagem: refNoMapa.mapa.caminhoImagemMapa,
            setorContextNome: refNoMapa.setorContexto?.nome,
            grupoContextNome: refNoMapa.grupoContexto?.nome,
            escaladaContextNome: nome,
            initialSelectedId: refNoMapa.referencia.pontosUids.isNotEmpty
                ? refNoMapa.referencia.pontosUids.first
                : null,
          ),
        )
        .toList(growable: false);

    return EstadoCroquiVia(itensNavegacaoCroqui: itensNavegacao);
  }
}
