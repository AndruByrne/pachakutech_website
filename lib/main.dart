import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'car_crush_privacy_policy_page.dart';
import 'home_page.dart';
import 'home_content.dart';
import 'education_content.dart';
import 'evaluation_content.dart';
import 'elevation_content.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pachakutech',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            secondary: Colors.orange.shade400,
            surfaceContainer: Colors.blueGrey.shade50),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(routes: [
  GoRoute(
    path: '/edu', // Or /edu/:slug
    builder: (context, state) {
      return EducationDetailPage(articleId: 'top');
    },
  ),
  GoRoute(
    path: '/edu/:id', // Or /edu/:slug
    builder: (context, state) {
      final id = state.pathParameters['id']!; // Or 'slug'
      return EducationDetailPage(articleId: id);
    },
  ),
  GoRoute(
    path: '/eval',
    builder: (context, state) {
      return EvaluationDetailPage(articleId: 'top');
    },
  ),
  GoRoute(
    path: '/eval/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return EvaluationDetailPage(articleId: id);
    },
  ),
  GoRoute(
    path: '/elev',
    builder: (context, state) {
      return ElevationDetailPage(articleId: 'top');
    },
  ),
  GoRoute(
    path: '/elev/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return ElevationDetailPage(articleId: id);
    },
  ),
  GoRoute(
    path: '/',
    builder: (context, state) => MyHomePage(),
  ),
  GoRoute(
      path: '/car_crush_privacy_policy',
      builder: (context, state) => const CarCrushPrivacyPolicyPage())
]);
