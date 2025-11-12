import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'diary_repository.dart';
import '../../core/result_extension.dart';

/// 일기 목록 Provider
final diaryEntriesProvider = FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final result = await diaryRepo.getEntries();
  
  return result.when(
    success: (entries) => entries,
    failure: (message, error) => throw Exception(message),
  );
});

