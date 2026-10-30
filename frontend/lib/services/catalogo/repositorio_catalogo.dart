// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../aresta_api/openapi/generated/dart/catalogo.dart';
import '../../aresta_api/sql/generated/dart/catalogo_sql.dart';

/// Modelo enriquecido de uma entidade do catálogo SQLite (`catalogo_aresta`)
/// combinada via `LEFT JOIN` com os nomes do setor pai, grupo pai e metadados do croqui.
class ItemCatalogoBusca {
  /// Identificador universal imutável (NanoID 14c) da entidade.
  final String uid;

  /// Categoria da entidade (`'escalada'`, `'setor'` ou `'grupo'`).
  final String tipo;

  /// Identificador universal do croqui ao qual esta entidade pertence.
  final String croquiUid;

  /// Slug identificador do croqui (ex: `'br_mg_igarape_pedra_grande'`).
  final String idSlug;

  /// Nome da via, setor ou grupo.
  final String nome;

  /// Graduação formatada da escalada (ex: `'6sup'`, `'V4'`, `'45m'`) quando `tipo == 'escalada'`.
  final String? escaladaGrau;

  /// Modalidade da escalada (`'esportiva'`, `'tradicional'`, `'boulder'`, `'multienfiada'`, `'highline'`).
  final String? escaladaTipo;

  /// UID do setor pai imediato (quando aplicável).
  final String? setorUid;

  /// Nome do setor pai resolvido via `LEFT JOIN` (quando aplicável).
  final String? setorNome;

  /// UID do grupo pai (quando aplicável).
  final String? grupoUid;

  /// Nome do grupo pai resolvido via `LEFT JOIN` (quando aplicável).
  final String? grupoNome;

  /// Nome do pico/croqui hospedeiro.
  final String picoNome;

  /// Município onde o pico está localizado.
  final String? cidade;

  /// Sigla da unidade federativa (ex: `'MG'`, `'RJ'`, `'SP'`).
  final String? estado;

  const ItemCatalogoBusca({
    required this.uid,
    required this.tipo,
    required this.croquiUid,
    required this.idSlug,
    required this.nome,
    this.escaladaGrau,
    this.escaladaTipo,
    this.setorUid,
    this.setorNome,
    this.grupoUid,
    this.grupoNome,
    required this.picoNome,
    this.cidade,
    this.estado,
  });

  /// Constrói a instância a partir de uma linha da query relacional do SQLite.
  factory ItemCatalogoBusca.deMapa(Map<String, Object?> mapa) {
    return ItemCatalogoBusca(
      uid: (mapa['uid'] as String?) ?? '',
      tipo: (mapa['tipo'] as String?) ?? '',
      croquiUid: (mapa['croqui_uid'] as String?) ?? '',
      idSlug: (mapa['id_slug'] as String?) ?? '',
      nome: (mapa['nome'] as String?) ?? '',
      escaladaGrau: mapa['escalada_grau'] as String?,
      escaladaTipo: mapa['escalada_tipo'] as String?,
      setorUid: mapa['setor_uid'] as String?,
      setorNome: mapa['setor_nome'] as String?,
      grupoUid: mapa['grupo_uid'] as String?,
      grupoNome: mapa['grupo_nome'] as String?,
      picoNome: (mapa['pico_nome'] as String?) ?? '',
      cidade: mapa['cidade'] as String?,
      estado: mapa['estado'] as String?,
    );
  }
}

/// Repositório responsável por gerenciar o banco SQLite local do catálogo (`catalogo.db`).
///
/// Fornece leitura da versão lógica em `catalogo_meta`, aplicação transacional de deltas
/// (`apply_delta`), substituição atômica em `full_download`, resolução de `id_slug` por UID
/// em $O(1)$ e consultas relacionais para a Busca Global, serializando todas as operações
/// de acesso a disco e SQLite para evitar race conditions.
class RepositorioCatalogo {
  /// Query parametrizada estática para resolução de `id_slug` por UID.
  ///
  /// Mantida como `static const` com placeholders `?` para garantir reutilização
  /// do statement compilado (`sqlite3_stmt`) no cache LRU do driver SQLite nativo.
  static const String _sqlObterIdSlugPorUid = '''
    SELECT id_slug FROM catalogo_croquis WHERE croqui_uid = ? OR id_slug = ?
    UNION ALL
    SELECT c.id_slug
    FROM catalogo_aresta a
    JOIN catalogo_croquis c ON c.croqui_uid = a.croqui_uid
    WHERE a.uid = ?
    LIMIT 1
  ''';

