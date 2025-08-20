import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:url_strategy/url_strategy.dart';

import 'car_crush_privacy_policy_page.dart';
import 'firebase_options.dart';
import 'home_page.dart';

const transitionDuration = Duration(milliseconds: 900);

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            secondary: Colors.orange.shade400,
            surfaceContainer: Colors.blueGrey.shade50),
        textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16)),
      ),
      routerConfig: goRouterSingleton,
    );
  }
}

var goRouterSingleton = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          print('routing to home'); // <- this is called twice, only on refresh
          return fadeTransitionOf(state, MyHomePage());
        },
      ),
      GoRoute(
          path: '/car_crush_privacy_policy',
          builder: (context, state) => const CarCrushPrivacyPolicyPage()),
      ...AppSection.values.expand<RouteBase>((section) {
        return [
          // Route for the section overview (e.g., /edu)
          GoRoute(
            path: section.routePath,
            pageBuilder: (context, state) {
              final params = state.extra as Map<String, dynamic>?;
              final scrollOffset = params?['scrollOffset'] as double? ?? 800.0;
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
              // It may be that this value is only interpreted by the header layout
              final scrollOffset = params?['scrollOffset'] as double? ?? 800.0;
              Widget pageWidget = section.buildDetailPage(
                articleId: articleId,
                homePageScrollOffset: scrollOffset,
              );
              return fadeTransitionOf(state, pageWidget);
            },
          ),
        ];
      }),
    ],
    errorBuilder: (ctx, state) => Scaffold(
          body: Center(
            child: Text('Page Not found: ${state.error}'),
          ),
        ));

CustomTransitionPage<void> fadeTransitionOf(
        GoRouterState state, Widget pageWidget) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: pageWidget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
        child: child,
      ),
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
    );
