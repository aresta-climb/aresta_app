// This is a generated file - do not edit.
//
// Generated from croqui.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use croquiDescriptor instead')
const Croqui$json = {
  '1': 'Croqui',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'nome', '3': 2, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 3, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'creditos', '3': 4, '4': 3, '5': 9, '10': 'creditos'},
    {
      '1': 'arquivos_markdown',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.acecmg.ArquivoMarkdown',
      '10': 'arquivosMarkdown'
    },
    {'1': 'picos', '3': 6, '4': 3, '5': 11, '6': '.acecmg.Pico', '10': 'picos'},
    {
      '1': 'arquivos_externos',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.acecmg.ArquivoExterno',
      '10': 'arquivosExternos'
    },
    {
      '1': 'caminho_thumbnail',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'caminhoThumbnail'
    },
    {
      '1': 'revisado_manualmente',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'revisadoManualmente'
    },
  ],
};

/// Descriptor for `Croqui`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List croquiDescriptor = $convert.base64Decode(
    'CgZDcm9xdWkSDgoCaWQYASABKAlSAmlkEhIKBG5vbWUYAiABKAlSBG5vbWUSHAoJZGVzY3JpY2'
    'FvGAMgASgJUglkZXNjcmljYW8SGgoIY3JlZGl0b3MYBCADKAlSCGNyZWRpdG9zEkQKEWFycXVp'
    'dm9zX21hcmtkb3duGAUgAygLMhcuYWNlY21nLkFycXVpdm9NYXJrZG93blIQYXJxdWl2b3NNYX'
    'JrZG93bhIiCgVwaWNvcxgGIAMoCzIMLmFjZWNtZy5QaWNvUgVwaWNvcxJDChFhcnF1aXZvc19l'
    'eHRlcm5vcxgHIAMoCzIWLmFjZWNtZy5BcnF1aXZvRXh0ZXJub1IQYXJxdWl2b3NFeHRlcm5vcx'
    'IrChFjYW1pbmhvX3RodW1ibmFpbBgIIAEoCVIQY2FtaW5ob1RodW1ibmFpbBIxChRyZXZpc2Fk'
    'b19tYW51YWxtZW50ZRgJIAEoCFITcmV2aXNhZG9NYW51YWxtZW50ZQ==');

@$core.Deprecated('Use arquivoExternoDescriptor instead')
const ArquivoExterno$json = {
  '1': 'ArquivoExterno',
  '2': [
    {'1': 'caminho', '3': 1, '4': 1, '5': 9, '10': 'caminho'},
    {'1': 'checksum_sha256', '3': 2, '4': 1, '5': 9, '10': 'checksumSha256'},
  ],
};

/// Descriptor for `ArquivoExterno`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoExternoDescriptor = $convert.base64Decode(
    'Cg5BcnF1aXZvRXh0ZXJubxIYCgdjYW1pbmhvGAEgASgJUgdjYW1pbmhvEicKD2NoZWNrc3VtX3'
    'NoYTI1NhgCIAEoCVIOY2hlY2tzdW1TaGEyNTY=');

@$core.Deprecated('Use arquivoMarkdownDescriptor instead')
const ArquivoMarkdown$json = {
  '1': 'ArquivoMarkdown',
  '2': [
    {'1': 'titulo', '3': 1, '4': 1, '5': 9, '10': 'titulo'},
    {'1': 'caminho', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'caminho'},
    {'1': 'conteudo', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'conteudo'},
  ],
  '8': [
    {'1': 'arquivo'},
  ],
};

/// Descriptor for `ArquivoMarkdown`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoMarkdownDescriptor = $convert.base64Decode(
    'Cg9BcnF1aXZvTWFya2Rvd24SFgoGdGl0dWxvGAEgASgJUgZ0aXR1bG8SGgoHY2FtaW5obxgCIA'
    'EoCUgAUgdjYW1pbmhvEhwKCGNvbnRldWRvGAMgASgJSABSCGNvbnRldWRvQgkKB2FycXVpdm8=');

@$core.Deprecated('Use picoDescriptor instead')
const Pico$json = {
  '1': 'Pico',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 2, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'estado', '3': 3, '4': 1, '5': 9, '10': 'estado'},
    {
      '1': 'localizacao',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Coordenada',
      '10': 'localizacao'
    },
    {'1': 'url_google_maps', '3': 5, '4': 1, '5': 9, '10': 'urlGoogleMaps'},
    {'1': 'nome_associacao', '3': 6, '4': 1, '5': 9, '10': 'nomeAssociacao'},
    {
      '1': 'url_filiacao_associacao',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'urlFiliacaoAssociacao'
    },
    {
      '1': 'chave_pix_manutencao',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
    {
      '1': 'patrocinadores',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Patrocinador',
      '10': 'patrocinadores'
    },
    {
      '1': 'setores_ou_grupos',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.acecmg.SetorOuGrupo',
      '10': 'setoresOuGrupos'
    },
  ],
  '9': [
    {'1': 10, '2': 11},
  ],
};

/// Descriptor for `Pico`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List picoDescriptor = $convert.base64Decode(
    'CgRQaWNvEhIKBG5vbWUYASABKAlSBG5vbWUSHAoJZGVzY3JpY2FvGAIgASgJUglkZXNjcmljYW'
    '8SFgoGZXN0YWRvGAMgASgJUgZlc3RhZG8SNAoLbG9jYWxpemFjYW8YBCABKAsyEi5hY2VjbWcu'
    'Q29vcmRlbmFkYVILbG9jYWxpemFjYW8SJgoPdXJsX2dvb2dsZV9tYXBzGAUgASgJUg11cmxHb2'
    '9nbGVNYXBzEicKD25vbWVfYXNzb2NpYWNhbxgGIAEoCVIObm9tZUFzc29jaWFjYW8SNgoXdXJs'
    'X2ZpbGlhY2FvX2Fzc29jaWFjYW8YByABKAlSFXVybEZpbGlhY2FvQXNzb2NpYWNhbxIwChRjaG'
    'F2ZV9waXhfbWFudXRlbmNhbxgIIAEoCVISY2hhdmVQaXhNYW51dGVuY2FvEjwKDnBhdHJvY2lu'
    'YWRvcmVzGAkgAygLMhQuYWNlY21nLlBhdHJvY2luYWRvclIOcGF0cm9jaW5hZG9yZXMSQAoRc2'
    'V0b3Jlc19vdV9ncnVwb3MYCyADKAsyFC5hY2VjbWcuU2V0b3JPdUdydXBvUg9zZXRvcmVzT3VH'
    'cnVwb3NKBAgKEAs=');

@$core.Deprecated('Use setorOuGrupoDescriptor instead')
const SetorOuGrupo$json = {
  '1': 'SetorOuGrupo',
  '2': [
    {
      '1': 'setor',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.acecmg.ArquivoSetor',
      '9': 0,
      '10': 'setor'
    },
    {
      '1': 'grupo',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.acecmg.ArquivoGrupo',
      '9': 0,
      '10': 'grupo'
    },
  ],
  '8': [
    {'1': 'tipo'},
  ],
};

/// Descriptor for `SetorOuGrupo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setorOuGrupoDescriptor = $convert.base64Decode(
    'CgxTZXRvck91R3J1cG8SLAoFc2V0b3IYASABKAsyFC5hY2VjbWcuQXJxdWl2b1NldG9ySABSBX'
    'NldG9yEiwKBWdydXBvGAIgASgLMhQuYWNlY21nLkFycXVpdm9HcnVwb0gAUgVncnVwb0IGCgR0'
    'aXBv');

@$core.Deprecated('Use arquivoSetorDescriptor instead')
const ArquivoSetor$json = {
  '1': 'ArquivoSetor',
  '2': [
    {'1': 'caminho', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'caminho'},
    {
      '1': 'conteudo',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Setor',
      '9': 0,
      '10': 'conteudo'
    },
  ],
  '8': [
    {'1': 'arquivo'},
  ],
};

