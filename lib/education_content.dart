import 'package:flutter/material.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'home_content.dart';

class EducationDetailPage extends BaseDetailPage {

  const EducationDetailPage({Key? super.key, required super.articleId, required super.homePageScrollOffset});


  @override
  State<StatefulWidget> createState() => _EducationDetailPageState();
}


class _EducationDetailPageState
    extends BaseDetailPageState<EducationDetailPage> {

  @override
  SubSectionMetaData subSectionMetaData = myContentSectionsData[0]; // Fetch or receive this

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Elevation Details: ${subSectionMetaData.title}",
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineMedium),
                    SizedBox(height: 20),
                    Text("ID: ${subSectionMetaData.id}"),
                    SizedBox(height: 20),
                    Text("Content related to elevation and growth... " * 20),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.5),
                    Text("End of elevation content."),
                  ],
                ),
              );
            },
            childCount: 1, // Your desired child count
          ),
        ),
      ),
      // Add more slivers specific to EvaluationDetailPage here if needed
    ];
  }
}
