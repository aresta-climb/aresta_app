// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../repositorio_dataset.dart';

/// Responsável por associar entidades estruturadas de [Croqui] e [Pico] ao [ResumoPico]
/// e extrair metadados de seções markdown de croquis.
///
/// A resolução visual de imagens de capa e miniaturas é delegada sob demanda
/// diretamente aos componentes de interface via `ProvedorImagemAresta.resolver`,
/// evitando I/O antecipado de imagens em disco durante a carga do catálogo.
class ExtratorMetadadosCroqui {
  /// Repositório de croquis opcional injetado.
  final DatasetRepository? repository;

  /// Cria uma instância do extrator com suporte a injeção de dependência.
  ExtratorMetadadosCroqui({this.repository});

  /// Carrega os dados estruturados do croqui e vincula ao [ResumoPico].
  ///
  /// Prioriza [parsedCroqui] caso já fornecido em memória. Caso contrário, delega a
  /// resolução hierárquica centralizada ao [DatasetRepository.getCroqui].
  Future<ResumoPico> carregarMetadadosLocais({
    required ResumoPico pico,
    String downloadsPath = '',
    String baseUrl = '',
    Croqui? parsedCroqui,
    DatasetRepository? repositoryOverride,
  }) async {
    Croqui? croqui = parsedCroqui;
    if (croqui == null) {
      final repo =
          repositoryOverride ?? repository ?? DatasetRepository.instance;
      croqui = await repo?.getCroqui(pico.id);
      if (croqui == null) {
        return pico;
      }
    }

    return pico.copyWith(
      croqui: croqui,
      pico: croqui.picos.isNotEmpty ? croqui.picos.first : null,
    );
  }

  /// Extrai o caminho da primeira imagem encontrada em uma seção textual de botão intitulado "capa".
  String? extrairCapaPathFromMarkdown(Croqui croqui, String baseDir) {
    for (final b in croqui.botoes) {
      if (b.texto.toLowerCase().contains('capa') &&
          b.hasDestino() &&
          b.destino.hasSecaoTextual()) {
        final conteudo = b.destino.secaoTextual.conteudo;
        final match = RegExp(r'!\[.*?\]\((.*?)\)').firstMatch(conteudo);
        if (match != null) {
          String path = match.group(1)!;
          if (!path.startsWith('http')) {
            if (path.startsWith('./')) path = path.substring(2);
            if (path.startsWith('/')) path = path.substring(1);
            if (baseDir.isNotEmpty && !path.startsWith(baseDir)) {
              return '$baseDir/$path';
            }
            return path;
          }
        }
      }
    }
    return null;
  }
}
