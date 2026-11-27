// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/modelos/dados_cartao_compartilhamento.dart';
import '../../idioma/tradutor_app.dart';
import '../firebase/telemetria.dart';
import '../repositorio_dataset.dart';
import 'capturador_imagem_cartao.dart';

/// Assinatura de função responsável por disparar o menu nativo de compartilhamento de texto.
typedef ExecutorCompartilhamento = Future<void> Function(String texto);

/// Assinatura de função responsável por disparar o menu nativo de compartilhamento de imagem PNG.
typedef ExecutorCompartilhamentoImagem = Future<void> Function(
  Uint8List bytesPng,
  String nomeArquivo,
);

/// Assinatura de função responsável por copiar o link curto para a área de transferência.
typedef CopiadorTextoCompartilhamento = Future<void> Function(String texto);

/// Serviço modular responsável por formatar mensagens amigáveis de compartilhamento,
/// gerar URLs compactas (`https://aresta.cc/s/<uid>` e `https://aresta.cc/sm/<uid>`),
/// exportar cartões PNG para Stories com cópia automática do link, registrar telemetria
/// por formato e invocar o menu nativo do sistema operacional (`share_plus`).
class ServicoCompartilhamento {
  final ExecutorCompartilhamento _executor;
  final ExecutorCompartilhamentoImagem? _executorImagemPersonalizado;
  final CopiadorTextoCompartilhamento _copiadorAreaTransferencia;
  final Future<Directory> Function() _provedorDiretorioTemporario;

  /// Capturador opcional associado a esta instância (útil em Fakes determinísticos).
  final CapturadorBytesCartao? capturadorCartao;

  ServicoCompartilhamento({
    ExecutorCompartilhamento? executorCompartilhamento,
    ExecutorCompartilhamentoImagem? executorImagem,
    CopiadorTextoCompartilhamento? copiadorAreaTransferencia,
    Future<Directory> Function()? provedorDiretorioTemporario,
    this.capturadorCartao,
  }) : _executor = executorCompartilhamento ?? _executorPadrao,
       _executorImagemPersonalizado = executorImagem,
       _copiadorAreaTransferencia =
           copiadorAreaTransferencia ?? _copiadorPadrao,
       _provedorDiretorioTemporario =
           provedorDiretorioTemporario ??
           (() => Directory.systemTemp.createTemp('aresta_share_'));

  static Future<void> _executorPadrao(String texto) async {
    await SharePlus.instance.share(ShareParams(text: texto));
  }

  static Future<void> _copiadorPadrao(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
  }