/// Descriptor for `ArquivoSetor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoSetorDescriptor = $convert.base64Decode(
    'CgxBcnF1aXZvU2V0b3ISGgoHY2FtaW5obxgBIAEoCUgAUgdjYW1pbmhvEisKCGNvbnRldWRvGA'
    'IgASgLMg0uYWNlY21nLlNldG9ySABSCGNvbnRldWRvQgkKB2FycXVpdm8=');

@$core.Deprecated('Use arquivoGrupoDescriptor instead')
const ArquivoGrupo$json = {
  '1': 'ArquivoGrupo',
  '2': [
    {'1': 'caminho', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'caminho'},
    {
      '1': 'conteudo',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Grupo',
      '9': 0,
      '10': 'conteudo'
    },
  ],
  '8': [
    {'1': 'arquivo'},
  ],
};

/// Descriptor for `ArquivoGrupo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List arquivoGrupoDescriptor = $convert.base64Decode(
    'CgxBcnF1aXZvR3J1cG8SGgoHY2FtaW5obxgBIAEoCUgAUgdjYW1pbmhvEisKCGNvbnRldWRvGA'
    'IgASgLMg0uYWNlY21nLkdydXBvSABSCGNvbnRldWRvQgkKB2FycXVpdm8=');

@$core.Deprecated('Use grupoDescriptor instead')
const Grupo$json = {
  '1': 'Grupo',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 2, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'mapas', '3': 3, '4': 3, '5': 11, '6': '.acecmg.Mapa', '10': 'mapas'},
    {
      '1': 'setores',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.acecmg.ArquivoSetor',
      '10': 'setores'
    },
  ],
};

/// Descriptor for `Grupo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grupoDescriptor = $convert.base64Decode(
    'CgVHcnVwbxISCgRub21lGAEgASgJUgRub21lEhwKCWRlc2NyaWNhbxgCIAEoCVIJZGVzY3JpY2'
    'FvEiIKBW1hcGFzGAMgAygLMgwuYWNlY21nLk1hcGFSBW1hcGFzEi4KB3NldG9yZXMYBCADKAsy'
    'FC5hY2VjbWcuQXJxdWl2b1NldG9yUgdzZXRvcmVz');

@$core.Deprecated('Use setorDescriptor instead')
const Setor$json = {
  '1': 'Setor',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {
      '1': 'localizacao_estacionamento',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Coordenada',
      '10': 'localizacaoEstacionamento'
    },
    {
      '1': 'localizacao_escalada',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Coordenada',
      '10': 'localizacaoEscalada'
    },
    {
      '1': 'trilhas',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Trilha',
      '10': 'trilhas'
    },
    {'1': 'sinal_de_celular', '3': 6, '4': 1, '5': 8, '10': 'sinalDeCelular'},
    {
      '1': 'amigavel_a_criancas',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'amigavelACriancas'
    },
    {'1': 'amigavel_a_bebes', '3': 8, '4': 1, '5': 8, '10': 'amigavelABebes'},
    {'1': 'descricao', '3': 9, '4': 1, '5': 9, '10': 'descricao'},
    {
      '1': 'mapas',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Mapa',
      '10': 'mapas'
    },
    {
      '1': 'escaladas',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Escalada',
      '10': 'escaladas'
    },
  ],
  '9': [
    {'1': 12, '2': 13},
  ],
};

/// Descriptor for `Setor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setorDescriptor = $convert.base64Decode(
    'CgVTZXRvchISCgRub21lGAEgASgJUgRub21lElEKGmxvY2FsaXphY2FvX2VzdGFjaW9uYW1lbn'
    'RvGAIgASgLMhIuYWNlY21nLkNvb3JkZW5hZGFSGWxvY2FsaXphY2FvRXN0YWNpb25hbWVudG8S'
    'RQoUbG9jYWxpemFjYW9fZXNjYWxhZGEYAyABKAsyEi5hY2VjbWcuQ29vcmRlbmFkYVITbG9jYW'
    'xpemFjYW9Fc2NhbGFkYRIoCgd0cmlsaGFzGAQgAygLMg4uYWNlY21nLlRyaWxoYVIHdHJpbGhh'
    'cxIoChBzaW5hbF9kZV9jZWx1bGFyGAYgASgIUg5zaW5hbERlQ2VsdWxhchIuChNhbWlnYXZlbF'
    '9hX2NyaWFuY2FzGAcgASgIUhFhbWlnYXZlbEFDcmlhbmNhcxIoChBhbWlnYXZlbF9hX2JlYmVz'
    'GAggASgIUg5hbWlnYXZlbEFCZWJlcxIcCglkZXNjcmljYW8YCSABKAlSCWRlc2NyaWNhbxIiCg'
    'VtYXBhcxgNIAMoCzIMLmFjZWNtZy5NYXBhUgVtYXBhcxIuCgllc2NhbGFkYXMYCyADKAsyEC5h'
    'Y2VjbWcuRXNjYWxhZGFSCWVzY2FsYWRhc0oECAwQDQ==');

@$core.Deprecated('Use mapaDescriptor instead')
const Mapa$json = {
  '1': 'Mapa',
  '2': [
    {
      '1': 'caminho_imagem_mapa',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'caminhoImagemMapa'
    },
    {'1': 'largura_mapa', '3': 2, '4': 1, '5': 5, '10': 'larguraMapa'},
    {'1': 'altura_mapa', '3': 3, '4': 1, '5': 5, '10': 'alturaMapa'},
    {
      '1': 'pontos_de_interesse',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Mapa.PontoDeInteresse',
      '10': 'pontosDeInteresse'
    },
  ],
  '3': [Mapa_PontoDeInteresse$json],
};

@$core.Deprecated('Use mapaDescriptor instead')
const Mapa_PontoDeInteresse$json = {
  '1': 'PontoDeInteresse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'box',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.acecmg.BoundingBox',
      '9': 0,
      '10': 'box'
    },
    {
      '1': 'box_obliqua',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.acecmg.BoundingBoxObliqua',
      '9': 0,
      '10': 'boxObliqua'
    },
  ],
  '8': [
    {'1': 'tipo_box'},
  ],
};

/// Descriptor for `Mapa`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mapaDescriptor = $convert.base64Decode(
    'CgRNYXBhEi4KE2NhbWluaG9faW1hZ2VtX21hcGEYASABKAlSEWNhbWluaG9JbWFnZW1NYXBhEi'
    'EKDGxhcmd1cmFfbWFwYRgCIAEoBVILbGFyZ3VyYU1hcGESHwoLYWx0dXJhX21hcGEYAyABKAVS'
    'CmFsdHVyYU1hcGESTQoTcG9udG9zX2RlX2ludGVyZXNzZRgEIAMoCzIdLmFjZWNtZy5NYXBhLl'
    'BvbnRvRGVJbnRlcmVzc2VSEXBvbnRvc0RlSW50ZXJlc3NlGqwBChBQb250b0RlSW50ZXJlc3Nl'
    'Eg4KAmlkGAEgASgJUgJpZBIUCgVsYWJlbBgCIAEoCVIFbGFiZWwSJwoDYm94GAMgASgLMhMuYW'
    'NlY21nLkJvdW5kaW5nQm94SABSA2JveBI9Cgtib3hfb2JsaXF1YRgFIAEoCzIaLmFjZWNtZy5C'
    'b3VuZGluZ0JveE9ibGlxdWFIAFIKYm94T2JsaXF1YUIKCgh0aXBvX2JveA==');

