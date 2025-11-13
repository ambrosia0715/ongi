import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../diary/data/diary_repository.dart';
import 'backup_service.dart';

/// 백업 서비스 Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  return BackupService(diaryRepo);
});

