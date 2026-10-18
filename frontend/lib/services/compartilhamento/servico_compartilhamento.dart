// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:share_plus/share_plus.dart';
import '../firebase/telemetria.dart';
import '../repositorio_dataset.dart';

/// Assinatura de função responsável por disparar o menu nativo de compartilhamento.
typedef ExecutorCompartilhamento = Future<void> Function(String texto);

/// Serviço modular responsável por formatar mensagens amigáveis de compartilhamento,
/// gerar URLs compactas (`https://aresta.cc/s/<uid>` e `https://aresta.cc/sm/<uid>`),
/// registrar telemetria e invocar o menu nativo do sistema operacional (`share_plus`).
class ServicoCompartilhamento {
  final ExecutorCompartilhamento _executor;

  ServicoCompartilhamento({
    ExecutorCompartilhamento? executorCompartilhamento,
  }) : _executor = executorCompartilhamento ?? _executorPadrao;

  static Future<void> _executorPadrao(String texto) async {
    await SharePlus.instance.share(ShareParams(text: texto));
  }

  /// Instância global ativa (substituível em testes de widget/integração).
  static ServicoCompartilhamento instancia = ServicoCompartilhamento();

  /// Restaura a instância padrão conectada ao `SharePlus.instance`.
  static void restaurarPadrao() {
    instancia = ServicoCompartilhamento();
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
    final mensagem =
        'Confira o croqui de $nomeCroquiResolvido$sufixoLocal no Aresta:\n$url';

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'pico',
      uid: uid,
      abrirMapa: abrirMapa,
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
    final refGrupo = _formatarArtigoGrupo(nomeGrupo);
    final mensagem =
        'Confira $refGrupo, em $nomeCroquiResolvido, no Aresta:\n$url';

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'grupo',
      uid: uid,
      abrirMapa: abrirMapa,
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
    final refSetor = _formatarArtigoSetor(nomeSetor);
    final mensagem =
        'Confira $refSetor, em $nomeCroquiResolvido, no Aresta:\n$url';

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'setor',
      uid: uid,
      abrirMapa: abrirMapa,
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
    final trechoSetor =
        temSetorEspecifico ? ' ${_formatarLocativoSetor(setorLimpo)}' : '';
    final mensagem =
        'Confira $nomeEscalada$sufixoGrau$trechoSetor, em $nomeCroquiResolvido, no Aresta:\n$url';

    await TelemetryService.instance.logCompartilharEntidade(
      idCroqui: idCroqui,
      tipoEntidade: 'via',
      uid: uid,
      abrirMapa: abrirMapa,
    );
    await _executor(mensagem);
  }
}
