import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../diary/data/diary_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/ad_banner_widget.dart';

/// 대시보드 페이지
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final entriesAsync = ref.watch(diaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ongi_logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.favorite, size: 24);
              },
            ),
            const SizedBox(width: 8),
            const Text('온기'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            // 로그인되지 않음 - 로그인 페이지로 리다이렉트
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/sign-in');
            });
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 환영 메시지
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '안녕하세요, ${user.email?.split('@')[0] ?? '사용자'}님',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '오늘도 따뜻한 하루를 기록해보세요',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 오늘 기록하기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/diary/editor'),
                          icon: const Icon(Icons.edit),
                          label: const Text('오늘 기록하기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 통계 카드
                      entriesAsync.when(
                        data: (entries) {
                          if (entries.isEmpty) {
                            return AppCard(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '아직 작성한 일기가 없습니다',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            );
                          }

                          // 감정 통계
                          final emotionCounts = <String, int>{};
                          for (var entry in entries) {
                            emotionCounts[entry.emotion] =
                                (emotionCounts[entry.emotion] ?? 0) + 1;
                          }

                          return Column(
                            children: [
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '통계',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatItem(
                                          context,
                                          '총 일기',
                                          entries.length.toString(),
                                          Icons.book,
                                        ),
                                        _buildStatItem(
                                          context,
                                          '이번 주',
                                          entries
                                              .where((e) => _isThisWeek(e.date))
                                              .length
                                              .toString(),
                                          Icons.calendar_today,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // 감정 분포 (간단한 표시)
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '감정 분포',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    ...emotionCounts.entries.map((entry) {
                                      final total = entries.length;
                                      final percentage =
                                          (entry.value / total * 100).round();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _getEmotionLabel(entry.key),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                Text(
                                                  '$percentage%',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: entry.value / total,
                                              backgroundColor: Colors.grey.shade200,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => AppCard(
                          child: Text(
                            '통계를 불러오는데 실패했습니다',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 일기 목록 보기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/diary/history'),
                          icon: const Icon(Icons.history),
                          label: const Text('일기 목록 보기'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 광고 배너 (Premium이 아닐 때만 표시)
              // TODO(ongi): Premium 상태 확인 후 조건부 표시
              const AdBannerWidget(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                '오류가 발생했습니다',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  bool _isThisWeek(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return date.isAfter(weekStart.subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  String _getEmotionLabel(String emotion) {
    return switch (emotion) {
      'warm' => '따뜻함',
      'calm' => '편안함',
      'neutral' => '무덤덤',
      'cool' => '차분',
      _ => emotion,
    };
  }
}