  /// Query parametrizada estática para resolução de metadados enriquecidos por UID ou `id_slug`.
  ///
  /// Mantida como `static const` com placeholders `?` para garantir reutilização
  /// do statement compilado (`sqlite3_stmt`) no cache LRU do driver SQLite nativo.
  static const String _sqlObterItemPorUid = '''
    SELECT
      e.uid,
      e.tipo,
      e.croqui_uid,
      c.id_slug,
      e.nome,
      e.escalada_grau,
      e.escalada_tipo,
      e.setor_uid,
      s.nome AS setor_nome,
      e.grupo_uid,
      g.nome AS grupo_nome,
      c.nome AS pico_nome,
      c.cidade,
      c.estado
    FROM catalogo_aresta e
    JOIN catalogo_croquis c ON c.croqui_uid = e.croqui_uid
    LEFT JOIN catalogo_aresta s ON s.uid = e.setor_uid
    LEFT JOIN catalogo_aresta g ON g.uid = e.grupo_uid
    WHERE e.uid = ?
    UNION ALL
    SELECT
      c.croqui_uid AS uid,
      'pico' AS tipo,
      c.croqui_uid,
      c.id_slug,
      c.nome,
      NULL AS escalada_grau,
      NULL AS escalada_tipo,
      NULL AS setor_uid,
      NULL AS setor_nome,
      NULL AS grupo_uid,
      NULL AS grupo_nome,
      c.nome AS pico_nome,
      c.cidade,
      c.estado
    FROM catalogo_croquis c
    WHERE c.croqui_uid = ? OR c.id_slug = ?
    LIMIT 1
  ''';

  /// Query estática para listagem completa das entidades pesquisáveis na Busca Global.
  static const String _sqlListarEntidadesDetalhadas = '''
    SELECT
      e.uid,
      e.tipo,
      e.croqui_uid,
      c.id_slug,
      e.nome,
      e.escalada_grau,
      e.escalada_tipo,
      e.setor_uid,
      s.nome AS setor_nome,
      e.grupo_uid,
      g.nome AS grupo_nome,
      c.nome AS pico_nome,
      c.cidade,
      c.estado
    FROM catalogo_aresta e
    JOIN catalogo_croquis c ON c.croqui_uid = e.croqui_uid
    LEFT JOIN catalogo_aresta s ON s.uid = e.setor_uid
    LEFT JOIN catalogo_aresta g ON g.uid = e.grupo_uid
    WHERE e.tipo IN ('escalada', 'setor', 'grupo')
    ORDER BY e.nome COLLATE NOCASE ASC
  ''';

  final Future<String> Function() _provedorCaminhoBanco;
  final DatabaseFactory? _fabricaBanco;
  Database? _banco;
  String? _caminhoAberto;
  Future<void>? _filaOperacoes;

  /// Notificador incrementado sempre que o banco de dados do catálogo é modificado.
  final ValueNotifier<int> versaoNotificador = ValueNotifier<int>(0);

  RepositorioCatalogo({
    Future<String> Function()? provedorCaminhoBanco,
    DatabaseFactory? fabricaBanco,
  })  : _provedorCaminhoBanco =
            provedorCaminhoBanco ?? _obterCaminhoPadraoCatalogo,
        _fabricaBanco = fabricaBanco;

