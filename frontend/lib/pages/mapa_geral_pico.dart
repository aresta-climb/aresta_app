import 'package:flutter/material.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/view_functions/mapa_geral_pico_functions.dart';
import 'package:frontend/navigation/navigation_functions.dart';

/// Página responsável por exibir o Mapa Geral de um Pico.
///
/// Esta tela fornece uma visão panorâmica (geralmente uma imagem ou croqui amplo)
/// que engloba múltiplos setores ou a área geral do local de escalada.
/// Ela é construída através de funções auxiliares (functions) para manter o código
/// modular e focado na estrutura principal (Scaffold).
class MapaGeralPicoPage extends StatelessWidget {
  /// O objeto [Pico] que contém as informações gerais e estruturais do local de escalada.
  final Pico pico;
  
  /// O objeto [Croqui] completo que armazena todos os dados das vias, setores e mapas.
  final Croqui croqui;
  
  /// O identificador único do Pico, usado para carregar imagens e buscar dados localmente.
  final String cragId;
  
  /// (Opcional) Um [Setor] de referência. Se fornecido, o botão flutuante (FAB) 
  /// permitirá que o usuário retorne rapidamente para este setor específico após visualizar o mapa.
  final Setor? returnToSetor;

  const MapaGeralPicoPage({
    super.key,
    required this.pico,
    required this.croqui,
    required this.cragId,
    this.returnToSetor,
  });

  @override
  Widget build(BuildContext context) {
    // Extrai o conteúdo em markdown correspondente ao Mapa Geral a partir do objeto Croqui
    final mapMd = getMapaGeralMarkdown(croqui);

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: AppBar(
        leading: AppNav.canGoBack(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => AppNav.back(context),
              )
            : null,
        title: Text('Mapa Geral do Pico', style: TextStyle(color: beastHide)),
        backgroundColor: nobleBlack,
        iconTheme: IconThemeData(color: beastHide),
      ),
      // Constrói o corpo principal (renderizando o markdown do mapa e controlando o zoom/pan)
      body: buildMapaGeralPicoBody(context, cragId, mapMd),
      // Adiciona o botão de voltar ao setor (caso aplicável) centralizado na parte inferior
      floatingActionButton: buildMapaGeralPicoFab(context, returnToSetor, cragId),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
