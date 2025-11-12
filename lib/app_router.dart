import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth/ui/sign_in_page.dart';
import 'auth/ui/sign_up_page.dart';
import 'diary/ui/diary_editor_page.dart';
import 'diary/ui/diary_history_page.dart';
import 'diary/ui/diary_detail_page.dart';
import 'dashboard/ui/dashboard_page.dart';
import 'settings/ui/settings_page.dart';
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/sign-in',
    debugLogDiagnostics: true, // 디버그 로그 활성화
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          print('Navigating to /sign-in');
          return const SignInPage();
        },
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/diary/editor',
        builder: (context, state) => const DiaryEditorPage(),
      ),
      GoRoute(
        path: '/diary/history',
        builder: (context, state) => const DiaryHistoryPage(),
      ),
      GoRoute(
        path: '/diary/detail/:date',
        builder: (context, state) {
          final date = state.pathParameters['date'] ?? '';
          return DiaryDetailPage(date: date);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) {
      // 에러 발생 시 표시할 페이지
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류가 발생했습니다: ${state.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('로그인 페이지로'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