@$core.Deprecated('Use boundingBoxDescriptor instead')
const BoundingBox$json = {
  '1': 'BoundingBox',
  '2': [
    {'1': 'xmin', '3': 1, '4': 1, '5': 5, '10': 'xmin'},
    {'1': 'ymin', '3': 2, '4': 1, '5': 5, '10': 'ymin'},
    {'1': 'xmax', '3': 3, '4': 1, '5': 5, '10': 'xmax'},
    {'1': 'ymax', '3': 4, '4': 1, '5': 5, '10': 'ymax'},
  ],
};

/// Descriptor for `BoundingBox`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boundingBoxDescriptor = $convert.base64Decode(
    'CgtCb3VuZGluZ0JveBISCgR4bWluGAEgASgFUgR4bWluEhIKBHltaW4YAiABKAVSBHltaW4SEg'
    'oEeG1heBgDIAEoBVIEeG1heBISCgR5bWF4GAQgASgFUgR5bWF4');

@$core.Deprecated('Use boundingBoxObliquaDescriptor instead')
const BoundingBoxObliqua$json = {
  '1': 'BoundingBoxObliqua',
  '2': [
    {'1': 'x1', '3': 1, '4': 1, '5': 5, '10': 'x1'},
    {'1': 'y1', '3': 2, '4': 1, '5': 5, '10': 'y1'},
    {'1': 'x2', '3': 3, '4': 1, '5': 5, '10': 'x2'},
    {'1': 'y2', '3': 4, '4': 1, '5': 5, '10': 'y2'},
    {'1': 'x3', '3': 5, '4': 1, '5': 5, '10': 'x3'},
    {'1': 'y3', '3': 6, '4': 1, '5': 5, '10': 'y3'},
    {'1': 'x4', '3': 7, '4': 1, '5': 5, '10': 'x4'},
    {'1': 'y4', '3': 8, '4': 1, '5': 5, '10': 'y4'},
  ],
};

/// Descriptor for `BoundingBoxObliqua`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boundingBoxObliquaDescriptor = $convert.base64Decode(
    'ChJCb3VuZGluZ0JveE9ibGlxdWESDgoCeDEYASABKAVSAngxEg4KAnkxGAIgASgFUgJ5MRIOCg'
    'J4MhgDIAEoBVICeDISDgoCeTIYBCABKAVSAnkyEg4KAngzGAUgASgFUgJ4MxIOCgJ5MxgGIAEo'
    'BVICeTMSDgoCeDQYByABKAVSAng0Eg4KAnk0GAggASgFUgJ5NA==');

@$core.Deprecated('Use escaladaDescriptor instead')
const Escalada$json = {
  '1': 'Escalada',
  '2': [
    {
      '1': 'via_esportiva',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.acecmg.ViaEsportiva',
      '9': 0,
      '10': 'viaEsportiva'
    },
    {
      '1': 'via_movel',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.acecmg.ViaMovel',
      '9': 0,
      '10': 'viaMovel'
    },
    {
      '1': 'boulder',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Boulder',
      '9': 0,
      '10': 'boulder'
    },
    {
      '1': 'via_multiplas_enfiadas',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.acecmg.ViaMultiplasEnfiadas',
      '9': 0,
      '10': 'viaMultiplasEnfiadas'
    },
    {
      '1': 'highline',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Highline',
      '9': 0,
      '10': 'highline'
    },
  ],
  '8': [
    {'1': 'tipo'},
  ],
};

/// Descriptor for `Escalada`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List escaladaDescriptor = $convert.base64Decode(
    'CghFc2NhbGFkYRI7Cg12aWFfZXNwb3J0aXZhGAEgASgLMhQuYWNlY21nLlZpYUVzcG9ydGl2YU'
    'gAUgx2aWFFc3BvcnRpdmESLwoJdmlhX21vdmVsGAIgASgLMhAuYWNlY21nLlZpYU1vdmVsSABS'
    'CHZpYU1vdmVsEisKB2JvdWxkZXIYAyABKAsyDy5hY2VjbWcuQm91bGRlckgAUgdib3VsZGVyEl'
    'QKFnZpYV9tdWx0aXBsYXNfZW5maWFkYXMYBCABKAsyHC5hY2VjbWcuVmlhTXVsdGlwbGFzRW5m'
    'aWFkYXNIAFIUdmlhTXVsdGlwbGFzRW5maWFkYXMSLgoIaGlnaGxpbmUYBSABKAsyEC5hY2VjbW'
    'cuSGlnaGxpbmVIAFIIaGlnaGxpbmVCBgoEdGlwbw==');

@$core.Deprecated('Use viaEsportivaDescriptor instead')
const ViaEsportiva$json = {
  '1': 'ViaEsportiva',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'id_no_mapa', '3': 16, '4': 1, '5': 9, '10': 'idNoMapa'},
    {
      '1': 'dificuldade',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldade'
    },
    {
      '1': 'dificuldade_artificial',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauArtificial.GrauArtificial',
      '10': 'dificuldadeArtificial'
    },
    {
      '1': 'exposicao',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauExposicao.GrauExposicao',
      '10': 'exposicao'
    },
    {
      '1': 'tipo_parede',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.acecmg.TipoParede.TipoParede',
      '10': 'tipoParede'
    },
    {'1': 'extensao', '3': 6, '4': 1, '5': 5, '10': 'extensao'},
    {
      '1': 'quantidade_protecoes_intermediarias',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'quantidadeProtecoesIntermediarias'
    },
    {
      '1': 'quantidade_protecoes_parada',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'quantidadeProtecoesParada'
    },
    {'1': 'tipo_ancoragem', '3': 9, '4': 1, '5': 9, '10': 'tipoAncoragem'},
    {'1': 'conquistadores', '3': 10, '4': 3, '5': 9, '10': 'conquistadores'},
    {'1': 'data_abertura', '3': 11, '4': 1, '5': 9, '10': 'dataAbertura'},
    {'1': 'data_manutencao', '3': 12, '4': 1, '5': 9, '10': 'dataManutencao'},
    {'1': 'descricao', '3': 13, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'url_video_beta', '3': 14, '4': 1, '5': 9, '10': 'urlVideoBeta'},
    {
      '1': 'chave_pix_manutencao',
      '3': 15,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
  ],
};

/// Descriptor for `ViaEsportiva`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viaEsportivaDescriptor = $convert.base64Decode(
    'CgxWaWFFc3BvcnRpdmESEgoEbm9tZRgBIAEoCVIEbm9tZRIcCgppZF9ub19tYXBhGBAgASgJUg'
    'hpZE5vTWFwYRI5CgtkaWZpY3VsZGFkZRgCIAEoDjIXLmFjZWNtZy5HcmF1VmlhLkdyYXVWaWFS'
    'C2RpZmljdWxkYWRlElwKFmRpZmljdWxkYWRlX2FydGlmaWNpYWwYAyABKA4yJS5hY2VjbWcuR3'
    'JhdUFydGlmaWNpYWwuR3JhdUFydGlmaWNpYWxSFWRpZmljdWxkYWRlQXJ0aWZpY2lhbBJBCgll'
    'eHBvc2ljYW8YBCABKA4yIy5hY2VjbWcuR3JhdUV4cG9zaWNhby5HcmF1RXhwb3NpY2FvUglleH'
    'Bvc2ljYW8SPgoLdGlwb19wYXJlZGUYBSABKA4yHS5hY2VjbWcuVGlwb1BhcmVkZS5UaXBvUGFy'
    'ZWRlUgp0aXBvUGFyZWRlEhoKCGV4dGVuc2FvGAYgASgFUghleHRlbnNhbxJOCiNxdWFudGlkYW'
    'RlX3Byb3RlY29lc19pbnRlcm1lZGlhcmlhcxgHIAEoBVIhcXVhbnRpZGFkZVByb3RlY29lc0lu'
    'dGVybWVkaWFyaWFzEj4KG3F1YW50aWRhZGVfcHJvdGVjb2VzX3BhcmFkYRgIIAEoBVIZcXVhbn'
    'RpZGFkZVByb3RlY29lc1BhcmFkYRIlCg50aXBvX2FuY29yYWdlbRgJIAEoCVINdGlwb0FuY29y'
    'YWdlbRImCg5jb25xdWlzdGFkb3JlcxgKIAMoCVIOY29ucXVpc3RhZG9yZXMSIwoNZGF0YV9hYm'
    'VydHVyYRgLIAEoCVIMZGF0YUFiZXJ0dXJhEicKD2RhdGFfbWFudXRlbmNhbxgMIAEoCVIOZGF0'
    'YU1hbnV0ZW5jYW8SHAoJZGVzY3JpY2FvGA0gASgJUglkZXNjcmljYW8SJAoOdXJsX3ZpZGVvX2'
    'JldGEYDiABKAlSDHVybFZpZGVvQmV0YRIwChRjaGF2ZV9waXhfbWFudXRlbmNhbxgPIAEoCVIS'
    'Y2hhdmVQaXhNYW51dGVuY2Fv');

