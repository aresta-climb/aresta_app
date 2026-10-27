// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../data/modelos/cadena.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/perfil_view_model.dart';
import '../widgets/caderneta/grafico_piramide_graus.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página dedicada à exibição da Caderneta Esportiva pessoal do atleta.
///
/// Apresenta o gráfico da pirâmide de graduação (vias e boulders) e o
/// histórico cronológico detalhado de ascensões, permitindo exclusão segura.
class CadernetaPage extends StatefulWidget {
  /// ViewModel injetado (ou inicializado por padrão com a instância local-first).
  final PerfilViewModel? viewModel;

  const CadernetaPage({super.key, this.viewModel});

  @override
  State<CadernetaPage> createState() => _CadernetaPageState();
}
