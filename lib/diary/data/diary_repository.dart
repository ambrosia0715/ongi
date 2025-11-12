import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';

/// Diary Entry 모델
class DiaryEntry {
  final String date; // yyyy-MM-dd 형식
  final String emotion; // warm, calm, neutral, cool
  final String goal;
  final List<TodoItem> todos;
  final String note;
  final String? aiComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    required this.date,
    required this.emotion,
    required this.goal,
    required this.todos,
    required this.note,
    this.aiComment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'emotion': emotion,
      'goal': goal,
      'todos': todos.map((t) => {'text': t.text, 'done': t.done}).toList(),
      'note': note,
      'aiComment': aiComment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      date: map['date'] as String,
      emotion: map['emotion'] as String,
      goal: map['goal'] as String,
      todos: (map['todos'] as List<dynamic>?)
              ?.map((t) => TodoItem(
                    text: t['text'] as String,
                    done: t['done'] as bool? ?? false,
                  ))
              .toList() ??
          [],
      note: map['note'] as String,
      aiComment: map['aiComment'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

/// 할 일 아이템
class TodoItem {
  final String text;
  final bool done;

  TodoItem({required this.text, required this.done});
}

/// Diary Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

/// 일기 데이터 처리 클래스
class DiaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사용자 ID 가져오기
  String? get _userId => _auth.currentUser?.uid;

  /// 오늘 날짜 문자열 (yyyy-MM-dd)
  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 일기 저장
  Future<Result<void>> saveEntry(DiaryEntry entry) async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      await _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries')
          .doc(entry.date)
          .set(entry.toMap(), SetOptions(merge: true));

      return const Success(null);
    } catch (e) {
      return Failure('일기를 저장하는데 실패했습니다.', e);
    }
  }

  /// 오늘 일기 가져오기
  Future<Result<DiaryEntry?>> getTodayEntry() async {
    return getEntry(_todayDate);
  }

  /// 특정 날짜 일기 가져오기
  Future<Result<DiaryEntry?>> getEntry(String date) async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      final doc = await _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries')
          .doc(date)
          .get();

      if (!doc.exists) {
        return const Success(null);
      }

      return Success(DiaryEntry.fromMap(doc.data()!));
    } catch (e) {
      return Failure('일기를 가져오는데 실패했습니다.', e);
    }
  }

  /// 일기 목록 가져오기 (최신순)
  Future<Result<List<DiaryEntry>>> getEntries({
    int limit = 30,
    String? emotionFilter,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      Query query = _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries')
          .orderBy('date', descending: true)
          .limit(limit);

      if (emotionFilter != null && emotionFilter.isNotEmpty) {
        query = query.where('emotion', isEqualTo: emotionFilter);
      }

      final snapshot = await query.get();
      final entries = snapshot.docs
          .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return Success(entries);
    } catch (e) {
      return Failure('일기 목록을 가져오는데 실패했습니다.', e);
    }
  }

  /// AI 코멘트 업데이트
  Future<Result<void>> updateAiComment(String date, String comment) async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      await _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries')
          .doc(date)
          .update({
        'aiComment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } catch (e) {
      return Failure('AI 코멘트를 업데이트하는데 실패했습니다.', e);
    }
  }
}

