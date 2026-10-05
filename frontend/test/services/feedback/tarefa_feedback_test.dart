// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/tarefa_feedback.dart';

void main() {
  group('TarefaFeedback', () {
    test('instancia corretamente e expõe getters em português e aliases', () {
      final arquivoProc = File('caminho/arquivo.processing');
      final arquivoImg = File('caminho/arquivo.png');
      final json = {
        'description': 'Falha no download do setor',
        'metadata': {
          'navigationTree': 'Home -> Detalhes',
          'feedbackId': 'feedback-uuid-42',
        },
      };

      final tarefa = TarefaFeedback(
        arquivoProcessamento: arquivoProc,
        id: 'feedback-uuid-42',
        conteudoJson: json,
        arquivoScreenshot: arquivoImg,
      );

      expect(tarefa.id, 'feedback-uuid-42');
      expect(tarefa.arquivoProcessamento, arquivoProc);
      expect(tarefa.processingFile, arquivoProc);
      expect(tarefa.arquivoScreenshot, arquivoImg);
      expect(tarefa.arquivoPng, arquivoImg);
      expect(tarefa.pngFile, arquivoImg);
      expect(tarefa.conteudoJson, json);
      expect(tarefa.jsonContent, json);
      expect(tarefa.descricao, 'Falha no download do setor');
      expect(tarefa.description, 'Falha no download do setor');
      expect(tarefa.metadados.feedbackId, 'feedback-uuid-42');
      expect(tarefa.metadados.navigationTree, 'Home -> Detalhes');
      expect(tarefa.metadata.feedbackId, 'feedback-uuid-42');
    });

    test('retorna valores default quando chaves estão ausentes no json', () {
      final arquivoProc = File('caminho/arquivo.processing');
      final tarefa = TarefaFeedback(
        arquivoProcessamento: arquivoProc,
        id: 'sem-dados',
        conteudoJson: {},
      );

      expect(tarefa.descricao, '');
      expect(tarefa.description, '');
      expect(tarefa.arquivoPng, isNull);
      expect(tarefa.pngFile, isNull);
      expect(tarefa.metadados.feedbackId, 'unknown');
    });

    test('construtor legado funciona com parâmetros originais em inglês', () {
      final arquivoProc = File('caminho/arquivo.processing');
      final arquivoImg = File('caminho/arquivo.png');
      final json = {'description': 'Teste legado'};

      final tarefa = TarefaFeedback.legado(
        processingFile: arquivoProc,
        id: 'legacy-id',
        jsonContent: json,
        pngFile: arquivoImg,
      );

      expect(tarefa.id, 'legacy-id');
      expect(tarefa.processingFile, arquivoProc);
      expect(tarefa.pngFile, arquivoImg);
      expect(tarefa.description, 'Teste legado');
    });
  });
}
