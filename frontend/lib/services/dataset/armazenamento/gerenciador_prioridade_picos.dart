// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:convert';
import 'package:frontend/services/firebase/app_logger.dart';
import '../modelos/resumo_pico.dart';

/// Gerencia a persistência e ordenação dos picos acessados recentemente.
///
/// Salva a lista de identificadores no arquivo `recent_picos.yaml` no diretório
/// de documentos do aplicativo, além de tratar migrações de versões legadas em JSON.
class GerenciadorPrioridadePicos {
  /// Recupera a lista de IDs de picos acessados recentemente a partir do diretório [docsPath].
  Future<List<String>> obterListaPrioridade(String docsPath) async {
    try {
      final yamlFile = File('$docsPath/recent_picos.yaml');
      final jsonFile = File('$docsPath/recent_picos.json');

      if (await yamlFile.exists()) {
        // Limpa o arquivo JSON legado se existir em paralelo
        if (await jsonFile.exists()) {
          try {
            await jsonFile.delete();
          } catch (_) {}
        }

        final content = await yamlFile.readAsString();
        final List<String> list = [];
        for (var line in content.split('\n')) {
          line = line.trim();
          if (line.startsWith('- ')) {
            String val = line.substring(2).trim();
            if ((val.startsWith('"') && val.endsWith('"')) ||
                (val.startsWith("'") && val.endsWith("'"))) {
              val = val.substring(1, val.length - 1);
            }
            list.add(val);
          }
        }
        return list;
      } else if (await jsonFile.exists()) {
        // Migração de JSON legado para YAML
        final content = await jsonFile.readAsString();
        final dynamic decoded = jsonDecode(content);
        final list = (decoded is List)
            ? decoded.map((e) => e.toString()).toList()
            : <String>[];

        final yamlContent = list.map((id) => '- "$id"').join('\n');
        await yamlFile.writeAsString(yamlContent);
        await jsonFile.delete();

        return list;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao ler lista de prioridade de picos',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return [];
  }

  /// Adiciona ou move o pico com [picoId] para o topo da lista de prioridade.
  Future<void> atualizarPrioridade(String docsPath, String picoId) async {
    try {
      final yamlFile = File('$docsPath/recent_picos.yaml');
      final List<String> prioridades = await obterListaPrioridade(docsPath);

      prioridades.remove(picoId);
      prioridades.insert(0, picoId);

      final yamlContent = prioridades.map((id) => '- "$id"').join('\n');
      await yamlFile.writeAsString(yamlContent);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao atualizar prioridade do pico $picoId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Ordena a lista de [picos] com base na [listaPrioridade].
  /// Picos não presentes na lista recebem prioridade mais baixa e são colocados no final.
  List<ResumoPico> ordenarPorPrioridade(
    List<ResumoPico> picos,
    List<String> listaPrioridade,
  ) {
    final List<ResumoPico> ordenados = List.from(picos);
    ordenados.sort((a, b) {
      int indexA = listaPrioridade.indexOf(a.id);
      int indexB = listaPrioridade.indexOf(b.id);

      if (indexA == -1) indexA = 999999;
      if (indexB == -1) indexB = 999999;

      return indexA.compareTo(indexB);
    });
    return ordenados;
  }
}
