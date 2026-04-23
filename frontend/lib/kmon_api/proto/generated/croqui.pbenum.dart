// This is a generated file - do not edit.
//
// Generated from croqui.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Se a via é toda fixa, mista ou toda em móvel.
class ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas extends $pb.ProtobufEnum {
  static const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas INDEFINIDO =
      ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas._(
          0, _omitEnumNames ? '' : 'INDEFINIDO');
  static const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas TODA_FIXA =
      ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas._(
          1, _omitEnumNames ? '' : 'TODA_FIXA');
  static const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas MISTA =
      ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas._(
          2, _omitEnumNames ? '' : 'MISTA');
  static const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas TODA_MOVEL =
      ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas._(
          3, _omitEnumNames ? '' : 'TODA_MOVEL');

  static const $core.List<ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas>
      values = <ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas>[
    INDEFINIDO,
    TODA_FIXA,
    MISTA,
    TODA_MOVEL,
  ];

  static final $core.List<ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas._(
      super.value, super.name);
}

class TipoParede_TipoParede extends $pb.ProtobufEnum {
  static const TipoParede_TipoParede INDEFINIDO =
      TipoParede_TipoParede._(0, _omitEnumNames ? '' : 'INDEFINIDO');
  static const TipoParede_TipoParede POSITIVO =
      TipoParede_TipoParede._(1, _omitEnumNames ? '' : 'POSITIVO');
  static const TipoParede_TipoParede VERTICAL =
      TipoParede_TipoParede._(2, _omitEnumNames ? '' : 'VERTICAL');
  static const TipoParede_TipoParede NEGATIVO =
      TipoParede_TipoParede._(3, _omitEnumNames ? '' : 'NEGATIVO');

  static const $core.List<TipoParede_TipoParede> values =
      <TipoParede_TipoParede>[
    INDEFINIDO,
    POSITIVO,
    VERTICAL,
    NEGATIVO,
  ];

  static final $core.List<TipoParede_TipoParede?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TipoParede_TipoParede? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TipoParede_TipoParede._(super.value, super.name);
}

