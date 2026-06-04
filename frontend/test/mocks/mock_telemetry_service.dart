import 'package:frontend/services/firebase/telemetry_service.dart';

class MockTelemetryService implements TelemetryService {
  final List<String> recordedEvents = [];
  final Map<String, Map<String, dynamic>> recordedParams = {};

  void clear() {
    recordedEvents.clear();
    recordedParams.clear();
  }


  @override
  Future<void> logAcaoExplorar(String idCroqui, String acao) async {
    recordedEvents.add('acao_explorar');
    recordedParams['acao_explorar'] = {'id_croqui': idCroqui, 'acao': acao};
  }

  @override
  Future<void> logAtualizarCroqui(String idCroqui, String versao, String timestampAtualizacao) async {
    recordedEvents.add('atualizar_croqui');
    recordedParams['atualizar_croqui'] = {'id_croqui': idCroqui, 'versao': versao, 'timestamp_atualizacao': timestampAtualizacao};
  }


  @override
  Future<void> logAcaoCroqui(String idCroqui, String acao) async {
    recordedEvents.add('acao_croqui');
    recordedParams['acao_croqui'] = {'id_croqui': idCroqui, 'acao': acao};
  }

  @override
  Future<void> logAbrirSetor(String idCroqui, String nomeSetor) async {
    recordedEvents.add('abrir_setor');
    recordedParams['abrir_setor'] = {'id_croqui': idCroqui, 'nome_setor': nomeSetor};
  }

  @override
  Future<void> logAbrirGrupo(String idCroqui, String nomeGrupo) async {
    recordedEvents.add('abrir_grupo');
    recordedParams['abrir_grupo'] = {'id_croqui': idCroqui, 'nome_grupo': nomeGrupo};
  }

  @override
  Future<void> logAbrirMapa(String idCroqui, String nomeSetor) async {
    recordedEvents.add('abrir_mapa');
    recordedParams['abrir_mapa'] = {'id_croqui': idCroqui, 'nome_setor': nomeSetor};
  }

  @override
  Future<void> logAcaoEscalada(String idCroqui, String nomeSetor, String nomeEscalada, String acao, String origem) async {
    recordedEvents.add('acao_escalada');
    recordedParams['acao_escalada'] = {'id_croqui': idCroqui, 'nome_setor': nomeSetor, 'nome_escalada': nomeEscalada, 'acao': acao, 'origem': origem};
  }

  @override
  Future<void> logNavegarAba(String aba) async {
    recordedEvents.add('navegar_aba');
    recordedParams['navegar_aba'] = {'aba': aba};
  }

  @override
  Future<void> logBuscaCroquis(String query, int numeroResultados) async {
    recordedEvents.add('busca_croquis');
    recordedParams['busca_croquis'] = {'query': query, 'numero_resultados': numeroResultados};
  }

  @override
  Future<void> logBuscaEscaladas(String query, int numeroResultados, String idCroqui) async {
    recordedEvents.add('busca_escaladas');
    recordedParams['busca_escaladas'] = {'query': query, 'numero_resultados': numeroResultados, 'id_croqui': idCroqui};
  }

  @override
  Future<void> logSincronizarApp({required bool auto}) async {
    recordedEvents.add('sincronizar_app');
    recordedParams['sincronizar_app'] = {'auto': auto.toString()};
  }

  @override
  Future<void> logLinkExterno(String url, String contexto) async {
    recordedEvents.add('link_externo');
    recordedParams['link_externo'] = {'url': url, 'contexto': contexto};
  }

  @override
  Future<void> logAcaoConfiguracoes(String acao) async {
    recordedEvents.add('acao_configuracoes');
    recordedParams['acao_configuracoes'] = {'acao': acao};
  }

  @override
  Future<void> logErroInteracao(String contexto, String erro) async {
    recordedEvents.add('erro_interacao');
    recordedParams['erro_interacao'] = {'contexto': contexto, 'erro': erro};
  }

}
