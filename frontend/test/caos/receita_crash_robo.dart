// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Perfil de dados iniciais utilizados na sessão exploratória do robô caótico.
enum TipoDatasetCaos {
  /// Catálogo realista contendo picos baixados e online com estrutura similar à produção.
  normal,

  /// Catálogo de estresse contendo casos limites (picos vazios, textos longos, graus exóticos, etc.).
  toxico,
}

/// Tipo de estratégia utilizada para identificar um widget interativo na tela sem depender de coordenadas `(x, y)`.
enum TipoSeletorRobo {
  /// Identifica o widget por uma `ValueKey<String>` explícita.
  porKey,

  /// Identifica o widget pelo seu `runtimeType` somado ao primeiro texto descendente visível.
  porTipoETexto,

  /// Identifica o widget pelo seu `runtimeType` somado ao `codePoint` do primeiro `Icon` descendente.
  porTipoEIcone,

  /// Fallback que identifica o widget pelo seu `runtimeType` e índice entre os candidatos visíveis.
  porTipoEIndice,
}

/// Tipo de ação executada pelo robô caótico em um passo da caminhada exploratória.
enum TipoAcaoRobo {
  /// Toque simples sobre o widget alvo.
  tap,

  /// Arraste/rolagem (`drag`) sobre um widget rolável.
  scroll,

  /// Inserção de texto fuzz em um campo de texto (`TextField`).
  digitarTexto,

  /// Acionamento do retorno declarativo/imperativo via `AppNav.back`.
  voltarAppNav,

  /// Acionamento do botão voltar do sistema operacional (`handlePopRoute`).
  voltarSistema,

  /// Simulação de evento assíncrono de conclusão de sincronização em segundo plano.
  dispararEventoSync,

  /// Simulação de transição de conectividade de rede (online <-> offline).
  alternarConectividade,
}

/// Seletor semântico resiliente para localizar um widget interativo durante gravação e reprodução (replay).
///
/// Evita o acoplamento a coordenadas de pixel para que ajustes visuais de espaçamento
/// não invalidem as receitas de regressão salvas.
@immutable
class SeletorAlvoRobo {
  /// Estratégia de localização do seletor.
  final TipoSeletorRobo tipo;

  /// Valor textual da `ValueKey<String>` quando [tipo] é [TipoSeletorRobo.porKey].
  final String? valorKey;

  /// Nome do tipo do widget (`runtimeType.toString()`) para seletores baseados em tipo.
  final String? tipoWidget;

  /// Texto descendente visível quando [tipo] é [TipoSeletorRobo.porTipoETexto].
  final String? texto;

  /// Ponto de código (`IconData.codePoint`) quando [tipo] é [TipoSeletorRobo.porTipoEIcone].
  final int? iconeCodePoint;

  /// Índice de desempate (base zero) quando múltiplos widgets idênticos estão visíveis na tela.
  final int ocorrencia;

  /// Constrói um seletor baseado em `ValueKey<String>`.
  const SeletorAlvoRobo.porKey(String this.valorKey, {this.ocorrencia = 0})
    : tipo = TipoSeletorRobo.porKey,
      tipoWidget = null,
      texto = null,
      iconeCodePoint = null;

  /// Constrói um seletor baseado no tipo do widget e texto descendente.
  const SeletorAlvoRobo.porTipoETexto({
    required String this.tipoWidget,
    required String this.texto,
    this.ocorrencia = 0,
  }) : tipo = TipoSeletorRobo.porTipoETexto,
       valorKey = null,
       iconeCodePoint = null;

  /// Constrói um seletor baseado no tipo do widget e ícone descendente.
  const SeletorAlvoRobo.porTipoEIcone({
    required String this.tipoWidget,
    required int this.iconeCodePoint,
    this.ocorrencia = 0,
  }) : tipo = TipoSeletorRobo.porTipoEIcone,
       valorKey = null,
       texto = null;