class GrauVia_GrauVia extends $pb.ProtobufEnum {
  static const GrauVia_GrauVia INDEFINIDO =
      GrauVia_GrauVia._(0, _omitEnumNames ? '' : 'INDEFINIDO');
  static const GrauVia_GrauVia PROJETO =
      GrauVia_GrauVia._(1, _omitEnumNames ? '' : 'PROJETO');
  static const GrauVia_GrauVia BR_1 =
      GrauVia_GrauVia._(2, _omitEnumNames ? '' : 'BR_1');
  static const GrauVia_GrauVia BR_1SUP =
      GrauVia_GrauVia._(3, _omitEnumNames ? '' : 'BR_1SUP');
  static const GrauVia_GrauVia BR_2 =
      GrauVia_GrauVia._(4, _omitEnumNames ? '' : 'BR_2');
  static const GrauVia_GrauVia BR_2SUP =
      GrauVia_GrauVia._(5, _omitEnumNames ? '' : 'BR_2SUP');
  static const GrauVia_GrauVia BR_3 =
      GrauVia_GrauVia._(6, _omitEnumNames ? '' : 'BR_3');
  static const GrauVia_GrauVia BR_3SUP =
      GrauVia_GrauVia._(7, _omitEnumNames ? '' : 'BR_3SUP');
  static const GrauVia_GrauVia BR_4 =
      GrauVia_GrauVia._(8, _omitEnumNames ? '' : 'BR_4');
  static const GrauVia_GrauVia BR_4SUP =
      GrauVia_GrauVia._(9, _omitEnumNames ? '' : 'BR_4SUP');
  static const GrauVia_GrauVia BR_5 =
      GrauVia_GrauVia._(10, _omitEnumNames ? '' : 'BR_5');
  static const GrauVia_GrauVia BR_5SUP =
      GrauVia_GrauVia._(11, _omitEnumNames ? '' : 'BR_5SUP');
  static const GrauVia_GrauVia BR_6 =
      GrauVia_GrauVia._(12, _omitEnumNames ? '' : 'BR_6');
  static const GrauVia_GrauVia BR_6SUP =
      GrauVia_GrauVia._(13, _omitEnumNames ? '' : 'BR_6SUP');
  static const GrauVia_GrauVia BR_7A =
      GrauVia_GrauVia._(14, _omitEnumNames ? '' : 'BR_7A');
  static const GrauVia_GrauVia BR_7B =
      GrauVia_GrauVia._(17, _omitEnumNames ? '' : 'BR_7B');
  static const GrauVia_GrauVia BR_7C =
      GrauVia_GrauVia._(18, _omitEnumNames ? '' : 'BR_7C');
  static const GrauVia_GrauVia BR_8A =
      GrauVia_GrauVia._(19, _omitEnumNames ? '' : 'BR_8A');
  static const GrauVia_GrauVia BR_8B =
      GrauVia_GrauVia._(20, _omitEnumNames ? '' : 'BR_8B');
  static const GrauVia_GrauVia BR_8C =
      GrauVia_GrauVia._(21, _omitEnumNames ? '' : 'BR_8C');
  static const GrauVia_GrauVia BR_9A =
      GrauVia_GrauVia._(22, _omitEnumNames ? '' : 'BR_9A');
  static const GrauVia_GrauVia BR_9B =
      GrauVia_GrauVia._(23, _omitEnumNames ? '' : 'BR_9B');
  static const GrauVia_GrauVia BR_9C =
      GrauVia_GrauVia._(24, _omitEnumNames ? '' : 'BR_9C');
  static const GrauVia_GrauVia BR_10A =
      GrauVia_GrauVia._(25, _omitEnumNames ? '' : 'BR_10A');
  static const GrauVia_GrauVia BR_10B =
      GrauVia_GrauVia._(26, _omitEnumNames ? '' : 'BR_10B');
  static const GrauVia_GrauVia BR_10C =
      GrauVia_GrauVia._(27, _omitEnumNames ? '' : 'BR_10C');
  static const GrauVia_GrauVia BR_11A =
      GrauVia_GrauVia._(28, _omitEnumNames ? '' : 'BR_11A');
  static const GrauVia_GrauVia BR_11B =
      GrauVia_GrauVia._(29, _omitEnumNames ? '' : 'BR_11B');
  static const GrauVia_GrauVia BR_11C =
      GrauVia_GrauVia._(30, _omitEnumNames ? '' : 'BR_11C');
  static const GrauVia_GrauVia BR_12A =
      GrauVia_GrauVia._(31, _omitEnumNames ? '' : 'BR_12A');
  static const GrauVia_GrauVia BR_12B =
      GrauVia_GrauVia._(32, _omitEnumNames ? '' : 'BR_12B');
  static const GrauVia_GrauVia BR_12C =
      GrauVia_GrauVia._(33, _omitEnumNames ? '' : 'BR_12C');
  static const GrauVia_GrauVia BR_13A =
      GrauVia_GrauVia._(34, _omitEnumNames ? '' : 'BR_13A');