@$core.Deprecated('Use viaMovelDescriptor instead')
const ViaMovel$json = {
  '1': 'ViaMovel',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'id_no_mapa', '3': 16, '4': 1, '5': 9, '10': 'idNoMapa'},
    {
      '1': 'dificuldade',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldade'
    },
    {
      '1': 'dificuldade_artificial',
      '3': 17,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauArtificial.GrauArtificial',
      '10': 'dificuldadeArtificial'
    },
    {
      '1': 'dificuldade_artificial_em_livre',
      '3': 18,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldadeArtificialEmLivre'
    },
    {
      '1': 'exposicao',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauExposicao.GrauExposicao',
      '10': 'exposicao'
    },
    {
      '1': 'tipo_parede',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.acecmg.TipoParede.TipoParede',
      '10': 'tipoParede'
    },
    {'1': 'extensao', '3': 5, '4': 1, '5': 5, '10': 'extensao'},
    {
      '1': 'quantidade_protecoes_intermediarias',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'quantidadeProtecoesIntermediarias'
    },
    {
      '1': 'quantidade_protecoes_parada',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'quantidadeProtecoesParada'
    },
    {'1': 'protecoes_moveis', '3': 8, '4': 1, '5': 9, '10': 'protecoesMoveis'},
    {'1': 'tipo_ancoragem', '3': 9, '4': 1, '5': 9, '10': 'tipoAncoragem'},
    {'1': 'conquistadores', '3': 10, '4': 3, '5': 9, '10': 'conquistadores'},
    {'1': 'data_abertura', '3': 11, '4': 1, '5': 9, '10': 'dataAbertura'},
    {'1': 'data_manutencao', '3': 12, '4': 1, '5': 9, '10': 'dataManutencao'},
    {'1': 'descricao', '3': 13, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'url_video_beta', '3': 14, '4': 1, '5': 9, '10': 'urlVideoBeta'},
    {
      '1': 'chave_pix_manutencao',
      '3': 15,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
  ],
};

/// Descriptor for `ViaMovel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viaMovelDescriptor = $convert.base64Decode(
    'CghWaWFNb3ZlbBISCgRub21lGAEgASgJUgRub21lEhwKCmlkX25vX21hcGEYECABKAlSCGlkTm'
    '9NYXBhEjkKC2RpZmljdWxkYWRlGAIgASgOMhcuYWNlY21nLkdyYXVWaWEuR3JhdVZpYVILZGlm'
    'aWN1bGRhZGUSXAoWZGlmaWN1bGRhZGVfYXJ0aWZpY2lhbBgRIAEoDjIlLmFjZWNtZy5HcmF1QX'
    'J0aWZpY2lhbC5HcmF1QXJ0aWZpY2lhbFIVZGlmaWN1bGRhZGVBcnRpZmljaWFsEl4KH2RpZmlj'
    'dWxkYWRlX2FydGlmaWNpYWxfZW1fbGl2cmUYEiABKA4yFy5hY2VjbWcuR3JhdVZpYS5HcmF1Vm'
    'lhUhxkaWZpY3VsZGFkZUFydGlmaWNpYWxFbUxpdnJlEkEKCWV4cG9zaWNhbxgDIAEoDjIjLmFj'
    'ZWNtZy5HcmF1RXhwb3NpY2FvLkdyYXVFeHBvc2ljYW9SCWV4cG9zaWNhbxI+Cgt0aXBvX3Bhcm'
    'VkZRgEIAEoDjIdLmFjZWNtZy5UaXBvUGFyZWRlLlRpcG9QYXJlZGVSCnRpcG9QYXJlZGUSGgoI'
    'ZXh0ZW5zYW8YBSABKAVSCGV4dGVuc2FvEk4KI3F1YW50aWRhZGVfcHJvdGVjb2VzX2ludGVybW'
    'VkaWFyaWFzGAYgASgFUiFxdWFudGlkYWRlUHJvdGVjb2VzSW50ZXJtZWRpYXJpYXMSPgobcXVh'
    'bnRpZGFkZV9wcm90ZWNvZXNfcGFyYWRhGAcgASgFUhlxdWFudGlkYWRlUHJvdGVjb2VzUGFyYW'
    'RhEikKEHByb3RlY29lc19tb3ZlaXMYCCABKAlSD3Byb3RlY29lc01vdmVpcxIlCg50aXBvX2Fu'
    'Y29yYWdlbRgJIAEoCVINdGlwb0FuY29yYWdlbRImCg5jb25xdWlzdGFkb3JlcxgKIAMoCVIOY2'
    '9ucXVpc3RhZG9yZXMSIwoNZGF0YV9hYmVydHVyYRgLIAEoCVIMZGF0YUFiZXJ0dXJhEicKD2Rh'
    'dGFfbWFudXRlbmNhbxgMIAEoCVIOZGF0YU1hbnV0ZW5jYW8SHAoJZGVzY3JpY2FvGA0gASgJUg'
    'lkZXNjcmljYW8SJAoOdXJsX3ZpZGVvX2JldGEYDiABKAlSDHVybFZpZGVvQmV0YRIwChRjaGF2'
    'ZV9waXhfbWFudXRlbmNhbxgPIAEoCVISY2hhdmVQaXhNYW51dGVuY2Fv');

@$core.Deprecated('Use boulderDescriptor instead')
const Boulder$json = {
  '1': 'Boulder',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'id_no_mapa', '3': 9, '4': 1, '5': 9, '10': 'idNoMapa'},
    {
      '1': 'dificuldade',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauBoulder.GrauBoulder',
      '10': 'dificuldade'
    },
    {
      '1': 'tipo_parede',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.acecmg.TipoParede.TipoParede',
      '10': 'tipoParede'
    },
    {'1': 'conquistadores', '3': 4, '4': 3, '5': 9, '10': 'conquistadores'},
    {'1': 'data_abertura', '3': 5, '4': 1, '5': 9, '10': 'dataAbertura'},
    {'1': 'descricao', '3': 6, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'url_video_beta', '3': 7, '4': 1, '5': 9, '10': 'urlVideoBeta'},
    {
      '1': 'chave_pix_manutencao',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
  ],
};

