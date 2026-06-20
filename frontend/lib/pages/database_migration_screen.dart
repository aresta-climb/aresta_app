import 'package:flutter/material.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Tela bloqueante de Migração de Banco de Dados.
///
/// Esta tela é exibida imediatamente ao iniciar o app, interceptando a navegação
/// normal, quando uma "breaking change" na versão da base de dados é detectada
/// (ex: o backend de croquis mudou de /v14/ para /v15/).
/// 
/// Ela impede que o usuário interaja com dados antigos/corrompidos e força
/// um novo download do Índice `syncIndex()` antes de liberar o aplicativo via
/// callback `onMigrationComplete`. Se houver erro de conexão, ela fica em
/// estado de Retry permanente até conseguir finalizar a transição.
class DatabaseMigrationScreen extends StatefulWidget {
  final SyncService syncService;
  final VoidCallback onMigrationComplete;

  const DatabaseMigrationScreen({super.key, required this.syncService, required this.onMigrationComplete});

  @override
  State<DatabaseMigrationScreen> createState() => _DatabaseMigrationScreenState();
}

class _DatabaseMigrationScreenState extends State<DatabaseMigrationScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    TelemetryService.instance.logDatabaseMigrationScreenOpened();
    _startMigration();
  }

  /// Inicia o processo de migração forçada, que consiste em puxar o novo
  /// índice de croquis após o aplicativo ter deletado silenciosamente o banco antigo.
  Future<void> _startMigration() async {
    if (_hasError) {
      TelemetryService.instance.logDatabaseMigrationTryAgain();
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final syncService = widget.syncService;
    
    try {
      final failed = await syncService.syncIndex(auto: false);
      if (syncService.syncStatus.value == SyncStatus.error || failed.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      } else {
        await syncService.confirmMigrationComplete();
        if (mounted) {
          widget.onMigrationComplete();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Atualizando o banco de dados. Isso exigirá internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ] else if (_hasError) ...[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível atualizar o banco de dados. Verifique sua conexão com a internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startMigration,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