  Future<void> _executarCompartilhamentoImagem(
    Uint8List bytesPng,
    String nomeArquivo,
  ) async {
    if (_executorImagemPersonalizado != null) {
      await _executorImagemPersonalizado(bytesPng, nomeArquivo);
      return;
    }

    final diretorioTemp = await _provedorDiretorioTemporario();
    final arquivo = File('${diretorioTemp.path}/$nomeArquivo');
    try {
      await arquivo.writeAsBytes(bytesPng, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              arquivo.path,
              mimeType: 'image/png',
              name: nomeArquivo,
            ),
          ],
        ),
      );
    } finally {
      if (await diretorioTemp.exists()) {
        await diretorioTemp.delete(recursive: true);
      }
    }
  }

  /// Instância global ativa (substituível em testes de widget/integração).
  static ServicoCompartilhamento instancia = ServicoCompartilhamento();

  /// Capturador ativo utilizado pelo modal de compartilhamento para rasterizar o cartão visual.
  static CapturadorBytesCartao capturadorPadrao =
      CapturadorImagemCartao.capturarPng;

  /// Restaura a instância padrão e o capturador oficial de cartões.
  static void restaurarPadrao() {
    instancia = ServicoCompartilhamento();
    capturadorPadrao = CapturadorImagemCartao.capturarPng;
  }

  /// Constrói a URL canônica de compartilhamento no domínio `aresta.cc`.
  ///
  /// - `https://aresta.cc/s/<uid>` quando [abrirMapa] é `false` (página de detalhes).
  /// - `https://aresta.cc/sm/<uid>` quando [abrirMapa] é `true` (mapa interativo).
  static String construirUrlCompartilhamento(
    String uid, {
    bool abrirMapa = false,
  }) {
    final prefixo = abrirMapa ? 'sm' : 's';
    return 'https://aresta.cc/$prefixo/$uid';
  }

  /// Resolve o nome amigável do croqui/pico a partir de [nomePreferencial] (quando informado e diferente de [idCroqui]),
  /// ou consultando em memória o [DatasetRepository.instance] (`croquisBaixados`, `picosBaixados`, `picosDisponiveis`,
  /// `gerenciadorSessaoOnline` e `indiceData`).
  static String resolverNomeCroqui(
    String idCroqui, {
    String? nomePreferencial,
  }) {
    final preferencialLimpo = (nomePreferencial ?? '').trim();
    if (preferencialLimpo.isNotEmpty && preferencialLimpo != idCroqui) {
      return preferencialLimpo;
    }

    final repo = DatasetRepository.instance;
    if (repo != null) {
      final dataset = repo.activeDataset.value;
      if (dataset != null) {
        for (final croquiBaixado in dataset.croquisBaixados) {
          if (croquiBaixado.id == idCroqui) {
            if (croquiBaixado.nome.trim().isNotEmpty) {
              return croquiBaixado.nome.trim();
            }
            if (croquiBaixado.picos.isNotEmpty &&
                croquiBaixado.picos.first.nome.trim().isNotEmpty) {
              return croquiBaixado.picos.first.nome.trim();
            }
          }
        }
        for (final p in dataset.picosBaixados) {
          if (p.id == idCroqui &&
              p.nome.trim().isNotEmpty &&
              p.nome != idCroqui) {
            return p.nome.trim();
          }
        }
        for (final p in dataset.picosDisponiveis) {
          if (p.id == idCroqui &&
              p.nome.trim().isNotEmpty &&
              p.nome != idCroqui) {
            return p.nome.trim();
          }
        }
      }

      final croquiOnline =
          repo.gerenciadorSessaoOnline.obterCroquiOnline(idCroqui);
      if (croquiOnline != null) {
        if (croquiOnline.nome.trim().isNotEmpty) {
          return croquiOnline.nome.trim();
        }
        if (croquiOnline.picos.isNotEmpty &&
            croquiOnline.picos.first.nome.trim().isNotEmpty) {
          return croquiOnline.picos.first.nome.trim();
        }
      }

      final croquisIndice = repo.indiceData.value?.croquis ?? const [];
      for (final r in croquisIndice) {
        if (r.id == idCroqui && r.nome.trim().isNotEmpty) {
          return r.nome.trim();
        }
      }
    }

    return idCroqui;
  }

  static String _formatarArtigoGrupo(String nomeGrupo) {
    final limpo = nomeGrupo.trim();
    if (limpo.toLowerCase().startsWith('grupo ')) {
      return 'o $limpo';
    }
    return 'o grupo $limpo';
  }

  static String _formatarArtigoSetor(String nomeSetor) {
    final limpo = nomeSetor.trim();
    final minusculo = limpo.toLowerCase();
    if (minusculo.startsWith('setor ') || minusculo.startsWith('bloco ')) {
      return 'o $limpo';
    }
    if (minusculo.startsWith('falésia ') || minusculo.startsWith('falesia ')) {
      return 'a $limpo';
    }
    return 'o setor $limpo';
  }

  static String _formatarLocativoSetor(String nomeSetor) {
    final limpo = nomeSetor.trim();
    final minusculo = limpo.toLowerCase();
    if (minusculo.startsWith('setor ') || minusculo.startsWith('bloco ')) {
      return 'no $limpo';
    }
    if (minusculo.startsWith('falésia ') || minusculo.startsWith('falesia ')) {
      return 'na $limpo';
    }
    return 'no setor $limpo';
  }

  /// Compartilha o link curto canônico a partir de um modelo [DadosCartaoCompartilhamento].
  Future<void> compartilharLinkPorDados(
    DadosCartaoCompartilhamento dados, {
    bool abrirMapa = false,
  }) {
    switch (dados.tipoEntidade) {
      case TipoEntidadeCompartilhavel.pico:
        return compartilharPico(
          idCroqui: dados.idCroqui,
          uid: dados.uid,
          nomePico: dados.nomePico,
          localizacao: dados.localizacaoPico,
          abrirMapa: abrirMapa,
        );
      case TipoEntidadeCompartilhavel.grupo:
        return compartilharGrupo(
          idCroqui: dados.idCroqui,
          uid: dados.uid,
          nomeGrupo: dados.nomeGrupo ?? dados.titulo,
          nomePico: dados.nomePico,
          abrirMapa: abrirMapa,
        );
      case TipoEntidadeCompartilhavel.setor:
        return compartilharSetor(
          idCroqui: dados.idCroqui,
          uid: dados.uid,
          nomeSetor: dados.nomeSetor ?? dados.titulo,
          nomePico: dados.nomePico,
          abrirMapa: abrirMapa,
        );
      case TipoEntidadeCompartilhavel.via:
        return compartilharEscalada(
          idCroqui: dados.idCroqui,
          uid: dados.uid,
          nomeEscalada: dados.titulo,
          grau: dados.grauDestaque,
          nomeSetor: dados.nomeSetor ?? dados.nomeGrupo ?? 'Geral',
          nomePico: dados.nomePico,
          abrirMapa: abrirMapa,
        );
    }
  }

  /// Copia a URL canônica da entidade para a área de transferência, registra telemetria
  /// com `formato: 'imagem_stories'` e compartilha exclusivamente os bytes PNG (`image/png`)
  /// para habilitar o destino Instagram Stories no menu nativo.
  Future<String> compartilharImagemStories({
    required DadosCartaoCompartilhamento dados,
    required Uint8List bytesPng,
    bool abrirMapa = false,
  }) async {
    final url = construirUrlCompartilhamento(dados.uid, abrirMapa: abrirMapa);
    await _copiadorAreaTransferencia(url);

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: dados.idCroqui,
      tipoEntidade: dados.tipoEntidade.codigoTelemetria,
      uid: dados.uid,
      abrirMapa: abrirMapa,
      formato: 'imagem_stories',
    );

    final nomeArquivo =
        'aresta_${dados.tipoEntidade.codigoTelemetria}_${dados.uid}.png';
    await _executarCompartilhamentoImagem(bytesPng, nomeArquivo);
    return url;
  }

  /// Compartilha a página ou mapa de um Pico/Croqui.
  Future<void> compartilharPico({
    required String idCroqui,
    required String uid,
    required String nomePico,
    String? localizacao,
    bool abrirMapa = false,
  }) async {
    final url = construirUrlCompartilhamento(uid, abrirMapa: abrirMapa);
    final nomeCroquiResolvido =
        resolverNomeCroqui(idCroqui, nomePreferencial: nomePico);
    final locLimpa = (localizacao ?? '').trim();
    final sufixoLocal = locLimpa.isNotEmpty ? ' ($locLimpa)' : '';
    final mensagem = tr(ChaveTexto.shareConfiraPico, {
      'pico': nomeCroquiResolvido,
      'loc': sufixoLocal,
      'url': url,
    });

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'pico',
      uid: uid,
      abrirMapa: abrirMapa,
      formato: 'link',
    );
    await _executor(mensagem);
  }

  /// Compartilha a página ou mapa de um Grupo de setores.
  Future<void> compartilharGrupo({
    required String idCroqui,
    required String uid,
    required String nomeGrupo,
    required String nomePico,
    bool abrirMapa = false,
  }) async {
    final url = construirUrlCompartilhamento(uid, abrirMapa: abrirMapa);
    final nomeCroquiResolvido =
        resolverNomeCroqui(idCroqui, nomePreferencial: nomePico);
    final emPortugues =
        ControladorIdiomaApp.instancia.idiomaAtual == IdiomaApp.portugues;
    final refGrupo = emPortugues
        ? _formatarArtigoGrupo(nomeGrupo)
        : nomeGrupo.trim();
    final mensagem = tr(ChaveTexto.shareConfiraGrupo, {
      'grupo': refGrupo,
      'pico': nomeCroquiResolvido,
      'url': url,
    });

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'grupo',
      uid: uid,
      abrirMapa: abrirMapa,
      formato: 'link',
    );
    await _executor(mensagem);
  }

  /// Compartilha a página ou mapa de um Setor.
  Future<void> compartilharSetor({
    required String idCroqui,
    required String uid,
    required String nomeSetor,
    required String nomePico,
    bool abrirMapa = false,
  }) async {
    final url = construirUrlCompartilhamento(uid, abrirMapa: abrirMapa);
    final nomeCroquiResolvido =
        resolverNomeCroqui(idCroqui, nomePreferencial: nomePico);
    final emPortugues =
        ControladorIdiomaApp.instancia.idiomaAtual == IdiomaApp.portugues;
    final refSetor = emPortugues
        ? _formatarArtigoSetor(nomeSetor)
        : nomeSetor.trim();
    final mensagem = tr(ChaveTexto.shareConfiraSetor, {
      'setor': refSetor,
      'pico': nomeCroquiResolvido,
      'url': url,
    });

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'setor',
      uid: uid,
      abrirMapa: abrirMapa,
      formato: 'link',
    );
    await _executor(mensagem);
  }

  /// Compartilha a página ou mapa de uma Escalada (Via, Boulder ou Highline).
  Future<void> compartilharEscalada({
    required String idCroqui,
    required String uid,
    required String nomeEscalada,
    String? grau,
    required String nomeSetor,
    required String nomePico,
    bool abrirMapa = false,
  }) async {
    final url = construirUrlCompartilhamento(uid, abrirMapa: abrirMapa);
    final nomeCroquiResolvido =
        resolverNomeCroqui(idCroqui, nomePreferencial: nomePico);
    final grauLimpo = (grau ?? '').trim();
    final sufixoGrau = grauLimpo.isNotEmpty ? ' ($grauLimpo)' : '';
    final setorLimpo = nomeSetor.trim();
    final temSetorEspecifico =
        setorLimpo.isNotEmpty && setorLimpo.toLowerCase() != 'geral';
    final emPortugues =
        ControladorIdiomaApp.instancia.idiomaAtual == IdiomaApp.portugues;
    final trechoSetor = temSetorEspecifico
        ? (emPortugues
              ? ' ${_formatarLocativoSetor(setorLimpo)}'
              : ' ($setorLimpo)')
        : '';
    final mensagem = tr(ChaveTexto.shareConfiraEscalada, {
      'via': nomeEscalada,
      'grau': sufixoGrau,
      'setor': trechoSetor,
      'pico': nomeCroquiResolvido,
      'url': url,
    });

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'via',
      uid: uid,
      abrirMapa: abrirMapa,
      formato: 'link',
    );
    await _executor(mensagem);
  }
}