  static const GrauVia_GrauVia FR_1 = BR_1SUP;
  static const GrauVia_GrauVia US_5_0 = BR_1SUP;
  static const GrauVia_GrauVia FR_2A = BR_2;
  static const GrauVia_GrauVia US_5_2 = BR_2;
  static const GrauVia_GrauVia FR_2C = BR_2SUP;
  static const GrauVia_GrauVia US_5_3 = BR_2SUP;
  static const GrauVia_GrauVia FR_3B = BR_3;
  static const GrauVia_GrauVia US_5_5 = BR_3;
  static const GrauVia_GrauVia FR_4A = BR_3SUP;
  static const GrauVia_GrauVia US_5_6 = BR_3SUP;
  static const GrauVia_GrauVia FR_4B_MAIS = BR_4;
  static const GrauVia_GrauVia US_5_7 = BR_4;
  static const GrauVia_GrauVia FR_5A_MAIS = BR_4SUP;
  static const GrauVia_GrauVia US_5_9 = BR_4SUP;
  static const GrauVia_GrauVia FR_5C = BR_5;
  static const GrauVia_GrauVia US_5_10A = BR_5;
  static const GrauVia_GrauVia FR_6A_MAIS = BR_5SUP;
  static const GrauVia_GrauVia US_5_10B = BR_5SUP;
  static const GrauVia_GrauVia FR_6B = BR_6;
  static const GrauVia_GrauVia US_5_10C = BR_6;
  static const GrauVia_GrauVia FR_6B_MAIS = BR_6SUP;
  static const GrauVia_GrauVia US_5_10D = BR_6SUP;
  static const GrauVia_GrauVia FR_6C = BR_7A;
  static const GrauVia_GrauVia US_5_11A = BR_7A;
  static const GrauVia_GrauVia FR_6C_MAIS = BR_7B;
  static const GrauVia_GrauVia US_5_11c = BR_7B;
  static const GrauVia_GrauVia FR_7A = BR_7C;
  static const GrauVia_GrauVia US_5_11D = BR_7C;
  static const GrauVia_GrauVia FR_7A_MAIS = BR_8A;
  static const GrauVia_GrauVia US_5_12A = BR_8A;
  static const GrauVia_GrauVia FR_7B = BR_8B;
  static const GrauVia_GrauVia US_5_12B = BR_8B;
  static const GrauVia_GrauVia FR_7B_MAIS = BR_8C;
  static const GrauVia_GrauVia US_5_12C = BR_8C;
  static const GrauVia_GrauVia FR_7C = BR_9A;
  static const GrauVia_GrauVia US_5_12D = BR_9A;
  static const GrauVia_GrauVia FR_7C_MAIS = BR_9B;
  static const GrauVia_GrauVia US_5_13A = BR_9B;
  static const GrauVia_GrauVia FR_8A = BR_9C;
  static const GrauVia_GrauVia US_5_13B = BR_9C;
  static const GrauVia_GrauVia FR_8A_MAIS = BR_10A;
  static const GrauVia_GrauVia US_5_13C = BR_10A;
  static const GrauVia_GrauVia FR_8B = BR_10B;
  static const GrauVia_GrauVia US_5_13D = BR_10B;
  static const GrauVia_GrauVia FR_8B_MAIS = BR_10C;
  static const GrauVia_GrauVia US_5_14A = BR_10C;
  static const GrauVia_GrauVia FR_8C = BR_11A;
  static const GrauVia_GrauVia US_5_14B = BR_11A;
  static const GrauVia_GrauVia FR_8C_MAIS = BR_11B;
  static const GrauVia_GrauVia US_5_14C = BR_11B;
  static const GrauVia_GrauVia FR_9A = BR_11C;
  static const GrauVia_GrauVia US_5_14D = BR_11C;
  static const GrauVia_GrauVia FR_9A_MAIS = BR_12A;
  static const GrauVia_GrauVia US_5_15A = BR_12A;
  static const GrauVia_GrauVia FR_9B = BR_12B;
  static const GrauVia_GrauVia US_5_15B = BR_12B;
  static const GrauVia_GrauVia FR_9B_MAIS = BR_12C;
  static const GrauVia_GrauVia US_5_15C = BR_12C;
  static const GrauVia_GrauVia FR_9C = BR_13A;
  static const GrauVia_GrauVia US_5_15D = BR_13A;

  static const $core.List<GrauVia_GrauVia> values = <GrauVia_GrauVia>[
    INDEFINIDO,
    PROJETO,
    BR_1,
    BR_1SUP,
    BR_2,
    BR_2SUP,
    BR_3,
    BR_3SUP,
    BR_4,
    BR_4SUP,
    BR_5,
    BR_5SUP,
    BR_6,
    BR_6SUP,
    BR_7A,
    BR_7B,
    BR_7C,
    BR_8A,
    BR_8B,
    BR_8C,
    BR_9A,
    BR_9B,
    BR_9C,
    BR_10A,
    BR_10B,
    BR_10C,
    BR_11A,
    BR_11B,
    BR_11C,
    BR_12A,
    BR_12B,
    BR_12C,
    BR_13A,
  ];

