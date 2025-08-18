import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/blog_content_detail_page.dart';

// No need for ContentRepository here if handled by BaseDetailPage, or keep if used elsewhere
// No need for BlogEntryCard or proto here directly if handled by BlogContentDetailPageState

class EducationDetailPage extends BlogContentDetailPage {
  // The appSection is now defined here and passed to the super constructor
  EducationDetailPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.education); // Pass the specific AppSection

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState
    extends BlogContentDetailPageState<EducationDetailPage> {

}
