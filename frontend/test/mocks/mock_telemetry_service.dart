import 'package:frontend/services/telemetry_service.dart';

class MockTelemetryService implements TelemetryService {
  final List<String> recordedEvents = [];
  final Map<String, Map<String, dynamic>> recordedParams = {};

  void clear() {
    recordedEvents.clear();
    recordedParams.clear();
  }

  @override
  Future<void> logAbrirApp() async {
    recordedEvents.add('abrir_app');
  }

  @override
  Future<void> logBaixarCroqui(String idCroqui) async {
    recordedEvents.add('baixar_croqui');
    recordedParams['baixar_croqui'] = {'id_croqui': idCroqui};
  }

  @override
  Future<void> logAtualizarCroqui(String idCroqui, String versao) async {
    recordedEvents.add('atualizar_croqui');
    recordedParams['atualizar_croqui'] = {'id_croqui': idCroqui, 'versao': versao};
  }

  @override
  Future<void> logAbrirCroqui(String idPico, String nomePico) async {
    recordedEvents.add('abrir_croqui');
    recordedParams['abrir_croqui'] = {'id_pico': idPico, 'nome_pico': nomePico};
  }

  @override
  Future<void> logAcaoCroqui(String idPico, String acao) async {
    recordedEvents.add('acao_croqui');
    recordedParams['acao_croqui'] = {'id_pico': idPico, 'acao': acao};
  }

  @override
  Future<void> logAbrirSetor(String idPico, String nomeSetor) async {
    recordedEvents.add('abrir_setor');
    recordedParams['abrir_setor'] = {'id_pico': idPico, 'nome_setor': nomeSetor};
  }

  @override
  Future<void> logAbrirGrupo(String idPico, String nomeGrupo) async {
    recordedEvents.add('abrir_grupo');
    recordedParams['abrir_grupo'] = {'id_pico': idPico, 'nome_grupo': nomeGrupo};
  }

  @override
  Future<void> logAbrirMapa(String idPico, String nomeSetorOuGrupo) async {
    recordedEvents.add('abrir_mapa');
    recordedParams['abrir_mapa'] = {'id_pico': idPico, 'nome_setor_ou_grupo': nomeSetorOuGrupo};
  }

  @override
  Future<void> logClicarEscaladaMapa(String idPico, String nomeSetorOuGrupo, String nomeEscalada) async {
    recordedEvents.add('clicar_escalada_mapa');
    recordedParams['clicar_escalada_mapa'] = {'id_pico': idPico, 'nome_setor_ou_grupo': nomeSetorOuGrupo, 'nome_escalada': nomeEscalada};
  }

  @override
  Future<void> logVerDetalhesEscalada(String idPico, String nomeSetorOuGrupo, String nomeEscalada, String origem) async {
    recordedEvents.add('ver_detalhes_escalada');
    recordedParams['ver_detalhes_escalada'] = {'id_pico': idPico, 'nome_setor_ou_grupo': nomeSetorOuGrupo, 'nome_escalada': nomeEscalada, 'origem': origem};
  }
}
