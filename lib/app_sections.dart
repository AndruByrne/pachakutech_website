// app_sections.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For db type

// Import your page types - ensure paths are correct
import './education_content.dart'; // Assuming EducationDetailPage is here
import './evaluation_content.dart'; // Assuming EvaluationDetailPage is here
import './elevation_content.dart'; // Assuming ElevationDetailPage is here
// import './base_detail_page.dart'; // BaseDetailPage itself might not be directly constructed by this

// Forward declare BlogRepository if it's used by the detail pages' constructors directly
// and you want to avoid circular dependencies at the import level for this file.
// However, it's cleaner if detail pages create their own repositories or receive them
// if the repository itself needs the AppSection for its construction.
// For now, assuming pages can take `db` and construct their repo.

enum AppSection {
  education(
    id: 'edu',
    title: 'Education',
    imageAsset: 'assets/education.jpg',
    bloggingCollection: 'edu_blog',
    linktreeCollection: 'edu_links',
  ),
  evaluation(
    id: 'eval',
    title: 'Evaluation & Exploration',
    imageAsset: 'assets/exploration.jpg',
    bloggingCollection: 'eval_blog',
    linktreeCollection: 'eval_links',
  ),
  elevation(
    id: 'elev',
    title: 'Elevation',
    imageAsset: 'assets/elevation.jpg',
    bloggingCollection: '',
    linktreeCollection: '',
  );

  const AppSection({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.bloggingCollection,
    required this.linktreeCollection,
  });

  final String id;
  final String title;
  final String imageAsset;
  final String bloggingCollection;
  final String linktreeCollection;

  String get routePath => '/$id'; // e.g. /edu
  String get articleRoutePath => '/$id/:articleId'; // e.g. /edu/:articleId

  static AppSection? fromId(String id) {
    for (AppSection section in values) {
      if (section.id == id) return section;
    }
    print("Warning: AppSection with id '$id' not found.");
    return null;
  }

  /// Builds the appropriate detail page widget for this section.
  Widget buildDetailPage({
    required BuildContext context, // Usually not needed directly for widget construction
    required FirebaseFirestore db,
    String? articleId, // Specific article within the section
    required double homePageScrollOffset,
  }) {
    switch (this) {
      case AppSection.education:
        return EducationDetailPage(
          // No longer needs to pass 'appSection: this' explicitly to EducationDetailPage,
          // as EducationDetailPage inherently IS for AppSection.education.
          // The specific page can still hold an 'appSection' field initialized to its type
          // if convenient for its internal logic (like for the state to access metadata).
          db: db,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      case AppSection.evaluation:
        return EvaluationDetailPage(
          db: db,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      case AppSection.elevation:
        return ElevationDetailPage(
          db: db,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
    // Add other cases as needed
    // Default case could throw an error if an AppSection isn't mapped
    // default:
    //   throw UnimplementedError('Detail page not implemented for $this');
    }
  }
}