  static Future<String> _obterCaminhoPadraoCatalogo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return '${diretorio.path}/catalogo.db';
  }

  /// Enfileira [operacao] para execução estritamente sequencial, impedindo que abertura,
  /// substituição de arquivo, consultas e fechamento colidam concorrentemente.
  Future<T> _executarSerializado<T>(Future<T> Function() operacao) async {
    final anterior = _filaOperacoes;
    final conclusao = Completer<void>();
    _filaOperacoes = conclusao.future;
    if (anterior != null) {
      await anterior;
    }
    try {
      return await operacao();
    } finally {
      if (identical(_filaOperacoes, conclusao.future)) {
        _filaOperacoes = null;
      }
      conclusao.complete();
    }
  }

  /// Abre ou reutiliza a conexão ativa com o banco SQLite, garantindo o schema DDL.
  Future<Database> _obterBanco() async {
    final caminho = await _provedorCaminhoBanco();
    if (_banco != null && _bancoEstaAberto && _caminhoAberto == caminho) {
      return _banco!;
    }
    await _fecharInterno();

    final arquivo = File(caminho);
    if (!arquivo.parent.existsSync()) {
      arquivo.parent.createSync(recursive: true);
    }

    final db = await (_fabricaBanco ?? databaseFactory).openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onOpen: (db) async {
          final infoCroquis =
              await db.rawQuery('PRAGMA table_info(catalogo_croquis)');
          final nomesColunas =
              infoCroquis.map((c) => c['name'] as String?).toSet();
          if (nomesColunas.contains('uf') && !nomesColunas.contains('estado')) {
            await db.execute(
              'ALTER TABLE catalogo_croquis RENAME COLUMN uf TO estado',
            );
          }
          if (nomesColunas.contains('atualizado_em')) {
            await db.execute(
              'ALTER TABLE catalogo_croquis DROP COLUMN atualizado_em',
            );
          }
          for (final ddl in comandosDdlCatalogo) {
            await db.execute(ddl);
          }
        },
      ),
    );
    _banco = db;
    _caminhoAberto = caminho;
    return db;
  }

  bool get _bancoEstaAberto => _banco != null && _banco!.isOpen;

  /// Verifica se o arquivo físico do banco `catalogo.db` já existe no armazenamento local.
  Future<bool> _arquivoExiste() async {
    final caminho = await _provedorCaminhoBanco();
    return File(caminho).existsSync();
  }

  /// Lê o hash `versao_catalogo` diretamente da tabela `catalogo_meta`.
  ///
  /// Retorna string vazia (`""`) caso o arquivo `catalogo.db` ainda não exista ou não possua versão.
  Future<String> obterVersaoCatalogo() {
    return _executarSerializado(() async {
      if (!await _arquivoExiste()) {
        return '';
      }
      final db = await _obterBanco();
      final linhas = await db.query(
        'catalogo_meta',
        columns: ['valor'],
        where: "chave = 'versao_catalogo'",
        limit: 1,
      );
      if (linhas.isNotEmpty) {
        final valor = linhas.first['valor'] as String?;
        if (valor != null && valor.isNotEmpty) {
          return valor;
        }
      }
      return '';
    });
  }

  /// Aplica transacionalmente um pacote de sincronização incremental ([RespostaSyncCatalogo])
  /// executando deleções, inserções/atualizações e a gravação da nova `versao_catalogo` em um único batch.
  Future<void> aplicarDelta(RespostaSyncCatalogo delta) {
    return _executarSerializado(() async {
      final db = await _obterBanco();
      await db.transaction((txn) async {
        final batch = txn.batch();

        final entidadesRemover = delta.deletes?.entidades ?? const <String>[];
        for (final uid in entidadesRemover) {
          batch.delete('catalogo_aresta', where: 'uid = ?', whereArgs: [uid]);
        }

        final croquisRemover = delta.deletes?.croquis ?? const <String>[];
        for (final croquiUid in croquisRemover) {
          batch.delete(
            'catalogo_croquis',
            where: 'croqui_uid = ?',
            whereArgs: [croquiUid],
          );
          batch.delete(
            'catalogo_aresta',
            where: 'croqui_uid = ?',
            whereArgs: [croquiUid],
          );
        }

        final croquisInserir =
            delta.upserts?.croquis ?? const <CatalogoCroqui>[];
        for (final c in croquisInserir) {
          batch.insert(
            'catalogo_croquis',
            LinhaCatalogoCroquis(
              croquiUid: c.croquiUid,
              idSlug: c.idSlug,
              nome: c.nome,
              cidade: c.cidade,
              estado: c.estado,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        final entidadesInserir =
            delta.upserts?.entidades ?? const <CatalogoEntidade>[];
        for (final e in entidadesInserir) {
          batch.insert(
            'catalogo_aresta',
            LinhaCatalogoAresta(
              uid: e.uid,
              tipo: e.tipo,
              croquiUid: e.croquiUid,
              nome: e.nome,
              escaladaGrau: e.escaladaGrau,
              escaladaTipo: e.escaladaTipo,
              setorUid: e.setorUid,
              grupoUid: e.grupoUid,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        final versaoDestino = delta.versaoDestino ?? delta.versaoAtual;
        if (versaoDestino != null && versaoDestino.isNotEmpty) {
          batch.insert(
            'catalogo_meta',
            LinhaCatalogoMeta(
              chave: 'versao_catalogo',
              valor: versaoDestino,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      versaoNotificador.value++;
    });
  }

  /// Substitui atomicamente o arquivo `catalogo.db` local pelos [bytesNovoBanco] baixados em `full_download`,
  /// removendo resíduos auxiliares (`-wal`, `-shm`, `-journal`) para evitar corrupção de páginas SQLite.
  Future<void> substituirBancoCompleto(Uint8List bytesNovoBanco) {
    return _executarSerializado(() async {
      await _fecharInterno();
      final caminho = await _provedorCaminhoBanco();
      final arquivoFinal = File(caminho);
      if (!arquivoFinal.parent.existsSync()) {
        arquivoFinal.parent.createSync(recursive: true);
      }
      for (final sufixo in const ['-wal', '-shm', '-journal']) {
        final arquivoAuxiliar = File('$caminho$sufixo');
        if (arquivoAuxiliar.existsSync()) {
          arquivoAuxiliar.deleteSync();
        }
      }
      final arquivoTemp = File('$caminho.tmp');
      await arquivoTemp.writeAsBytes(bytesNovoBanco, flush: true);
      await arquivoTemp.rename(caminho);
      versaoNotificador.value++;
    });
  }

  /// Resolve em $O(1)$ a qual `id_slug` de croqui um determinado [uid] (de croqui, grupo, setor, escalada ou botão) pertence.
  Future<String?> obterIdSlugPorUid(String uid) {
    return _executarSerializado(() async {
      if (!await _arquivoExiste()) {
        return null;
      }
      final db = await _obterBanco();
      final linhas = await db.rawQuery(
        _sqlObterIdSlugPorUid,
        [uid, uid, uid],
      );
      if (linhas.isNotEmpty) {
        return linhas.first['id_slug'] as String?;
      }
      return null;
    });
  }

  /// Resolve em $O(1)$ os metadados enriquecidos ([ItemCatalogoBusca]) de uma entidade
  /// (`escalada`, `setor`, `grupo`, `botao` ou `pico`) a partir do seu [uid] ou `id_slug`.
  ///
  /// Retorna `null` caso o banco `catalogo.db` ainda não exista ou o [uid] não conste no catálogo.
  Future<ItemCatalogoBusca?> obterItemPorUid(String uid) {
    return _executarSerializado(() async {
      if (!await _arquivoExiste()) {
        return null;
      }
      final db = await _obterBanco();
      final linhas = await db.rawQuery(
        _sqlObterItemPorUid,
        [uid, uid, uid],
      );
      if (linhas.isNotEmpty) {
        return ItemCatalogoBusca.deMapa(linhas.first);
      }
      return null;
    });
  }

  /// Lista todos os croquis registrados em `catalogo_croquis` ordenados alfabeticamente por nome.
  Future<List<LinhaCatalogoCroquis>> listarCroquis() {
    return _executarSerializado(() async {
      if (!await _arquivoExiste()) {
        return const [];
      }
      final db = await _obterBanco();
      final linhas = await db.query(
        'catalogo_croquis',
        orderBy: 'nome COLLATE NOCASE ASC',
      );
      return linhas.map(LinhaCatalogoCroquis.fromMap).toList();
    });
  }

  /// Lista todas as entidades pesquisáveis (`escalada`, `setor` e `grupo`) enriquecidas
  /// via `LEFT JOIN` com os nomes do setor pai, grupo pai e metadados do pico.
  Future<List<ItemCatalogoBusca>> listarEntidadesDetalhadas() {
    return _executarSerializado(() async {
      if (!await _arquivoExiste()) {
        return const [];
      }
      final db = await _obterBanco();
      final linhas = await db.rawQuery(_sqlListarEntidadesDetalhadas);
      return linhas.map(ItemCatalogoBusca.deMapa).toList();
    });
  }

  /// Fecha a conexão ativa com o banco SQLite internamente (para uso dentro de bloco já serializado).
  Future<void> _fecharInterno() async {
    final db = _banco;
    _banco = null;
    _caminhoAberto = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  /// Fecha a conexão ativa com o banco SQLite de forma serializada.
  Future<void> fechar() {
    if (_banco == null && _filaOperacoes == null) {
      return Future<void>.value();
    }
    return _executarSerializado(_fecharInterno);
  }
}
