// This is a generated file - do not edit.
//
// Generated from indice.proto.

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

@$core.Deprecated('Use indiceDescriptor instead')
const Indice$json = {
  '1': 'Indice',
  '2': [
    {'1': 'url_base', '3': 1, '4': 1, '5': 9, '10': 'urlBase'},
    {
      '1': 'croquis',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.acecmg.ResumoCroqui',
      '10': 'croquis'
    },
  ],
};

/// Descriptor for `Indice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indiceDescriptor = $convert.base64Decode(
    'CgZJbmRpY2USGQoIdXJsX2Jhc2UYASABKAlSB3VybEJhc2USLgoHY3JvcXVpcxgCIAMoCzIULm'
    'FjZWNtZy5SZXN1bW9Dcm9xdWlSB2Nyb3F1aXM=');

@$core.Deprecated('Use resumoCroquiDescriptor instead')
const ResumoCroqui$json = {
  '1': 'ResumoCroqui',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'nome', '3': 2, '4': 1, '5': 9, '10': 'nome'},
    {'1': 'descricao', '3': 3, '4': 1, '5': 9, '10': 'descricao'},
    {'1': 'nome_arquivo', '3': 4, '4': 1, '5': 9, '10': 'nomeArquivo'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'checksum_sha256', '3': 6, '4': 1, '5': 9, '10': 'checksumSha256'},
    {'1': 'data_update', '3': 7, '4': 1, '5': 9, '10': 'dataUpdate'},
  ],
};

/// Descriptor for `ResumoCroqui`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumoCroquiDescriptor = $convert.base64Decode(
    'CgxSZXN1bW9Dcm9xdWkSDgoCaWQYASABKAlSAmlkEhIKBG5vbWUYAiABKAlSBG5vbWUSHAoJZG'
    'VzY3JpY2FvGAMgASgJUglkZXNjcmljYW8SIQoMbm9tZV9hcnF1aXZvGAQgASgJUgtub21lQXJx'
    'dWl2bxIQCgN1cmwYBSABKAlSA3VybBInCg9jaGVja3N1bV9zaGEyNTYYBiABKAlSDmNoZWNrc3'
    'VtU2hhMjU2Eh8KC2RhdGFfdXBkYXRlGAcgASgJUgpkYXRhVXBkYXRl');
