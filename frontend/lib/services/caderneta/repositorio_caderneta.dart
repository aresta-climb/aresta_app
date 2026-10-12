// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
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
    String? Function(String escaladaUid)? resolvedorGrau,
  });
}

/// Implementação padrão local-first de [RepositorioCaderneta] utilizando persistência
/// atômica segura no dispositivo através de [SharedPreferences].
class RepositorioCadernetaLocal implements RepositorioCaderneta {
  static const String _chaveCadenas = 'aresta_cadenas_v1';
  static const String _chavePerfil = 'aresta_perfil_escalador_v1';

  static RepositorioCadernetaLocal? _instanciaCompartilhada;

  /// Retorna ou instancia a instância singleton do repositório.
  static RepositorioCadernetaLocal get instancia =>
      _instanciaCompartilhada ??= RepositorioCadernetaLocal();

  /// Permite sobrescrever a instância singleton para fins de teste.
  @visibleForTesting
  static set instancia(RepositorioCadernetaLocal? mock) {
    _instanciaCompartilhada = mock;
  }

  SharedPreferences? _preferencias;
  final ValueNotifier<List<Cadena>> _cadenasNotifier =
      ValueNotifier<List<Cadena>>(const []);
  final ValueNotifier<PerfilEscalador> _perfilNotifier =
      ValueNotifier<PerfilEscalador>(PerfilEscalador.criarPadrao());

  final List<Cadena> _cadenas = [];

  /// Construtor que aceita opcionalmente uma instância injetada de [SharedPreferences].
  RepositorioCadernetaLocal({SharedPreferences? preferencias})
      : _preferencias = preferencias;

  @override
  ValueListenable<List<Cadena>> get cadenasNotifier => _cadenasNotifier;

  @override
  ValueListenable<PerfilEscalador> get perfilNotifier => _perfilNotifier;

  @override
  Future<void> inicializar() async {
    _preferencias ??= await SharedPreferences.getInstance();

    // Carrega o perfil do atleta
    final jsonPerfil = _preferencias!.getString(_chavePerfil);
    if (jsonPerfil != null && jsonPerfil.isNotEmpty) {
      try {
        _perfilNotifier.value = PerfilEscalador.fromJson(jsonPerfil);
      } catch (_) {
        _perfilNotifier.value = PerfilEscalador.criarPadrao();
        await _persistirPerfil();
      }
    } else {
      _perfilNotifier.value = PerfilEscalador.criarPadrao();
      await _persistirPerfil();
    }

    // Carrega as cadenas salvas
    final jsonCadenas = _preferencias!.getString(_chaveCadenas);
    _cadenas.clear();
    if (jsonCadenas != null && jsonCadenas.isNotEmpty) {
      try {
        final lista = json.decode(jsonCadenas) as List<dynamic>;
        for (final item in lista) {
          if (item is Map<String, dynamic>) {
            _cadenas.add(Cadena.fromMap(item));
          }
        }
      } catch (_) {
        _cadenas.clear();
      }
    }

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

    await _persistirCadenas();
    _cadenasNotifier.value = List.unmodifiable(_cadenas);
  }

  @override
  Future<void> excluirCadena(String id) async {
    _cadenas.removeWhere((c) => c.id == id);
    await _persistirCadenas();
    _cadenasNotifier.value = List.unmodifiable(_cadenas);
  }

  @override
  List<Cadena> obterCadenasPorEscalada(String escaladaUid) {
    final filtradas =
        _cadenas.where((c) => c.escaladaUid == escaladaUid).toList();
    filtradas.sort((a, b) => b.dataAscensao.compareTo(a.dataAscensao));
    return List.unmodifiable(filtradas);
  }

  @override
  Cadena? obterMelhorAscensao(String escaladaUid) {
    final ascensoes = obterCadenasPorEscalada(escaladaUid);
    if (ascensoes.isEmpty) return null;

    final ordenadas = List<Cadena>.from(ascensoes)
      ..sort((a, b) {
        final prioridade =
            b.prioridadeVisual.compareTo(a.prioridadeVisual);
        if (prioridade != 0) return prioridade;
        return b.dataAscensao.compareTo(a.dataAscensao);
      });

    return ordenadas.first;
  }

  @override
  Future<void> salvarPerfil(PerfilEscalador perfil) async {
    _perfilNotifier.value = perfil;
    await _persistirPerfil();
  }

  @override
  PerfilEscalador obterPerfil() => _perfilNotifier.value;

  @override
  EstatisticasCaderneta calcularEstatisticas({
    String? Function(String escaladaUid)? resolvedorGrau,
  }) {
    return EstatisticasCaderneta.calcular(
      _cadenas,
      resolvedorGrau: resolvedorGrau,
    );
  }

  Future<void> _persistirCadenas() async {
    final mapList = _cadenas.map((c) => c.toMap()).toList();
    await _preferencias?.setString(_chaveCadenas, json.encode(mapList));
  }

  Future<void> _persistirPerfil() async {
    await _preferencias?.setString(
      _chavePerfil,
      _perfilNotifier.value.toJson(),
    );
  }
}
