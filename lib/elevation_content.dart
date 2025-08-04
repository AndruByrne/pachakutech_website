import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'blog_content_detail_page.dart';
import 'content_repo.dart';
import 'base_detail_page.dart';

class ElevationDetailPage extends BlogContentDetailPage {
  // The appSection is now defined here and passed to the super constructor
  ElevationDetailPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.elevation); // Pass the specific AppSection

  @override
  State<ElevationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState
    extends BlogContentDetailPageState<ElevationDetailPage> {}
