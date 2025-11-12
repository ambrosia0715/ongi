import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/diary_repository.dart';
import '../../widgets/app_card.dart';
import '../../core/result_extension.dart';

/// 특정 날짜 일기 Provider
final diaryEntryProvider = FutureProvider.family.autoDispose<DiaryEntry?, String>((ref, date) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final result = await diaryRepo.getEntry(date);
  
  return result.when(
    success: (entry) => entry,
    failure: (message, error) => throw Exception(message),
  );
});

/// 일기 상세 페이지
class DiaryDetailPage extends ConsumerWidget {
  final String date;

  const DiaryDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(diaryEntryProvider(date));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(date)),
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return Center(
              child: Text(
                '일기를 찾을 수 없습니다',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 감정
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        _getEmotionIcon(entry.emotion),
                        color: _getEmotionColor(entry.emotion),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getEmotionLabel(entry.emotion),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 목표
                if (entry.goal.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 작은 목표',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.goal,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 할 일
                if (entry.todos.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 할 일',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...entry.todos.map((todo) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                todo.done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: todo.done
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  todo.text,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: todo.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 마음 한 줄
                if (entry.note.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '마음 한 줄',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.note,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // AI 코멘트
                if (entry.aiComment != null && entry.aiComment!.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI 코멘트',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.aiComment!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
            ],
          ),
        ),
      ),
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

  IconData _getEmotionIcon(String emotion) {
    return switch (emotion) {
      'warm' => Icons.favorite,
      'calm' => Icons.spa,
      'neutral' => Icons.sentiment_neutral,
      'cool' => Icons.ac_unit,
      _ => Icons.sentiment_neutral,
    };
  }

  Color _getEmotionColor(String emotion) {
    return switch (emotion) {
      'warm' => Colors.red.shade300,
      'calm' => Colors.blue.shade300,
      'neutral' => Colors.grey.shade400,
      'cool' => Colors.cyan.shade300,
      _ => Colors.grey,
    };
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

