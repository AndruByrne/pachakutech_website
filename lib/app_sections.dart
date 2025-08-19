import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './education_content.dart';
import './evaluation_content.dart';
import './elevation_content.dart';
import 'about_us_page.dart';
// These are circular, but Dart allows this if the types can be resolved at compile time

enum AppSection {
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
  ),
  education(
    id: 'edu',
    title: 'Education',
    imageAsset: 'assets/education.jpg',
    bloggingCollection: 'edu_blog',
    linktreeCollection: 'edu_links',
  ),
  about_us(
    id: 'abt',
    title: 'Happy Customers',
    imageAsset: '',
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
  bool get hasBlogContent => bloggingCollection.isNotEmpty; // <-- ADD THIS
  bool get hasLinktreeContent =>
      linktreeCollection.isNotEmpty; // <-- ADD THIS (for future use)

  static AppSection? fromId(String id) {
    for (AppSection section in values) {
      if (section.id == id) return section;
    }
    print("Warning: AppSection with id '$id' not found.");
    return null;
  }

  /// Builds the appropriate detail page widget for this section.
  Widget buildDetailPage({
    String? articleId, // Specific article within the section
    required double homePageScrollOffset,
  }) {
    switch (this) {
      case AppSection.education:
        return EducationDetailPage(
          db: FirebaseFirestore.instance,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      case AppSection.evaluation:
        return EvaluationDetailPage(
          db: FirebaseFirestore.instance,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      case AppSection.elevation:
        return ElevationDetailPage(
          db: FirebaseFirestore.instance,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      case AppSection.about_us:
        return AboutUsPage(
          db: FirebaseFirestore.instance,
          articleId: articleId,
          homePageScrollOffset: homePageScrollOffset,
        );
      default:
        throw Exception('Unknown AppSection: $this');
    }
  }
}
