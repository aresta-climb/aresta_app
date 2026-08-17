import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'editor_croqui.dart';
import 'package:frontend/services/firebase/app_logger.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/network_constants.dart';

class TopoDataset {
  final List<Map<String, dynamic>> availablePicos;
  final List<Map<String, dynamic>> downloadedPicos;

  TopoDataset({required this.availablePicos, required this.downloadedPicos});
}

/// Um repositório que gerencia a sincronização e o armazenamento de dados de escalada.
///
/// Ele atua como o gerenciador de estado central para informações de picos, lidando com
/// armazenamento local, downloads e a lógica de prioridade de guias.
class DatasetRepository {
  final EditorDeCroqui editorDeCroqui;
  AssetBundle? assetBundle;

  static DatasetRepository? _instance;
  static DatasetRepository? get instance => _instance;

  DatasetRepository({required this.editorDeCroqui, this.assetBundle}) {
    _instance = this;
    // Ouve mudanças no modo experimental/editor para recarregar o índice
    editorDeCroqui.isExperimentalMode.addListener(_handleModeChange);
    editorDeCroqui.editorUrl.addListener(_handleModeChange);
  }

  void _handleModeChange() {
    debugPrint('[DatasetRepo] Modo alterado detectado. Recarregando índice...');
    init();
  }

  // ===========================================================================
  // SECTION: Estado e Notificadores
  // ===========================================================================

  /// Isso notifica a interface do usuário sempre que os dados mudam
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(null);

  /// Armazena o índice completo em memória
  final ValueNotifier<Indice?> indiceData = ValueNotifier(null);

  /// Gatilho para resetar a página Home (carrossel).
  final ValueNotifier<int> homeResetTrigger = ValueNotifier(0);

  // ===========================================================================
  // SECTION: Carregamento de Dados e Inicialização
  // ===========================================================================

  /// Inicializa o repositório carregando o índice do armazenamento local.
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File(editorDeCroqui.indicePath(directory.path));

      if (!await localIndiceFile.exists()) {
        await _unpackPreloadedAssets(directory.path);
      }

