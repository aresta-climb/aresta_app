import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'zip_interceptor_client.dart';
import 'package:path_provider/path_provider.dart';
import '../aresta_api/proto/generated/indice.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Representa o estado de sincronização do aplicativo.
enum SyncStatus {
  updated,
  updating,
  outdated,
  error,
  justUpdated
}

class TopoDataset {
  final List<Map<String, dynamic>> availablePicos;
  final List<Map<String, dynamic>> downloadedPicos;

  TopoDataset({
    required this.availablePicos,
    required this.downloadedPicos,
  });
}

/// Um repositório que gerencia a sincronização e o armazenamento de dados de escalada.
/// 
/// Ele atua como o gerenciador de estado central para informações de picos, lidando com
/// armazenamento local, downloads e a lógica de prioridade de guias.
class DatasetRepository {
  final EditorDeCroqui editorDeCroqui;

  static DatasetRepository? _instance;
  static DatasetRepository? get instance => _instance;

  DatasetRepository({required this.editorDeCroqui}) {
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

  /// Notifica os ouvintes sobre o status de sincronização atual.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.updating);

  /// Gatilho para resetar a página Home (carrossel).
  final ValueNotifier<int> homeResetTrigger = ValueNotifier(0);

  /// Rastreia quais picos estão sendo baixados no momento
  final ValueNotifier<Set<String>> downloadingCrags = ValueNotifier({});


  // ===========================================================================
  // SECTION: Carregamento de Dados e Inicialização
  // ===========================================================================

  /// Inicializa o repositório carregando o índice do armazenamento local.
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localIndiceFile = File(editorDeCroqui.indicePath(directory.path));
      
      if (await localIndiceFile.exists()) {
        final bytes = await localIndiceFile.readAsBytes();
        final localIndice = Indice.fromBuffer(bytes);
        await loadIndiceToMemory(localIndice);
      } else {
        loadEmpty();
      }
    } catch (e) {
      debugPrint('[DatasetRepo] Erro na inicialização: $e');
      loadEmpty();
    }
  }

  /// Processa um [Indice] protobuf e atualiza o [activeDataset].
  /// 
  /// Ele mapeia os dados do protobuf para uma lista de mapas e identifica quais picos
  /// já estão armazenados localmente.
  Future<void> loadIndiceToMemory(Indice indice) async {
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
          final List<String> urlParts = resumo.url.split('/');
          if (urlParts.length >= 2) {
            String folderName = urlParts[urlParts.length - 2];
            locationText = folderName.replaceAll('_', ' ').split(' ').map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            }).join(' ');
          }

          // Cálculo de URL de thumbnail
          String thumbnailUrl = '';
          final url = resumo.url;
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
          
          debugPrint('[DatasetRepo] Verificando $picoId: isStored=$isStored (Exp=${editorDeCroqui.isExperimentalMode.value})');
          if (isStored) {
            debugPrint('[DatasetRepo] -> Encontrado em: ${file.path}');
          }

          final Map<String, dynamic> picoMap = {
            'nome': resumo.nome,
            'local': locationText,
            'id': picoId,
            'url': '${editorDeCroqui.activeBaseUrl}/${resumo.url}',
            'checksum': resumo.checksumSha256Croqui,
            'thumbnailUrl': thumbnailUrl,
            'isDownloaded': isStored,
            'dataUpdate': resumo.hasTimestampUpdate() ? resumo.timestampUpdate.toDateTime().toIso8601String() : null,
          };

          parsedPicos.add(picoMap);
          if (isStored) {
            downloaded.add(picoMap);
          }
        } catch (itemEx) {
          debugPrint('Error parsing individual crag ${resumo.id}: $itemEx');
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
      await Future.wait(downloaded.map((picoData) async {
        try {
          await updatePicoMetadata(picoData['id'], picoData, docsPath);
        } catch (e) {
          debugPrint('Error updating metadata for ${picoData['id']}: $e');
        }
      }));

      // 4. Notifica a UI
      activeDataset.value = TopoDataset(
        availablePicos: parsedPicos,
        downloadedPicos: downloaded,
      );
    } catch (e) {
      debugPrint('Critical error in loadIndiceToMemory: $e');
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
  Future<void> _updateDatasetAfterDownload(String id) async {
    if (activeDataset.value != null) {
      final updatedDownloaded = await _filterDownloaded(activeDataset.value!.availablePicos);
      activeDataset.value = TopoDataset(
        availablePicos: activeDataset.value!.availablePicos,
        downloadedPicos: updatedDownloaded,
      );
    }
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
            if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
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
      debugPrint('Error reading priority list: $e');
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
      
      String yamlContent = priorityList.map((itemId) => '- "$itemId"').join('\n');
      await yamlFile.writeAsString(yamlContent);
    } catch (e) {
      debugPrint('Error updating priority list: $e');
    }
  }
  
  /// Atualiza apenas a lista de prioridades (usado após a navegação para evitar saltos na interface do usuário)
  Future<void> updatePriorityAfterNavigation(String id) async {
    await _updatePriority(id);
    // Notifica os ouvintes do conjunto de dados que algo mudou (ordenação)
    if (activeDataset.value != null) {
      final updated = await _filterDownloaded(activeDataset.value!.availablePicos);
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
  Future<List<Map<String, dynamic>>> _filterDownloaded(List<Map<String, dynamic>> picos) async {
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

  /// Realiza o download completo de um Crag e seus arquivos associados para o armazenamento local.
  /// 
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    final String? url = crag['url'];
    final String? id = crag['id'];

    if (url == null || id == null) return false;

    // Marca como baixando
    downloadingCrags.value = {...downloadingCrags.value, id};

    try {
      debugPrint('Baixando pico $id de $url...');
      
      Uint8List bytes;
      final client = ZipInterceptorClient();
      var response = await client.get(Uri.parse(url));

      // Fallback para modo experimental: se falhar e a URL tiver 'picos/', tentamos sem o prefixo
      if (response.statusCode != 200 && editorDeCroqui.isExperimentalMode.value && url.contains('/picos/')) {
        final altUrl = url.replaceFirst('/picos/', '/');
        debugPrint('Fallback do Modo Experimental: Tentando $altUrl');
        response = await client.get(Uri.parse(altUrl));
      }

      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      } else {
        debugPrint('Failed to fetch croqui binary from $url (Status: ${response.statusCode})');
        return false;
      }

      if (true) { // Substituindo o bloco do response.statusCode == 200
        final directory = await getApplicationDocumentsDirectory();
        final downloadsPath = editorDeCroqui.downloadsPath(directory.path);
        final downloadsDir = Directory('$downloadsPath/$id');
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$id.binarypb');
        await file.writeAsBytes(bytes);
        
        debugPrint('Saved to: ${file.path}');

        // Atualiza o conjunto de dados para que a interface saiba que há um novo download (parcial)
        await _updateDatasetAfterDownload(id);
        TelemetryService.instance.logBaixarCroqui(id);

        // --- Baixa todos os Arquivos Externos (Imagens/Markdowns) em Paralelo ---
        try {
          final parsedPico = Croqui.fromBuffer(bytes);
          
          String baseDir = '';
          final baseUrl = editorDeCroqui.activeBaseUrl;
          if (url.startsWith(baseUrl)) {
            String relative = url.substring(baseUrl.length);
            if (relative.startsWith('/')) relative = relative.substring(1);
            int lastSlash = relative.lastIndexOf('/');
            if (lastSlash != -1) {
              baseDir = relative.substring(0, lastSlash);
            }
          } else {
             // Fallback se a URL não começar com baseUrl por algum motivo
             int lastSlash = url.lastIndexOf('/');
             if (lastSlash != -1) {
                baseDir = url.substring(url.indexOf('://') + 3); // strip https://
                baseDir = baseDir.substring(baseDir.indexOf('/')); // strip domain
                if (baseDir.startsWith('/')) baseDir = baseDir.substring(1);
                baseDir = baseDir.substring(0, baseDir.lastIndexOf('/'));
             }
          }

          // Coleta todos os caminhos de imagem a serem baixados
          final Set<String> pathsToDownload = {};

          // 1. Arquivos externos explícitos
          for (var ext in parsedPico.arquivosExternos) {
            pathsToDownload.add(ext.caminho);
          }

          // 2. Extrai caminhos de mapas
          for (var pico in parsedPico.picos) {
            for (var sog in pico.setoresOuGrupos) {
              if (sog.whichTipo() == SetorOuGrupo_Tipo.setor && sog.setor.hasConteudo()) {
                for (var mapa in sog.setor.conteudo.mapas) {
                  if (mapa.caminhoImagemMapa.isNotEmpty) {
                    String cleanPath = mapa.caminhoImagemMapa;
                    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                    if (baseDir.isNotEmpty && !cleanPath.startsWith(baseDir)) {
                      pathsToDownload.add('$baseDir/$cleanPath');
                    } else {
                      pathsToDownload.add(cleanPath);
                    }
                  }
                }
              } else if (sog.whichTipo() == SetorOuGrupo_Tipo.grupo && sog.grupo.hasConteudo()) {
                for (var mapa in sog.grupo.conteudo.mapas) {
                  if (mapa.caminhoImagemMapa.isNotEmpty) {
                    String cleanPath = mapa.caminhoImagemMapa;
                    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                    if (baseDir.isNotEmpty && !cleanPath.startsWith(baseDir)) {
                      pathsToDownload.add('$baseDir/$cleanPath');
                    } else {
                      pathsToDownload.add(cleanPath);
                    }
                  }
                }
                for (var arquivoSetor in sog.grupo.conteudo.setores) {
                  if (arquivoSetor.hasConteudo()) {
                    for (var mapa in arquivoSetor.conteudo.mapas) {
                      if (mapa.caminhoImagemMapa.isNotEmpty) {
                        String cleanPath = mapa.caminhoImagemMapa;
                        if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                        if (baseDir.isNotEmpty && !cleanPath.startsWith(baseDir)) {
                          pathsToDownload.add('$baseDir/$cleanPath');
                        } else {
                          pathsToDownload.add(cleanPath);
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // 3. Extrai caminhos de imagens markdown
          final jsonStr = jsonEncode(parsedPico.toProto3Json());
          final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
          final matches = regex.allMatches(jsonStr);
          for (final match in matches) {
            if (match.groupCount >= 1) {
              String path = match.group(1)!;
              if (!path.startsWith('http://') && !path.startsWith('https://')) {
                if (path.startsWith('./')) path = path.substring(2);
                if (path.startsWith('/')) path = path.substring(1);
                
                if (baseDir.isNotEmpty && !path.startsWith(baseDir)) {
                  pathsToDownload.add('$baseDir/$path');
                } else {
                  pathsToDownload.add(path);
                }
              }
            }
          }

          // Baixa todos os arquivos em paralelo
          await Future.wait(pathsToDownload.map((caminho) async {
            try {
              final imageUrl = '$baseUrl/$caminho';
              final imgResponse = await client.get(Uri.parse(imageUrl));
              if (imgResponse.statusCode == 200) {
                final imgFile = File('${downloadsDir.path}/$caminho');
                if (!await imgFile.parent.exists()) {
                  await imgFile.parent.create(recursive: true);
                }
                await imgFile.writeAsBytes(imgResponse.bodyBytes);
                debugPrint('Downloading $caminho');
              } else {
                debugPrint('Failed to download $caminho, status: ${imgResponse.statusCode}');
              }
            } catch (e) {
              debugPrint('Error downloading $caminho: $e');
            }
          }));

        // Após o download paralelo, atualiza o caminho da capa
        await updatePicoMetadata(id, crag, directory.path, parsedPico: parsedPico);

        // Atualiza o estado global para que os ícones mudem em tempo real
        await _refreshActiveDataset();

        return true;
      } catch (downloadEx) {
        debugPrint('Error during parallel download for $id: $downloadEx');
      }

      return true;
    }
  } catch (e) {
      debugPrint('Error downloading crag: $e');
    } finally {
      // Desmarca como baixando, independentemente de sucesso ou falha
      downloadingCrags.value = {...downloadingCrags.value}..remove(id);
    }
    return false;
  }

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
      debugPrint('Error loading croqui $id: $e');
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
        debugPrint('[DatasetRepo] Pasta não encontrada para deleção: ${dir.path}');
      }
    } catch (e) {
      debugPrint('[DatasetRepo] Erro ao deletar crag: $e');
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

    // 3. Emite novo estado
    activeDataset.value = TopoDataset(
      availablePicos: currentAvailable,
      downloadedPicos: updatedDownloaded,
    );
  }

  // ===========================================================================
  // SECTION: Metadados e Resolução de Imagens
  // ===========================================================================

  /// Extrai e atualiza o caminho da imagem de capa (capaPath) e outros metadados no mapa do pico.
  Future<void> updatePicoMetadata(String id, Map<String, dynamic> picoData, String docsPath, {Croqui? parsedPico}) async {
    try {
      Croqui croqui;
      if (parsedPico != null) {
        croqui = parsedPico;
      } else {
        final downloadsPath = editorDeCroqui.downloadsPath(docsPath);
        final picoFile = File('$downloadsPath/$id/$id.binarypb');
        if (!picoFile.existsSync()) return;
        croqui = Croqui.fromBuffer(await picoFile.readAsBytes());
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
              File? foundFile = _findImageRecursively('$downloadsPath/$id', fileName);
              if (foundFile != null) {
                imgFile = foundFile;
              } else {
                imgFile = imgFile; // Mantém o original se nada for encontrado
              }
            }
          } else {
            // Se já for apenas o nome do arquivo, tenta a busca recursiva
            File? foundFile = _findImageRecursively('$downloadsPath/$id', capaPath);
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
      debugPrint('Error updating capa path for $id: $e');
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
      debugPrint('Error during recursive image search: $e');
    }
    return null;
  }

  /// Tenta encontrar a primeira imagem em um arquivo markdown intitulado "capa".
  String? _extractCapaPathFromMarkdown(Croqui croqui, String baseDir) {
    try {
      final capaBotao = croqui.botoes.firstWhere(
        (b) => b.texto.toLowerCase().contains('capa') && b.hasDestino() && b.destino.hasSecaoTextual(),
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
      debugPrint('Error extracting capa from markdown: $e');
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
