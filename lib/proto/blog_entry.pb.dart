// This is a generated file - do not edit.
//
// Generated from blog_entry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class BlogEntry_ContentBlock extends $pb.GeneratedMessage {
  factory BlogEntry_ContentBlock({
    $core.String? title,
    $core.String? linkUrl,
    $core.String? imageUrl,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (linkUrl != null) result.linkUrl = linkUrl;
    if (imageUrl != null) result.imageUrl = imageUrl;
    return result;
  }

  BlogEntry_ContentBlock._();

  factory BlogEntry_ContentBlock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BlogEntry_ContentBlock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BlogEntry.ContentBlock',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'linkUrl')
    ..aOS(3, _omitFieldNames ? '' : 'imageUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlogEntry_ContentBlock clone() =>
      BlogEntry_ContentBlock()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlogEntry_ContentBlock copyWith(
          void Function(BlogEntry_ContentBlock) updates) =>
      super.copyWith((message) => updates(message as BlogEntry_ContentBlock))
          as BlogEntry_ContentBlock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlogEntry_ContentBlock create() => BlogEntry_ContentBlock._();
  @$core.override
  BlogEntry_ContentBlock createEmptyInstance() => create();
  static $pb.PbList<BlogEntry_ContentBlock> createRepeated() =>
      $pb.PbList<BlogEntry_ContentBlock>();
  @$core.pragma('dart2js:noInline')
  static BlogEntry_ContentBlock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BlogEntry_ContentBlock>(create);
  static BlogEntry_ContentBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get linkUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set linkUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLinkUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinkUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get imageUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set imageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasImageUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearImageUrl() => $_clearField(3);
}

class BlogEntry extends $pb.GeneratedMessage {
  factory BlogEntry({
    $core.Iterable<BlogEntry_ContentBlock>? content,
  }) {
    final result = create();
    if (content != null) result.content.addAll(content);
    return result;
  }

  BlogEntry._();

  factory BlogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BlogEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BlogEntry',
      createEmptyInstance: create)
    ..pc<BlogEntry_ContentBlock>(
        1, _omitFieldNames ? '' : 'content', $pb.PbFieldType.PM,
        subBuilder: BlogEntry_ContentBlock.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlogEntry clone() => BlogEntry()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BlogEntry copyWith(void Function(BlogEntry) updates) =>
      super.copyWith((message) => updates(message as BlogEntry)) as BlogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlogEntry create() => BlogEntry._();
  @$core.override
  BlogEntry createEmptyInstance() => create();
  static $pb.PbList<BlogEntry> createRepeated() => $pb.PbList<BlogEntry>();
  @$core.pragma('dart2js:noInline')
  static BlogEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlogEntry>(create);
  static BlogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BlogEntry_ContentBlock> get content => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
