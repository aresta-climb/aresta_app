import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/theme/app_colors.dart';

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

    final syncService = widget.syncService;

    try {
      final failed = await syncService.syncIndex(auto: false);
      if (syncService.syncStatus.value == SyncStatus.error ||
          syncService.syncStatus.value == SyncStatus.offline ||
          failed.isNotEmpty) {
        if (mounted) {
          setState(() {
            _etapa = EtapaMigracao.erro;
          });
        }
      } else {
        await syncService.confirmMigrationComplete();
        if (mounted) {
          setState(() {
            _etapa = EtapaMigracao.concluido;
          });
          widget.onMigrationComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _etapa = EtapaMigracao.erro;
        });
      }
    }
  }

  /// Retorna o texto descritivo correspondente à etapa atual.
  String _obterTextoEtapa() {
    switch (_etapa) {
      case EtapaMigracao.verificando:
        return 'Verificando conexão com a internet...';
      case EtapaMigracao.sincronizando:
        return 'Baixando novo catálogo de croquis...';
      case EtapaMigracao.concluido:
        return 'Catálogo atualizado com sucesso!';
      case EtapaMigracao.erro:
        return 'Não foi possível atualizar o banco de dados. Verifique sua conexão com a internet.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        _etapa == EtapaMigracao.verificando ||
        _etapa == EtapaMigracao.sincronizando;
    final bool isError = _etapa == EtapaMigracao.erro;

    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                  // Ícone de cabeçalho
                  Icon(
                    isError ? Icons.error_outline : Icons.cloud_sync_outlined,
                    size: 56,
                    color: isError ? Colors.red : AppColors.brandColor,
                  ),
                  const SizedBox(height: 16),

                  // Título principal
                  const Text(
                    'ATUALIZAÇÃO DE BASE DE DADOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mensagem contextual explicando a necessidade da migração
                  Text(
                    'Esta nova versão do aplicativo inclui atualizações estruturais no catálogo de croquis e precisa sincronizar pela internet uma única vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.ashGrey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Indicador de progresso ou erro
                  if (isLoading) ...[
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.brandColor,
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
