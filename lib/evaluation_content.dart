import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'package:pachakutech_website/blog_entry_card.dart';
import 'proto/blog_entry.pb.dart';
import 'content_repo.dart';

class EvaluationDetailPage extends BaseDetailPage {
  final AppSection appSection = AppSection.evaluation;
  final ContentRepository contentRepo;

  EvaluationDetailPage({
    super.key,
    required super.db,
    required super.articleId,
    required super.homePageScrollOffset,
  }) : contentRepo = ContentRepository(db: db);

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState
    extends BaseDetailPageState<EvaluationDetailPage> {
  late Future<List<BlogEntry>> _blogEntries;
  late Future<List<Map<String, dynamic>>> _linkTreeEntries;

  @override
  void initState() {
    super.initState();
    _blogEntries = widget.contentRepo.fetchEduBlogEntries();
    _linkTreeEntries = widget.contentRepo.fetchEvalLinkTree();
  }

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: FutureBuilder(
            future: _blogEntries,
            builder: (context, asyncSnapshot) {
              var blogEntries = asyncSnapshot.data;
              print('building ${blogEntries?.length ?? 'NO'} eval entries');
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      BlogEntryCard(blogEntry: blogEntries?[index]),
                  childCount:
                      blogEntries?.length ?? 0, // Your desired child count
                ),
              );
            }),
      ),
    ];
  }

  @override
  String get backgroundImageAsset =>
      widget.appSection.imageAsset; // Accesses the local appSection
  @override
  String get sectionId => widget.appSection.id;

  @override
  String get sectionTitle => widget.appSection.title;
}