  static final $core.List<GrauVia_GrauVia?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 34);
  static GrauVia_GrauVia? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrauVia_GrauVia._(super.value, super.name);
}

class GrauBoulder_GrauBoulder extends $pb.ProtobufEnum {
  static const GrauBoulder_GrauBoulder INDEFINIDO =
      GrauBoulder_GrauBoulder._(0, _omitEnumNames ? '' : 'INDEFINIDO');
  static const GrauBoulder_GrauBoulder VB =
      GrauBoulder_GrauBoulder._(1, _omitEnumNames ? '' : 'VB');
  static const GrauBoulder_GrauBoulder V0 =
      GrauBoulder_GrauBoulder._(2, _omitEnumNames ? '' : 'V0');
  static const GrauBoulder_GrauBoulder V1 =
      GrauBoulder_GrauBoulder._(3, _omitEnumNames ? '' : 'V1');
  static const GrauBoulder_GrauBoulder V2 =
      GrauBoulder_GrauBoulder._(4, _omitEnumNames ? '' : 'V2');
  static const GrauBoulder_GrauBoulder V3 =
      GrauBoulder_GrauBoulder._(5, _omitEnumNames ? '' : 'V3');
  static const GrauBoulder_GrauBoulder V4 =
      GrauBoulder_GrauBoulder._(6, _omitEnumNames ? '' : 'V4');
  static const GrauBoulder_GrauBoulder V5 =
      GrauBoulder_GrauBoulder._(7, _omitEnumNames ? '' : 'V5');
  static const GrauBoulder_GrauBoulder V6 =
      GrauBoulder_GrauBoulder._(8, _omitEnumNames ? '' : 'V6');
  static const GrauBoulder_GrauBoulder V7 =
      GrauBoulder_GrauBoulder._(9, _omitEnumNames ? '' : 'V7');
  static const GrauBoulder_GrauBoulder V8 =
      GrauBoulder_GrauBoulder._(10, _omitEnumNames ? '' : 'V8');
  static const GrauBoulder_GrauBoulder V9 =
      GrauBoulder_GrauBoulder._(11, _omitEnumNames ? '' : 'V9');
  static const GrauBoulder_GrauBoulder V10 =
      GrauBoulder_GrauBoulder._(12, _omitEnumNames ? '' : 'V10');
  static const GrauBoulder_GrauBoulder V11 =
      GrauBoulder_GrauBoulder._(13, _omitEnumNames ? '' : 'V11');
  static const GrauBoulder_GrauBoulder V12 =
      GrauBoulder_GrauBoulder._(14, _omitEnumNames ? '' : 'V12');
  static const GrauBoulder_GrauBoulder V13 =
      GrauBoulder_GrauBoulder._(15, _omitEnumNames ? '' : 'V13');
  static const GrauBoulder_GrauBoulder V14 =
      GrauBoulder_GrauBoulder._(16, _omitEnumNames ? '' : 'V14');
  static const GrauBoulder_GrauBoulder V15 =
      GrauBoulder_GrauBoulder._(17, _omitEnumNames ? '' : 'V15');
  static const GrauBoulder_GrauBoulder V16 =
      GrauBoulder_GrauBoulder._(18, _omitEnumNames ? '' : 'V16');
  static const GrauBoulder_GrauBoulder V17 =
      GrauBoulder_GrauBoulder._(19, _omitEnumNames ? '' : 'V17');

  static const $core.List<GrauBoulder_GrauBoulder> values =
      <GrauBoulder_GrauBoulder>[
    INDEFINIDO,
    VB,
    V0,
    V1,
    V2,
    V3,
    V4,
    V5,
    V6,
    V7,
    V8,
    V9,
    V10,
    V11,
    V12,
    V13,
    V14,
    V15,
    V16,
    V17,
  ];

  static final $core.List<GrauBoulder_GrauBoulder?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 19);
  static GrauBoulder_GrauBoulder? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrauBoulder_GrauBoulder._(super.value, super.name);
}