  /// Constrói um seletor baseado no tipo do widget e índice de ocorrência.
  const SeletorAlvoRobo.porTipoEIndice({
    required String this.tipoWidget,
    this.ocorrencia = 0,
  }) : tipo = TipoSeletorRobo.porTipoEIndice,
       valorKey = null,
       texto = null,
       iconeCodePoint = null;

  /// Construtor interno completo para desserialização JSON.
  const SeletorAlvoRobo._({
    required this.tipo,
    this.valorKey,
    this.tipoWidget,
    this.texto,
    this.iconeCodePoint,
    this.ocorrencia = 0,
  });

  /// Converte o seletor em mapa serializável para JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tipo': tipo.name,
      if (valorKey != null) 'valorKey': valorKey,
      if (tipoWidget != null) 'tipoWidget': tipoWidget,
      if (texto != null) 'texto': texto,
      if (iconeCodePoint != null) 'iconeCodePoint': iconeCodePoint,
      'ocorrencia': ocorrencia,
    };
  }

  /// Reconstrói um [SeletorAlvoRobo] a partir de um mapa JSON.
  factory SeletorAlvoRobo.fromJson(Map<String, dynamic> json) {
    final nomeTipo = json['tipo'] as String;
    final tipo = TipoSeletorRobo.values.firstWhere((e) => e.name == nomeTipo);
    return SeletorAlvoRobo._(
      tipo: tipo,
      valorKey: json['valorKey'] as String?,
      tipoWidget: json['tipoWidget'] as String?,
      texto: json['texto'] as String?,
      iconeCodePoint: json['iconeCodePoint'] as int?,
      ocorrencia: (json['ocorrencia'] as int?) ?? 0,
    );
  }

  /// Descrição legível do alvo para logs de diagnóstico e relatórios de falha.
  String get descricaoLegivel {
    switch (tipo) {
      case TipoSeletorRobo.porKey:
        return 'Key("$valorKey")[#$ocorrencia]';
      case TipoSeletorRobo.porTipoETexto:
        return '$tipoWidget(texto: "$texto")[#$ocorrencia]';
      case TipoSeletorRobo.porTipoEIcone:
        return '$tipoWidget(icone: 0x${iconeCodePoint!.toRadixString(16)})[#$ocorrencia]';
      case TipoSeletorRobo.porTipoEIndice:
        return '$tipoWidget[#$ocorrencia]';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeletorAlvoRobo &&
          tipo == other.tipo &&
          valorKey == other.valorKey &&
          tipoWidget == other.tipoWidget &&
          texto == other.texto &&
          iconeCodePoint == other.iconeCodePoint &&
          ocorrencia == other.ocorrencia;

  @override
  int get hashCode => Object.hash(
    tipo,
    valorKey,
    tipoWidget,
    texto,
    iconeCodePoint,
    ocorrencia,
  );
}

/// Representa uma única ação e seu avanço temporal na trilha do robô caótico.
@immutable
class PassoRobo {
  /// Tipo de interação ou evento disparado neste passo.
  final TipoAcaoRobo acao;

  /// Seletor do widget alvo (nulo para ações globais como voltar ou eventos de sistema).
  final SeletorAlvoRobo? alvo;

  /// Texto inserido quando [acao] é [TipoAcaoRobo.digitarTexto].
  final String? textoDigitado;

  /// Deslocamento horizontal quando [acao] é [TipoAcaoRobo.scroll].
  final double? deslocamentoDx;

  /// Deslocamento vertical quando [acao] é [TipoAcaoRobo.scroll].
  final double? deslocamentoDy;

  /// Indica se após a ação o robô aguardou estabilização completa (`pumpAndSettle`).
  final bool pumpAndSettle;

  /// Duração parcial em milissegundos avançada via `pump` quando [pumpAndSettle] é `false`.
  final int? pumpMs;

  /// Cria um passo imutável da caminhada do robô.
  const PassoRobo({
    required this.acao,
    this.alvo,
    this.textoDigitado,
    this.deslocamentoDx,
    this.deslocamentoDy,
    this.pumpAndSettle = true,
    this.pumpMs,
  });

  /// Converte o passo em mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acao': acao.name,
      if (alvo != null) 'alvo': alvo!.toJson(),
      if (textoDigitado != null) 'textoDigitado': textoDigitado,
      if (deslocamentoDx != null) 'deslocamentoDx': deslocamentoDx,
      if (deslocamentoDy != null) 'deslocamentoDy': deslocamentoDy,
      'pumpAndSettle': pumpAndSettle,
      if (pumpMs != null) 'pumpMs': pumpMs,
    };
  }

  /// Reconstrói um [PassoRobo] a partir de um mapa JSON.
  factory PassoRobo.fromJson(Map<String, dynamic> json) {
    final nomeAcao = json['acao'] as String;
    final acao = TipoAcaoRobo.values.firstWhere((e) => e.name == nomeAcao);
    final alvoJson = json['alvo'] as Map<String, dynamic>?;
    return PassoRobo(
      acao: acao,
      alvo: alvoJson != null ? SeletorAlvoRobo.fromJson(alvoJson) : null,
      textoDigitado: json['textoDigitado'] as String?,
      deslocamentoDx: (json['deslocamentoDx'] as num?)?.toDouble(),
      deslocamentoDy: (json['deslocamentoDy'] as num?)?.toDouble(),
      pumpAndSettle: (json['pumpAndSettle'] as bool?) ?? true,
      pumpMs: json['pumpMs'] as int?,
    );
  }

  /// Formata o passo de maneira legível para logs e relatórios.
  String get descricaoLegivel {
    final sufixoTempo = pumpAndSettle ? 'pumpAndSettle' : 'pump(${pumpMs ?? 100}ms)';
    final descAlvo = alvo != null ? ' -> ${alvo!.descricaoLegivel}' : '';
    return '${acao.name}$descAlvo [$sufixoTempo]';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassoRobo &&
          acao == other.acao &&
          alvo == other.alvo &&
          textoDigitado == other.textoDigitado &&
          deslocamentoDx == other.deslocamentoDx &&
          deslocamentoDy == other.deslocamentoDy &&
          pumpAndSettle == other.pumpAndSettle &&
          pumpMs == other.pumpMs;

  @override
  int get hashCode => Object.hash(
    acao,
    alvo,
    textoDigitado,
    deslocamentoDx,
    deslocamentoDy,
    pumpAndSettle,
    pumpMs,
  );
}

