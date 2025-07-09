import 'package:flutter/material.dart';
import 'home_content.dart';

class EducationDetailPage extends StatelessWidget {
  final SummarySectionData summaryData;
  final ValueNotifier<double> mainScrollNotifier;

  const EducationDetailPage(
      {Key? key, required this.summaryData, required this.mainScrollNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Give it some min height to see scrolling behavior if content is short
      constraints:
          BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Education Details: ${summaryData.title}",
              style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 20),
          Text("ID: ${summaryData.id}"),
          SizedBox(height: 20),
          Text("Here is some more detailed content about education... " * 20),
          // To make it scrollable
          SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          // Extra space
          Text("End of education content."),
        ],
      ),
    );
  }
}
