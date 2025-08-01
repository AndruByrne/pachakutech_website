import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';

class BlogEntryCard extends StatelessWidget {
  final BlogEntry? blogEntry;

  const BlogEntryCard({Key? key, required this.blogEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Card(
        margin: const EdgeInsets.all(4.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StaggeredGrid.count(
              crossAxisCount: constraints.maxWidth < 600 ? 2 : 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                ...blogEntry?.content.asMap().entries.map((entry) {
                      final index = entry.key;
                      final block = entry.value;
                      final bool isLead = index == 0;

                      return StaggeredGridTile.count(
                        //the text-only case
                        crossAxisCellCount: 2,
                        mainAxisCellCount: 2,
                        child: Text(
                          block.title,
                          style: TextStyle(
                              fontWeight:
                                  isLead ? FontWeight.bold : FontWeight.normal),
                        ),
                      );
                    }) ??
                    []
              ]),
        ),
      );
    });
  }
}
