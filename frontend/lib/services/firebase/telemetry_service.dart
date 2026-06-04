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

  @visibleForTesting
  static void resetForTesting() {
    instance = TelemetryService._privateConstructor();
  }

  /// Método interno de utilidade para printar no console local e despachar ao Firebase.
  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    if (kDebugMode) {
      print('📈 [Telemetry] Evento disparado: $name | Parâmetros: $parameters');
    }
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Telemetry] Erro ao enviar evento (Firebase pronto?): $e');
      }
    }
  }


  /// Registra ações relacionadas à aba Explorar (ex: expandir detalhes, baixar croqui).
  Future<void> logAcaoExplorar(String idCroqui, String acao) {
    return _logEvent('acao_explorar', {
      'id_croqui': idCroqui,
      'acao': acao,
    });
  }

  /// Registra quando um croqui já baixado é atualizado com uma nova versão (sha256).
  /// Agora também armazena o timestamp exato do update.
  Future<void> logAtualizarCroqui(String idCroqui, String versao, String timestampAtualizacao) {
    return _logEvent('atualizar_croqui', {
      'id_croqui': idCroqui,
      'versao': versao,
      'timestamp_atualizacao': timestampAtualizacao,
    });
  }



  /// Registra ações diversas feitas dentro da página do pico (e.g. buscar, deletar).
  Future<void> logAcaoCroqui(String idCroqui, String acao) {
    return _logEvent('acao_croqui', {
      'id_croqui': idCroqui,
      'acao': acao,
    });
  }

  /// Registra quando um setor específico de um pico é aberto.
  Future<void> logAbrirSetor(String idCroqui, String nomeSetor) {
    return _logEvent('abrir_setor', {
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
    });
  }

  /// Registra quando um grupo (sub-setores) específico é aberto.
  Future<void> logAbrirGrupo(String idCroqui, String nomeGrupo) {
    return _logEvent('abrir_grupo', {
      'id_croqui': idCroqui,
      'nome_grupo': nomeGrupo,
    });
  }

  /// Registra quando o mapa de um setor ou de um grupo é maximizado/visualizado.
  Future<void> logAbrirMapa(String idCroqui, String nomeSetor) {
    return _logEvent('abrir_mapa', {
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
    });
  }

  /// Registra ações relacionadas a uma escalada/via (e.g., ver no mapa, abrir detalhes).
  Future<void> logAcaoEscalada(String idCroqui, String nomeSetor, String nomeEscalada, String acao, String origem) {
    return _logEvent('acao_escalada', {
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
      'nome_escalada': nomeEscalada,
      'acao': acao,
      'origem': origem,
    });
  }

  /// Registra cliques na navegação principal inferior do app.
  Future<void> logNavegarAba(String aba) {
    return _logEvent('navegar_aba', {'aba': aba});
  }

  /// Registra buscas realizadas na aba explorar (croquis inteiros).
  Future<void> logBuscaCroquis(String query, int numeroResultados) {
    return _logEvent('busca_croquis', {
      'query': query,
      'numero_resultados': numeroResultados,
    });
  }

  /// Registra buscas globais dentro de um croqui buscando por vias.
  Future<void> logBuscaEscaladas(String query, int numeroResultados, String idCroqui) {
    return _logEvent('busca_escaladas', {
      'query': query,
      'numero_resultados': numeroResultados,
      'id_croqui': idCroqui,
    });
  }

  /// Registra os eventos de sincronização de dados local.
  Future<void> logSincronizarApp({required bool auto}) {
    return _logEvent('sincronizar_app', {'auto': auto.toString()});
  }

  /// Registra cliques em links de rotas de GPS e páginas web (ex: Termos de uso).
  Future<void> logLinkExterno(String url, String contexto) {
    return _logEvent('link_externo', {'url': url, 'contexto': contexto});
  }

  /// Registra interações gerais nas telas de configuração.
  Future<void> logAcaoConfiguracoes(String acao) {
    return _logEvent('acao_configuracoes', {'acao': acao});
  }

  /// Registra falhas ao engajar com alguma ação principal.
  Future<void> logErroInteracao(String contexto, String erro) {
    return _logEvent('erro_interacao', {'contexto': contexto, 'erro': erro});
  }

}
