// This is a generated file - do not edit.
//
// Generated from blog_entry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use blogEntryDescriptor instead')
const BlogEntry$json = {
  '1': 'BlogEntry',
  '2': [
    {
      '1': 'content',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.BlogEntry.ContentBlock',
      '10': 'content'
    },
    {'1': 'title', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'title', '17': true},
    {'1': 'tags', '3': 3, '4': 3, '5': 9, '10': 'tags'},
  ],
  '3': [BlogEntry_ContentBlock$json],
  '8': [
    {'1': '_title'},
  ],
};

@$core.Deprecated('Use blogEntryDescriptor instead')
const BlogEntry_ContentBlock$json = {
  '1': 'ContentBlock',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'title', '17': true},
    {
      '1': 'link_url',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'linkUrl',
      '17': true
    },
    {
      '1': 'image_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'imageUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_title'},
    {'1': '_link_url'},
    {'1': '_image_url'},
  ],
};

/// Descriptor for `BlogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blogEntryDescriptor = $convert.base64Decode(
    'CglCbG9nRW50cnkSMQoHY29udGVudBgBIAMoCzIXLkJsb2dFbnRyeS5Db250ZW50QmxvY2tSB2'
    'NvbnRlbnQSGQoFdGl0bGUYAiABKAlIAFIFdGl0bGWIAQESEgoEdGFncxgDIAMoCVIEdGFncxqQ'
    'AQoMQ29udGVudEJsb2NrEhkKBXRpdGxlGAEgASgJSABSBXRpdGxliAEBEh4KCGxpbmtfdXJsGA'
    'IgASgJSAFSB2xpbmtVcmyIAQESIAoJaW1hZ2VfdXJsGAMgASgJSAJSCGltYWdlVXJsiAEBQggK'
    'Bl90aXRsZUILCglfbGlua191cmxCDAoKX2ltYWdlX3VybEIICgZfdGl0bGU=');