/// Descriptor for `Boulder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boulderDescriptor = $convert.base64Decode(
    'CgdCb3VsZGVyEhIKBG5vbWUYASABKAlSBG5vbWUSHAoKaWRfbm9fbWFwYRgJIAEoCVIIaWROb0'
    '1hcGESQQoLZGlmaWN1bGRhZGUYAiABKA4yHy5hY2VjbWcuR3JhdUJvdWxkZXIuR3JhdUJvdWxk'
    'ZXJSC2RpZmljdWxkYWRlEj4KC3RpcG9fcGFyZWRlGAMgASgOMh0uYWNlY21nLlRpcG9QYXJlZG'
    'UuVGlwb1BhcmVkZVIKdGlwb1BhcmVkZRImCg5jb25xdWlzdGFkb3JlcxgEIAMoCVIOY29ucXVp'
    'c3RhZG9yZXMSIwoNZGF0YV9hYmVydHVyYRgFIAEoCVIMZGF0YUFiZXJ0dXJhEhwKCWRlc2NyaW'
    'NhbxgGIAEoCVIJZGVzY3JpY2FvEiQKDnVybF92aWRlb19iZXRhGAcgASgJUgx1cmxWaWRlb0Jl'
    'dGESMAoUY2hhdmVfcGl4X21hbnV0ZW5jYW8YCCABKAlSEmNoYXZlUGl4TWFudXRlbmNhbw==');

@$core.Deprecated('Use viaMultiplasEnfiadasDescriptor instead')
const ViaMultiplasEnfiadas$json = {
  '1': 'ViaMultiplasEnfiadas',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'id_no_mapa', '3': 20, '4': 1, '5': 9, '10': 'idNoMapa'},
    {
      '1': 'mapas',
      '3': 21,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Mapa',
      '10': 'mapas'
    },
    {
      '1': 'dificuldade_media',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldadeMedia'
    },
    {
      '1': 'dificuldade_maxima',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldadeMaxima'
    },
    {
      '1': 'dificuldade_artificial',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauArtificial.GrauArtificial',
      '10': 'dificuldadeArtificial'
    },
    {
      '1': 'dificuldade_artificial_em_livre',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauVia.GrauVia',
      '10': 'dificuldadeArtificialEmLivre'
    },
    {
      '1': 'exposicao',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauExposicao.GrauExposicao',
      '10': 'exposicao'
    },
    {
      '1': 'duracao',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.acecmg.GrauDuracao.GrauDuracao',
      '10': 'duracao'
    },
    {'1': 'numero_enfiadas', '3': 8, '4': 1, '5': 5, '10': 'numeroEnfiadas'},
    {
      '1': 'comprimento_total',
      '3': 9,
      '4': 1,
      '5': 5,
      '10': 'comprimentoTotal'
    },
    {
      '1': 'comprimento_maior_enfiada',
      '3': 10,
      '4': 1,
      '5': 5,
      '10': 'comprimentoMaiorEnfiada'
    },
    {
      '1': 'quantidade_costuras_intermediarias',
      '3': 22,
      '4': 1,
      '5': 5,
      '10': 'quantidadeCosturasIntermediarias'
    },
    {
      '1': 'quantidade_equipamentos_parada',
      '3': 23,
      '4': 1,
      '5': 5,
      '10': 'quantidadeEquipamentosParada'
    },
    {
      '1': 'tipo_via_multiplas_enfiadas',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.acecmg.ViaMultiplasEnfiadas.TipoViaMultiplasEnfiadas',
      '10': 'tipoViaMultiplasEnfiadas'
    },
    {
      '1': 'equipamento_recomendado',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'equipamentoRecomendado'
    },
    {
      '1': 'enfiadas',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.acecmg.Escalada',
      '10': 'enfiadas'
    },
    {'1': 'descricao', '3': 14, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'conquistadores', '3': 15, '4': 3, '5': 9, '10': 'conquistadores'},
    {'1': 'data_abertura', '3': 16, '4': 1, '5': 9, '10': 'dataAbertura'},
    {'1': 'data_manutencao', '3': 17, '4': 1, '5': 9, '10': 'dataManutencao'},
    {'1': 'url_video_beta', '3': 18, '4': 1, '5': 9, '10': 'urlVideoBeta'},
    {
      '1': 'chave_pix_manutencao',
      '3': 19,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
  ],
  '4': [ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas$json],
};

@$core.Deprecated('Use viaMultiplasEnfiadasDescriptor instead')
const ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas$json = {
  '1': 'TipoViaMultiplasEnfiadas',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'TODA_FIXA', '2': 1},
    {'1': 'MISTA', '2': 2},
    {'1': 'TODA_MOVEL', '2': 3},
  ],
};

/// Descriptor for `ViaMultiplasEnfiadas`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List viaMultiplasEnfiadasDescriptor = $convert.base64Decode(
    'ChRWaWFNdWx0aXBsYXNFbmZpYWRhcxISCgRub21lGAEgASgJUgRub21lEhwKCmlkX25vX21hcG'
    'EYFCABKAlSCGlkTm9NYXBhEiIKBW1hcGFzGBUgAygLMgwuYWNlY21nLk1hcGFSBW1hcGFzEkQK'
    'EWRpZmljdWxkYWRlX21lZGlhGAIgASgOMhcuYWNlY21nLkdyYXVWaWEuR3JhdVZpYVIQZGlmaW'
    'N1bGRhZGVNZWRpYRJGChJkaWZpY3VsZGFkZV9tYXhpbWEYAyABKA4yFy5hY2VjbWcuR3JhdVZp'
    'YS5HcmF1VmlhUhFkaWZpY3VsZGFkZU1heGltYRJcChZkaWZpY3VsZGFkZV9hcnRpZmljaWFsGA'
    'QgASgOMiUuYWNlY21nLkdyYXVBcnRpZmljaWFsLkdyYXVBcnRpZmljaWFsUhVkaWZpY3VsZGFk'
    'ZUFydGlmaWNpYWwSXgofZGlmaWN1bGRhZGVfYXJ0aWZpY2lhbF9lbV9saXZyZRgFIAEoDjIXLm'
    'FjZWNtZy5HcmF1VmlhLkdyYXVWaWFSHGRpZmljdWxkYWRlQXJ0aWZpY2lhbEVtTGl2cmUSQQoJ'
    'ZXhwb3NpY2FvGAYgASgOMiMuYWNlY21nLkdyYXVFeHBvc2ljYW8uR3JhdUV4cG9zaWNhb1IJZX'
    'hwb3NpY2FvEjkKB2R1cmFjYW8YByABKA4yHy5hY2VjbWcuR3JhdUR1cmFjYW8uR3JhdUR1cmFj'
    'YW9SB2R1cmFjYW8SJwoPbnVtZXJvX2VuZmlhZGFzGAggASgFUg5udW1lcm9FbmZpYWRhcxIrCh'
    'Fjb21wcmltZW50b190b3RhbBgJIAEoBVIQY29tcHJpbWVudG9Ub3RhbBI6Chljb21wcmltZW50'
    'b19tYWlvcl9lbmZpYWRhGAogASgFUhdjb21wcmltZW50b01haW9yRW5maWFkYRJMCiJxdWFudG'
    'lkYWRlX2Nvc3R1cmFzX2ludGVybWVkaWFyaWFzGBYgASgFUiBxdWFudGlkYWRlQ29zdHVyYXNJ'
    'bnRlcm1lZGlhcmlhcxJECh5xdWFudGlkYWRlX2VxdWlwYW1lbnRvc19wYXJhZGEYFyABKAVSHH'
    'F1YW50aWRhZGVFcXVpcGFtZW50b3NQYXJhZGESdAobdGlwb192aWFfbXVsdGlwbGFzX2VuZmlh'
    'ZGFzGAsgASgOMjUuYWNlY21nLlZpYU11bHRpcGxhc0VuZmlhZGFzLlRpcG9WaWFNdWx0aXBsYX'
    'NFbmZpYWRhc1IYdGlwb1ZpYU11bHRpcGxhc0VuZmlhZGFzEjcKF2VxdWlwYW1lbnRvX3JlY29t'
    'ZW5kYWRvGAwgASgJUhZlcXVpcGFtZW50b1JlY29tZW5kYWRvEiwKCGVuZmlhZGFzGA0gAygLMh'
    'AuYWNlY21nLkVzY2FsYWRhUghlbmZpYWRhcxIcCglkZXNjcmljYW8YDiABKAlSCWRlc2NyaWNh'
    'bxImCg5jb25xdWlzdGFkb3JlcxgPIAMoCVIOY29ucXVpc3RhZG9yZXMSIwoNZGF0YV9hYmVydH'
    'VyYRgQIAEoCVIMZGF0YUFiZXJ0dXJhEicKD2RhdGFfbWFudXRlbmNhbxgRIAEoCVIOZGF0YU1h'
    'bnV0ZW5jYW8SJAoOdXJsX3ZpZGVvX2JldGEYEiABKAlSDHVybFZpZGVvQmV0YRIwChRjaGF2ZV'
    '9waXhfbWFudXRlbmNhbxgTIAEoCVISY2hhdmVQaXhNYW51dGVuY2FvIlQKGFRpcG9WaWFNdWx0'
    'aXBsYXNFbmZpYWRhcxIOCgpJTkRFRklOSURPEAASDQoJVE9EQV9GSVhBEAESCQoFTUlTVEEQAh'
    'IOCgpUT0RBX01PVkVMEAM=');

