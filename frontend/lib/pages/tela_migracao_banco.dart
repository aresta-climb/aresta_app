// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/theme/cores_app.dart';
import '../idioma/tradutor_app.dart';

/// Etapas do processo de migração de banco de dados.
enum EtapaMigracao {
  /// Verificando conexão e preparando ambiente local.
  verificando,

  /// Baixando o novo índice e metadados estruturais da CDN.
  sincronizando,

  /// Migração concluída com sucesso.
  concluido,

  /// Falha na migração (sem internet ou erro de rede).
  erro,
}

/// Tela de Migração de Banco de Dados.
///
/// Exibida quando uma alteração estrutural no formato de dados (`kDataVersion`)
/// é detectada na inicialização da aplicação. Força o download do novo catálogo
/// antes de liberar o acesso normal do usuário.
///
/// Possui auto-retry reativo via [Connectivity] que retoma a sincronização
/// automaticamente assim que a conexão de internet for restabelecida.
class DatabaseMigrationScreen extends StatefulWidget {
  final SyncService syncService;
  final VoidCallback onMigrationComplete;
  final Stream<List<ConnectivityResult>>? connectivityStream;

  const DatabaseMigrationScreen({
    super.key,
    required this.syncService,
    required this.onMigrationComplete,
    this.connectivityStream,
  });

  @override
  State<DatabaseMigrationScreen> createState() =>
      _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  EtapaMigracao _etapa = EtapaMigracao.verificando;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    TelemetryService.instance.logDatabaseMigrationScreenOpened();
    _iniciarOuvinteConectividade();
    _startMigration();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Configura o ouvinte de rede para tentar novamente de forma automática.
  void _iniciarOuvinteConectividade() {
    final stream =
        widget.connectivityStream ?? Connectivity().onConnectivityChanged;
    _connectivitySubscription = stream.listen((results) {
      if (!results.contains(ConnectivityResult.none) &&
          _etapa == EtapaMigracao.erro) {
        _startMigration();
      }
    });
  }

  /// Inicia a sincronização forçada do novo índice de croquis.
  Future<void> _startMigration() async {
    if (_etapa == EtapaMigracao.erro) {
      TelemetryService.instance.logDatabaseMigrationTryAgain();
    }

    if (mounted) {
      setState(() {
        _etapa = EtapaMigracao.sincronizando;
      });
    }

    try {
      final sucesso = await widget.syncService.executarMigracao();
      if (mounted) {
        if (sucesso) {
          setState(() {
            _etapa = EtapaMigracao.concluido;
          });
          widget.onMigrationComplete();
        } else {
          setState(() {
            _etapa = EtapaMigracao.erro;
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro inesperado na tela de migração de banco',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _etapa = EtapaMigracao.erro;
        });
      }
    }
  }

  /// Retorna o texto descritivo correspondente à etapa atual.
  String _obterTextoEtapa(BuildContext context) {
    switch (_etapa) {
      case EtapaMigracao.verificando:
        return context.tr(ChaveTexto.sistemaMigracaoVerificando);
      case EtapaMigracao.sincronizando:
        return context.tr(ChaveTexto.sistemaMigracaoBaixando);
      case EtapaMigracao.concluido:
        return context.tr(ChaveTexto.comumCatalogoAtualizadoSucesso);
      case EtapaMigracao.erro:
        return context.tr(ChaveTexto.sistemaMigracaoErro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        _etapa == EtapaMigracao.verificando ||
        _etapa == EtapaMigracao.sincronizando;
    final bool isError = _etapa == EtapaMigracao.erro;

    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: ControladorIdiomaApp.instancia.notificadorIdioma,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: context.colors.deepBasalt,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: context.colors.caveShadow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.colors.graniteEdge),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isError
                            ? Icons.error_outline
                            : Icons.cloud_sync_outlined,
                        size: 56,
                        color: isError ? Colors.red : AppColors.brandColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _obterTextoEtapa(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (isError) ...[
                    Text(
                      _obterTextoEtapa(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startMigration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tentar Novamente',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
