import 'package:flutter/material.dart';
import 'home_content.dart';

class ElevationDetailPage extends StatelessWidget {
  final SummarySectionData summaryData;
  const ElevationDetailPage({Key? key, required this.summaryData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Elevation Details: ${summaryData.title}", style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 20),
          Text("ID: ${summaryData.id}"),
          SizedBox(height: 20),
          Text("Content related to elevation and growth... " * 20),
          SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          Text("End of elevation content."),
        ],
      ),
    );
  }
}
