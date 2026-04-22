import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../kmon_api/proto/indice.pb.dart';
import '../kmon_api/proto/croqui.pb.dart';

/// Representa o estado de sincronização do aplicativo.
enum SyncStatus {
  updated,
  updating,
  outdated,
  error 
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
  /// Isso notifica a interface do usuário sempre que os dados mudam
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(null);

  /// Notifica os ouvintes sobre o status de sincronização atual.
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.updating);

  /// Rastreia quais picos estão sendo baixados no momento
  final ValueNotifier<Set<String>> downloadingCrags = ValueNotifier({});

  // Backend do Github pages
  final String _baseUrl = 'https://acecmg.github.io/kmon_serving';

  /// Processa um [Indice] protobuf e atualiza o [activeDataset].
  /// 
  /// Ele mapeia os dados do protobuf para uma lista de mapas e identifica quais picos
  /// já estão armazenados localmente.
  Future<void> loadIndiceToMemory(Indice indice) async {
    final List<Map<String, dynamic>> parsedPicos = indice.croquis.map((resumo) {
      // TODO: Usando o campo de descrição como localização/subtítulo por enquanto
      String locationText;
      if (resumo.descricao.isNotEmpty) {
        locationText = resumo.descricao;
      } else {
        locationText = 'Local Desconhecido';
      }
      
      return {
        'nome': resumo.nome,
        'local': locationText,
        'id': resumo.id,
        'url': '$_baseUrl/${resumo.url}',
        'checksum': resumo.checksumSha256,
      };
    }).toList();

    // Identifica quais já foram baixados
    final List<Map<String, dynamic>> downloaded = await _filterDownloaded(parsedPicos);

    // Atualiza o gerenciador de estado, o que reconstrói instantaneamente as páginas Home e Browse
    activeDataset.value = TopoDataset(
      availablePicos: parsedPicos,
      downloadedPicos: downloaded,
    );
  }

  /// Define o conjunto de dados para um estado vazio.
  void loadEmpty() {
    activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);
  }

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

  /// Filtra e ordena a lista de picos com base no que está disponível localmente.
  /// 
  /// Os picos são ordenados de acordo com a lista de prioridades (os mais recentes primeiro).
  Future<List<Map<String, dynamic>>> _filterDownloaded(List<Map<String, dynamic>> picos) async {
    final directory = await getApplicationDocumentsDirectory();
    final List<String> priorityList = await _getPriorityList();
    final List<Map<String, dynamic>> downloaded = [];
    
    for (var pico in picos) {
      final file = File('${directory.path}/downloads/${pico['id']}/${pico['id']}.binarypb');
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

  /// Baixa o binarypb de um pico e seus arquivos externos associados para o armazenamento local.
  /// 
  /// Retorna [true] se as operações de download e salvamento forem bem-sucedidas.
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    final String? url = crag['url'];
    final String? id = crag['id'];

    if (url == null || id == null) return false;

    // Marca como baixando
    downloadingCrags.value = {...downloadingCrags.value, id};

    try {
      debugPrint('Downloading crag $id from $url...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads/$id');
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$id.binarypb');
        await file.writeAsBytes(response.bodyBytes);
        
        debugPrint('Saved to: ${file.path}');

        // Atualiza o conjunto de dados para que a interface saiba que há um novo download (parcial)
        if (activeDataset.value != null) {
          final updatedDownloaded = await _filterDownloaded(activeDataset.value!.availablePicos);
          activeDataset.value = TopoDataset(
            availablePicos: activeDataset.value!.availablePicos,
            downloadedPicos: updatedDownloaded,
          );
        }

        // --- Baixa todos os Arquivos Externos (Imagens/Markdowns) ---
        try {
          final parsedPico = Croqui.fromBuffer(response.bodyBytes);
          
          String baseDir = '';
          if (url.startsWith(_baseUrl)) {
            String relative = url.substring(_baseUrl.length);
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

          for (var ext in parsedPico.arquivosExternos) {
             final imageUrl = '$_baseUrl/${ext.caminho}';
             final imgResponse = await http.get(Uri.parse(imageUrl));
             if (imgResponse.statusCode == 200) {
                final imgFile = File('${downloadsDir.path}/${ext.caminho}');
                if (!await imgFile.parent.exists()) {
                   await imgFile.parent.create(recursive: true);
                }
                await imgFile.writeAsBytes(imgResponse.bodyBytes);
             }
          }

          // Extrai e baixa imagens markdown
          try {
            final jsonStr = jsonEncode(parsedPico.toProto3Json());
            final RegExp regex = RegExp(r'!\[.*?\]\((.*?)\)');
            final matches = regex.allMatches(jsonStr);
            for (final match in matches) {
              if (match.groupCount >= 1) {
                String path = match.group(1)!;
                if (!path.startsWith('http://') && !path.startsWith('https://')) {
                  if (path.startsWith('./')) path = path.substring(2);
                  if (path.startsWith('/')) path = path.substring(1);
                  
                  String fullCaminho;
                  if (baseDir.isNotEmpty) {
                    fullCaminho = '$baseDir/$path';
                  } else {
                    fullCaminho = path;
                  }
                  
                  final imageUrl = '$_baseUrl/$fullCaminho';
                  debugPrint('Attempting to download markdown image: $imageUrl');
                  
                  final imgResponse = await http.get(Uri.parse(imageUrl));
                  if (imgResponse.statusCode == 200) {
                    final imgFile = File('${downloadsDir.path}/$fullCaminho');
                    if (!await imgFile.parent.exists()) {
                       await imgFile.parent.create(recursive: true);
                    }
                    await imgFile.writeAsBytes(imgResponse.bodyBytes);
                    debugPrint('Successfully downloaded markdown image to ${imgFile.path}');
                  } else {
                    debugPrint('Failed to download markdown image: $imageUrl, status: ${imgResponse.statusCode}');
                  }
                }
              }
            }
          } catch (mdEx) {
            debugPrint('Error downloading markdown images for $id: $mdEx');
          }

        } catch (downloadEx) {
          debugPrint('Error downloading external files for $id: $downloadEx');
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
      final file = File('${directory.path}/downloads/$id/$id.binarypb');
      
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
      final dir = Directory('${directory.path}/downloads/$id');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        if (activeDataset.value != null) {
          final updatedDownloaded = await _filterDownloaded(activeDataset.value!.availablePicos);
          activeDataset.value = TopoDataset(
            availablePicos: activeDataset.value!.availablePicos,
            downloadedPicos: updatedDownloaded,
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting crag: $e');
    }
    return false;
  }
}