class GrauArtificial_GrauArtificial extends $pb.ProtobufEnum {
  static const GrauArtificial_GrauArtificial INDEFINIDO =
      GrauArtificial_GrauArtificial._(0, _omitEnumNames ? '' : 'INDEFINIDO');

  /// Pontos de apoio sólidos isolados ou em uma curta sequência, com pouca exposição.
  static const GrauArtificial_GrauArtificial A0 =
      GrauArtificial_GrauArtificial._(1, _omitEnumNames ? '' : 'A0');
  static const GrauArtificial_GrauArtificial A0_MAIS =
      GrauArtificial_GrauArtificial._(2, _omitEnumNames ? '' : 'A0_MAIS');

  /// Peças fixas ou colocações sólidas de material móvel, fáceis e seguras, em uma
  /// sequência razoavelmente longa.
  static const GrauArtificial_GrauArtificial A1 =
      GrauArtificial_GrauArtificial._(3, _omitEnumNames ? '' : 'A1');
  static const GrauArtificial_GrauArtificial A1_MAIS =
      GrauArtificial_GrauArtificial._(4, _omitEnumNames ? '' : 'A1_MAIS');

  /// Colocação geralmente sólida das proteções móveis, porém mais difíceis. Algumas
  /// colocações podem não ser sólidas, mas estarão logo acima de uma boa peça. Não
  /// há quedas perigosas.
  static const GrauArtificial_GrauArtificial A2 =
      GrauArtificial_GrauArtificial._(5, _omitEnumNames ? '' : 'A2');

  /// Como A2, mas com possibilidade de mais colocações ruins acima de uma boa. Potencial
  /// de queda aproximado de 6 a 9 metros, mas sem atingir platôs.
  static const GrauArtificial_GrauArtificial A2_MAIS =
      GrauArtificial_GrauArtificial._(6, _omitEnumNames ? '' : 'A2_MAIS');

  /// Artificial difícil. Várias colocações frágeis em sequência, poucas proteções sólidas.
  /// Potencial de queda de até 15 metros, mas geralmente não causa acidentes graves.
  static const GrauArtificial_GrauArtificial A3 =
      GrauArtificial_GrauArtificial._(7, _omitEnumNames ? '' : 'A3');

  /// Como A3, mas com maior potencial de quedas perigosas.
  static const GrauArtificial_GrauArtificial A3_MAIS =
      GrauArtificial_GrauArtificial._(8, _omitEnumNames ? '' : 'A3_MAIS');

  /// Escaladas muito perigosas. Quedas potenciais de 18 a 30 metros, com perigo de atingir
  /// platôs ou lacas de pedra. Peças que aguentam somente o peso do corpo.
  static const GrauArtificial_GrauArtificial A4 =
      GrauArtificial_GrauArtificial._(9, _omitEnumNames ? '' : 'A4');

  /// Como o A4, mas são necessárias várias horas para cada enfiada de corda.
  static const GrauArtificial_GrauArtificial A4_MAIS =
      GrauArtificial_GrauArtificial._(10, _omitEnumNames ? '' : 'A4_MAIS');

  /// Extremo, sob o ponto de vista técnico e psicológico.
  static const GrauArtificial_GrauArtificial A5 =
      GrauArtificial_GrauArtificial._(11, _omitEnumNames ? '' : 'A5');

  /// Como um A5 em que as paradas não são sólidas.
  static const GrauArtificial_GrauArtificial A5_MAIS =
      GrauArtificial_GrauArtificial._(12, _omitEnumNames ? '' : 'A5_MAIS');

  static const $core.List<GrauArtificial_GrauArtificial> values =
      <GrauArtificial_GrauArtificial>[
    INDEFINIDO,
    A0,
    A0_MAIS,
    A1,
    A1_MAIS,
    A2,
    A2_MAIS,
    A3,
    A3_MAIS,
    A4,
    A4_MAIS,
    A5,
    A5_MAIS,
  ];

