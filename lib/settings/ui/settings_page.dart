import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../core/result_extension.dart';
import '../../backup/data/backup_providers.dart';
import '../../diary/data/diary_providers.dart';

/// 백업 처리
Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
  final backupService = ref.read(backupServiceProvider);
  
  // 로딩 다이얼로그 표시
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final result = await backupService.shareBackup(context);
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
    
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('백업이 완료되었습니다. 파일이 공유되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      },
      failure: (message, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 실패: $message'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('백업 중 오류가 발생했습니다: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// 복원 처리
Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
  // 확인 다이얼로그
  if (!context.mounted) return;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('데이터 복원'),
      content: const Text(
        '백업 파일을 복원하면 기존 데이터가 덮어씌워질 수 있습니다.\n정말 복원하시겠습니까?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('복원'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final backupService = ref.read(backupServiceProvider);
  
  // 로딩 다이얼로그 표시
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final result = await backupService.importBackup();
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
    
    result.when(
      success: (count) {
        // 일기 목록 새로고침
        ref.invalidate(diaryEntriesProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원이 완료되었습니다. ($count개의 일기가 복원되었습니다)'),
            backgroundColor: Colors.green,
          ),
        );
      },
      failure: (message, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 실패: $message'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('복원 중 오류가 발생했습니다: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 계정 정보
            SizedBox(
              width: double.infinity,
              child: AppCard(
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
            ),
            const SizedBox(height: 16),
            
            // 테마 설정
            SizedBox(
              width: double.infinity,
              child: AppCard(
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
            ),
            const SizedBox(height: 16),
            
            // 데이터 관리
            SizedBox(
              width: double.infinity,
              child: AppCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('데이터 백업'),
                      subtitle: const Text('일기 데이터를 백업합니다'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleBackup(context, ref),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('데이터 복원'),
                      subtitle: const Text('백업한 데이터를 복원합니다'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleRestore(context, ref),
                    ),
                  ],
                ),
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