      if (await localIndiceFile.exists()) {
        final bytes = await localIndiceFile.readAsBytes();
        final localIndice = Indice.fromBuffer(bytes);
        indiceData.value = localIndice;
        await loadIndiceToMemory(localIndice);
      } else {
        loadEmpty();
      }
    } catch (e) {
      AppLogger.instance.logError(
        '[DatasetRepo] Erro na inicialização',
        error: e,
      );
      loadEmpty();
    }
  }

  /// Extrai os assets pré-baixados (pre-bundled) do pacote do aplicativo (bundle)
  /// e os copia para o diretório de documentos do dispositivo.
  ///
  /// Isso é feito apenas na primeira vez que o app é inicializado sem cache local,
  /// garantindo que o usuário tenha um 'indice.binarypb' e as thumbnails iniciais
  /// sem precisar de internet para o primeiro acesso.
  /// Se houver qualquer falha durante a extração de um item específico, o erro será logado.
  Future<void> _unpackPreloadedAssets(String docsPath) async {
    try {
      final bundle = assetBundle ?? rootBundle;

      ByteData? indiceData;
      try {
        // Tenta carregar o índice principal pré-empacotado.
        indiceData = await bundle.load('assets/preload/indice.binarypb');
      } catch (e) {
        // Se falhar (por exemplo, pasta preload não existe no build), loga o erro e aborta o unpack
        AppLogger.instance.logError(
          '[DatasetRepo] Preload de indice.binarypb não encontrado ou erro ao carregar',
          error: e,
        );
        return;
      }

      // Escreve o índice localmente para uso imediato pelo app
      final indiceFile = File(editorDeCroqui.indicePath(docsPath));
      await indiceFile.writeAsBytes(
        indiceData.buffer.asUint8List(
          indiceData.offsetInBytes,
          indiceData.lengthInBytes,
        ),
      );

      final indice = Indice.fromBuffer(
        indiceData.buffer.asUint8List(
          indiceData.offsetInBytes,
          indiceData.lengthInBytes,
        ),
      );
      final thumbnailsDir = Directory('$docsPath/thumbnails');
      if (!thumbnailsDir.existsSync()) {
        thumbnailsDir.createSync(recursive: true);
      }

      // Itera sobre todos os croquis do índice para tentar extrair suas respectivas thumbnails pré-baixadas
      for (var resumo in indice.croquis) {
        final urlRelativa = resumo.caminhoRelativo;
        final lastSlash = urlRelativa.lastIndexOf('/');
        if (lastSlash != -1) {
          final baseDir = urlRelativa.substring(0, lastSlash);
          final String cragId = resumo.id.isNotEmpty
              ? resumo.id
              : baseDir.replaceAll('/', '_');

          try {
            // Extrai a thumbnail do bundle e salva na pasta local de thumbnails do aplicativo
            final thumbData = await bundle.load(
              'assets/preload/thumbnails/$cragId.webp',
            );
            final thumbFile = File('${thumbnailsDir.path}/$cragId.webp');
            await thumbFile.writeAsBytes(
              thumbData.buffer.asUint8List(
                thumbData.offsetInBytes,
                thumbData.lengthInBytes,
              ),
            );
          } catch (e) {
            // Em vez de ignorar silenciosamente as falhas de thumbnail, registramos o erro no log
            AppLogger.instance.logError(
              '[DatasetRepo] Erro ao carregar thumbnail $cragId do preload',
              error: e,
            );
          }
        }
      }

      // Evita que o app considere esta instalação limpa como "precisando de migração",
      // registrando a versão dos dados recém pré-carregados.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    } catch (e) {
      AppLogger.instance.logError(
        '[DatasetRepo] Erro geral ao descompactar assets',
        error: e,
      );
    }
  }

  /// Processa um [Indice] protobuf e atualiza o [activeDataset].
  ///
  /// Ele mapeia os dados do protobuf para uma lista de mapas e identifica quais picos
  /// já estão armazenados localmente.
  Future<void> loadIndiceToMemory(Indice indice) async {
    indiceData.value = indice;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<String> priorityList = await _getPriorityList();
      final String docsPath = directory.path;

      // 1. Mapeia os picos e já verifica se estão baixados localmente
      final List<Map<String, dynamic>> parsedPicos = [];
      final List<Map<String, dynamic>> downloaded = [];

      for (var resumo in indice.croquis) {
        try {
          // Extração segura de localização
          String locationText = 'Local Desconhecido';
          final List<String> urlParts = resumo.caminhoRelativo.split('/');
          if (urlParts.length >= 2) {
            String folderName = urlParts[urlParts.length - 2];
            locationText = folderName
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() +
                      word.substring(1).toLowerCase();
                })
                .join(' ');
          }

          // Cálculo de URL de thumbnail
          String thumbnailUrl = '';
          final url = resumo.caminhoRelativo;
          final lastSlash = url.lastIndexOf('/');
          final baseUrl = editorDeCroqui.activeBaseUrl;
          if (lastSlash != -1) {
            final baseDir = url.substring(0, lastSlash);
            thumbnailUrl = '$baseUrl/$baseDir/imagens/thumbnail.webp';
          } else {
            thumbnailUrl = '$baseUrl/imagens/thumbnail.webp';
          }

          // Verifica se está baixado (lógica do _filterDownloaded integrada)
          final String picoId = resumo.id;
          final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
          final file = File('$downloadsPath/$picoId/$picoId.binarypb');
          final bool isStored = await file.exists();

          debugPrint(
            '[DatasetRepo] Verificando $picoId: isStored=$isStored (Exp=${editorDeCroqui.isExperimentalMode.value})',
          );
          if (isStored) {
            debugPrint('[DatasetRepo] -> Encontrado em: ${file.path}');
          }

          final Map<String, dynamic> picoMap = {
            'nome': resumo.nome,
            'local': locationText,
            'descricao': resumo.descricao,
            'id': picoId,
            'url': '${editorDeCroqui.activeBaseUrl}/${resumo.caminhoRelativo}',
            'checksum': resumo.checksumSha256Croqui,
            'thumbnailUrl': thumbnailUrl,
            'isDownloaded': isStored,
            'dataUpdate': resumo.hasTimestampUpdate()
                ? resumo.timestampUpdate.toDateTime().toIso8601String()
                : null,
            if (resumo.hasLocalizacao())
              'latitude': resumo.localizacao.latitude / 10000000.0,
            if (resumo.hasLocalizacao())
              'longitude': resumo.localizacao.longitude / 10000000.0,
            if (resumo.hasPrecomputados())
              'estatisticas': {
                'totalVias': resumo.precomputados.totalEscaladas,
                'totalSetores': resumo.precomputados.totalSetores,
                'totalEsportivas': resumo.precomputados.totalEsportivas,
                'totalMoveis': resumo.precomputados.totalMoveis,
                'totalBoulders': resumo.precomputados.totalBoulders,
                'totalMultiplasEnfiadas': resumo.precomputados.totalMultiplasEnfiadas,
                'totalHighlines': resumo.precomputados.totalHighlines,
              },
          };

          parsedPicos.add(picoMap);
          if (isStored) {
            downloaded.add(picoMap);
          }
        } catch (itemEx) {
          AppLogger.instance.logError(
            'Error parsing individual crag ${resumo.id}',
            error: itemEx,
          );
        }
      }

      // 2. Ordena os baixados pela prioridade
      downloaded.sort((a, b) {
        String idA;
        if (a['id'] != null) {
          idA = a['id'];
        } else {
          idA = '';
        }

        String idB;
        if (b['id'] != null) {
          idB = b['id'];
        } else {
          idB = '';
        }

        int indexA = priorityList.indexOf(idA);
        int indexB = priorityList.indexOf(idB);

        if (indexA == -1) {
          indexA = 999999;
        }
        if (indexB == -1) {
          indexB = 999999;
        }
        return indexA.compareTo(indexB);
      });

      // 3. Atualiza metadados (capas, etc) em paralelo para os baixados
      await Future.wait(
        downloaded.map((picoData) async {
          try {
            await updatePicoMetadata(picoData['id'], picoData, docsPath);
          } catch (e) {
            AppLogger.instance.logError(
              'Error updating metadata for ${picoData['id']}',
              error: e,
            );
          }
        }),
      );

      // 4. Notifica a UI
      activeDataset.value = TopoDataset(
        availablePicos: parsedPicos,
        downloadedPicos: downloaded,
      );
    } catch (e) {
      AppLogger.instance.logError(
        'Critical error in loadIndiceToMemory',
        error: e,
      );
      // Se falhar tudo, tenta ao menos manter o estado anterior ou limpar se estiver nulo
      if (activeDataset.value == null) {
        loadEmpty();
      }
    }
  }

  /// Define o conjunto de dados para um estado vazio.
  void loadEmpty() {
    activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);
  }

  /// Atualiza o conjunto de dados ativo após um download bem-sucedido.
  Future<void> updateDatasetAfterDownload(String id) async {
    await _refreshActiveDataset();
  }

  // ===========================================================================
  // SECTION: Prioridade e Acessados Recentemente
  // ===========================================================================

  /// Recupera a lista de IDs de picos acessados recentemente do armazenamento local.
  Future<List<String>> _getPriorityList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final yamlFile = File('${directory.path}/recent_picos.yaml');
      final jsonFile = File('${directory.path}/recent_picos.json');

      if (await yamlFile.exists()) {
        // Limpa o arquivo JSON restante se ele existir junto com o arquivo YAML
        if (await jsonFile.exists()) {
          try {
            await jsonFile.delete();
          } catch (_) {}
        }

        final content = await yamlFile.readAsString();
        final List<String> list = [];
        for (var line in content.split('\n')) {
          line = line.trim();
          if (line.startsWith('- ')) {
            String val = line.substring(2).trim();
            if ((val.startsWith('"') && val.endsWith('"')) ||
                (val.startsWith("'") && val.endsWith("'"))) {
              val = val.substring(1, val.length - 1);
            }
            list.add(val);
          }
        }
        return list;
      } else if (await jsonFile.exists()) {
        // Migração de JSON para YAML
        final content = await jsonFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final list = jsonList.cast<String>();

        // Escreve o novo arquivo YAML e exclui o antigo arquivo JSON
        String yamlContent = list.map((id) => '- "$id"').join('\n');
        await yamlFile.writeAsString(yamlContent);
        await jsonFile.delete();

        return list;
      }
    } catch (e) {
      AppLogger.instance.logError('Error reading priority list', error: e);
    }
    return [];
  }

  /// Atualiza a lista "Recentes" movendo o [id] fornecido para o topo da prioridade.
  Future<void> _updatePriority(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final yamlFile = File('${directory.path}/recent_picos.yaml');
      List<String> priorityList = await _getPriorityList();

      priorityList.remove(id);
      priorityList.insert(0, id);

      String yamlContent = priorityList
          .map((itemId) => '- "$itemId"')
          .join('\n');
      await yamlFile.writeAsString(yamlContent);
    } catch (e) {
      AppLogger.instance.logError('Error updating priority list', error: e);
    }
  }

  /// Atualiza apenas a lista de prioridades (usado após a navegação para evitar saltos na interface do usuário)
  Future<void> updatePriorityAfterNavigation(String id) async {
    await _updatePriority(id);
    // Notifica os ouvintes do conjunto de dados que algo mudou (ordenação)
    if (activeDataset.value != null) {
      final updated = await _filterDownloaded(
        activeDataset.value!.availablePicos,
      );
      activeDataset.value = TopoDataset(
        availablePicos: activeDataset.value!.availablePicos,
        downloadedPicos: updated,
      );
    }
  }

  // ===========================================================================
  // SECTION: Dados Locais e Filtragem
  // ===========================================================================

  /// Filtra e ordena a lista de picos com base no que está disponível localmente.
  ///
  /// Os picos são ordenados de acordo com a lista de prioridades (os mais recentes primeiro).
  Future<List<Map<String, dynamic>>> _filterDownloaded(
    List<Map<String, dynamic>> picos,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final List<String> priorityList = await _getPriorityList();
    final List<Map<String, dynamic>> downloaded = [];

    final downloadsPath = editorDeCroqui.downloadsPath(directory.path);
    for (var pico in picos) {
      final file = File('$downloadsPath/${pico['id']}/${pico['id']}.binarypb');
      if (await file.exists()) {
        downloaded.add(pico);
      }
    }

    // Ordena com base no índice em priorityList (índice menor = prioridade maior)
    // Itens que não estão na lista são colocados no final, portanto não aparecem no carrossel, apenas na lista suspensa
    downloaded.sort((a, b) {
      int indexA = priorityList.indexOf(a['id']);
      int indexB = priorityList.indexOf(b['id']);
      // Fallback for items not in the list (put them at the end)
      if (indexA == -1) indexA = 999999;
      if (indexB == -1) indexB = 999999;
      return indexA.compareTo(indexB);
    });

    return downloaded;
  }

  // ===========================================================================
  // SECTION: Sincronização e Downloads
  // ===========================================================================

  /// Carrega os dados completos do [Croqui] de um arquivo local.
  Future<Croqui?> getCroqui(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = editorDeCroqui.downloadsPath(directory.path);
      final file = File('$downloadsPath/$id/$id.binarypb');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return Croqui.fromBuffer(bytes);
      }
    } catch (e) {
      AppLogger.instance.logError('Error loading croqui $id', error: e);
    }
    return null;
  }

  /// Exclui o binarypb de um pico do armazenamento local e atualiza o conjunto de dados.
  Future<bool> deleteCrag(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = editorDeCroqui.downloadsPath(directory.path);
      final dir = Directory('$downloadsPath/$id');

      debugPrint('[DatasetRepo] Deletando pico $id em $downloadsPath');

      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint('[DatasetRepo] Pasta deletada com sucesso.');

        // Atualiza o estado global para que os ícones mudem em tempo real
        await _refreshActiveDataset();
        return true;
      } else {
        debugPrint(
          '[DatasetRepo] Pasta não encontrada para deleção: ${dir.path}',
        );
      }
    } catch (e) {
      AppLogger.instance.logError(
        '[DatasetRepo] Erro ao deletar crag',
        error: e,
      );
    }
    return false;
  }

  /// Recarrega o estado de download de todos os picos e notifica a interface.
  /// Útil para manter os ícones de download sincronizados em tempo real.
  Future<void> _refreshActiveDataset() async {
    if (activeDataset.value == null) return;

    final currentAvailable = activeDataset.value!.availablePicos;
    final directory = await getApplicationDocumentsDirectory();
    final docsPath = directory.path;

    // 1. Re-verifica o status de download para todos
    final List<Map<String, dynamic>> updatedDownloaded = [];
    for (var pico in currentAvailable) {
      String picoId;
      if (pico['id'] != null) {
        picoId = pico['id'];
      } else {
        picoId = '';
      }

      final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
      final file = File('$downloadsPath/$picoId/$picoId.binarypb');
      final bool isStored = await file.exists();

      pico['isDownloaded'] = isStored;
      if (isStored) {
        updatedDownloaded.add(pico);
      }
    }

    // 2. Re-ordena os baixados
    final List<String> priorityList = await _getPriorityList();
    updatedDownloaded.sort((a, b) {
      String idA;
      if (a['id'] != null) {
        idA = a['id'];
      } else {
        idA = '';
      }

      String idB;
      if (b['id'] != null) {
        idB = b['id'];
      } else {
        idB = '';
      }

      int indexA = priorityList.indexOf(idA);
      int indexB = priorityList.indexOf(idB);

      if (indexA == -1) {
        indexA = 999999;
      }
      if (indexB == -1) {
        indexB = 999999;
      }
      return indexA.compareTo(indexB);
    });

    // 3. Atualiza metadados para todo mundo novamente para garantir
    await Future.wait(
      updatedDownloaded.map((p) => updatePicoMetadata(p['id'], p, docsPath)),
    );

    // 4. Emite novo estado
    activeDataset.value = TopoDataset(
      availablePicos: currentAvailable,
      downloadedPicos: updatedDownloaded,
    );
  }

  // ===========================================================================
  // SECTION: Metadados e Resolução de Imagens
  // ===========================================================================

  /// Extrai e atualiza o caminho da imagem de capa (capaPath) e outros metadados no mapa do pico.
  Future<void> updatePicoMetadata(
    String id,
    Map<String, dynamic> picoData,
    String docsPath, {
    Croqui? parsedPico,
  }) async {
    try {
      Croqui croqui;
      if (parsedPico != null) {
        croqui = parsedPico;
      } else {
        final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
        final picoFile = File('$downloadsPath/$id/$id.binarypb');
        if (!picoFile.existsSync()) {
          return;
        }
        croqui = Croqui.fromBuffer(await picoFile.readAsBytes());
      }

      if (croqui.picos.isNotEmpty) {
        picoData['data'] = {'pico': croqui.picos.first, 'croqui': croqui};
      }

      String baseDir = '';
      final baseUrl = editorDeCroqui.activeBaseUrl;
      final String? url = picoData['url'];
      if (url != null && url.startsWith(baseUrl)) {
        String relative = url.substring(baseUrl.length);
        if (relative.startsWith('/')) relative = relative.substring(1);
        int lastSlash = relative.lastIndexOf('/');
        if (lastSlash != -1) {
          baseDir = relative.substring(0, lastSlash);
        }
      }

      String? capaPath;
      // Prioridade 1: caminhoThumbnail explicitamente definido no croqui.pb
      if (croqui.hasCaminhoThumbnail() && croqui.caminhoThumbnail.isNotEmpty) {
        capaPath = croqui.caminhoThumbnail;
      }
      // Prioridade 2: Procurar por um markdown intitulado "capa" e extrair a primeira imagem
      else {
        capaPath = _extractCapaPathFromMarkdown(croqui, baseDir);
      }

      if (capaPath != null) {
        final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
        String fullPath = '$downloadsPath/$id/$capaPath';
        File imgFile = File(fullPath);

        // 1. Tenta o caminho direto
        if (!imgFile.existsSync()) {
          // 2. Tenta o caminho sem o baseDir (caso o croqui já traga o caminho completo)
          if (capaPath.contains('/')) {
            final fileName = capaPath.split('/').last;
            final directFile = File('$downloadsPath/$id/$fileName');
            if (directFile.existsSync()) {
              imgFile = directFile;
            } else {
              // 3. Fallback robusto: Busca recursiva pelo nome do arquivo (igual ao OfflineMarkdown)
              File? foundFile = _findImageRecursively(
                '$downloadsPath/$id',
                fileName,
              );
              if (foundFile != null) {
                imgFile = foundFile;
              } else {
                imgFile = imgFile; // Mantém o original se nada for encontrado
              }
            }
          } else {
            // Se já for apenas o nome do arquivo, tenta a busca recursiva
            File? foundFile = _findImageRecursively(
              '$downloadsPath/$id',
              capaPath,
            );
            if (foundFile != null) {
              imgFile = foundFile;
            } else {
              imgFile = imgFile; // Mantém o original se nada for encontrado
            }
          }
        }

        if (imgFile.existsSync()) {
          debugPrint('Cover image found for $id at: ${imgFile.path}');
          picoData['capaPath'] = imgFile.path;

          // Notifica os ouvintes se já estivermos com os dados carregados
          if (activeDataset.value != null) {
            // Criamos novas listas para garantir que o ValueNotifier dispare a atualização
            activeDataset.value = TopoDataset(
              availablePicos: List.from(activeDataset.value!.availablePicos),
              downloadedPicos: List.from(activeDataset.value!.downloadedPicos),
            );
          }
        } else {
          debugPrint('Cover image NOT found for $id. Attempted: $fullPath');
        }
      }
    } catch (e) {
      AppLogger.instance.logError('Error updating capa path for $id', error: e);
    }
  }

  /// Busca uma imagem recursivamente em um diretório pelo nome do arquivo.
  File? _findImageRecursively(String rootPath, String fileName) {
    try {
      final dir = Directory(rootPath);
      if (!dir.existsSync()) return null;

      final searchName = Uri.decodeComponent(fileName).toLowerCase();
      String searchBaseName = searchName;
      if (searchName.contains('.')) {
        searchBaseName = searchName.substring(0, searchName.lastIndexOf('.'));
      }

      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File) {
          final String ePath = entity.path.replaceAll('\\', '/');
          final String eName = ePath.split('/').last;
          final String eNameLower = Uri.decodeComponent(eName).toLowerCase();

          // Correspondência exata
          if (eNameLower == searchName) return entity;

          // Correspondência de nome base (lida com .webp vs .jpg)
          String eBaseName = eNameLower;
          if (eNameLower.contains('.')) {
            eBaseName = eNameLower.substring(0, eNameLower.lastIndexOf('.'));
          }

          if (eBaseName == searchBaseName) return entity;
        }
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Error during recursive image search',
        error: e,
      );
    }
    return null;
  }

  /// Tenta encontrar a primeira imagem em um arquivo markdown intitulado "capa".
  String? _extractCapaPathFromMarkdown(Croqui croqui, String baseDir) {
    try {
      final capaBotao = croqui.botoes.firstWhere(
        (b) =>
            b.texto.toLowerCase().contains('capa') &&
            b.hasDestino() &&
            b.destino.hasSecaoTextual(),
        orElse: () => Botao(),
      );

      if (capaBotao.hasDestino() && capaBotao.destino.hasSecaoTextual()) {
        final capaMd = capaBotao.destino.secaoTextual;
        if (capaMd.hasConteudo() && capaMd.conteudo.isNotEmpty) {
          final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
          final match = regex.firstMatch(capaMd.conteudo);
          if (match != null && match.groupCount >= 1) {
            String path = match.group(1)!;
            // Ignora URLs absolutas
            if (!path.startsWith('http')) {
              if (path.startsWith('./')) path = path.substring(2);
              if (path.startsWith('/')) path = path.substring(1);
              if (baseDir.isNotEmpty) {
                if (!path.startsWith(baseDir)) {
                  return '$baseDir/$path';
                } else {
                  return path;
                }
              } else {
                return path;
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logError(
        'Error extracting capa from markdown',
        error: e,
      );
    }
    return null;
  }

  // ===========================================================================
  // SECTION: Auxiliares de Interface (UI)
  // ===========================================================================

  /// Dispara um reset visual na página Home.
  void triggerHomeReset() {
    homeResetTrigger.value++;
  }
}
