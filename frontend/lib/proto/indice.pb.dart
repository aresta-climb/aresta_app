// This is a generated file - do not edit.
//
// Generated from indice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Representa um índice de croquis de escalada, apontando para onde recuperar o
/// croqui inteiro.
class Indice extends $pb.GeneratedMessage {
  factory Indice({
    $core.String? urlBase,
    $core.Iterable<ResumoCroqui>? croquis,
  }) {
    final result = create();
    if (urlBase != null) result.urlBase = urlBase;
    if (croquis != null) result.croquis.addAll(croquis);
    return result;
  }

  Indice._();

  factory Indice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Indice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Indice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'urlBase')
    ..pPM<ResumoCroqui>(2, _omitFieldNames ? '' : 'croquis',
        subBuilder: ResumoCroqui.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Indice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Indice copyWith(void Function(Indice) updates) =>
      super.copyWith((message) => updates(message as Indice)) as Indice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Indice create() => Indice._();
  @$core.override
  Indice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Indice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Indice>(create);
  static Indice? _defaultInstance;

  /// URL base da qual todos os croquis possuem suas URLs relativas a.
  @$pb.TagNumber(1)
  $core.String get urlBase => $_getSZ(0);
  @$pb.TagNumber(1)
  set urlBase($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrlBase() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrlBase() => $_clearField(1);

  /// Lista de croquis disponíveis.
  @$pb.TagNumber(2)
  $pb.PbList<ResumoCroqui> get croquis => $_getList(1);
}

/// Resumo de um croqui que está disponível para o índice.
class ResumoCroqui extends $pb.GeneratedMessage {
  factory ResumoCroqui({
    $core.String? id,
    $core.String? nome,
    $core.String? descricao,
    $core.String? nomeArquivo,
    $core.String? url,
    $core.String? checksumSha256,
    $core.String? dataUpdate,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (nomeArquivo != null) result.nomeArquivo = nomeArquivo;
    if (url != null) result.url = url;
    if (checksumSha256 != null) result.checksumSha256 = checksumSha256;
    if (dataUpdate != null) result.dataUpdate = dataUpdate;
    return result;
  }

  ResumoCroqui._();

  factory ResumoCroqui.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResumoCroqui.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResumoCroqui',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'nome')
    ..aOS(3, _omitFieldNames ? '' : 'descricao')
    ..aOS(4, _omitFieldNames ? '' : 'nomeArquivo')
    ..aOS(5, _omitFieldNames ? '' : 'url')
    ..aOS(6, _omitFieldNames ? '' : 'checksumSha256')
    ..aOS(7, _omitFieldNames ? '' : 'dataUpdate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumoCroqui clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumoCroqui copyWith(void Function(ResumoCroqui) updates) =>
      super.copyWith((message) => updates(message as ResumoCroqui))
          as ResumoCroqui;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResumoCroqui create() => ResumoCroqui._();
  @$core.override
  ResumoCroqui createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResumoCroqui getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResumoCroqui>(create);
  static ResumoCroqui? _defaultInstance;

  /// Identificador único do croqui.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Nome do local do croqui.
  @$pb.TagNumber(2)
  $core.String get nome => $_getSZ(1);
  @$pb.TagNumber(2)
  set nome($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNome() => $_has(1);
  @$pb.TagNumber(2)
  void clearNome() => $_clearField(2);

  /// Descrição curta e em alto nível do local.
  @$pb.TagNumber(3)
  $core.String get descricao => $_getSZ(2);
  @$pb.TagNumber(3)
  set descricao($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescricao() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescricao() => $_clearField(3);

  /// Nome do arquivo do croqui.
  @$pb.TagNumber(4)
  $core.String get nomeArquivo => $_getSZ(3);
  @$pb.TagNumber(4)
  set nomeArquivo($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNomeArquivo() => $_has(3);
  @$pb.TagNumber(4)
  void clearNomeArquivo() => $_clearField(4);

  /// URL para recuperar o croqui inteiro, relativo ao website do indice.
  @$pb.TagNumber(5)
  $core.String get url => $_getSZ(4);
  @$pb.TagNumber(5)
  set url($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearUrl() => $_clearField(5);

  /// Checksum SHA256 da última versão do croqui.
  /// Se diferente do checksum da versão baixada, há atualizações.
  @$pb.TagNumber(6)
  $core.String get checksumSha256 => $_getSZ(5);
  @$pb.TagNumber(6)
  set checksumSha256($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChecksumSha256() => $_has(5);
  @$pb.TagNumber(6)
  void clearChecksumSha256() => $_clearField(6);

  /// Data do último update, no formato YYYY-MM-DD.
  @$pb.TagNumber(7)
  $core.String get dataUpdate => $_getSZ(6);
  @$pb.TagNumber(7)
  set dataUpdate($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDataUpdate() => $_has(6);
  @$pb.TagNumber(7)
  void clearDataUpdate() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