@$core.Deprecated('Use highlineDescriptor instead')
const Highline$json = {
  '1': 'Highline',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'id_no_mapa', '3': 13, '4': 1, '5': 9, '10': 'idNoMapa'},
    {'1': 'distancia', '3': 2, '4': 1, '5': 5, '10': 'distancia'},
    {'1': 'altura', '3': 3, '4': 1, '5': 5, '10': 'altura'},
    {'1': 'exposicao', '3': 4, '4': 1, '5': 5, '10': 'exposicao'},
    {'1': 'conquistadores', '3': 5, '4': 3, '5': 9, '10': 'conquistadores'},
    {'1': 'data_abertura', '3': 6, '4': 1, '5': 9, '10': 'dataAbertura'},
    {'1': 'data_manutencao', '3': 7, '4': 1, '5': 9, '10': 'dataManutencao'},
    {'1': 'descricao_acesso', '3': 8, '4': 1, '5': 9, '10': 'descricaoAcesso'},
    {
      '1': 'descricao_ancoragem',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'descricaoAncoragem'
    },
    {'1': 'descricao', '3': 10, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'url_video_beta', '3': 11, '4': 1, '5': 9, '10': 'urlVideoBeta'},
    {
      '1': 'chave_pix_manutencao',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'chavePixManutencao'
    },
  ],
};

/// Descriptor for `Highline`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List highlineDescriptor = $convert.base64Decode(
    'CghIaWdobGluZRISCgRub21lGAEgASgJUgRub21lEhwKCmlkX25vX21hcGEYDSABKAlSCGlkTm'
    '9NYXBhEhwKCWRpc3RhbmNpYRgCIAEoBVIJZGlzdGFuY2lhEhYKBmFsdHVyYRgDIAEoBVIGYWx0'
    'dXJhEhwKCWV4cG9zaWNhbxgEIAEoBVIJZXhwb3NpY2FvEiYKDmNvbnF1aXN0YWRvcmVzGAUgAy'
    'gJUg5jb25xdWlzdGFkb3JlcxIjCg1kYXRhX2FiZXJ0dXJhGAYgASgJUgxkYXRhQWJlcnR1cmES'
    'JwoPZGF0YV9tYW51dGVuY2FvGAcgASgJUg5kYXRhTWFudXRlbmNhbxIpChBkZXNjcmljYW9fYW'
    'Nlc3NvGAggASgJUg9kZXNjcmljYW9BY2Vzc28SLwoTZGVzY3JpY2FvX2FuY29yYWdlbRgJIAEo'
    'CVISZGVzY3JpY2FvQW5jb3JhZ2VtEhwKCWRlc2NyaWNhbxgKIAEoCVIJZGVzY3JpY2FvEiQKDn'
    'VybF92aWRlb19iZXRhGAsgASgJUgx1cmxWaWRlb0JldGESMAoUY2hhdmVfcGl4X21hbnV0ZW5j'
    'YW8YDCABKAlSEmNoYXZlUGl4TWFudXRlbmNhbw==');

@$core.Deprecated('Use patrocinadorDescriptor instead')
const Patrocinador$json = {
  '1': 'Patrocinador',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'mensagem', '3': 2, '4': 1, '5': 9, '10': 'mensagem'},
    {'1': 'url_logo', '3': 3, '4': 1, '5': 9, '10': 'urlLogo'},
    {'1': 'url_link', '3': 4, '4': 1, '5': 9, '10': 'urlLink'},
  ],
};

/// Descriptor for `Patrocinador`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patrocinadorDescriptor = $convert.base64Decode(
    'CgxQYXRyb2NpbmFkb3ISEgoEbm9tZRgBIAEoCVIEbm9tZRIaCghtZW5zYWdlbRgCIAEoCVIIbW'
    'Vuc2FnZW0SGQoIdXJsX2xvZ28YAyABKAlSB3VybExvZ28SGQoIdXJsX2xpbmsYBCABKAlSB3Vy'
    'bExpbms=');

@$core.Deprecated('Use trilhaDescriptor instead')
const Trilha$json = {
  '1': 'Trilha',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 2, '4': 1, '5': 9, '10': 'descricao'},
    {
      '1': 'tempo_aproximacao',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'tempoAproximacao'
    },
    {
      '1': 'pontos',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.acecmg.PontoDeInteresse',
      '10': 'pontos'
    },
  ],
};

/// Descriptor for `Trilha`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trilhaDescriptor = $convert.base64Decode(
    'CgZUcmlsaGESEgoEbm9tZRgBIAEoCVIEbm9tZRIcCglkZXNjcmljYW8YAiABKAlSCWRlc2NyaW'
    'NhbxIrChF0ZW1wb19hcHJveGltYWNhbxgDIAEoCVIQdGVtcG9BcHJveGltYWNhbxIwCgZwb250'
    'b3MYBCADKAsyGC5hY2VjbWcuUG9udG9EZUludGVyZXNzZVIGcG9udG9z');

@$core.Deprecated('Use pontoDeInteresseDescriptor instead')
const PontoDeInteresse$json = {
  '1': 'PontoDeInteresse',
  '2': [
    {'1': 'nome', '3': 1, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 2, '4': 1, '5': 9, '10': 'descricao'},
    {
      '1': 'localizacao',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.acecmg.Coordenada',
      '10': 'localizacao'
    },
  ],
};

/// Descriptor for `PontoDeInteresse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pontoDeInteresseDescriptor = $convert.base64Decode(
    'ChBQb250b0RlSW50ZXJlc3NlEhIKBG5vbWUYASABKAlSBG5vbWUSHAoJZGVzY3JpY2FvGAIgAS'
    'gJUglkZXNjcmljYW8SNAoLbG9jYWxpemFjYW8YAyABKAsyEi5hY2VjbWcuQ29vcmRlbmFkYVIL'
    'bG9jYWxpemFjYW8=');

@$core.Deprecated('Use coordenadaDescriptor instead')
const Coordenada$json = {
  '1': 'Coordenada',
  '2': [
    {'1': 'latitude', '3': 1, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 2, '4': 1, '5': 1, '10': 'longitude'},
  ],
};

/// Descriptor for `Coordenada`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coordenadaDescriptor = $convert.base64Decode(
    'CgpDb29yZGVuYWRhEhoKCGxhdGl0dWRlGAEgASgBUghsYXRpdHVkZRIcCglsb25naXR1ZGUYAi'
    'ABKAFSCWxvbmdpdHVkZQ==');

@$core.Deprecated('Use tipoParedeDescriptor instead')
const TipoParede$json = {
  '1': 'TipoParede',
  '4': [TipoParede_TipoParede$json],
};

@$core.Deprecated('Use tipoParedeDescriptor instead')
const TipoParede_TipoParede$json = {
  '1': 'TipoParede',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'POSITIVO', '2': 1},
    {'1': 'VERTICAL', '2': 2},
    {'1': 'NEGATIVO', '2': 3},
  ],
};

