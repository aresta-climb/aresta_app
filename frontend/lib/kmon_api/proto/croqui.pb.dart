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

import 'croqui.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'croqui.pbenum.dart';

/// Representa um croqui de escalada, que pode incluir um ou mais picos.
class Croqui extends $pb.GeneratedMessage {
  factory Croqui({
    $core.String? id,
    $core.String? nome,
    $core.String? descricao,
    $core.Iterable<$core.String>? creditos,
    $core.Iterable<ArquivoMarkdown>? arquivosMarkdown,
    $core.Iterable<Pico>? picos,
    $core.Iterable<ArquivoExterno>? arquivosExternos,
    $core.String? caminhoThumbnail,
    $core.bool? revisadoManualmente,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (creditos != null) result.creditos.addAll(creditos);
    if (arquivosMarkdown != null)
      result.arquivosMarkdown.addAll(arquivosMarkdown);
    if (picos != null) result.picos.addAll(picos);
    if (arquivosExternos != null)
      result.arquivosExternos.addAll(arquivosExternos);
    if (caminhoThumbnail != null) result.caminhoThumbnail = caminhoThumbnail;
    if (revisadoManualmente != null)
      result.revisadoManualmente = revisadoManualmente;
    return result;
  }

  Croqui._();

  factory Croqui.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Croqui.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Croqui',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'nome')
    ..aOS(3, _omitFieldNames ? '' : 'descricao')
    ..pPS(4, _omitFieldNames ? '' : 'creditos')
    ..pPM<ArquivoMarkdown>(5, _omitFieldNames ? '' : 'arquivosMarkdown',
        subBuilder: ArquivoMarkdown.create)
    ..pPM<Pico>(6, _omitFieldNames ? '' : 'picos', subBuilder: Pico.create)
    ..pPM<ArquivoExterno>(7, _omitFieldNames ? '' : 'arquivosExternos',
        subBuilder: ArquivoExterno.create)
    ..aOS(8, _omitFieldNames ? '' : 'caminhoThumbnail')
    ..aOB(9, _omitFieldNames ? '' : 'revisadoManualmente')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Croqui clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Croqui copyWith(void Function(Croqui) updates) =>
      super.copyWith((message) => updates(message as Croqui)) as Croqui;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Croqui create() => Croqui._();
  @$core.override
  Croqui createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Croqui getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Croqui>(create);
  static Croqui? _defaultInstance;

  /// Identificador único do croqui. Ideal formato como "br_mg_igarape_pedra_grande".
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Nome oficial do croqui.
  @$pb.TagNumber(2)
  $core.String get nome => $_getSZ(1);
  @$pb.TagNumber(2)
  set nome($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNome() => $_has(1);
  @$pb.TagNumber(2)
  void clearNome() => $_clearField(2);

  /// Descrição curta do pico do croqui, que será exibida na lista de croquis.
  /// Máximo recomendado de 100 palavras.
  @$pb.TagNumber(3)
  $core.String get descricao => $_getSZ(2);
  @$pb.TagNumber(3)
  set descricao($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescricao() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescricao() => $_clearField(3);

  /// Créditos ao criador do croqui.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get creditos => $_getList(3);

  /// Arquivos markdown para complementar as informações do croqui.
  @$pb.TagNumber(5)
  $pb.PbList<ArquivoMarkdown> get arquivosMarkdown => $_getList(4);

  /// Picos que fazem parte desse croqui.
  @$pb.TagNumber(6)
  $pb.PbList<Pico> get picos => $_getList(5);

  /// Arquivos externos que não estão incluídos no .binarypb.
  @$pb.TagNumber(7)
  $pb.PbList<ArquivoExterno> get arquivosExternos => $_getList(6);

  /// Caminho para a thumbnail do croqui (imagem em miniatura para prever croquis não baixados).
  /// Essa imagem deve ter no máximo 1200x1200.
  @$pb.TagNumber(8)
  $core.String get caminhoThumbnail => $_getSZ(7);
  @$pb.TagNumber(8)
  set caminhoThumbnail($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCaminhoThumbnail() => $_has(7);
  @$pb.TagNumber(8)
  void clearCaminhoThumbnail() => $_clearField(8);

  /// Representa se o croqui já foi revisado manualmente para garantir qualidade.
  @$pb.TagNumber(9)
  $core.bool get revisadoManualmente => $_getBF(8);
  @$pb.TagNumber(9)
  set revisadoManualmente($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRevisadoManualmente() => $_has(8);
  @$pb.TagNumber(9)
  void clearRevisadoManualmente() => $_clearField(9);
}

/// Informações sobre arquivos externos que não estão incluídos no .binarypb.
class ArquivoExterno extends $pb.GeneratedMessage {
  factory ArquivoExterno({
    $core.String? caminho,
    $core.String? checksumSha256,
  }) {
    final result = create();
    if (caminho != null) result.caminho = caminho;
    if (checksumSha256 != null) result.checksumSha256 = checksumSha256;
    return result;
  }

  ArquivoExterno._();

  factory ArquivoExterno.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoExterno.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoExterno',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'caminho')
    ..aOS(2, _omitFieldNames ? '' : 'checksumSha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoExterno clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoExterno copyWith(void Function(ArquivoExterno) updates) =>
      super.copyWith((message) => updates(message as ArquivoExterno))
          as ArquivoExterno;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoExterno create() => ArquivoExterno._();
  @$core.override
  ArquivoExterno createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoExterno getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoExterno>(create);
  static ArquivoExterno? _defaultInstance;

  /// Caminho do arquivo, relativo à localização do .binarypb.
  @$pb.TagNumber(1)
  $core.String get caminho => $_getSZ(0);
  @$pb.TagNumber(1)
  set caminho($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCaminho() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaminho() => $_clearField(1);

  /// Checksum SHA256 do arquivo.
  @$pb.TagNumber(2)
  $core.String get checksumSha256 => $_getSZ(1);
  @$pb.TagNumber(2)
  set checksumSha256($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChecksumSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearChecksumSha256() => $_clearField(2);
}

enum ArquivoMarkdown_Arquivo { caminho, conteudo, notSet }

/// Representa um arquivo markdown com informações sobre o croqui.
class ArquivoMarkdown extends $pb.GeneratedMessage {
  factory ArquivoMarkdown({
    $core.String? titulo,
    $core.String? caminho,
    $core.String? conteudo,
  }) {
    final result = create();
    if (titulo != null) result.titulo = titulo;
    if (caminho != null) result.caminho = caminho;
    if (conteudo != null) result.conteudo = conteudo;
    return result;
  }

  ArquivoMarkdown._();

  factory ArquivoMarkdown.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoMarkdown.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ArquivoMarkdown_Arquivo>
      _ArquivoMarkdown_ArquivoByTag = {
    2: ArquivoMarkdown_Arquivo.caminho,
    3: ArquivoMarkdown_Arquivo.conteudo,
    0: ArquivoMarkdown_Arquivo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoMarkdown',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'titulo')
    ..aOS(2, _omitFieldNames ? '' : 'caminho')
    ..aOS(3, _omitFieldNames ? '' : 'conteudo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoMarkdown clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoMarkdown copyWith(void Function(ArquivoMarkdown) updates) =>
      super.copyWith((message) => updates(message as ArquivoMarkdown))
          as ArquivoMarkdown;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoMarkdown create() => ArquivoMarkdown._();
  @$core.override
  ArquivoMarkdown createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoMarkdown getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoMarkdown>(create);
  static ArquivoMarkdown? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ArquivoMarkdown_Arquivo whichArquivo() =>
      _ArquivoMarkdown_ArquivoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearArquivo() => $_clearField($_whichOneof(0));

  /// Título do arquivo.
  @$pb.TagNumber(1)
  $core.String get titulo => $_getSZ(0);
  @$pb.TagNumber(1)
  set titulo($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitulo() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitulo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get caminho => $_getSZ(1);
  @$pb.TagNumber(2)
  set caminho($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCaminho() => $_has(1);
  @$pb.TagNumber(2)
  void clearCaminho() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get conteudo => $_getSZ(2);
  @$pb.TagNumber(3)
  set conteudo($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConteudo() => $_has(2);
  @$pb.TagNumber(3)
  void clearConteudo() => $_clearField(3);
}

/// Representa um pico de escalada completo (ex: Serra do Cipó, Gruta da Lapinha).
class Pico extends $pb.GeneratedMessage {
  factory Pico({
    $core.String? nome,
    $core.String? descricao,
    $core.String? estado,
    Coordenada? localizacao,
    $core.String? urlGoogleMaps,
    $core.String? nomeAssociacao,
    $core.String? urlFiliacaoAssociacao,
    $core.String? chavePixManutencao,
    $core.Iterable<Patrocinador>? patrocinadores,
    $core.Iterable<SetorOuGrupo>? setoresOuGrupos,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (estado != null) result.estado = estado;
    if (localizacao != null) result.localizacao = localizacao;
    if (urlGoogleMaps != null) result.urlGoogleMaps = urlGoogleMaps;
    if (nomeAssociacao != null) result.nomeAssociacao = nomeAssociacao;
    if (urlFiliacaoAssociacao != null)
      result.urlFiliacaoAssociacao = urlFiliacaoAssociacao;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (patrocinadores != null) result.patrocinadores.addAll(patrocinadores);
    if (setoresOuGrupos != null) result.setoresOuGrupos.addAll(setoresOuGrupos);
    return result;
  }

  Pico._();

  factory Pico.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Pico.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Pico',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOS(2, _omitFieldNames ? '' : 'descricao')
    ..aOS(3, _omitFieldNames ? '' : 'estado')
    ..aOM<Coordenada>(4, _omitFieldNames ? '' : 'localizacao',
        subBuilder: Coordenada.create)
    ..aOS(5, _omitFieldNames ? '' : 'urlGoogleMaps')
    ..aOS(6, _omitFieldNames ? '' : 'nomeAssociacao')
    ..aOS(7, _omitFieldNames ? '' : 'urlFiliacaoAssociacao')
    ..aOS(8, _omitFieldNames ? '' : 'chavePixManutencao')
    ..pPM<Patrocinador>(9, _omitFieldNames ? '' : 'patrocinadores',
        subBuilder: Patrocinador.create)
    ..pPM<SetorOuGrupo>(11, _omitFieldNames ? '' : 'setoresOuGrupos',
        subBuilder: SetorOuGrupo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pico clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pico copyWith(void Function(Pico) updates) =>
      super.copyWith((message) => updates(message as Pico)) as Pico;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Pico create() => Pico._();
  @$core.override
  Pico createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Pico getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Pico>(create);
  static Pico? _defaultInstance;

  /// Nome oficial do pico de escalada.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Visão geral, história e informações gerais de acesso.
  @$pb.TagNumber(2)
  $core.String get descricao => $_getSZ(1);
  @$pb.TagNumber(2)
  set descricao($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescricao() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescricao() => $_clearField(2);

  /// Estado do local de escalada.
  @$pb.TagNumber(3)
  $core.String get estado => $_getSZ(2);
  @$pb.TagNumber(3)
  set estado($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEstado() => $_has(2);
  @$pb.TagNumber(3)
  void clearEstado() => $_clearField(3);

  /// Localização do ponto de referência principal (geralmente o estacionamento).
  @$pb.TagNumber(4)
  Coordenada get localizacao => $_getN(3);
  @$pb.TagNumber(4)
  set localizacao(Coordenada value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLocalizacao() => $_has(3);
  @$pb.TagNumber(4)
  void clearLocalizacao() => $_clearField(4);
  @$pb.TagNumber(4)
  Coordenada ensureLocalizacao() => $_ensure(3);

  /// Link para o ponto de referência principal no Google Maps.
  @$pb.TagNumber(5)
  $core.String get urlGoogleMaps => $_getSZ(4);
  @$pb.TagNumber(5)
  set urlGoogleMaps($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUrlGoogleMaps() => $_has(4);
  @$pb.TagNumber(5)
  void clearUrlGoogleMaps() => $_clearField(5);

  /// Nome da associação local responsável (ex: ACEC-MG).
  @$pb.TagNumber(6)
  $core.String get nomeAssociacao => $_getSZ(5);
  @$pb.TagNumber(6)
  set nomeAssociacao($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNomeAssociacao() => $_has(5);
  @$pb.TagNumber(6)
  void clearNomeAssociacao() => $_clearField(6);

  /// Link para a página onde o escalador pode se afiliar.
  @$pb.TagNumber(7)
  $core.String get urlFiliacaoAssociacao => $_getSZ(6);
  @$pb.TagNumber(7)
  set urlFiliacaoAssociacao($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUrlFiliacaoAssociacao() => $_has(6);
  @$pb.TagNumber(7)
  void clearUrlFiliacaoAssociacao() => $_clearField(7);

  /// Chave Pix para contribuições diretas ao fundo de manutenção local.
  @$pb.TagNumber(8)
  $core.String get chavePixManutencao => $_getSZ(7);
  @$pb.TagNumber(8)
  set chavePixManutencao($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChavePixManutencao() => $_has(7);
  @$pb.TagNumber(8)
  void clearChavePixManutencao() => $_clearField(8);

  /// Patrocinadores atuais do croqui deste local.
  @$pb.TagNumber(9)
  $pb.PbList<Patrocinador> get patrocinadores => $_getList(8);

  /// Elementos de escalada contidos neste pico (setores ou grupos).
  @$pb.TagNumber(11)
  $pb.PbList<SetorOuGrupo> get setoresOuGrupos => $_getList(9);
}

enum SetorOuGrupo_Tipo { setor, grupo, notSet }

/// Representa um elemento (Setor ou Grupo) de um Pico.
class SetorOuGrupo extends $pb.GeneratedMessage {
  factory SetorOuGrupo({
    ArquivoSetor? setor,
    ArquivoGrupo? grupo,
  }) {
    final result = create();
    if (setor != null) result.setor = setor;
    if (grupo != null) result.grupo = grupo;
    return result;
  }

  SetorOuGrupo._();

  factory SetorOuGrupo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetorOuGrupo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SetorOuGrupo_Tipo> _SetorOuGrupo_TipoByTag =
      {
    1: SetorOuGrupo_Tipo.setor,
    2: SetorOuGrupo_Tipo.grupo,
    0: SetorOuGrupo_Tipo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetorOuGrupo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ArquivoSetor>(1, _omitFieldNames ? '' : 'setor',
        subBuilder: ArquivoSetor.create)
    ..aOM<ArquivoGrupo>(2, _omitFieldNames ? '' : 'grupo',
        subBuilder: ArquivoGrupo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetorOuGrupo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetorOuGrupo copyWith(void Function(SetorOuGrupo) updates) =>
      super.copyWith((message) => updates(message as SetorOuGrupo))
          as SetorOuGrupo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetorOuGrupo create() => SetorOuGrupo._();
  @$core.override
  SetorOuGrupo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetorOuGrupo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetorOuGrupo>(create);
  static SetorOuGrupo? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SetorOuGrupo_Tipo whichTipo() => _SetorOuGrupo_TipoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearTipo() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ArquivoSetor get setor => $_getN(0);
  @$pb.TagNumber(1)
  set setor(ArquivoSetor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSetor() => $_has(0);
  @$pb.TagNumber(1)
  void clearSetor() => $_clearField(1);
  @$pb.TagNumber(1)
  ArquivoSetor ensureSetor() => $_ensure(0);

  @$pb.TagNumber(2)
  ArquivoGrupo get grupo => $_getN(1);
  @$pb.TagNumber(2)
  set grupo(ArquivoGrupo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGrupo() => $_has(1);
  @$pb.TagNumber(2)
  void clearGrupo() => $_clearField(2);
  @$pb.TagNumber(2)
  ArquivoGrupo ensureGrupo() => $_ensure(1);
}

enum ArquivoSetor_Arquivo { caminho, conteudo, notSet }

/// Use para referenciar um outro arquivo que contenha informação de setor caso necessário.
class ArquivoSetor extends $pb.GeneratedMessage {
  factory ArquivoSetor({
    $core.String? caminho,
    Setor? conteudo,
  }) {
    final result = create();
    if (caminho != null) result.caminho = caminho;
    if (conteudo != null) result.conteudo = conteudo;
    return result;
  }

  ArquivoSetor._();

  factory ArquivoSetor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoSetor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ArquivoSetor_Arquivo>
      _ArquivoSetor_ArquivoByTag = {
    1: ArquivoSetor_Arquivo.caminho,
    2: ArquivoSetor_Arquivo.conteudo,
    0: ArquivoSetor_Arquivo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoSetor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'caminho')
    ..aOM<Setor>(2, _omitFieldNames ? '' : 'conteudo', subBuilder: Setor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoSetor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoSetor copyWith(void Function(ArquivoSetor) updates) =>
      super.copyWith((message) => updates(message as ArquivoSetor))
          as ArquivoSetor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoSetor create() => ArquivoSetor._();
  @$core.override
  ArquivoSetor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoSetor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoSetor>(create);
  static ArquivoSetor? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ArquivoSetor_Arquivo whichArquivo() =>
      _ArquivoSetor_ArquivoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearArquivo() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get caminho => $_getSZ(0);
  @$pb.TagNumber(1)
  set caminho($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCaminho() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaminho() => $_clearField(1);

  @$pb.TagNumber(2)
  Setor get conteudo => $_getN(1);
  @$pb.TagNumber(2)
  set conteudo(Setor value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConteudo() => $_has(1);
  @$pb.TagNumber(2)
  void clearConteudo() => $_clearField(2);
  @$pb.TagNumber(2)
  Setor ensureConteudo() => $_ensure(1);
}

enum ArquivoGrupo_Arquivo { caminho, conteudo, notSet }

/// Use para referenciar um outro arquivo que contenha informação de grupo caso necessário.
class ArquivoGrupo extends $pb.GeneratedMessage {
  factory ArquivoGrupo({
    $core.String? caminho,
    Grupo? conteudo,
  }) {
    final result = create();
    if (caminho != null) result.caminho = caminho;
    if (conteudo != null) result.conteudo = conteudo;
    return result;
  }

  ArquivoGrupo._();

  factory ArquivoGrupo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArquivoGrupo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ArquivoGrupo_Arquivo>
      _ArquivoGrupo_ArquivoByTag = {
    1: ArquivoGrupo_Arquivo.caminho,
    2: ArquivoGrupo_Arquivo.conteudo,
    0: ArquivoGrupo_Arquivo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArquivoGrupo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOS(1, _omitFieldNames ? '' : 'caminho')
    ..aOM<Grupo>(2, _omitFieldNames ? '' : 'conteudo', subBuilder: Grupo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoGrupo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArquivoGrupo copyWith(void Function(ArquivoGrupo) updates) =>
      super.copyWith((message) => updates(message as ArquivoGrupo))
          as ArquivoGrupo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArquivoGrupo create() => ArquivoGrupo._();
  @$core.override
  ArquivoGrupo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArquivoGrupo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArquivoGrupo>(create);
  static ArquivoGrupo? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ArquivoGrupo_Arquivo whichArquivo() =>
      _ArquivoGrupo_ArquivoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearArquivo() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get caminho => $_getSZ(0);
  @$pb.TagNumber(1)
  set caminho($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCaminho() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaminho() => $_clearField(1);

  @$pb.TagNumber(2)
  Grupo get conteudo => $_getN(1);
  @$pb.TagNumber(2)
  set conteudo(Grupo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConteudo() => $_has(1);
  @$pb.TagNumber(2)
  void clearConteudo() => $_clearField(2);
  @$pb.TagNumber(2)
  Grupo ensureConteudo() => $_ensure(1);
}

/// Representa um grupo de setores (ex: Vale Oculto na Sinuosa, ou conjuntos de blocos de Boulder).
class Grupo extends $pb.GeneratedMessage {
  factory Grupo({
    $core.String? nome,
    $core.String? descricao,
    $core.Iterable<Mapa>? mapas,
    $core.Iterable<ArquivoSetor>? setores,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (mapas != null) result.mapas.addAll(mapas);
    if (setores != null) result.setores.addAll(setores);
    return result;
  }

  Grupo._();

  factory Grupo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Grupo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Grupo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOS(2, _omitFieldNames ? '' : 'descricao')
    ..pPM<Mapa>(3, _omitFieldNames ? '' : 'mapas', subBuilder: Mapa.create)
    ..pPM<ArquivoSetor>(4, _omitFieldNames ? '' : 'setores',
        subBuilder: ArquivoSetor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Grupo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Grupo copyWith(void Function(Grupo) updates) =>
      super.copyWith((message) => updates(message as Grupo)) as Grupo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Grupo create() => Grupo._();
  @$core.override
  Grupo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Grupo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Grupo>(create);
  static Grupo? _defaultInstance;

  /// Nome do grupo (ex: Vale Oculto).
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Características do grupo, acesso, etc.
  @$pb.TagNumber(2)
  $core.String get descricao => $_getSZ(1);
  @$pb.TagNumber(2)
  set descricao($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescricao() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescricao() => $_clearField(2);

  /// Mapas do grupo (geralmente mapas de acesso ou visão geral).
  @$pb.TagNumber(3)
  $pb.PbList<Mapa> get mapas => $_getList(2);

  /// Setores que compõem este grupo.
  @$pb.TagNumber(4)
  $pb.PbList<ArquivoSetor> get setores => $_getList(3);
}

/// Representa uma parede ou setor específico dentro de um Pico.
/// Para boulders, isso costuma ser o bloco.
class Setor extends $pb.GeneratedMessage {
  factory Setor({
    $core.String? nome,
    Coordenada? localizacaoEstacionamento,
    Coordenada? localizacaoEscalada,
    $core.Iterable<Trilha>? trilhas,
    $core.bool? sinalDeCelular,
    $core.bool? amigavelACriancas,
    $core.bool? amigavelABebes,
    $core.String? descricao,
    $core.Iterable<Escalada>? escaladas,
    $core.Iterable<Mapa>? mapas,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (localizacaoEstacionamento != null)
      result.localizacaoEstacionamento = localizacaoEstacionamento;
    if (localizacaoEscalada != null)
      result.localizacaoEscalada = localizacaoEscalada;
    if (trilhas != null) result.trilhas.addAll(trilhas);
    if (sinalDeCelular != null) result.sinalDeCelular = sinalDeCelular;
    if (amigavelACriancas != null) result.amigavelACriancas = amigavelACriancas;
    if (amigavelABebes != null) result.amigavelABebes = amigavelABebes;
    if (descricao != null) result.descricao = descricao;
    if (escaladas != null) result.escaladas.addAll(escaladas);
    if (mapas != null) result.mapas.addAll(mapas);
    return result;
  }

  Setor._();

  factory Setor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Setor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Setor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOM<Coordenada>(2, _omitFieldNames ? '' : 'localizacaoEstacionamento',
        subBuilder: Coordenada.create)
    ..aOM<Coordenada>(3, _omitFieldNames ? '' : 'localizacaoEscalada',
        subBuilder: Coordenada.create)
    ..pPM<Trilha>(4, _omitFieldNames ? '' : 'trilhas',
        subBuilder: Trilha.create)
    ..aOB(6, _omitFieldNames ? '' : 'sinalDeCelular')
    ..aOB(7, _omitFieldNames ? '' : 'amigavelACriancas')
    ..aOB(8, _omitFieldNames ? '' : 'amigavelABebes')
    ..aOS(9, _omitFieldNames ? '' : 'descricao')
    ..pPM<Escalada>(11, _omitFieldNames ? '' : 'escaladas',
        subBuilder: Escalada.create)
    ..pPM<Mapa>(13, _omitFieldNames ? '' : 'mapas', subBuilder: Mapa.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Setor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Setor copyWith(void Function(Setor) updates) =>
      super.copyWith((message) => updates(message as Setor)) as Setor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Setor create() => Setor._();
  @$core.override
  Setor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Setor getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Setor>(create);
  static Setor? _defaultInstance;

  /// Nome do setor (ex: Savassinha).
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Coordenada do estacionamento.
  @$pb.TagNumber(2)
  Coordenada get localizacaoEstacionamento => $_getN(1);
  @$pb.TagNumber(2)
  set localizacaoEstacionamento(Coordenada value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalizacaoEstacionamento() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalizacaoEstacionamento() => $_clearField(2);
  @$pb.TagNumber(2)
  Coordenada ensureLocalizacaoEstacionamento() => $_ensure(1);

  /// Coordenada da escalada do setor.
  @$pb.TagNumber(3)
  Coordenada get localizacaoEscalada => $_getN(2);
  @$pb.TagNumber(3)
  set localizacaoEscalada(Coordenada value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalizacaoEscalada() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalizacaoEscalada() => $_clearField(3);
  @$pb.TagNumber(3)
  Coordenada ensureLocalizacaoEscalada() => $_ensure(2);

  /// Trilhas que vão do estacionamento ao setor.
  @$pb.TagNumber(4)
  $pb.PbList<Trilha> get trilhas => $_getList(3);

  /// Possível sinal de celular no setor.
  @$pb.TagNumber(6)
  $core.bool get sinalDeCelular => $_getBF(4);
  @$pb.TagNumber(6)
  set sinalDeCelular($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(6)
  $core.bool hasSinalDeCelular() => $_has(4);
  @$pb.TagNumber(6)
  void clearSinalDeCelular() => $_clearField(6);

  /// Setor e acesso favorável a crianças.
  @$pb.TagNumber(7)
  $core.bool get amigavelACriancas => $_getBF(5);
  @$pb.TagNumber(7)
  set amigavelACriancas($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(7)
  $core.bool hasAmigavelACriancas() => $_has(5);
  @$pb.TagNumber(7)
  void clearAmigavelACriancas() => $_clearField(7);

  /// Setor e acesso favorável a bebês.
  @$pb.TagNumber(8)
  $core.bool get amigavelABebes => $_getBF(6);
  @$pb.TagNumber(8)
  set amigavelABebes($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(8)
  $core.bool hasAmigavelABebes() => $_has(6);
  @$pb.TagNumber(8)
  void clearAmigavelABebes() => $_clearField(8);

  /// Características da escalada no setor, insolação, qualidade da rocha, etc.
  @$pb.TagNumber(9)
  $core.String get descricao => $_getSZ(7);
  @$pb.TagNumber(9)
  set descricao($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasDescricao() => $_has(7);
  @$pb.TagNumber(9)
  void clearDescricao() => $_clearField(9);

  /// Todas as escaladas deste setor.
  @$pb.TagNumber(11)
  $pb.PbList<Escalada> get escaladas => $_getList(8);

  /// Mapas do setor.
  @$pb.TagNumber(13)
  $pb.PbList<Mapa> get mapas => $_getList(9);
}

enum Mapa_PontoDeInteresse_TipoBox { box, boxObliqua, notSet }

/// Representa um ponto de interesse no mapa.
class Mapa_PontoDeInteresse extends $pb.GeneratedMessage {
  factory Mapa_PontoDeInteresse({
    $core.String? id,
    $core.String? label,
    BoundingBox? box,
    BoundingBoxObliqua? boxObliqua,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (box != null) result.box = box;
    if (boxObliqua != null) result.boxObliqua = boxObliqua;
    return result;
  }

  Mapa_PontoDeInteresse._();

  factory Mapa_PontoDeInteresse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Mapa_PontoDeInteresse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Mapa_PontoDeInteresse_TipoBox>
      _Mapa_PontoDeInteresse_TipoBoxByTag = {
    3: Mapa_PontoDeInteresse_TipoBox.box,
    5: Mapa_PontoDeInteresse_TipoBox.boxObliqua,
    0: Mapa_PontoDeInteresse_TipoBox.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mapa.PontoDeInteresse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [3, 5])
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOM<BoundingBox>(3, _omitFieldNames ? '' : 'box',
        subBuilder: BoundingBox.create)
    ..aOM<BoundingBoxObliqua>(5, _omitFieldNames ? '' : 'boxObliqua',
        subBuilder: BoundingBoxObliqua.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapa_PontoDeInteresse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapa_PontoDeInteresse copyWith(
          void Function(Mapa_PontoDeInteresse) updates) =>
      super.copyWith((message) => updates(message as Mapa_PontoDeInteresse))
          as Mapa_PontoDeInteresse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Mapa_PontoDeInteresse create() => Mapa_PontoDeInteresse._();
  @$core.override
  Mapa_PontoDeInteresse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Mapa_PontoDeInteresse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Mapa_PontoDeInteresse>(create);
  static Mapa_PontoDeInteresse? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(5)
  Mapa_PontoDeInteresse_TipoBox whichTipoBox() =>
      _Mapa_PontoDeInteresse_TipoBoxByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(5)
  void clearTipoBox() => $_clearField($_whichOneof(0));

  /// ID do ponto de interesse no mapa.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Label do ponto de interesse que estava escrita no mapa.
  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  /// Bounding box retangular.
  @$pb.TagNumber(3)
  BoundingBox get box => $_getN(2);
  @$pb.TagNumber(3)
  set box(BoundingBox value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBox() => $_has(2);
  @$pb.TagNumber(3)
  void clearBox() => $_clearField(3);
  @$pb.TagNumber(3)
  BoundingBox ensureBox() => $_ensure(2);

  /// Bounding box oblíqua.
  @$pb.TagNumber(5)
  BoundingBoxObliqua get boxObliqua => $_getN(3);
  @$pb.TagNumber(5)
  set boxObliqua(BoundingBoxObliqua value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasBoxObliqua() => $_has(3);
  @$pb.TagNumber(5)
  void clearBoxObliqua() => $_clearField(5);
  @$pb.TagNumber(5)
  BoundingBoxObliqua ensureBoxObliqua() => $_ensure(3);
}

/// Representa um mapa do setor.
class Mapa extends $pb.GeneratedMessage {
  factory Mapa({
    $core.String? caminhoImagemMapa,
    $core.int? larguraMapa,
    $core.int? alturaMapa,
    $core.Iterable<Mapa_PontoDeInteresse>? pontosDeInteresse,
  }) {
    final result = create();
    if (caminhoImagemMapa != null) result.caminhoImagemMapa = caminhoImagemMapa;
    if (larguraMapa != null) result.larguraMapa = larguraMapa;
    if (alturaMapa != null) result.alturaMapa = alturaMapa;
    if (pontosDeInteresse != null)
      result.pontosDeInteresse.addAll(pontosDeInteresse);
    return result;
  }

  Mapa._();

  factory Mapa.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Mapa.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mapa',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'caminhoImagemMapa')
    ..aI(2, _omitFieldNames ? '' : 'larguraMapa')
    ..aI(3, _omitFieldNames ? '' : 'alturaMapa')
    ..pPM<Mapa_PontoDeInteresse>(4, _omitFieldNames ? '' : 'pontosDeInteresse',
        subBuilder: Mapa_PontoDeInteresse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapa clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapa copyWith(void Function(Mapa) updates) =>
      super.copyWith((message) => updates(message as Mapa)) as Mapa;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Mapa create() => Mapa._();
  @$core.override
  Mapa createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Mapa getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Mapa>(create);
  static Mapa? _defaultInstance;

  /// Caminho do arquivo (geralmente em .webp) contendo a foto desenhada da parede.
  @$pb.TagNumber(1)
  $core.String get caminhoImagemMapa => $_getSZ(0);
  @$pb.TagNumber(1)
  set caminhoImagemMapa($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCaminhoImagemMapa() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaminhoImagemMapa() => $_clearField(1);

  /// Largura do mapa em pixels.
  @$pb.TagNumber(2)
  $core.int get larguraMapa => $_getIZ(1);
  @$pb.TagNumber(2)
  set larguraMapa($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLarguraMapa() => $_has(1);
  @$pb.TagNumber(2)
  void clearLarguraMapa() => $_clearField(2);

  /// Altura do mapa em pixels.
  @$pb.TagNumber(3)
  $core.int get alturaMapa => $_getIZ(2);
  @$pb.TagNumber(3)
  set alturaMapa($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlturaMapa() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlturaMapa() => $_clearField(3);

  /// Posição de cada ponto de interesse.
  @$pb.TagNumber(4)
  $pb.PbList<Mapa_PontoDeInteresse> get pontosDeInteresse => $_getList(3);
}

/// Caixa de enquadramento / bounding box retangular de parte da imagem.
class BoundingBox extends $pb.GeneratedMessage {
  factory BoundingBox({
    $core.int? xmin,
    $core.int? ymin,
    $core.int? xmax,
    $core.int? ymax,
  }) {
    final result = create();
    if (xmin != null) result.xmin = xmin;
    if (ymin != null) result.ymin = ymin;
    if (xmax != null) result.xmax = xmax;
    if (ymax != null) result.ymax = ymax;
    return result;
  }

  BoundingBox._();

  factory BoundingBox.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoundingBox.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoundingBox',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'xmin')
    ..aI(2, _omitFieldNames ? '' : 'ymin')
    ..aI(3, _omitFieldNames ? '' : 'xmax')
    ..aI(4, _omitFieldNames ? '' : 'ymax')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBox clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBox copyWith(void Function(BoundingBox) updates) =>
      super.copyWith((message) => updates(message as BoundingBox))
          as BoundingBox;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoundingBox create() => BoundingBox._();
  @$core.override
  BoundingBox createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoundingBox getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BoundingBox>(create);
  static BoundingBox? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get xmin => $_getIZ(0);
  @$pb.TagNumber(1)
  set xmin($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasXmin() => $_has(0);
  @$pb.TagNumber(1)
  void clearXmin() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get ymin => $_getIZ(1);
  @$pb.TagNumber(2)
  set ymin($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasYmin() => $_has(1);
  @$pb.TagNumber(2)
  void clearYmin() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get xmax => $_getIZ(2);
  @$pb.TagNumber(3)
  set xmax($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasXmax() => $_has(2);
  @$pb.TagNumber(3)
  void clearXmax() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get ymax => $_getIZ(3);
  @$pb.TagNumber(4)
  set ymax($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasYmax() => $_has(3);
  @$pb.TagNumber(4)
  void clearYmax() => $_clearField(4);
}

/// Caixa de enquadramento / bounding box oblíqua pra parte da imagem.
/// Definido pela posição dos 4 cantos da área da bounding box.
class BoundingBoxObliqua extends $pb.GeneratedMessage {
  factory BoundingBoxObliqua({
    $core.int? x1,
    $core.int? y1,
    $core.int? x2,
    $core.int? y2,
    $core.int? x3,
    $core.int? y3,
    $core.int? x4,
    $core.int? y4,
  }) {
    final result = create();
    if (x1 != null) result.x1 = x1;
    if (y1 != null) result.y1 = y1;
    if (x2 != null) result.x2 = x2;
    if (y2 != null) result.y2 = y2;
    if (x3 != null) result.x3 = x3;
    if (y3 != null) result.y3 = y3;
    if (x4 != null) result.x4 = x4;
    if (y4 != null) result.y4 = y4;
    return result;
  }

  BoundingBoxObliqua._();

  factory BoundingBoxObliqua.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoundingBoxObliqua.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoundingBoxObliqua',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'x1')
    ..aI(2, _omitFieldNames ? '' : 'y1')
    ..aI(3, _omitFieldNames ? '' : 'x2')
    ..aI(4, _omitFieldNames ? '' : 'y2')
    ..aI(5, _omitFieldNames ? '' : 'x3')
    ..aI(6, _omitFieldNames ? '' : 'y3')
    ..aI(7, _omitFieldNames ? '' : 'x4')
    ..aI(8, _omitFieldNames ? '' : 'y4')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBoxObliqua clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoundingBoxObliqua copyWith(void Function(BoundingBoxObliqua) updates) =>
      super.copyWith((message) => updates(message as BoundingBoxObliqua))
          as BoundingBoxObliqua;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoundingBoxObliqua create() => BoundingBoxObliqua._();
  @$core.override
  BoundingBoxObliqua createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoundingBoxObliqua getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BoundingBoxObliqua>(create);
  static BoundingBoxObliqua? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get x1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set x1($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX1() => $_has(0);
  @$pb.TagNumber(1)
  void clearX1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get y1 => $_getIZ(1);
  @$pb.TagNumber(2)
  set y1($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY1() => $_has(1);
  @$pb.TagNumber(2)
  void clearY1() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get x2 => $_getIZ(2);
  @$pb.TagNumber(3)
  set x2($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasX2() => $_has(2);
  @$pb.TagNumber(3)
  void clearX2() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get y2 => $_getIZ(3);
  @$pb.TagNumber(4)
  set y2($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasY2() => $_has(3);
  @$pb.TagNumber(4)
  void clearY2() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get x3 => $_getIZ(4);
  @$pb.TagNumber(5)
  set x3($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasX3() => $_has(4);
  @$pb.TagNumber(5)
  void clearX3() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get y3 => $_getIZ(5);
  @$pb.TagNumber(6)
  set y3($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasY3() => $_has(5);
  @$pb.TagNumber(6)
  void clearY3() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get x4 => $_getIZ(6);
  @$pb.TagNumber(7)
  set x4($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasX4() => $_has(6);
  @$pb.TagNumber(7)
  void clearX4() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get y4 => $_getIZ(7);
  @$pb.TagNumber(8)
  set y4($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasY4() => $_has(7);
  @$pb.TagNumber(8)
  void clearY4() => $_clearField(8);
}

enum Escalada_Tipo {
  viaEsportiva,
  viaMovel,
  boulder,
  viaMultiplasEnfiadas,
  highline,
  notSet
}

/// Representa uma escalada de qualquer tipo.
class Escalada extends $pb.GeneratedMessage {
  factory Escalada({
    ViaEsportiva? viaEsportiva,
    ViaMovel? viaMovel,
    Boulder? boulder,
    ViaMultiplasEnfiadas? viaMultiplasEnfiadas,
    Highline? highline,
  }) {
    final result = create();
    if (viaEsportiva != null) result.viaEsportiva = viaEsportiva;
    if (viaMovel != null) result.viaMovel = viaMovel;
    if (boulder != null) result.boulder = boulder;
    if (viaMultiplasEnfiadas != null)
      result.viaMultiplasEnfiadas = viaMultiplasEnfiadas;
    if (highline != null) result.highline = highline;
    return result;
  }

  Escalada._();

  factory Escalada.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Escalada.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Escalada_Tipo> _Escalada_TipoByTag = {
    1: Escalada_Tipo.viaEsportiva,
    2: Escalada_Tipo.viaMovel,
    3: Escalada_Tipo.boulder,
    4: Escalada_Tipo.viaMultiplasEnfiadas,
    5: Escalada_Tipo.highline,
    0: Escalada_Tipo.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Escalada',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<ViaEsportiva>(1, _omitFieldNames ? '' : 'viaEsportiva',
        subBuilder: ViaEsportiva.create)
    ..aOM<ViaMovel>(2, _omitFieldNames ? '' : 'viaMovel',
        subBuilder: ViaMovel.create)
    ..aOM<Boulder>(3, _omitFieldNames ? '' : 'boulder',
        subBuilder: Boulder.create)
    ..aOM<ViaMultiplasEnfiadas>(
        4, _omitFieldNames ? '' : 'viaMultiplasEnfiadas',
        subBuilder: ViaMultiplasEnfiadas.create)
    ..aOM<Highline>(5, _omitFieldNames ? '' : 'highline',
        subBuilder: Highline.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Escalada clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Escalada copyWith(void Function(Escalada) updates) =>
      super.copyWith((message) => updates(message as Escalada)) as Escalada;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Escalada create() => Escalada._();
  @$core.override
  Escalada createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Escalada getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Escalada>(create);
  static Escalada? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  Escalada_Tipo whichTipo() => _Escalada_TipoByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearTipo() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ViaEsportiva get viaEsportiva => $_getN(0);
  @$pb.TagNumber(1)
  set viaEsportiva(ViaEsportiva value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasViaEsportiva() => $_has(0);
  @$pb.TagNumber(1)
  void clearViaEsportiva() => $_clearField(1);
  @$pb.TagNumber(1)
  ViaEsportiva ensureViaEsportiva() => $_ensure(0);

  @$pb.TagNumber(2)
  ViaMovel get viaMovel => $_getN(1);
  @$pb.TagNumber(2)
  set viaMovel(ViaMovel value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasViaMovel() => $_has(1);
  @$pb.TagNumber(2)
  void clearViaMovel() => $_clearField(2);
  @$pb.TagNumber(2)
  ViaMovel ensureViaMovel() => $_ensure(1);

  @$pb.TagNumber(3)
  Boulder get boulder => $_getN(2);
  @$pb.TagNumber(3)
  set boulder(Boulder value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBoulder() => $_has(2);
  @$pb.TagNumber(3)
  void clearBoulder() => $_clearField(3);
  @$pb.TagNumber(3)
  Boulder ensureBoulder() => $_ensure(2);

  @$pb.TagNumber(4)
  ViaMultiplasEnfiadas get viaMultiplasEnfiadas => $_getN(3);
  @$pb.TagNumber(4)
  set viaMultiplasEnfiadas(ViaMultiplasEnfiadas value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasViaMultiplasEnfiadas() => $_has(3);
  @$pb.TagNumber(4)
  void clearViaMultiplasEnfiadas() => $_clearField(4);
  @$pb.TagNumber(4)
  ViaMultiplasEnfiadas ensureViaMultiplasEnfiadas() => $_ensure(3);

  @$pb.TagNumber(5)
  Highline get highline => $_getN(4);
  @$pb.TagNumber(5)
  set highline(Highline value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasHighline() => $_has(4);
  @$pb.TagNumber(5)
  void clearHighline() => $_clearField(5);
  @$pb.TagNumber(5)
  Highline ensureHighline() => $_ensure(4);
}

/// Representa uma linha de escalada esportiva (via) individual de uma enfiada e somente com proteções fixas.
class ViaEsportiva extends $pb.GeneratedMessage {
  factory ViaEsportiva({
    $core.String? nome,
    GrauVia_GrauVia? dificuldade,
    GrauArtificial_GrauArtificial? dificuldadeArtificial,
    GrauExposicao_GrauExposicao? exposicao,
    TipoParede_TipoParede? tipoParede,
    $core.int? extensao,
    $core.int? quantidadeProtecoesIntermediarias,
    $core.int? quantidadeProtecoesParada,
    $core.String? tipoAncoragem,
    $core.Iterable<$core.String>? conquistadores,
    $core.String? dataAbertura,
    $core.String? dataManutencao,
    $core.String? descricao,
    $core.String? urlVideoBeta,
    $core.String? chavePixManutencao,
    $core.String? idNoMapa,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (dificuldade != null) result.dificuldade = dificuldade;
    if (dificuldadeArtificial != null)
      result.dificuldadeArtificial = dificuldadeArtificial;
    if (exposicao != null) result.exposicao = exposicao;
    if (tipoParede != null) result.tipoParede = tipoParede;
    if (extensao != null) result.extensao = extensao;
    if (quantidadeProtecoesIntermediarias != null)
      result.quantidadeProtecoesIntermediarias =
          quantidadeProtecoesIntermediarias;
    if (quantidadeProtecoesParada != null)
      result.quantidadeProtecoesParada = quantidadeProtecoesParada;
    if (tipoAncoragem != null) result.tipoAncoragem = tipoAncoragem;
    if (conquistadores != null) result.conquistadores.addAll(conquistadores);
    if (dataAbertura != null) result.dataAbertura = dataAbertura;
    if (dataManutencao != null) result.dataManutencao = dataManutencao;
    if (descricao != null) result.descricao = descricao;
    if (urlVideoBeta != null) result.urlVideoBeta = urlVideoBeta;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (idNoMapa != null) result.idNoMapa = idNoMapa;
    return result;
  }

  ViaEsportiva._();

  factory ViaEsportiva.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ViaEsportiva.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ViaEsportiva',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aE<GrauVia_GrauVia>(2, _omitFieldNames ? '' : 'dificuldade',
        enumValues: GrauVia_GrauVia.values)
    ..aE<GrauArtificial_GrauArtificial>(
        3, _omitFieldNames ? '' : 'dificuldadeArtificial',
        enumValues: GrauArtificial_GrauArtificial.values)
    ..aE<GrauExposicao_GrauExposicao>(4, _omitFieldNames ? '' : 'exposicao',
        enumValues: GrauExposicao_GrauExposicao.values)
    ..aE<TipoParede_TipoParede>(5, _omitFieldNames ? '' : 'tipoParede',
        enumValues: TipoParede_TipoParede.values)
    ..aI(6, _omitFieldNames ? '' : 'extensao')
    ..aI(7, _omitFieldNames ? '' : 'quantidadeProtecoesIntermediarias')
    ..aI(8, _omitFieldNames ? '' : 'quantidadeProtecoesParada')
    ..aOS(9, _omitFieldNames ? '' : 'tipoAncoragem')
    ..pPS(10, _omitFieldNames ? '' : 'conquistadores')
    ..aOS(11, _omitFieldNames ? '' : 'dataAbertura')
    ..aOS(12, _omitFieldNames ? '' : 'dataManutencao')
    ..aOS(13, _omitFieldNames ? '' : 'descricao')
    ..aOS(14, _omitFieldNames ? '' : 'urlVideoBeta')
    ..aOS(15, _omitFieldNames ? '' : 'chavePixManutencao')
    ..aOS(16, _omitFieldNames ? '' : 'idNoMapa')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaEsportiva clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaEsportiva copyWith(void Function(ViaEsportiva) updates) =>
      super.copyWith((message) => updates(message as ViaEsportiva))
          as ViaEsportiva;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ViaEsportiva create() => ViaEsportiva._();
  @$core.override
  ViaEsportiva createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ViaEsportiva getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ViaEsportiva>(create);
  static ViaEsportiva? _defaultInstance;

  /// Nome da via.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Grau de dificuldade em livre da via (ex "BR_6sup").
  @$pb.TagNumber(2)
  GrauVia_GrauVia get dificuldade => $_getN(1);
  @$pb.TagNumber(2)
  set dificuldade(GrauVia_GrauVia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDificuldade() => $_has(1);
  @$pb.TagNumber(2)
  void clearDificuldade() => $_clearField(2);

  /// Grau de escalada em artificial, se houver trechos de artificial (ex: "A1", "A2").
  @$pb.TagNumber(3)
  GrauArtificial_GrauArtificial get dificuldadeArtificial => $_getN(2);
  @$pb.TagNumber(3)
  set dificuldadeArtificial(GrauArtificial_GrauArtificial value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDificuldadeArtificial() => $_has(2);
  @$pb.TagNumber(3)
  void clearDificuldadeArtificial() => $_clearField(3);

  /// Grau de exposição da via. Normalmente não preenchido em vias esportivas, que
  /// costumam ser "E1".
  @$pb.TagNumber(4)
  GrauExposicao_GrauExposicao get exposicao => $_getN(3);
  @$pb.TagNumber(4)
  set exposicao(GrauExposicao_GrauExposicao value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExposicao() => $_has(3);
  @$pb.TagNumber(4)
  void clearExposicao() => $_clearField(4);

  /// Tipo de parede predominante (negativo, vertical, positivo).
  @$pb.TagNumber(5)
  TipoParede_TipoParede get tipoParede => $_getN(4);
  @$pb.TagNumber(5)
  set tipoParede(TipoParede_TipoParede value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTipoParede() => $_has(4);
  @$pb.TagNumber(5)
  void clearTipoParede() => $_clearField(5);

  /// Extensão da via, em metros.
  @$pb.TagNumber(6)
  $core.int get extensao => $_getIZ(5);
  @$pb.TagNumber(6)
  set extensao($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExtensao() => $_has(5);
  @$pb.TagNumber(6)
  void clearExtensao() => $_clearField(6);

  /// Número de proteções fixas intermediárias (chapeletas) na via (define quantas costuras levar).
  @$pb.TagNumber(7)
  $core.int get quantidadeProtecoesIntermediarias => $_getIZ(6);
  @$pb.TagNumber(7)
  set quantidadeProtecoesIntermediarias($core.int value) =>
      $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasQuantidadeProtecoesIntermediarias() => $_has(6);
  @$pb.TagNumber(7)
  void clearQuantidadeProtecoesIntermediarias() => $_clearField(7);

  /// Número de proteções fixas na parada da via (define quantas costuras levar).
  @$pb.TagNumber(8)
  $core.int get quantidadeProtecoesParada => $_getIZ(7);
  @$pb.TagNumber(8)
  set quantidadeProtecoesParada($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasQuantidadeProtecoesParada() => $_has(7);
  @$pb.TagNumber(8)
  void clearQuantidadeProtecoesParada() => $_clearField(8);

  /// TODO: Tipo da parada (ex: "Corrente", "Pinus", "Parabolt Duplo").
  @$pb.TagNumber(9)
  $core.String get tipoAncoragem => $_getSZ(8);
  @$pb.TagNumber(9)
  set tipoAncoragem($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTipoAncoragem() => $_has(8);
  @$pb.TagNumber(9)
  void clearTipoAncoragem() => $_clearField(9);

  /// Nomes dos conquistadores.
  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get conquistadores => $_getList(9);

  /// Data de abertura da via (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(11)
  $core.String get dataAbertura => $_getSZ(10);
  @$pb.TagNumber(11)
  set dataAbertura($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDataAbertura() => $_has(10);
  @$pb.TagNumber(11)
  void clearDataAbertura() => $_clearField(11);

  /// Data da última manutenção da via (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(12)
  $core.String get dataManutencao => $_getSZ(11);
  @$pb.TagNumber(12)
  set dataManutencao($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDataManutencao() => $_has(11);
  @$pb.TagNumber(12)
  void clearDataManutencao() => $_clearField(12);

  /// Dicas de segurança, movimentação chave (beta) e equipamentos recomendados.
  @$pb.TagNumber(13)
  $core.String get descricao => $_getSZ(12);
  @$pb.TagNumber(13)
  set descricao($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDescricao() => $_has(12);
  @$pb.TagNumber(13)
  void clearDescricao() => $_clearField(13);

  /// URL local do arquivo .mp4 para o vídeo demonstrativo do beta (se baixado via Wi-Fi).
  @$pb.TagNumber(14)
  $core.String get urlVideoBeta => $_getSZ(13);
  @$pb.TagNumber(14)
  set urlVideoBeta($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasUrlVideoBeta() => $_has(13);
  @$pb.TagNumber(14)
  void clearUrlVideoBeta() => $_clearField(14);

  /// Chave Pix do mantenedor ou conquistador específico desta via.
  @$pb.TagNumber(15)
  $core.String get chavePixManutencao => $_getSZ(14);
  @$pb.TagNumber(15)
  set chavePixManutencao($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasChavePixManutencao() => $_has(14);
  @$pb.TagNumber(15)
  void clearChavePixManutencao() => $_clearField(15);

  /// ID da via no mapa. Provavelmente um número, como 1, ou a, ou 1a, etc.
  @$pb.TagNumber(16)
  $core.String get idNoMapa => $_getSZ(15);
  @$pb.TagNumber(16)
  set idNoMapa($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasIdNoMapa() => $_has(15);
  @$pb.TagNumber(16)
  void clearIdNoMapa() => $_clearField(16);
}

/// Representa uma linha de escalada (via) individual de uma enfiada ou totalmente móvel ou mista com proteções fixas.
class ViaMovel extends $pb.GeneratedMessage {
  factory ViaMovel({
    $core.String? nome,
    GrauVia_GrauVia? dificuldade,
    GrauExposicao_GrauExposicao? exposicao,
    TipoParede_TipoParede? tipoParede,
    $core.int? extensao,
    $core.int? quantidadeProtecoesIntermediarias,
    $core.int? quantidadeProtecoesParada,
    $core.String? protecoesMoveis,
    $core.String? tipoAncoragem,
    $core.Iterable<$core.String>? conquistadores,
    $core.String? dataAbertura,
    $core.String? dataManutencao,
    $core.String? descricao,
    $core.String? urlVideoBeta,
    $core.String? chavePixManutencao,
    $core.String? idNoMapa,
    GrauArtificial_GrauArtificial? dificuldadeArtificial,
    GrauVia_GrauVia? dificuldadeArtificialEmLivre,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (dificuldade != null) result.dificuldade = dificuldade;
    if (exposicao != null) result.exposicao = exposicao;
    if (tipoParede != null) result.tipoParede = tipoParede;
    if (extensao != null) result.extensao = extensao;
    if (quantidadeProtecoesIntermediarias != null)
      result.quantidadeProtecoesIntermediarias =
          quantidadeProtecoesIntermediarias;
    if (quantidadeProtecoesParada != null)
      result.quantidadeProtecoesParada = quantidadeProtecoesParada;
    if (protecoesMoveis != null) result.protecoesMoveis = protecoesMoveis;
    if (tipoAncoragem != null) result.tipoAncoragem = tipoAncoragem;
    if (conquistadores != null) result.conquistadores.addAll(conquistadores);
    if (dataAbertura != null) result.dataAbertura = dataAbertura;
    if (dataManutencao != null) result.dataManutencao = dataManutencao;
    if (descricao != null) result.descricao = descricao;
    if (urlVideoBeta != null) result.urlVideoBeta = urlVideoBeta;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (idNoMapa != null) result.idNoMapa = idNoMapa;
    if (dificuldadeArtificial != null)
      result.dificuldadeArtificial = dificuldadeArtificial;
    if (dificuldadeArtificialEmLivre != null)
      result.dificuldadeArtificialEmLivre = dificuldadeArtificialEmLivre;
    return result;
  }

  ViaMovel._();

  factory ViaMovel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ViaMovel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ViaMovel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aE<GrauVia_GrauVia>(2, _omitFieldNames ? '' : 'dificuldade',
        enumValues: GrauVia_GrauVia.values)
    ..aE<GrauExposicao_GrauExposicao>(3, _omitFieldNames ? '' : 'exposicao',
        enumValues: GrauExposicao_GrauExposicao.values)
    ..aE<TipoParede_TipoParede>(4, _omitFieldNames ? '' : 'tipoParede',
        enumValues: TipoParede_TipoParede.values)
    ..aI(5, _omitFieldNames ? '' : 'extensao')
    ..aI(6, _omitFieldNames ? '' : 'quantidadeProtecoesIntermediarias')
    ..aI(7, _omitFieldNames ? '' : 'quantidadeProtecoesParada')
    ..aOS(8, _omitFieldNames ? '' : 'protecoesMoveis')
    ..aOS(9, _omitFieldNames ? '' : 'tipoAncoragem')
    ..pPS(10, _omitFieldNames ? '' : 'conquistadores')
    ..aOS(11, _omitFieldNames ? '' : 'dataAbertura')
    ..aOS(12, _omitFieldNames ? '' : 'dataManutencao')
    ..aOS(13, _omitFieldNames ? '' : 'descricao')
    ..aOS(14, _omitFieldNames ? '' : 'urlVideoBeta')
    ..aOS(15, _omitFieldNames ? '' : 'chavePixManutencao')
    ..aOS(16, _omitFieldNames ? '' : 'idNoMapa')
    ..aE<GrauArtificial_GrauArtificial>(
        17, _omitFieldNames ? '' : 'dificuldadeArtificial',
        enumValues: GrauArtificial_GrauArtificial.values)
    ..aE<GrauVia_GrauVia>(
        18, _omitFieldNames ? '' : 'dificuldadeArtificialEmLivre',
        enumValues: GrauVia_GrauVia.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaMovel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaMovel copyWith(void Function(ViaMovel) updates) =>
      super.copyWith((message) => updates(message as ViaMovel)) as ViaMovel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ViaMovel create() => ViaMovel._();
  @$core.override
  ViaMovel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ViaMovel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViaMovel>(create);
  static ViaMovel? _defaultInstance;

  /// Nome da via.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Grau de dificuldade em livre da via (ex "BR_6sup").
  @$pb.TagNumber(2)
  GrauVia_GrauVia get dificuldade => $_getN(1);
  @$pb.TagNumber(2)
  set dificuldade(GrauVia_GrauVia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDificuldade() => $_has(1);
  @$pb.TagNumber(2)
  void clearDificuldade() => $_clearField(2);

  /// Grau de exposição da via.
  @$pb.TagNumber(3)
  GrauExposicao_GrauExposicao get exposicao => $_getN(2);
  @$pb.TagNumber(3)
  set exposicao(GrauExposicao_GrauExposicao value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExposicao() => $_has(2);
  @$pb.TagNumber(3)
  void clearExposicao() => $_clearField(3);

  /// Tipo de parede predominante (negativo, vertical, positivo).
  @$pb.TagNumber(4)
  TipoParede_TipoParede get tipoParede => $_getN(3);
  @$pb.TagNumber(4)
  set tipoParede(TipoParede_TipoParede value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTipoParede() => $_has(3);
  @$pb.TagNumber(4)
  void clearTipoParede() => $_clearField(4);

  /// Extensão da via, em metros.
  @$pb.TagNumber(5)
  $core.int get extensao => $_getIZ(4);
  @$pb.TagNumber(5)
  set extensao($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExtensao() => $_has(4);
  @$pb.TagNumber(5)
  void clearExtensao() => $_clearField(5);

  /// Número de proteções fixas intermediárias (chapeletas) na via.
  @$pb.TagNumber(6)
  $core.int get quantidadeProtecoesIntermediarias => $_getIZ(5);
  @$pb.TagNumber(6)
  set quantidadeProtecoesIntermediarias($core.int value) =>
      $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasQuantidadeProtecoesIntermediarias() => $_has(5);
  @$pb.TagNumber(6)
  void clearQuantidadeProtecoesIntermediarias() => $_clearField(6);

  /// Número de proteções fixas na parada da via.
  @$pb.TagNumber(7)
  $core.int get quantidadeProtecoesParada => $_getIZ(6);
  @$pb.TagNumber(7)
  set quantidadeProtecoesParada($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasQuantidadeProtecoesParada() => $_has(6);
  @$pb.TagNumber(7)
  void clearQuantidadeProtecoesParada() => $_clearField(7);

  /// Tipo de proteções móveis a serem usadas na via. Descrição textual.
  @$pb.TagNumber(8)
  $core.String get protecoesMoveis => $_getSZ(7);
  @$pb.TagNumber(8)
  set protecoesMoveis($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProtecoesMoveis() => $_has(7);
  @$pb.TagNumber(8)
  void clearProtecoesMoveis() => $_clearField(8);

  /// TODO: Tipo da parada (ex: "Corrente", "Pinus", "Parabolt Duplo").
  @$pb.TagNumber(9)
  $core.String get tipoAncoragem => $_getSZ(8);
  @$pb.TagNumber(9)
  set tipoAncoragem($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTipoAncoragem() => $_has(8);
  @$pb.TagNumber(9)
  void clearTipoAncoragem() => $_clearField(9);

  /// Nomes dos conquistadores.
  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get conquistadores => $_getList(9);

  /// Data de abertura da via (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(11)
  $core.String get dataAbertura => $_getSZ(10);
  @$pb.TagNumber(11)
  set dataAbertura($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDataAbertura() => $_has(10);
  @$pb.TagNumber(11)
  void clearDataAbertura() => $_clearField(11);

  /// Data da última manutenção da via (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(12)
  $core.String get dataManutencao => $_getSZ(11);
  @$pb.TagNumber(12)
  set dataManutencao($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDataManutencao() => $_has(11);
  @$pb.TagNumber(12)
  void clearDataManutencao() => $_clearField(12);

  /// Dicas de segurança, movimentação chave (beta) e equipamentos recomendados.
  @$pb.TagNumber(13)
  $core.String get descricao => $_getSZ(12);
  @$pb.TagNumber(13)
  set descricao($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDescricao() => $_has(12);
  @$pb.TagNumber(13)
  void clearDescricao() => $_clearField(13);

  /// URL local do arquivo .mp4 para o vídeo demonstrativo do beta (se baixado via Wi-Fi).
  @$pb.TagNumber(14)
  $core.String get urlVideoBeta => $_getSZ(13);
  @$pb.TagNumber(14)
  set urlVideoBeta($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasUrlVideoBeta() => $_has(13);
  @$pb.TagNumber(14)
  void clearUrlVideoBeta() => $_clearField(14);

  /// Chave Pix do mantenedor ou conquistador específico desta via.
  @$pb.TagNumber(15)
  $core.String get chavePixManutencao => $_getSZ(14);
  @$pb.TagNumber(15)
  set chavePixManutencao($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasChavePixManutencao() => $_has(14);
  @$pb.TagNumber(15)
  void clearChavePixManutencao() => $_clearField(15);

  /// ID da via no mapa. Provavelmente um número, como 1, ou a, ou 1a, etc.
  @$pb.TagNumber(16)
  $core.String get idNoMapa => $_getSZ(15);
  @$pb.TagNumber(16)
  set idNoMapa($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasIdNoMapa() => $_has(15);
  @$pb.TagNumber(16)
  void clearIdNoMapa() => $_clearField(16);

  /// Grau de escalada em artificial, se houver trechos de artificial (ex: "A1", "A2").
  @$pb.TagNumber(17)
  GrauArtificial_GrauArtificial get dificuldadeArtificial => $_getN(16);
  @$pb.TagNumber(17)
  set dificuldadeArtificial(GrauArtificial_GrauArtificial value) =>
      $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasDificuldadeArtificial() => $_has(16);
  @$pb.TagNumber(17)
  void clearDificuldadeArtificial() => $_clearField(17);

  /// Grau do lance em artificial se escalado em livre.
  @$pb.TagNumber(18)
  GrauVia_GrauVia get dificuldadeArtificialEmLivre => $_getN(17);
  @$pb.TagNumber(18)
  set dificuldadeArtificialEmLivre(GrauVia_GrauVia value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasDificuldadeArtificialEmLivre() => $_has(17);
  @$pb.TagNumber(18)
  void clearDificuldadeArtificialEmLivre() => $_clearField(18);
}

/// Representa uma linha de boulder individual.
class Boulder extends $pb.GeneratedMessage {
  factory Boulder({
    $core.String? nome,
    GrauBoulder_GrauBoulder? dificuldade,
    TipoParede_TipoParede? tipoParede,
    $core.Iterable<$core.String>? conquistadores,
    $core.String? dataAbertura,
    $core.String? descricao,
    $core.String? urlVideoBeta,
    $core.String? chavePixManutencao,
    $core.String? idNoMapa,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (dificuldade != null) result.dificuldade = dificuldade;
    if (tipoParede != null) result.tipoParede = tipoParede;
    if (conquistadores != null) result.conquistadores.addAll(conquistadores);
    if (dataAbertura != null) result.dataAbertura = dataAbertura;
    if (descricao != null) result.descricao = descricao;
    if (urlVideoBeta != null) result.urlVideoBeta = urlVideoBeta;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (idNoMapa != null) result.idNoMapa = idNoMapa;
    return result;
  }

  Boulder._();

  factory Boulder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Boulder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Boulder',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aE<GrauBoulder_GrauBoulder>(2, _omitFieldNames ? '' : 'dificuldade',
        enumValues: GrauBoulder_GrauBoulder.values)
    ..aE<TipoParede_TipoParede>(3, _omitFieldNames ? '' : 'tipoParede',
        enumValues: TipoParede_TipoParede.values)
    ..pPS(4, _omitFieldNames ? '' : 'conquistadores')
    ..aOS(5, _omitFieldNames ? '' : 'dataAbertura')
    ..aOS(6, _omitFieldNames ? '' : 'descricao')
    ..aOS(7, _omitFieldNames ? '' : 'urlVideoBeta')
    ..aOS(8, _omitFieldNames ? '' : 'chavePixManutencao')
    ..aOS(9, _omitFieldNames ? '' : 'idNoMapa')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Boulder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Boulder copyWith(void Function(Boulder) updates) =>
      super.copyWith((message) => updates(message as Boulder)) as Boulder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Boulder create() => Boulder._();
  @$core.override
  Boulder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Boulder getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Boulder>(create);
  static Boulder? _defaultInstance;

  /// Nome do boulder.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Grau de dificuldade (ex: "V3", "V8").
  @$pb.TagNumber(2)
  GrauBoulder_GrauBoulder get dificuldade => $_getN(1);
  @$pb.TagNumber(2)
  set dificuldade(GrauBoulder_GrauBoulder value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDificuldade() => $_has(1);
  @$pb.TagNumber(2)
  void clearDificuldade() => $_clearField(2);

  /// Tipo de parede predominante (negativo, vertical, positivo).
  @$pb.TagNumber(3)
  TipoParede_TipoParede get tipoParede => $_getN(2);
  @$pb.TagNumber(3)
  set tipoParede(TipoParede_TipoParede value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTipoParede() => $_has(2);
  @$pb.TagNumber(3)
  void clearTipoParede() => $_clearField(3);

  /// Nomes dos conquistadores ou primeira ascensão.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get conquistadores => $_getList(3);

  /// Data de abertura do boulder (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(5)
  $core.String get dataAbertura => $_getSZ(4);
  @$pb.TagNumber(5)
  set dataAbertura($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDataAbertura() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataAbertura() => $_clearField(5);

  /// Dicas de segurança, movimentação chave (beta) e número/posicionamento de crashpads recomendados.
  @$pb.TagNumber(6)
  $core.String get descricao => $_getSZ(5);
  @$pb.TagNumber(6)
  set descricao($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDescricao() => $_has(5);
  @$pb.TagNumber(6)
  void clearDescricao() => $_clearField(6);

  /// URL local do arquivo .mp4 para o vídeo demonstrativo do beta (se baixado via Wi-Fi).
  @$pb.TagNumber(7)
  $core.String get urlVideoBeta => $_getSZ(6);
  @$pb.TagNumber(7)
  set urlVideoBeta($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUrlVideoBeta() => $_has(6);
  @$pb.TagNumber(7)
  void clearUrlVideoBeta() => $_clearField(7);

  /// Chave Pix do mantenedor ou conquistador específico deste boulder.
  @$pb.TagNumber(8)
  $core.String get chavePixManutencao => $_getSZ(7);
  @$pb.TagNumber(8)
  set chavePixManutencao($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChavePixManutencao() => $_has(7);
  @$pb.TagNumber(8)
  void clearChavePixManutencao() => $_clearField(8);

  /// ID no mapa. Provavelmente um número, como 1, ou a, ou 1a, etc.
  @$pb.TagNumber(9)
  $core.String get idNoMapa => $_getSZ(8);
  @$pb.TagNumber(9)
  set idNoMapa($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIdNoMapa() => $_has(8);
  @$pb.TagNumber(9)
  void clearIdNoMapa() => $_clearField(9);
}

/// Representa uma via de escalada de múltiplas enfiadas.
/// NEXT_ID: 24
class ViaMultiplasEnfiadas extends $pb.GeneratedMessage {
  factory ViaMultiplasEnfiadas({
    $core.String? nome,
    GrauVia_GrauVia? dificuldadeMedia,
    GrauVia_GrauVia? dificuldadeMaxima,
    GrauArtificial_GrauArtificial? dificuldadeArtificial,
    GrauVia_GrauVia? dificuldadeArtificialEmLivre,
    GrauExposicao_GrauExposicao? exposicao,
    GrauDuracao_GrauDuracao? duracao,
    $core.int? numeroEnfiadas,
    $core.int? comprimentoTotal,
    $core.int? comprimentoMaiorEnfiada,
    ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas? tipoViaMultiplasEnfiadas,
    $core.String? equipamentoRecomendado,
    $core.Iterable<Escalada>? enfiadas,
    $core.String? descricao,
    $core.Iterable<$core.String>? conquistadores,
    $core.String? dataAbertura,
    $core.String? dataManutencao,
    $core.String? urlVideoBeta,
    $core.String? chavePixManutencao,
    $core.String? idNoMapa,
    $core.Iterable<Mapa>? mapas,
    $core.int? quantidadeCosturasIntermediarias,
    $core.int? quantidadeEquipamentosParada,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (dificuldadeMedia != null) result.dificuldadeMedia = dificuldadeMedia;
    if (dificuldadeMaxima != null) result.dificuldadeMaxima = dificuldadeMaxima;
    if (dificuldadeArtificial != null)
      result.dificuldadeArtificial = dificuldadeArtificial;
    if (dificuldadeArtificialEmLivre != null)
      result.dificuldadeArtificialEmLivre = dificuldadeArtificialEmLivre;
    if (exposicao != null) result.exposicao = exposicao;
    if (duracao != null) result.duracao = duracao;
    if (numeroEnfiadas != null) result.numeroEnfiadas = numeroEnfiadas;
    if (comprimentoTotal != null) result.comprimentoTotal = comprimentoTotal;
    if (comprimentoMaiorEnfiada != null)
      result.comprimentoMaiorEnfiada = comprimentoMaiorEnfiada;
    if (tipoViaMultiplasEnfiadas != null)
      result.tipoViaMultiplasEnfiadas = tipoViaMultiplasEnfiadas;
    if (equipamentoRecomendado != null)
      result.equipamentoRecomendado = equipamentoRecomendado;
    if (enfiadas != null) result.enfiadas.addAll(enfiadas);
    if (descricao != null) result.descricao = descricao;
    if (conquistadores != null) result.conquistadores.addAll(conquistadores);
    if (dataAbertura != null) result.dataAbertura = dataAbertura;
    if (dataManutencao != null) result.dataManutencao = dataManutencao;
    if (urlVideoBeta != null) result.urlVideoBeta = urlVideoBeta;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (idNoMapa != null) result.idNoMapa = idNoMapa;
    if (mapas != null) result.mapas.addAll(mapas);
    if (quantidadeCosturasIntermediarias != null)
      result.quantidadeCosturasIntermediarias =
          quantidadeCosturasIntermediarias;
    if (quantidadeEquipamentosParada != null)
      result.quantidadeEquipamentosParada = quantidadeEquipamentosParada;
    return result;
  }

  ViaMultiplasEnfiadas._();

  factory ViaMultiplasEnfiadas.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ViaMultiplasEnfiadas.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ViaMultiplasEnfiadas',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aE<GrauVia_GrauVia>(2, _omitFieldNames ? '' : 'dificuldadeMedia',
        enumValues: GrauVia_GrauVia.values)
    ..aE<GrauVia_GrauVia>(3, _omitFieldNames ? '' : 'dificuldadeMaxima',
        enumValues: GrauVia_GrauVia.values)
    ..aE<GrauArtificial_GrauArtificial>(
        4, _omitFieldNames ? '' : 'dificuldadeArtificial',
        enumValues: GrauArtificial_GrauArtificial.values)
    ..aE<GrauVia_GrauVia>(
        5, _omitFieldNames ? '' : 'dificuldadeArtificialEmLivre',
        enumValues: GrauVia_GrauVia.values)
    ..aE<GrauExposicao_GrauExposicao>(6, _omitFieldNames ? '' : 'exposicao',
        enumValues: GrauExposicao_GrauExposicao.values)
    ..aE<GrauDuracao_GrauDuracao>(7, _omitFieldNames ? '' : 'duracao',
        enumValues: GrauDuracao_GrauDuracao.values)
    ..aI(8, _omitFieldNames ? '' : 'numeroEnfiadas')
    ..aI(9, _omitFieldNames ? '' : 'comprimentoTotal')
    ..aI(10, _omitFieldNames ? '' : 'comprimentoMaiorEnfiada')
    ..aE<ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas>(
        11, _omitFieldNames ? '' : 'tipoViaMultiplasEnfiadas',
        enumValues: ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.values)
    ..aOS(12, _omitFieldNames ? '' : 'equipamentoRecomendado')
    ..pPM<Escalada>(13, _omitFieldNames ? '' : 'enfiadas',
        subBuilder: Escalada.create)
    ..aOS(14, _omitFieldNames ? '' : 'descricao')
    ..pPS(15, _omitFieldNames ? '' : 'conquistadores')
    ..aOS(16, _omitFieldNames ? '' : 'dataAbertura')
    ..aOS(17, _omitFieldNames ? '' : 'dataManutencao')
    ..aOS(18, _omitFieldNames ? '' : 'urlVideoBeta')
    ..aOS(19, _omitFieldNames ? '' : 'chavePixManutencao')
    ..aOS(20, _omitFieldNames ? '' : 'idNoMapa')
    ..pPM<Mapa>(21, _omitFieldNames ? '' : 'mapas', subBuilder: Mapa.create)
    ..aI(22, _omitFieldNames ? '' : 'quantidadeCosturasIntermediarias')
    ..aI(23, _omitFieldNames ? '' : 'quantidadeEquipamentosParada')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaMultiplasEnfiadas clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ViaMultiplasEnfiadas copyWith(void Function(ViaMultiplasEnfiadas) updates) =>
      super.copyWith((message) => updates(message as ViaMultiplasEnfiadas))
          as ViaMultiplasEnfiadas;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ViaMultiplasEnfiadas create() => ViaMultiplasEnfiadas._();
  @$core.override
  ViaMultiplasEnfiadas createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ViaMultiplasEnfiadas getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ViaMultiplasEnfiadas>(create);
  static ViaMultiplasEnfiadas? _defaultInstance;

  /// Nome da via.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Grau de dificuldade médio da via (ex: "5sup", "7a").
  @$pb.TagNumber(2)
  GrauVia_GrauVia get dificuldadeMedia => $_getN(1);
  @$pb.TagNumber(2)
  set dificuldadeMedia(GrauVia_GrauVia value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDificuldadeMedia() => $_has(1);
  @$pb.TagNumber(2)
  void clearDificuldadeMedia() => $_clearField(2);

  /// Grau de dificuldade do lance mais difícil da via (ex: "5sup", "7a").
  @$pb.TagNumber(3)
  GrauVia_GrauVia get dificuldadeMaxima => $_getN(2);
  @$pb.TagNumber(3)
  set dificuldadeMaxima(GrauVia_GrauVia value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDificuldadeMaxima() => $_has(2);
  @$pb.TagNumber(3)
  void clearDificuldadeMaxima() => $_clearField(3);

  /// Grau de escalada em artificial, se houver trechos de artificial (ex: "A1", "A2").
  @$pb.TagNumber(4)
  GrauArtificial_GrauArtificial get dificuldadeArtificial => $_getN(3);
  @$pb.TagNumber(4)
  set dificuldadeArtificial(GrauArtificial_GrauArtificial value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDificuldadeArtificial() => $_has(3);
  @$pb.TagNumber(4)
  void clearDificuldadeArtificial() => $_clearField(4);

  /// Grau do lance em artificial se escalado em livre.
  @$pb.TagNumber(5)
  GrauVia_GrauVia get dificuldadeArtificialEmLivre => $_getN(4);
  @$pb.TagNumber(5)
  set dificuldadeArtificialEmLivre(GrauVia_GrauVia value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDificuldadeArtificialEmLivre() => $_has(4);
  @$pb.TagNumber(5)
  void clearDificuldadeArtificialEmLivre() => $_clearField(5);

  /// Grau de exposição da via trad (ex: "E2", "E3"). Determina a qualidade/risco das proteções.
  @$pb.TagNumber(6)
  GrauExposicao_GrauExposicao get exposicao => $_getN(5);
  @$pb.TagNumber(6)
  set exposicao(GrauExposicao_GrauExposicao value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasExposicao() => $_has(5);
  @$pb.TagNumber(6)
  void clearExposicao() => $_clearField(6);

  /// Duração estimada para escalar a via.
  @$pb.TagNumber(7)
  GrauDuracao_GrauDuracao get duracao => $_getN(6);
  @$pb.TagNumber(7)
  set duracao(GrauDuracao_GrauDuracao value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDuracao() => $_has(6);
  @$pb.TagNumber(7)
  void clearDuracao() => $_clearField(7);

  /// Número de enfiadas.
  @$pb.TagNumber(8)
  $core.int get numeroEnfiadas => $_getIZ(7);
  @$pb.TagNumber(8)
  set numeroEnfiadas($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNumeroEnfiadas() => $_has(7);
  @$pb.TagNumber(8)
  void clearNumeroEnfiadas() => $_clearField(8);

  /// Comprimento total da via.
  @$pb.TagNumber(9)
  $core.int get comprimentoTotal => $_getIZ(8);
  @$pb.TagNumber(9)
  set comprimentoTotal($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasComprimentoTotal() => $_has(8);
  @$pb.TagNumber(9)
  void clearComprimentoTotal() => $_clearField(9);

  /// Comprimento da maior enfiada da via.
  @$pb.TagNumber(10)
  $core.int get comprimentoMaiorEnfiada => $_getIZ(9);
  @$pb.TagNumber(10)
  set comprimentoMaiorEnfiada($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasComprimentoMaiorEnfiada() => $_has(9);
  @$pb.TagNumber(10)
  void clearComprimentoMaiorEnfiada() => $_clearField(10);

  @$pb.TagNumber(11)
  ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas get tipoViaMultiplasEnfiadas =>
      $_getN(10);
  @$pb.TagNumber(11)
  set tipoViaMultiplasEnfiadas(
          ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTipoViaMultiplasEnfiadas() => $_has(10);
  @$pb.TagNumber(11)
  void clearTipoViaMultiplasEnfiadas() => $_clearField(11);

  /// Descrição do rack/equipamentos móveis recomendados (ex: "Camalots duplos #0.3-3, 1 jogo stoppers").
  @$pb.TagNumber(12)
  $core.String get equipamentoRecomendado => $_getSZ(11);
  @$pb.TagNumber(12)
  set equipamentoRecomendado($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEquipamentoRecomendado() => $_has(11);
  @$pb.TagNumber(12)
  void clearEquipamentoRecomendado() => $_clearField(12);

  /// Detalhamento de cada enfiada da via, se houver.
  @$pb.TagNumber(13)
  $pb.PbList<Escalada> get enfiadas => $_getList(12);

  /// Relato por escrito do croqui (enfiada por enfiada, orientações, etc).
  @$pb.TagNumber(14)
  $core.String get descricao => $_getSZ(13);
  @$pb.TagNumber(14)
  set descricao($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDescricao() => $_has(13);
  @$pb.TagNumber(14)
  void clearDescricao() => $_clearField(14);

  /// Nome dos conquistadores.
  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get conquistadores => $_getList(14);

  /// Data de abertura da via (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(16)
  $core.String get dataAbertura => $_getSZ(15);
  @$pb.TagNumber(16)
  set dataAbertura($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasDataAbertura() => $_has(15);
  @$pb.TagNumber(16)
  void clearDataAbertura() => $_clearField(16);

  /// Data da última manutenção da via.
  @$pb.TagNumber(17)
  $core.String get dataManutencao => $_getSZ(16);
  @$pb.TagNumber(17)
  set dataManutencao($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDataManutencao() => $_has(16);
  @$pb.TagNumber(17)
  void clearDataManutencao() => $_clearField(17);

  /// URL local do arquivo .mp4 para o vídeo demonstrativo do beta (se baixado via Wi-Fi).
  @$pb.TagNumber(18)
  $core.String get urlVideoBeta => $_getSZ(17);
  @$pb.TagNumber(18)
  set urlVideoBeta($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasUrlVideoBeta() => $_has(17);
  @$pb.TagNumber(18)
  void clearUrlVideoBeta() => $_clearField(18);

  /// Chave Pix do mantenedor ou conquistador específico desta via.
  @$pb.TagNumber(19)
  $core.String get chavePixManutencao => $_getSZ(18);
  @$pb.TagNumber(19)
  set chavePixManutencao($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasChavePixManutencao() => $_has(18);
  @$pb.TagNumber(19)
  void clearChavePixManutencao() => $_clearField(19);

  /// ID da via no mapa. Provavelmente um número, como 1, ou a, ou 1a, etc.
  @$pb.TagNumber(20)
  $core.String get idNoMapa => $_getSZ(19);
  @$pb.TagNumber(20)
  set idNoMapa($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasIdNoMapa() => $_has(19);
  @$pb.TagNumber(20)
  void clearIdNoMapa() => $_clearField(20);

  /// Mapas da via de múltiplas enfiadas, se houver.
  @$pb.TagNumber(21)
  $pb.PbList<Mapa> get mapas => $_getList(20);

  /// Número de costuras a levar para proteções intermediárias por enfiada.
  @$pb.TagNumber(22)
  $core.int get quantidadeCosturasIntermediarias => $_getIZ(21);
  @$pb.TagNumber(22)
  set quantidadeCosturasIntermediarias($core.int value) =>
      $_setSignedInt32(21, value);
  @$pb.TagNumber(22)
  $core.bool hasQuantidadeCosturasIntermediarias() => $_has(21);
  @$pb.TagNumber(22)
  void clearQuantidadeCosturasIntermediarias() => $_clearField(22);

  /// Número de equipamentos a levar para proteções nas paradas da via.
  @$pb.TagNumber(23)
  $core.int get quantidadeEquipamentosParada => $_getIZ(22);
  @$pb.TagNumber(23)
  set quantidadeEquipamentosParada($core.int value) =>
      $_setSignedInt32(22, value);
  @$pb.TagNumber(23)
  $core.bool hasQuantidadeEquipamentosParada() => $_has(22);
  @$pb.TagNumber(23)
  void clearQuantidadeEquipamentosParada() => $_clearField(23);
}

/// Um highline montado na rocha.
class Highline extends $pb.GeneratedMessage {
  factory Highline({
    $core.String? nome,
    $core.int? distancia,
    $core.int? altura,
    $core.int? exposicao,
    $core.Iterable<$core.String>? conquistadores,
    $core.String? dataAbertura,
    $core.String? dataManutencao,
    $core.String? descricaoAcesso,
    $core.String? descricaoAncoragem,
    $core.String? descricao,
    $core.String? urlVideoBeta,
    $core.String? chavePixManutencao,
    $core.String? idNoMapa,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (distancia != null) result.distancia = distancia;
    if (altura != null) result.altura = altura;
    if (exposicao != null) result.exposicao = exposicao;
    if (conquistadores != null) result.conquistadores.addAll(conquistadores);
    if (dataAbertura != null) result.dataAbertura = dataAbertura;
    if (dataManutencao != null) result.dataManutencao = dataManutencao;
    if (descricaoAcesso != null) result.descricaoAcesso = descricaoAcesso;
    if (descricaoAncoragem != null)
      result.descricaoAncoragem = descricaoAncoragem;
    if (descricao != null) result.descricao = descricao;
    if (urlVideoBeta != null) result.urlVideoBeta = urlVideoBeta;
    if (chavePixManutencao != null)
      result.chavePixManutencao = chavePixManutencao;
    if (idNoMapa != null) result.idNoMapa = idNoMapa;
    return result;
  }

  Highline._();

  factory Highline.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Highline.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Highline',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aI(2, _omitFieldNames ? '' : 'distancia')
    ..aI(3, _omitFieldNames ? '' : 'altura')
    ..aI(4, _omitFieldNames ? '' : 'exposicao')
    ..pPS(5, _omitFieldNames ? '' : 'conquistadores')
    ..aOS(6, _omitFieldNames ? '' : 'dataAbertura')
    ..aOS(7, _omitFieldNames ? '' : 'dataManutencao')
    ..aOS(8, _omitFieldNames ? '' : 'descricaoAcesso')
    ..aOS(9, _omitFieldNames ? '' : 'descricaoAncoragem')
    ..aOS(10, _omitFieldNames ? '' : 'descricao')
    ..aOS(11, _omitFieldNames ? '' : 'urlVideoBeta')
    ..aOS(12, _omitFieldNames ? '' : 'chavePixManutencao')
    ..aOS(13, _omitFieldNames ? '' : 'idNoMapa')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Highline clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Highline copyWith(void Function(Highline) updates) =>
      super.copyWith((message) => updates(message as Highline)) as Highline;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Highline create() => Highline._();
  @$core.override
  Highline createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Highline getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Highline>(create);
  static Highline? _defaultInstance;

  /// Nome do highline.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Distância do highline.
  @$pb.TagNumber(2)
  $core.int get distancia => $_getIZ(1);
  @$pb.TagNumber(2)
  set distancia($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDistancia() => $_has(1);
  @$pb.TagNumber(2)
  void clearDistancia() => $_clearField(2);

  /// Altura do highline.
  @$pb.TagNumber(3)
  $core.int get altura => $_getIZ(2);
  @$pb.TagNumber(3)
  set altura($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAltura() => $_has(2);
  @$pb.TagNumber(3)
  void clearAltura() => $_clearField(3);

  /// Exposição do highline.
  @$pb.TagNumber(4)
  $core.int get exposicao => $_getIZ(3);
  @$pb.TagNumber(4)
  set exposicao($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExposicao() => $_has(3);
  @$pb.TagNumber(4)
  void clearExposicao() => $_clearField(4);

  /// Nome dos conquistadores.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get conquistadores => $_getList(4);

  /// Data de abertura do highline (ex: "1997" ou "1997-06" ou "1997-06-30").
  @$pb.TagNumber(6)
  $core.String get dataAbertura => $_getSZ(5);
  @$pb.TagNumber(6)
  set dataAbertura($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDataAbertura() => $_has(5);
  @$pb.TagNumber(6)
  void clearDataAbertura() => $_clearField(6);

  /// Data da última manutenção do highline.
  @$pb.TagNumber(7)
  $core.String get dataManutencao => $_getSZ(6);
  @$pb.TagNumber(7)
  set dataManutencao($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDataManutencao() => $_has(6);
  @$pb.TagNumber(7)
  void clearDataManutencao() => $_clearField(7);

  /// Descrição do acesso do highline.
  @$pb.TagNumber(8)
  $core.String get descricaoAcesso => $_getSZ(7);
  @$pb.TagNumber(8)
  set descricaoAcesso($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDescricaoAcesso() => $_has(7);
  @$pb.TagNumber(8)
  void clearDescricaoAcesso() => $_clearField(8);

  /// Descrição da ancoragem do highline.
  @$pb.TagNumber(9)
  $core.String get descricaoAncoragem => $_getSZ(8);
  @$pb.TagNumber(9)
  set descricaoAncoragem($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDescricaoAncoragem() => $_has(8);
  @$pb.TagNumber(9)
  void clearDescricaoAncoragem() => $_clearField(9);

  /// Outras descrições do highline.
  @$pb.TagNumber(10)
  $core.String get descricao => $_getSZ(9);
  @$pb.TagNumber(10)
  set descricao($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDescricao() => $_has(9);
  @$pb.TagNumber(10)
  void clearDescricao() => $_clearField(10);

  /// URL local do arquivo .mp4 para o vídeo demonstrativo do beta (se baixado via Wi-Fi).
  @$pb.TagNumber(11)
  $core.String get urlVideoBeta => $_getSZ(10);
  @$pb.TagNumber(11)
  set urlVideoBeta($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUrlVideoBeta() => $_has(10);
  @$pb.TagNumber(11)
  void clearUrlVideoBeta() => $_clearField(11);

  /// Chave Pix do mantenedor ou conquistador específico deste highline.
  @$pb.TagNumber(12)
  $core.String get chavePixManutencao => $_getSZ(11);
  @$pb.TagNumber(12)
  set chavePixManutencao($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasChavePixManutencao() => $_has(11);
  @$pb.TagNumber(12)
  void clearChavePixManutencao() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get idNoMapa => $_getSZ(12);
  @$pb.TagNumber(13)
  set idNoMapa($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIdNoMapa() => $_has(12);
  @$pb.TagNumber(13)
  void clearIdNoMapa() => $_clearField(13);
}

/// Dados de um patrocinador que apoia financeiramente a manutenção ou os croquis.
class Patrocinador extends $pb.GeneratedMessage {
  factory Patrocinador({
    $core.String? nome,
    $core.String? mensagem,
    $core.String? urlLogo,
    $core.String? urlLink,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (mensagem != null) result.mensagem = mensagem;
    if (urlLogo != null) result.urlLogo = urlLogo;
    if (urlLink != null) result.urlLink = urlLink;
    return result;
  }

  Patrocinador._();

  factory Patrocinador.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Patrocinador.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Patrocinador',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOS(2, _omitFieldNames ? '' : 'mensagem')
    ..aOS(3, _omitFieldNames ? '' : 'urlLogo')
    ..aOS(4, _omitFieldNames ? '' : 'urlLink')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Patrocinador clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Patrocinador copyWith(void Function(Patrocinador) updates) =>
      super.copyWith((message) => updates(message as Patrocinador))
          as Patrocinador;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Patrocinador create() => Patrocinador._();
  @$core.override
  Patrocinador createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Patrocinador getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Patrocinador>(create);
  static Patrocinador? _defaultInstance;

  /// Nome da empresa ou entidade apoiadora.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Slogan curto ou mensagem de agradecimento.
  @$pb.TagNumber(2)
  $core.String get mensagem => $_getSZ(1);
  @$pb.TagNumber(2)
  set mensagem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMensagem() => $_has(1);
  @$pb.TagNumber(2)
  void clearMensagem() => $_clearField(2);

  /// URL do arquivo de imagem da marca do patrocinador.
  @$pb.TagNumber(3)
  $core.String get urlLogo => $_getSZ(2);
  @$pb.TagNumber(3)
  set urlLogo($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrlLogo() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrlLogo() => $_clearField(3);

  /// Link para o site oficial ou Instagram do patrocinador.
  @$pb.TagNumber(4)
  $core.String get urlLink => $_getSZ(3);
  @$pb.TagNumber(4)
  set urlLink($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUrlLink() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrlLink() => $_clearField(4);
}

/// Dados de uma trilha de aproximação.
class Trilha extends $pb.GeneratedMessage {
  factory Trilha({
    $core.String? nome,
    $core.String? descricao,
    $core.String? tempoAproximacao,
    $core.Iterable<PontoDeInteresse>? pontos,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (tempoAproximacao != null) result.tempoAproximacao = tempoAproximacao;
    if (pontos != null) result.pontos.addAll(pontos);
    return result;
  }

  Trilha._();

  factory Trilha.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Trilha.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Trilha',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOS(2, _omitFieldNames ? '' : 'descricao')
    ..aOS(3, _omitFieldNames ? '' : 'tempoAproximacao')
    ..pPM<PontoDeInteresse>(4, _omitFieldNames ? '' : 'pontos',
        subBuilder: PontoDeInteresse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Trilha clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Trilha copyWith(void Function(Trilha) updates) =>
      super.copyWith((message) => updates(message as Trilha)) as Trilha;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Trilha create() => Trilha._();
  @$core.override
  Trilha createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Trilha getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Trilha>(create);
  static Trilha? _defaultInstance;

  /// Nome dessa trilha.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Descrição dessa trilha.
  @$pb.TagNumber(2)
  $core.String get descricao => $_getSZ(1);
  @$pb.TagNumber(2)
  set descricao($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescricao() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescricao() => $_clearField(2);

  /// Tempo estimado de caminhada da trilha.
  @$pb.TagNumber(3)
  $core.String get tempoAproximacao => $_getSZ(2);
  @$pb.TagNumber(3)
  set tempoAproximacao($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTempoAproximacao() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempoAproximacao() => $_clearField(3);

  /// Cada ponto de interesse da trilha em sequência, do início ao fim.
  @$pb.TagNumber(4)
  $pb.PbList<PontoDeInteresse> get pontos => $_getList(3);
}

/// Ponto de interesse de uma trilha.
class PontoDeInteresse extends $pb.GeneratedMessage {
  factory PontoDeInteresse({
    $core.String? nome,
    $core.String? descricao,
    Coordenada? localizacao,
  }) {
    final result = create();
    if (nome != null) result.nome = nome;
    if (descricao != null) result.descricao = descricao;
    if (localizacao != null) result.localizacao = localizacao;
    return result;
  }

  PontoDeInteresse._();

  factory PontoDeInteresse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PontoDeInteresse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PontoDeInteresse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nome')
    ..aOS(2, _omitFieldNames ? '' : 'descricao')
    ..aOM<Coordenada>(3, _omitFieldNames ? '' : 'localizacao',
        subBuilder: Coordenada.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PontoDeInteresse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PontoDeInteresse copyWith(void Function(PontoDeInteresse) updates) =>
      super.copyWith((message) => updates(message as PontoDeInteresse))
          as PontoDeInteresse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PontoDeInteresse create() => PontoDeInteresse._();
  @$core.override
  PontoDeInteresse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PontoDeInteresse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PontoDeInteresse>(create);
  static PontoDeInteresse? _defaultInstance;

  /// Nome do ponto de interesse.
  @$pb.TagNumber(1)
  $core.String get nome => $_getSZ(0);
  @$pb.TagNumber(1)
  set nome($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNome() => $_has(0);
  @$pb.TagNumber(1)
  void clearNome() => $_clearField(1);

  /// Descrição do ponto de interesse.
  @$pb.TagNumber(2)
  $core.String get descricao => $_getSZ(1);
  @$pb.TagNumber(2)
  set descricao($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescricao() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescricao() => $_clearField(2);

  /// Localização do ponto de interesse.
  @$pb.TagNumber(3)
  Coordenada get localizacao => $_getN(2);
  @$pb.TagNumber(3)
  set localizacao(Coordenada value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalizacao() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalizacao() => $_clearField(3);
  @$pb.TagNumber(3)
  Coordenada ensureLocalizacao() => $_ensure(2);
}

/// Estrutura de geolocalização.
class Coordenada extends $pb.GeneratedMessage {
  factory Coordenada({
    $core.double? latitude,
    $core.double? longitude,
  }) {
    final result = create();
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    return result;
  }

  Coordenada._();

  factory Coordenada.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Coordenada.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Coordenada',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'latitude')
    ..aD(2, _omitFieldNames ? '' : 'longitude')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Coordenada clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Coordenada copyWith(void Function(Coordenada) updates) =>
      super.copyWith((message) => updates(message as Coordenada)) as Coordenada;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Coordenada create() => Coordenada._();
  @$core.override
  Coordenada createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Coordenada getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Coordenada>(create);
  static Coordenada? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get latitude => $_getN(0);
  @$pb.TagNumber(1)
  set latitude($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLatitude() => $_has(0);
  @$pb.TagNumber(1)
  void clearLatitude() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get longitude => $_getN(1);
  @$pb.TagNumber(2)
  set longitude($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongitude() => $_clearField(2);
}

/// Tipo de uma parede.
class TipoParede extends $pb.GeneratedMessage {
  factory TipoParede() => create();

  TipoParede._();

  factory TipoParede.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TipoParede.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TipoParede',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipoParede clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipoParede copyWith(void Function(TipoParede) updates) =>
      super.copyWith((message) => updates(message as TipoParede)) as TipoParede;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TipoParede create() => TipoParede._();
  @$core.override
  TipoParede createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TipoParede getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TipoParede>(create);
  static TipoParede? _defaultInstance;
}

/// Representa grau de dificuldade de vias de escalada em livre, em vários estilos de graduações
/// diferentes.
/// Referência: https://www.thecrag.com/en/article/grades
class GrauVia extends $pb.GeneratedMessage {
  factory GrauVia() => create();

  GrauVia._();

  factory GrauVia.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrauVia.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrauVia',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauVia clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauVia copyWith(void Function(GrauVia) updates) =>
      super.copyWith((message) => updates(message as GrauVia)) as GrauVia;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrauVia create() => GrauVia._();
  @$core.override
  GrauVia createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrauVia getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GrauVia>(create);
  static GrauVia? _defaultInstance;
}

/// Representa grau de dificuldade de boulders, em vários estilos de graduações
/// diferentes.
/// Referência: https://www.thecrag.com/en/article/grades
class GrauBoulder extends $pb.GeneratedMessage {
  factory GrauBoulder() => create();

  GrauBoulder._();

  factory GrauBoulder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrauBoulder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrauBoulder',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauBoulder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauBoulder copyWith(void Function(GrauBoulder) updates) =>
      super.copyWith((message) => updates(message as GrauBoulder))
          as GrauBoulder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrauBoulder create() => GrauBoulder._();
  @$core.override
  GrauBoulder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrauBoulder getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrauBoulder>(create);
  static GrauBoulder? _defaultInstance;
}

/// Representa grau de dificuldade de escalada em artificial.
/// Referência: https://agmontanhismo.org/conheca-sobre-graduacao-de-vias/
class GrauArtificial extends $pb.GeneratedMessage {
  factory GrauArtificial() => create();

  GrauArtificial._();

  factory GrauArtificial.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrauArtificial.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrauArtificial',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauArtificial clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauArtificial copyWith(void Function(GrauArtificial) updates) =>
      super.copyWith((message) => updates(message as GrauArtificial))
          as GrauArtificial;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrauArtificial create() => GrauArtificial._();
  @$core.override
  GrauArtificial createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrauArtificial getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrauArtificial>(create);
  static GrauArtificial? _defaultInstance;
}

/// Representa grau de duração de uma via tradicional.
/// Referência: https://agmontanhismo.org/conheca-sobre-graduacao-de-vias/
class GrauDuracao extends $pb.GeneratedMessage {
  factory GrauDuracao() => create();

  GrauDuracao._();

  factory GrauDuracao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrauDuracao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrauDuracao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauDuracao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauDuracao copyWith(void Function(GrauDuracao) updates) =>
      super.copyWith((message) => updates(message as GrauDuracao))
          as GrauDuracao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrauDuracao create() => GrauDuracao._();
  @$core.override
  GrauDuracao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrauDuracao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrauDuracao>(create);
  static GrauDuracao? _defaultInstance;
}

/// Representa grau de exposição de uma via tradicional.
/// Referência: https://agmontanhismo.org/conheca-sobre-graduacao-de-vias/
class GrauExposicao extends $pb.GeneratedMessage {
  factory GrauExposicao() => create();

  GrauExposicao._();

  factory GrauExposicao.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GrauExposicao.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GrauExposicao',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'acecmg'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauExposicao clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GrauExposicao copyWith(void Function(GrauExposicao) updates) =>
      super.copyWith((message) => updates(message as GrauExposicao))
          as GrauExposicao;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GrauExposicao create() => GrauExposicao._();
  @$core.override
  GrauExposicao createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GrauExposicao getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GrauExposicao>(create);
  static GrauExposicao? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
