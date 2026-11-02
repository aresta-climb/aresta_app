// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import 'armazenamento_local_caderneta.dart';
import 'estatisticas_caderneta.dart';

/// Contrato abstrato do repositório reativo da caderneta pessoal de cadenas e perfil.
///
/// Desenvolvido em padrão *Local-First*, provendo reatividade imediata via [ValueListenable]
/// e desacoplamento para posterior integração transparente com o PowerSync SDK.
abstract interface class RepositorioCaderneta {
  /// Notificador reativo contendo a lista imutável de todas as ascensões registradas.
  ValueListenable<List<Cadena>> get cadenasNotifier;

  /// Notificador reativo da identidade esportiva pública do atleta.
  ValueListenable<PerfilEscalador> get perfilNotifier;

  /// Inicializa o repositório a partir do armazenamento local permanente.
  Future<void> inicializar();

  /// Salva ou atualiza uma ascensão esportiva na caderneta.
  Future<void> salvarCadena(Cadena cadena);

  /// Exclui permanentemente uma ascensão esportiva pelo seu [id] UUID.
  Future<void> excluirCadena(String id);

  /// Retorna as ascensões registradas para uma via específica ([escaladaUid]),
  /// ordenadas da mais recente para a mais antiga.
  List<Cadena> obterCadenasPorEscalada(String escaladaUid);

  /// Retorna a ascensão de maior destaque esportivo em uma via específica.
  ///
  /// Prioriza estilos esportivos superiores (Flash > À Vista > Trabalhado > Tentativa)
  /// e desempata pela data de realização mais recente.
  Cadena? obterMelhorAscensao(String escaladaUid);

  /// Salva ou atualiza as informações do perfil do atleta.
  Future<void> salvarPerfil(PerfilEscalador perfil);

  /// Retorna a instância síncrona atual do perfil do atleta.
  PerfilEscalador obterPerfil();

  /// Compila as métricas analíticas e pirâmide de graduação com os dados da caderneta.
  EstatisticasCaderneta calcularEstatisticas({
    String? Function(String escaladaUid)? obterGrauDaVia,
  });
}

/// Implementação padrão local-first de [RepositorioCaderneta], separando o estado
/// reativo e as consultas de domínio do adaptador de persistência [ArmazenamentoLocalCaderneta].
class RepositorioCadernetaLocal implements RepositorioCaderneta {
  static RepositorioCadernetaLocal? _instanciaCompartilhada;

  /// Retorna ou instancia a instância singleton do repositório.
  static RepositorioCadernetaLocal get instancia =>
      _instanciaCompartilhada ??= RepositorioCadernetaLocal();

  /// Permite sobrescrever a instância singleton para fins de teste.
  @visibleForTesting
  static set instancia(RepositorioCadernetaLocal? substituto) {
    _instanciaCompartilhada = substituto;
  }

  final ArmazenamentoLocalCaderneta _armazenamento;
  final ValueNotifier<List<Cadena>> _cadenasNotifier =
      ValueNotifier<List<Cadena>>(const []);
  final ValueNotifier<PerfilEscalador> _perfilNotifier =
      ValueNotifier<PerfilEscalador>(PerfilEscalador.criarPadrao());

  final List<Cadena> _cadenas = [];

  /// Construtor que aceita opcionalmente um [ArmazenamentoLocalCaderneta] ou [SharedPreferences].
  RepositorioCadernetaLocal({
    SharedPreferences? preferencias,
    ArmazenamentoLocalCaderneta? armazenamento,
  }) : _armazenamento =
           armazenamento ??
           ArmazenamentoLocalCaderneta(preferencias: preferencias);

  @override
  ValueListenable<List<Cadena>> get cadenasNotifier => _cadenasNotifier;

  @override
  ValueListenable<PerfilEscalador> get perfilNotifier => _perfilNotifier;

  @override
  Future<void> inicializar() async {
    _perfilNotifier.value = await _armazenamento.carregarOuCriarPerfil();
    _cadenas
      ..clear()
      ..addAll(await _armazenamento.carregarCadenas());
    _cadenasNotifier.value = List.unmodifiable(_cadenas);
  }

  @override
  Future<void> salvarCadena(Cadena cadena) async {
    final indiceExistente = _cadenas.indexWhere((c) => c.id == cadena.id);
    if (indiceExistente >= 0) {
      _cadenas[indiceExistente] = cadena;
    } else {
      _cadenas.insert(0, cadena);
    }

    await _armazenamento.salvarCadenas(_cadenas);
    _cadenasNotifier.value = List.unmodifiable(_cadenas);
  }

  @override
  Future<void> excluirCadena(String id) async {
    _cadenas.removeWhere((c) => c.id == id);
    await _armazenamento.salvarCadenas(_cadenas);
    _cadenasNotifier.value = List.unmodifiable(_cadenas);
  }

  @override
  List<Cadena> obterCadenasPorEscalada(String escaladaUid) {
    final filtradas = _cadenas
        .where((c) => c.escaladaUid == escaladaUid)
        .toList();
    filtradas.sort((a, b) => b.dataAscensao.compareTo(a.dataAscensao));
    return List.unmodifiable(filtradas);
  }

  @override
  Cadena? obterMelhorAscensao(String escaladaUid) {
    final ascensoes = obterCadenasPorEscalada(escaladaUid);
    if (ascensoes.isEmpty) return null;

    final ordenadas = List<Cadena>.from(ascensoes)
      ..sort((a, b) {
        final prioridade = b.prioridadeVisual.compareTo(a.prioridadeVisual);
        if (prioridade != 0) return prioridade;
        return b.dataAscensao.compareTo(a.dataAscensao);
      });

    return ordenadas.first;
  }

  @override
  Future<void> salvarPerfil(PerfilEscalador perfil) async {
    _perfilNotifier.value = perfil;
    await _armazenamento.salvarPerfil(perfil);
  }

  @override
  PerfilEscalador obterPerfil() => _perfilNotifier.value;

  @override
  EstatisticasCaderneta calcularEstatisticas({
    String? Function(String escaladaUid)? obterGrauDaVia,
  }) {
    return EstatisticasCaderneta.calcular(
      _cadenas,
      obterGrauDaVia: obterGrauDaVia,
    );
  }
}
