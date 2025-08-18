import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'package:pachakutech_website/blog_content_detail_page.dart';
import 'package:pachakutech_website/widgets/blog_entry_card.dart';
import 'proto/blog_entry.pb.dart';
import 'content_repo.dart';

class EvaluationDetailPage extends BlogContentDetailPage {

  EvaluationDetailPage({
    super.key,
    required super.db,
    required super.articleId,
    required super.homePageScrollOffset,
  })  : super(appSection: AppSection.evaluation);

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState
    extends BlogContentDetailPageState<EvaluationDetailPage> {
}