/// Descriptor for `TipoParede`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tipoParedeDescriptor = $convert.base64Decode(
    'CgpUaXBvUGFyZWRlIkYKClRpcG9QYXJlZGUSDgoKSU5ERUZJTklETxAAEgwKCFBPU0lUSVZPEA'
    'ESDAoIVkVSVElDQUwQAhIMCghORUdBVElWTxAD');

@$core.Deprecated('Use grauViaDescriptor instead')
const GrauVia$json = {
  '1': 'GrauVia',
  '4': [GrauVia_GrauVia$json],
};

@$core.Deprecated('Use grauViaDescriptor instead')
const GrauVia_GrauVia$json = {
  '1': 'GrauVia',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'PROJETO', '2': 1},
    {'1': 'BR_1', '2': 2},
    {'1': 'BR_1SUP', '2': 3},
    {'1': 'FR_1', '2': 3},
    {'1': 'US_5_0', '2': 3},
    {'1': 'BR_2', '2': 4},
    {'1': 'FR_2A', '2': 4},
    {'1': 'US_5_2', '2': 4},
    {'1': 'BR_2SUP', '2': 5},
    {'1': 'FR_2C', '2': 5},
    {'1': 'US_5_3', '2': 5},
    {'1': 'BR_3', '2': 6},
    {'1': 'FR_3B', '2': 6},
    {'1': 'US_5_5', '2': 6},
    {'1': 'BR_3SUP', '2': 7},
    {'1': 'FR_4A', '2': 7},
    {'1': 'US_5_6', '2': 7},
    {'1': 'BR_4', '2': 8},
    {'1': 'FR_4B_MAIS', '2': 8},
    {'1': 'US_5_7', '2': 8},
    {'1': 'BR_4SUP', '2': 9},
    {'1': 'FR_5A_MAIS', '2': 9},
    {'1': 'US_5_9', '2': 9},
    {'1': 'BR_5', '2': 10},
    {'1': 'FR_5C', '2': 10},
    {'1': 'US_5_10A', '2': 10},
    {'1': 'BR_5SUP', '2': 11},
    {'1': 'FR_6A_MAIS', '2': 11},
    {'1': 'US_5_10B', '2': 11},
    {'1': 'BR_6', '2': 12},
    {'1': 'FR_6B', '2': 12},
    {'1': 'US_5_10C', '2': 12},
    {'1': 'BR_6SUP', '2': 13},
    {'1': 'FR_6B_MAIS', '2': 13},
    {'1': 'US_5_10D', '2': 13},
    {'1': 'BR_7A', '2': 14},
    {'1': 'FR_6C', '2': 14},
    {'1': 'US_5_11A', '2': 14},
    {'1': 'BR_7B', '2': 17},
    {'1': 'FR_6C_MAIS', '2': 17},
    {'1': 'US_5_11c', '2': 17},
    {'1': 'BR_7C', '2': 18},
    {'1': 'FR_7A', '2': 18},
    {'1': 'US_5_11D', '2': 18},
    {'1': 'BR_8A', '2': 19},
    {'1': 'FR_7A_MAIS', '2': 19},
    {'1': 'US_5_12A', '2': 19},
    {'1': 'BR_8B', '2': 20},
    {'1': 'FR_7B', '2': 20},
    {'1': 'US_5_12B', '2': 20},
    {'1': 'BR_8C', '2': 21},
    {'1': 'FR_7B_MAIS', '2': 21},
    {'1': 'US_5_12C', '2': 21},
    {'1': 'BR_9A', '2': 22},
    {'1': 'FR_7C', '2': 22},
    {'1': 'US_5_12D', '2': 22},
    {'1': 'BR_9B', '2': 23},
    {'1': 'FR_7C_MAIS', '2': 23},
    {'1': 'US_5_13A', '2': 23},
    {'1': 'BR_9C', '2': 24},
    {'1': 'FR_8A', '2': 24},
    {'1': 'US_5_13B', '2': 24},
    {'1': 'BR_10A', '2': 25},
    {'1': 'FR_8A_MAIS', '2': 25},
    {'1': 'US_5_13C', '2': 25},
    {'1': 'BR_10B', '2': 26},
    {'1': 'FR_8B', '2': 26},
    {'1': 'US_5_13D', '2': 26},
    {'1': 'BR_10C', '2': 27},
    {'1': 'FR_8B_MAIS', '2': 27},
    {'1': 'US_5_14A', '2': 27},
    {'1': 'BR_11A', '2': 28},
    {'1': 'FR_8C', '2': 28},
    {'1': 'US_5_14B', '2': 28},
    {'1': 'BR_11B', '2': 29},
    {'1': 'FR_8C_MAIS', '2': 29},
    {'1': 'US_5_14C', '2': 29},
    {'1': 'BR_11C', '2': 30},
    {'1': 'FR_9A', '2': 30},
    {'1': 'US_5_14D', '2': 30},
    {'1': 'BR_12A', '2': 31},
    {'1': 'FR_9A_MAIS', '2': 31},
    {'1': 'US_5_15A', '2': 31},
    {'1': 'BR_12B', '2': 32},
    {'1': 'FR_9B', '2': 32},
    {'1': 'US_5_15B', '2': 32},
    {'1': 'BR_12C', '2': 33},
    {'1': 'FR_9B_MAIS', '2': 33},
    {'1': 'US_5_15C', '2': 33},
    {'1': 'BR_13A', '2': 34},
    {'1': 'FR_9C', '2': 34},
    {'1': 'US_5_15D', '2': 34},
  ],
  '3': {'2': true},
};

/// Descriptor for `GrauVia`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grauViaDescriptor = $convert.base64Decode(
    'CgdHcmF1VmlhIq8JCgdHcmF1VmlhEg4KCklOREVGSU5JRE8QABILCgdQUk9KRVRPEAESCAoEQl'
    'JfMRACEgsKB0JSXzFTVVAQAxIICgRGUl8xEAMSCgoGVVNfNV8wEAMSCAoEQlJfMhAEEgkKBUZS'
    'XzJBEAQSCgoGVVNfNV8yEAQSCwoHQlJfMlNVUBAFEgkKBUZSXzJDEAUSCgoGVVNfNV8zEAUSCA'
    'oEQlJfMxAGEgkKBUZSXzNCEAYSCgoGVVNfNV81EAYSCwoHQlJfM1NVUBAHEgkKBUZSXzRBEAcS'
    'CgoGVVNfNV82EAcSCAoEQlJfNBAIEg4KCkZSXzRCX01BSVMQCBIKCgZVU181XzcQCBILCgdCUl'
    '80U1VQEAkSDgoKRlJfNUFfTUFJUxAJEgoKBlVTXzVfORAJEggKBEJSXzUQChIJCgVGUl81QxAK'
    'EgwKCFVTXzVfMTBBEAoSCwoHQlJfNVNVUBALEg4KCkZSXzZBX01BSVMQCxIMCghVU181XzEwQh'
    'ALEggKBEJSXzYQDBIJCgVGUl82QhAMEgwKCFVTXzVfMTBDEAwSCwoHQlJfNlNVUBANEg4KCkZS'
    'XzZCX01BSVMQDRIMCghVU181XzEwRBANEgkKBUJSXzdBEA4SCQoFRlJfNkMQDhIMCghVU181Xz'
    'ExQRAOEgkKBUJSXzdCEBESDgoKRlJfNkNfTUFJUxAREgwKCFVTXzVfMTFjEBESCQoFQlJfN0MQ'
    'EhIJCgVGUl83QRASEgwKCFVTXzVfMTFEEBISCQoFQlJfOEEQExIOCgpGUl83QV9NQUlTEBMSDA'
    'oIVVNfNV8xMkEQExIJCgVCUl84QhAUEgkKBUZSXzdCEBQSDAoIVVNfNV8xMkIQFBIJCgVCUl84'
    'QxAVEg4KCkZSXzdCX01BSVMQFRIMCghVU181XzEyQxAVEgkKBUJSXzlBEBYSCQoFRlJfN0MQFh'
    'IMCghVU181XzEyRBAWEgkKBUJSXzlCEBcSDgoKRlJfN0NfTUFJUxAXEgwKCFVTXzVfMTNBEBcS'
    'CQoFQlJfOUMQGBIJCgVGUl84QRAYEgwKCFVTXzVfMTNCEBgSCgoGQlJfMTBBEBkSDgoKRlJfOE'
    'FfTUFJUxAZEgwKCFVTXzVfMTNDEBkSCgoGQlJfMTBCEBoSCQoFRlJfOEIQGhIMCghVU181XzEz'
    'RBAaEgoKBkJSXzEwQxAbEg4KCkZSXzhCX01BSVMQGxIMCghVU181XzE0QRAbEgoKBkJSXzExQR'
    'AcEgkKBUZSXzhDEBwSDAoIVVNfNV8xNEIQHBIKCgZCUl8xMUIQHRIOCgpGUl84Q19NQUlTEB0S'
    'DAoIVVNfNV8xNEMQHRIKCgZCUl8xMUMQHhIJCgVGUl85QRAeEgwKCFVTXzVfMTREEB4SCgoGQl'
    'JfMTJBEB8SDgoKRlJfOUFfTUFJUxAfEgwKCFVTXzVfMTVBEB8SCgoGQlJfMTJCECASCQoFRlJf'
    'OUIQIBIMCghVU181XzE1QhAgEgoKBkJSXzEyQxAhEg4KCkZSXzlCX01BSVMQIRIMCghVU181Xz'
    'E1QxAhEgoKBkJSXzEzQRAiEgkKBUZSXzlDECISDAoIVVNfNV8xNUQQIhoCEAE=');