/// Pacote completo e autocontido de reprodução de um crash encontrado pelo robô caótico.
///
/// Pode ser acoplado no contexto `receita_robo_caotico` do Sentry e salvo em
/// `frontend/test/caos/caminhos_regressao/` para execução permanente na suíte de testes.
class ReceitaCrashRobo {
  /// Semente pseudo-aleatória que originou a sessão.
  final int seed;

  /// Perfil de dataset ativo quando a falha ocorreu.
  final TipoDatasetCaos dataset;

  /// Assinatura única da falha (`TipoExcecao|FramePrincipal`) utilizada para deduplicação.
  final String assinaturaFalha;

  /// Resumo textual da exceção capturada.
  final String resumoErro;

  /// Sequência mínima de passos obtida após o encolhimento por busca binária (`ddmin`).
  final List<PassoRobo> passosMinimos;

  /// Sequência completa original de passos antes do encolhimento.
  final List<PassoRobo> passosOriginais;

  /// Instruções passo a passo para reproduzir o bug e mantê-lo como teste de regressão.
  final String instrucoesRegressao;

  /// Constrói uma instância de [ReceitaCrashRobo].
  const ReceitaCrashRobo({
    required this.seed,
    required this.dataset,
    required this.assinaturaFalha,
    required this.resumoErro,
    required this.passosMinimos,
    required this.passosOriginais,
    required this.instrucoesRegressao,
  });

