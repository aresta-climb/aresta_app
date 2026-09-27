// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/dtos/card_croqui_dto.dart';

export '../../data/dtos/card_croqui_dto.dart';

/// Apelido para manter compatibilidade com componentes legados que importam [CardCroquiViewModel].
///
/// O modelo canônico de transferência de dados para Dumb UI agora reside em [CardCroquiDTO].
typedef CardCroquiViewModel = CardCroquiDTO;
