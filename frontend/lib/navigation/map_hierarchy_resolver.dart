import '../aresta_api/proto/generated/croqui.pb.dart';
import 'navigation_tree.dart' show CarrosselItemData;

/// Representa o destino de navegação hierárquica a partir de um mapa.
/// 
/// Contém a lista de dados dos mapas alvo a serem exibidos, o rótulo para o botão de interface
/// (por exemplo, nome do Grupo ou "Mapa Geral"), e os contextos necessários
/// para inicializar o visualizador (como [grupoContext] e [setorContext]).
class MapDestination {
  final List<CarrosselItemData> mapasData;
  final String label;
  final Grupo? grupoContext;
  final Setor? setorContext;

  MapDestination({
    required this.mapasData,
    required this.label,
    this.grupoContext,
    this.setorContext,
  });
}

class MapHierarchyResolver {
  /// Avalia os contextos atuais (Setor e Grupo) para descobrir o mapa de nível superior.
  /// 
  /// A hierarquia de navegação funciona assim:
  /// 1. Mapa de Setor -> "Sobe" para Mapa do Grupo (se houver).
  /// 2. Mapa de Setor (sem Mapa do Grupo) ou Mapa do Grupo -> "Sobe" para Mapa Geral (se houver).
  /// 3. Mapa Geral -> Nulo (topo da hierarquia).
  ///
  /// Retorna um objeto [MapDestination] com as informações do próximo mapa acima, 
  /// ou `null` caso não haja mapa de nível superior disponível.
  static MapDestination? resolveUpDestination({
    required Pico pico,
    Setor? setorContext,
    Grupo? grupoContext,
  }) {
    // 0. Se estamos visualizando o Mapa Geral, não há para onde subir
    if (setorContext == null && grupoContext == null) {
      return null;
    }

    // 1. Se estivermos visualizando um Setor, e ele pertencer a um Grupo que possui mapas
    if (setorContext != null && grupoContext != null && grupoContext.mapas.isNotEmpty) {
      // Retorna todos os mapas do Grupo
      final mapasData = grupoContext.mapas.map((m) => CarrosselItemData(
        mapaCaminhoImagem: m.caminhoImagemMapa,
        grupoContextNome: grupoContext.nome,
      )).toList();

      return MapDestination(
        mapasData: mapasData,
        label: grupoContext.nome,
        grupoContext: grupoContext,
        setorContext: null, // Subiu de Setor para Grupo, então perde o contexto de Setor
      );
    }

    // 2. Se estivermos num Grupo, ou num Setor sem Grupo (ou cujo grupo não tem mapa)
    // Verificamos se o Pico tem Mapas Gerais
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo() && pico.mapasGerais.conteudo.mapas.isNotEmpty) {
      final mapasData = pico.mapasGerais.conteudo.mapas.map((m) => CarrosselItemData(
        mapaCaminhoImagem: m.caminhoImagemMapa,
      )).toList();

      return MapDestination(
        mapasData: mapasData,
        label: 'Mapa Geral',
        grupoContext: null, // Subiu para o Geral, perde o contexto de Grupo
        setorContext: null, // Subiu para o Geral, perde o contexto de Setor
      );
    }

    // 3. Sem nível superior disponível
    return null;
  }
}