@$core.Deprecated('Use grauBoulderDescriptor instead')
const GrauBoulder$json = {
  '1': 'GrauBoulder',
  '4': [GrauBoulder_GrauBoulder$json],
};

@$core.Deprecated('Use grauBoulderDescriptor instead')
const GrauBoulder_GrauBoulder$json = {
  '1': 'GrauBoulder',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'VB', '2': 1},
    {'1': 'V0', '2': 2},
    {'1': 'V1', '2': 3},
    {'1': 'V2', '2': 4},
    {'1': 'V3', '2': 5},
    {'1': 'V4', '2': 6},
    {'1': 'V5', '2': 7},
    {'1': 'V6', '2': 8},
    {'1': 'V7', '2': 9},
    {'1': 'V8', '2': 10},
    {'1': 'V9', '2': 11},
    {'1': 'V10', '2': 12},
    {'1': 'V11', '2': 13},
    {'1': 'V12', '2': 14},
    {'1': 'V13', '2': 15},
    {'1': 'V14', '2': 16},
    {'1': 'V15', '2': 17},
    {'1': 'V16', '2': 18},
    {'1': 'V17', '2': 19},
  ],
};

/// Descriptor for `GrauBoulder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grauBoulderDescriptor = $convert.base64Decode(
    'CgtHcmF1Qm91bGRlciK9AQoLR3JhdUJvdWxkZXISDgoKSU5ERUZJTklETxAAEgYKAlZCEAESBg'
    'oCVjAQAhIGCgJWMRADEgYKAlYyEAQSBgoCVjMQBRIGCgJWNBAGEgYKAlY1EAcSBgoCVjYQCBIG'
    'CgJWNxAJEgYKAlY4EAoSBgoCVjkQCxIHCgNWMTAQDBIHCgNWMTEQDRIHCgNWMTIQDhIHCgNWMT'
    'MQDxIHCgNWMTQQEBIHCgNWMTUQERIHCgNWMTYQEhIHCgNWMTcQEw==');

@$core.Deprecated('Use grauArtificialDescriptor instead')
const GrauArtificial$json = {
  '1': 'GrauArtificial',
  '4': [GrauArtificial_GrauArtificial$json],
};

@$core.Deprecated('Use grauArtificialDescriptor instead')
const GrauArtificial_GrauArtificial$json = {
  '1': 'GrauArtificial',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'A0', '2': 1},
    {'1': 'A0_MAIS', '2': 2},
    {'1': 'A1', '2': 3},
    {'1': 'A1_MAIS', '2': 4},
    {'1': 'A2', '2': 5},
    {'1': 'A2_MAIS', '2': 6},
    {'1': 'A3', '2': 7},
    {'1': 'A3_MAIS', '2': 8},
    {'1': 'A4', '2': 9},
    {'1': 'A4_MAIS', '2': 10},
    {'1': 'A5', '2': 11},
    {'1': 'A5_MAIS', '2': 12},
  ],
};

/// Descriptor for `GrauArtificial`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grauArtificialDescriptor = $convert.base64Decode(
    'Cg5HcmF1QXJ0aWZpY2lhbCKeAQoOR3JhdUFydGlmaWNpYWwSDgoKSU5ERUZJTklETxAAEgYKAk'
    'EwEAESCwoHQTBfTUFJUxACEgYKAkExEAMSCwoHQTFfTUFJUxAEEgYKAkEyEAUSCwoHQTJfTUFJ'
    'UxAGEgYKAkEzEAcSCwoHQTNfTUFJUxAIEgYKAkE0EAkSCwoHQTRfTUFJUxAKEgYKAkE1EAsSCw'
    'oHQTVfTUFJUxAM');

@$core.Deprecated('Use grauDuracaoDescriptor instead')
const GrauDuracao$json = {
  '1': 'GrauDuracao',
  '4': [GrauDuracao_GrauDuracao$json],
};

@$core.Deprecated('Use grauDuracaoDescriptor instead')
const GrauDuracao_GrauDuracao$json = {
  '1': 'GrauDuracao',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'D1', '2': 1},
    {'1': 'D2', '2': 2},
    {'1': 'D3', '2': 3},
    {'1': 'D4', '2': 4},
    {'1': 'D5', '2': 5},
    {'1': 'D6', '2': 6},
    {'1': 'D7', '2': 7},
  ],
};

/// Descriptor for `GrauDuracao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grauDuracaoDescriptor = $convert.base64Decode(
    'CgtHcmF1RHVyYWNhbyJVCgtHcmF1RHVyYWNhbxIOCgpJTkRFRklOSURPEAASBgoCRDEQARIGCg'
    'JEMhACEgYKAkQzEAMSBgoCRDQQBBIGCgJENRAFEgYKAkQ2EAYSBgoCRDcQBw==');

@$core.Deprecated('Use grauExposicaoDescriptor instead')
const GrauExposicao$json = {
  '1': 'GrauExposicao',
  '4': [GrauExposicao_GrauExposicao$json],
};

@$core.Deprecated('Use grauExposicaoDescriptor instead')
const GrauExposicao_GrauExposicao$json = {
  '1': 'GrauExposicao',
  '2': [
    {'1': 'INDEFINIDO', '2': 0},
    {'1': 'E1', '2': 1},
    {'1': 'E2', '2': 2},
    {'1': 'E3', '2': 3},
    {'1': 'E4', '2': 4},
    {'1': 'E5', '2': 5},
  ],
};

/// Descriptor for `GrauExposicao`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List grauExposicaoDescriptor = $convert.base64Decode(
    'Cg1HcmF1RXhwb3NpY2FvIkcKDUdyYXVFeHBvc2ljYW8SDgoKSU5ERUZJTklETxAAEgYKAkUxEA'
    'ESBgoCRTIQAhIGCgJFMxADEgYKAkU0EAQSBgoCRTUQBQ==');