  /// Extrai uma assinatura estável (`TipoExcecao|Arquivo:Linha`) a partir de uma exceção e pilha.
  static String extrairAssinaturaFalha(Object excecao, StackTrace? stackTrace) {
    final tipo = excecao.runtimeType.toString();
    final textoStack = stackTrace?.toString() ?? '';
    final padraoArquivo = RegExp(r'([a-zA-Z0-9_]+\.dart:\d+)');
    final match = padraoArquivo.firstMatch(textoStack);
    final framePrincipal = match != null ? match.group(1)! : excecao.toString().split('\n').first;
    return '$tipo|$framePrincipal';
  }

  /// Cria uma receita completa calculando automaticamente a assinatura e as instruções de regressão.
  factory ReceitaCrashRobo.criar({
    required int seed,
    required TipoDatasetCaos dataset,
    required Object excecao,
    StackTrace? stackTrace,
    required List<PassoRobo> passosMinimos,
    required List<PassoRobo> passosOriginais,
  }) {
    final assinatura = extrairAssinaturaFalha(excecao, stackTrace);
    final nomeArquivoSugerido = 'crash_${dataset.name}_seed_$seed.json';
    return ReceitaCrashRobo(
      seed: seed,
      dataset: dataset,
      assinaturaFalha: assinatura,
      resumoErro: excecao.toString(),
      passosMinimos: List<PassoRobo>.unmodifiable(passosMinimos),
      passosOriginais: List<PassoRobo>.unmodifiable(passosOriginais),
      instrucoesRegressao:
          '1. Salve este JSON em frontend/test/caos/caminhos_regressao/$nomeArquivoSugerido\n'
          '2. Reproduza localmente com: flutter test test/caos/regressao_caminhos_test.dart\n'
          '3. Corrija a causa raiz e mantenha o arquivo JSON commitado para evitar regressão.',
    );
  }

  /// Converte a receita completa em um mapa JSON pronto para persistência ou envio ao Sentry.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'seed': seed,
      'dataset': dataset.name,
      'assinatura_falha': assinaturaFalha,
      'resumo_erro': resumoErro,
      'instrucoes_regressao': instrucoesRegressao,
      'passos_minimos': passosMinimos.map((p) => p.toJson()).toList(),
      'passos_originais': passosOriginais.map((p) => p.toJson()).toList(),
    };
  }

  /// Reconstrói uma [ReceitaCrashRobo] a partir de um mapa JSON.
  factory ReceitaCrashRobo.fromJson(Map<String, dynamic> json) {
    final nomeDataset = json['dataset'] as String;
    final dataset = TipoDatasetCaos.values.firstWhere((d) => d.name == nomeDataset);
    final minimosBrutos = (json['passos_minimos'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PassoRobo.fromJson)
        .toList();
    final originaisBrutos = (json['passos_originais'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PassoRobo.fromJson)
        .toList();

    return ReceitaCrashRobo(
      seed: json['seed'] as int,
      dataset: dataset,
      assinaturaFalha: json['assinatura_falha'] as String,
      resumoErro: json['resumo_erro'] as String,
      instrucoesRegressao: (json['instrucoes_regressao'] as String?) ?? '',
      passosMinimos: List<PassoRobo>.unmodifiable(minimosBrutos),
      passosOriginais: List<PassoRobo>.unmodifiable(
        originaisBrutos.isEmpty ? minimosBrutos : originaisBrutos,
      ),
    );
  }

  /// Salva a receita formatada com indentação no [arquivo] informado.
  void salvarEmArquivo(File arquivo) {
    if (!arquivo.parent.existsSync()) {
      arquivo.parent.createSync(recursive: true);
    }
    const codificador = JsonEncoder.withIndent('  ');
    arquivo.writeAsStringSync('${codificador.convert(toJson())}\n');
  }

  /// Carrega uma [ReceitaCrashRobo] a partir de um arquivo `.json` no disco.
  factory ReceitaCrashRobo.carregarDeArquivo(File arquivo) {
    final conteudo = arquivo.readAsStringSync();
    final mapa = jsonDecode(conteudo) as Map<String, dynamic>;
    return ReceitaCrashRobo.fromJson(mapa);
  }
}
