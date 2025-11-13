import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../diary/data/diary_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/ad_banner_widget.dart';

/// 대시보드 페이지
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 provider 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('[Dashboard] 페이지 진입 - provider 새로고침');
        ref.invalidate(diaryEntriesProvider); // provider 무효화하여 새로 로드
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final entriesAsync = ref.watch(diaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // 빈 제목으로 AppBar 유지
        centerTitle: true,
        toolbarHeight: 56, // 기본 AppBar 높이
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
                      // 앱 로고 (로그인 페이지와 동일한 크기)
                      Center(
                        child: Image.asset(
                          'assets/images/ongi_logo.png',
                          height: 120,
                          width: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.favorite,
                              size: 80,
                              color: Color(0xFF8B6F5E),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 환영 메시지
                      SizedBox(
                        width: double.infinity,
                        child: AppCard(
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
                            return const SizedBox.shrink(); // 일기가 없으면 통계 영역 숨김
                          }

                          // 감정 통계
                          final emotionCounts = <String, int>{};
                          for (var entry in entries) {
                            print('[Dashboard] 일기 감정: date=${entry.date}, emotion=${entry.emotion}');
                            emotionCounts[entry.emotion] =
                                (emotionCounts[entry.emotion] ?? 0) + 1;
                          }
                          print('[Dashboard] 감정 통계: $emotionCounts');

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
                                    // 감정을 정렬하여 표시 (감정 이름 순)
                                    ...() {
                                      final sortedEntries = emotionCounts.entries.toList()
                                        ..sort((a, b) {
                                          // 감정 순서: warm, calm, neutral, cool
                                          const order = ['warm', 'calm', 'neutral', 'cool'];
                                          final aIndex = order.indexOf(a.key);
                                          final bIndex = order.indexOf(b.key);
                                          if (aIndex == -1 && bIndex == -1) return a.key.compareTo(b.key);
                                          if (aIndex == -1) return 1;
                                          if (bIndex == -1) return -1;
                                          return aIndex.compareTo(bIndex);
                                        });
                                      return sortedEntries.map((entry) {
                                      final total = entries.length;
                                      final percentage =
                                          (entry.value / total * 100).round();
                                      print('[Dashboard] 감정 분포 표시: ${entry.key}(${_getEmotionLabel(entry.key)}) = ${entry.value}/${total} (${percentage}%)');
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
                                    }).toList();
                                    }(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(), // 로딩 중일 때는 아무것도 표시하지 않음
                        error: (error, stack) {
                          // 에러 발생 시에도 통계 영역 숨김 (일기 목록 버튼은 계속 표시)
                          print('Error loading entries: $error');
                          return const SizedBox.shrink();
                        },
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

