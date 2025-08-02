import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:url_strategy/url_strategy.dart';

import 'car_crush_privacy_policy_page.dart';
import 'firebase_options.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  setPathUrlStrategy();
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final FirebaseFirestore db;

  const MyApp({super.key, required this.db});

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
      routerConfig: goRouterSingleton,
    );
  }
}

var goRouterSingleton = GoRouter(routes: [
  GoRoute(
    path: '/',
    builder: (context, state) {
      print('routing to home'); // <- this is called twice, but only on refresh, not on first load
      return MyHomePage();
    },
  ),
  GoRoute(
      path: '/car_crush_privacy_policy',
      builder: (context, state) => const CarCrushPrivacyPolicyPage()),
  ...AppSection.values.expand<RouteBase>((section) {
    // For each section, we return a list containing its two routes
    return [
      // Route for the section overview (e.g., /edu)
      GoRoute(
        path: section.routePath,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          final scrollOffset = params?['scrollOffset'] as double? ?? 0.0;
          Widget pageWidget = section.buildDetailPage(
            articleId: null, // For overview
            homePageScrollOffset: scrollOffset,
          );
          return fadeTransitionOf(state, pageWidget);
        },
      ),
      // Route for a specific article (e.g., /edu/:articleId)
      GoRoute(
        path: section.articleRoutePath,
        pageBuilder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          final params = state.extra as Map<String, dynamic>?;
          final scrollOffset = params?['scrollOffset'] as double? ?? 0.0;
          Widget pageWidget = section.buildDetailPage(
            articleId: articleId,
            homePageScrollOffset: scrollOffset,
          );
          return fadeTransitionOf(state, pageWidget);
        },
      ),
    ];
  }),
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
