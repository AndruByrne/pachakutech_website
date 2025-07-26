import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import 'content_repo.dart';

class EducationDetailPage extends BaseDetailPage {
  final AppSection appSection = AppSection.education;
  final ContentRepository contentRepo;

  EducationDetailPage(
      {super.key,
      required super.db,
      required super.articleId,
      required super.homePageScrollOffset})
      : contentRepo = ContentRepository(db: db);

  @override
  State<StatefulWidget> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState
    extends BaseDetailPageState<EducationDetailPage> {
  late Future<List<BlogEntry>> _blogEntries;
  late Future<List<Map<String, dynamic>>> _linkTreeEntries;

  @override
  initState() {
    super.initState();
    _blogEntries =
        widget.contentRepo.fetchBlogEntries(appSection: widget.appSection);
    _linkTreeEntries = widget.contentRepo.fetchEduLinkTree();
  }

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: FutureBuilder(
            future: _blogEntries,
            builder: (context, asyncSnapshot) {
              var blogEntries =
                  asyncSnapshot.hasData ? asyncSnapshot.data ?? [] : [];
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < blogEntries.length) {
                      final entry = blogEntries[index];
                      return ListTile(
                        title: Text(entry['content']?[0]?['title'] ??
                            'No Title'), // just testing
                      );
                    } else {
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Elevation Details: ${sectionTitle}",
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            SizedBox(height: 20),
                            Text("ID: ${sectionId}"),
                            SizedBox(height: 20),
                            Text("Content related to elevation and growth... " *
                                20),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5),
                            Text("End of elevation content."),
                          ],
                        ),
                      );
                    }
                  },
                  childCount:
                      blogEntries.length + 1, // Your desired child count
                ),
              );
            }),
      ),
      // Add more slivers specific to EvaluationDetailPage here if needed
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
