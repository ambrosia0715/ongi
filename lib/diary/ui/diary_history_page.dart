import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/diary_providers.dart';
import '../../widgets/app_card.dart';

/// 일기 히스토리 페이지
class DiaryHistoryPage extends ConsumerWidget {
  const DiaryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(diaryEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 목록'),
      ),
      body: Column(
        children: [
          // 감정 필터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text('필터: '),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context,
                          label: '전체',
                          isSelected: true,
                          onSelected: () {
                            // TODO(ongi): 필터 기능 구현
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: '따뜻함',
                          isSelected: false,
                          onSelected: () {
                            // TODO(ongi): 필터 기능 구현
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: '편안함',
                          isSelected: false,
                          onSelected: () {
                            // TODO(ongi): 필터 기능 구현
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: '무덤덤',
                          isSelected: false,
                          onSelected: () {
                            // TODO(ongi): 필터 기능 구현
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          label: '차분',
                          isSelected: false,
                          onSelected: () {
                            // TODO(ongi): 필터 기능 구현
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // 일기 목록
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아직 작성한 일기가 없습니다',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () {
                          context.push('/diary/detail/${entry.date}');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(entry.date),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                _buildEmotionChip(context, entry.emotion),
                              ],
                            ),
                            if (entry.goal.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '목표: ${entry.goal}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (entry.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.note,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
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
                      '일기를 불러오는데 실패했습니다',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(diaryEntriesProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildEmotionChip(BuildContext context, String emotion) {
    final Map<String, String> emotionLabels = {
      'warm': '따뜻함',
      'calm': '편안함',
      'neutral': '무덤덤',
      'cool': '차분',
    };
    
    return Chip(
      label: Text(emotionLabels[emotion] ?? emotion),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('yyyy년 MM월 dd일').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

