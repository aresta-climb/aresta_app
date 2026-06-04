import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Serviço responsável por disparar eventos de telemetria para o Firebase Analytics.
/// 
/// O uso deste serviço é fundamental para entender o engajamento dos usuários, 
/// descobrir quais partes do aplicativo são mais acessadas, e quais croquis 
/// recebem mais atenção. O Firebase agrega esses dados anonimamente.
/// 
/// ## Como adicionar novas telemetrias:
/// 1. Crie um novo método `Future<void> logNomeDaSuaAcao(...)` nesta classe.
/// 2. Defina os parâmetros necessários no mapa `params` que serão úteis para a análise.
/// 3. Chame o `_logEvent` passando o nome do evento e os parâmetros.
/// 4. Adicione um mock da nova função no `MockTelemetryService` e o verifique nos testes.
class TelemetryService {
  TelemetryService._privateConstructor();
  
  /// Instância singleton mutável (não const) para facilitar a injeção do mock nos testes.
  static TelemetryService instance = TelemetryService._privateConstructor();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Método interno de utilidade para printar no console local e despachar ao Firebase.
  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    if (kDebugMode) {
      print('📈 [Telemetry] Evento disparado: $name | Parâmetros: $parameters');
    }
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Registra que o aplicativo foi aberto. Usado para contar usuários ativos.
  Future<void> logAbrirApp() => _logEvent('abrir_app');

  /// Registra quando o usuário faz download de um croqui novo.
  Future<void> logBaixarCroqui(String idCroqui) {
    return _logEvent('baixar_croqui', {'id_croqui': idCroqui});
  }

  /// Registra quando um croqui já baixado é atualizado com uma nova versão (sha256).
  /// Agora também armazena o timestamp exato do update.
  Future<void> logAtualizarCroqui(String idCroqui, String versao) {
    return _logEvent('atualizar_croqui', {
      'id_croqui': idCroqui,
      'versao': versao,
      'timestamp_atualizacao': DateTime.now().toIso8601String(),
    });
  }

  /// Registra quando o usuário abre a visualização principal de um Pico/Croqui.
  Future<void> logAbrirCroqui(String idPico, String nomePico) {
    return _logEvent('abrir_croqui', {
      'id_pico': idPico,
      'nome_pico': nomePico,
    });
  }

  /// Registra ações diversas feitas dentro da página do pico (e.g. buscar, deletar).
  Future<void> logAcaoCroqui(String idPico, String acao) {
    return _logEvent('acao_croqui', {
      'id_pico': idPico,
      'acao': acao,
    });
  }

  /// Registra quando um setor específico de um pico é aberto.
  Future<void> logAbrirSetor(String idPico, String nomeSetor) {
    return _logEvent('abrir_setor', {
      'id_pico': idPico,
      'nome_setor': nomeSetor,
    });
  }

  /// Registra quando um grupo (sub-setores) específico é aberto.
  Future<void> logAbrirGrupo(String idPico, String nomeGrupo) {
    return _logEvent('abrir_grupo', {
      'id_pico': idPico,
      'nome_grupo': nomeGrupo,
    });
  }

  /// Registra quando o mapa de um setor ou de um grupo é maximizado/visualizado.
  Future<void> logAbrirMapa(String idPico, String nomeSetorOuGrupo) {
    return _logEvent('abrir_mapa', {
      'id_pico': idPico,
      'nome_setor_ou_grupo': nomeSetorOuGrupo,
    });
  }

  /// Registra cliques realizados em cima de pontos no mapa interativo.
  Future<void> logClicarEscaladaMapa(String idPico, String nomeSetorOuGrupo, String nomeEscalada) {
    return _logEvent('clicar_escalada_mapa', {
      'id_pico': idPico,
      'nome_setor_ou_grupo': nomeSetorOuGrupo,
      'nome_escalada': nomeEscalada,
    });
  }

  /// Registra o fluxo do usuário clicando para ver detalhes da via de escalada (modal).
  /// Pode vir de diferentes `origem` (lista de setor, busca, mapa, etc).
  Future<void> logVerDetalhesEscalada(String idPico, String nomeSetorOuGrupo, String nomeEscalada, String origem) {
    return _logEvent('ver_detalhes_escalada', {
      'id_pico': idPico,
      'nome_setor_ou_grupo': nomeSetorOuGrupo,
      'nome_escalada': nomeEscalada,
      'origem': origem,
    });
  }
}
