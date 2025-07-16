import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'car_crush_privacy_policy_page.dart';
import 'home_page.dart';
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
    pageBuilder: (context, state) {
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget pageWidget = EducationDetailPage(
        articleId: 'top',
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, pageWidget);
    },
  ),
  GoRoute(
    path: '/edu/:article', // Or /edu/:slug
    pageBuilder: (context, state) {
      final id = state.pathParameters['article']!;
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget detailPageWidget = EvaluationDetailPage(
        articleId: id,
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, detailPageWidget);
    },
  ),
  GoRoute(
    path: '/eval',
    pageBuilder: (context, state) {
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget pageWidget = EvaluationDetailPage(
        articleId: 'top',
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, pageWidget);
    },
  ),
  GoRoute(
    path: '/eval/:article',
    pageBuilder: (context, state) {
      final id = state.pathParameters['article']!;
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget detailPageWidget = EvaluationDetailPage(
        articleId: id,
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, detailPageWidget);
    },
  ),
  GoRoute(
    path: '/elev',
    pageBuilder: (context, state) {
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget detailPageWidget = ElevationDetailPage(
        articleId: 'top',
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, detailPageWidget);
    },
  ),
  GoRoute(
    path: '/elev/:article',
    pageBuilder: (context, state) {
      final id = state.pathParameters['article']!;
      final params = state.extra as Map<String, dynamic>?;
      final scrollOffset = params?['scrollOffset'] ?? 0.0;
      Widget detailPageWidget = ElevationDetailPage(
        articleId: id,
        homePageScrollOffset: scrollOffset,
      );
      return fadeTransitionOf(state, detailPageWidget);
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

CustomTransitionPage<void> fadeTransitionOf(
    GoRouterState state, Widget pageWidget) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: pageWidget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Use a FadeTransition or any other transition you prefer
      // The Hero animation will happen on top of/concurrently with this.
      return FadeTransition(
        opacity: animation,
        //animation.drive(CurveTween(curve: Curves.easeInOut)),
        child: child,
      );
    },
    transitionDuration:
        const Duration(milliseconds: 300), // Match Hero duration or adjust
    // reverseTransitionDuration: const Duration(milliseconds: 300), // For pop
  );
}
