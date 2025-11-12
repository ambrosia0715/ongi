import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../core/result_extension.dart';

/// 설정 페이지
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 계정 정보
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '계정',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  userAsync.when(
                    data: (user) => Text(
                      user?.email ?? '로그인되지 않음',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('오류'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 테마 설정
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('다크 모드'),
                    trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light);
                    },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 알림 설정 (스텁)
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('알림 설정'),
                    subtitle: const Text('일기 작성 알림'),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO(ongi): 알림 설정 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('알림 기능은 준비 중입니다'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 광고 설정
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('광고 표시'),
                    subtitle: const Text('무료 버전에서는 광고가 표시됩니다'),
                    trailing: Switch(
                      value: true, // TODO(ongi): Premium 상태에 따라 변경
                      onChanged: (value) {
                        // TODO(ongi): Premium 전환 시 광고 제거
                        if (!value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Premium 구독 시 광고가 제거됩니다'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 데이터 관리 (스텁)
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('데이터 백업'),
                    subtitle: const Text('일기 데이터를 백업합니다'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(ongi): 데이터 백업 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('백업 기능은 준비 중입니다'),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('데이터 복원'),
                    subtitle: const Text('백업한 데이터를 복원합니다'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(ongi): 데이터 복원 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('복원 기능은 준비 중입니다'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // 로그아웃
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final authRepo = ref.read(authRepositoryProvider);
                  final result = await authRepo.signOut();
                  
                  if (!context.mounted) return;
                  
                  result.when(
                    success: (_) {
                      context.go('/sign-in');
                    },
                    failure: (message, error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('로그아웃'),
              ),
            ),
            const SizedBox(height: 16),
            
            // 앱 정보
            Center(
              child: Text(
                '온기 v1.0.0\n© 2025 Ambro',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