  static final $core.List<GrauArtificial_GrauArtificial?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static GrauArtificial_GrauArtificial? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrauArtificial_GrauArtificial._(super.value, super.name);
}

class GrauDuracao_GrauDuracao extends $pb.ProtobufEnum {
  static const GrauDuracao_GrauDuracao INDEFINIDO =
      GrauDuracao_GrauDuracao._(0, _omitEnumNames ? '' : 'INDEFINIDO');

  /// Poucas horas de escalada.
  static const GrauDuracao_GrauDuracao D1 =
      GrauDuracao_GrauDuracao._(1, _omitEnumNames ? '' : 'D1');

  /// Meio dia de escalada.
  static const GrauDuracao_GrauDuracao D2 =
      GrauDuracao_GrauDuracao._(2, _omitEnumNames ? '' : 'D2');

  /// Um dia quase inteiro de escalada.
  static const GrauDuracao_GrauDuracao D3 =
      GrauDuracao_GrauDuracao._(3, _omitEnumNames ? '' : 'D3');

  /// Um longo dia de escalada.
  static const GrauDuracao_GrauDuracao D4 =
      GrauDuracao_GrauDuracao._(4, _omitEnumNames ? '' : 'D4');

  /// Requer uma noite na parede. Cordadas muito velozes podem repeti-la em um dia.
  static const GrauDuracao_GrauDuracao D5 =
      GrauDuracao_GrauDuracao._(5, _omitEnumNames ? '' : 'D5');

  /// Dois dias inteiros ou mais de escalada. Normalmente inclui longos e complicados
  /// trechos de escalada em artificial.
  static const GrauDuracao_GrauDuracao D6 =
      GrauDuracao_GrauDuracao._(6, _omitEnumNames ? '' : 'D6');

  /// Expedições a locais de acesso remoto com longa aproximação e muitos dias de escalada.
  static const GrauDuracao_GrauDuracao D7 =
      GrauDuracao_GrauDuracao._(7, _omitEnumNames ? '' : 'D7');

  static const $core.List<GrauDuracao_GrauDuracao> values =
      <GrauDuracao_GrauDuracao>[
    INDEFINIDO,
    D1,
    D2,
    D3,
    D4,
    D5,
    D6,
    D7,
  ];

  static final $core.List<GrauDuracao_GrauDuracao?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static GrauDuracao_GrauDuracao? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrauDuracao_GrauDuracao._(super.value, super.name);
}

class GrauExposicao_GrauExposicao extends $pb.ProtobufEnum {
  static const GrauExposicao_GrauExposicao INDEFINIDO =
      GrauExposicao_GrauExposicao._(0, _omitEnumNames ? '' : 'INDEFINIDO');

  /// Vias bem protegidas, grampeação nível esportiva.
  static const GrauExposicao_GrauExposicao E1 =
      GrauExposicao_GrauExposicao._(1, _omitEnumNames ? '' : 'E1');

  /// Vias com proteção regular.
  static const GrauExposicao_GrauExposicao E2 =
      GrauExposicao_GrauExposicao._(2, _omitEnumNames ? '' : 'E2');

  /// Vias com proteção regular com trechos perigosos.
  static const GrauExposicao_GrauExposicao E3 =
      GrauExposicao_GrauExposicao._(3, _omitEnumNames ? '' : 'E3');

  /// Vias perigosas em caso de queda.
  static const GrauExposicao_GrauExposicao E4 =
      GrauExposicao_GrauExposicao._(4, _omitEnumNames ? '' : 'E4');

  /// Vias muito perigosas em caso de queda.
  static const GrauExposicao_GrauExposicao E5 =
      GrauExposicao_GrauExposicao._(5, _omitEnumNames ? '' : 'E5');

  static const $core.List<GrauExposicao_GrauExposicao> values =
      <GrauExposicao_GrauExposicao>[
    INDEFINIDO,
    E1,
    E2,
    E3,
    E4,
    E5,
  ];

  static final $core.List<GrauExposicao_GrauExposicao?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static GrauExposicao_GrauExposicao? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GrauExposicao_GrauExposicao._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
