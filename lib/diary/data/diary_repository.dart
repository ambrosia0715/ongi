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
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DiaryRepository()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance {
    print('[DiaryRepository] 생성자 실행 - Firestore 인스턴스 생성');
    // Firestore 설정 (오프라인 지속성 비활성화 - 문제 해결을 위해)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print('[DiaryRepository] Firestore 설정 완료');
  }

  /// 사용자 ID 가져오기
  String? get _userId => _auth.currentUser?.uid;

  /// 오늘 날짜 문자열 (yyyy-MM-dd)
  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 일기 저장
  Future<Result<void>> saveEntry(DiaryEntry entry) async {
    print('[DiaryRepository] ========== saveEntry 메서드 호출됨 ==========');
    print('[DiaryRepository] 현재 시간: ${DateTime.now()}');

    final userId = _userId;
    print('[DiaryRepository] 사용자 ID 확인: ${userId ?? "null"}');

    if (userId == null) {
      print('[DiaryRepository] saveEntry: 사용자 ID가 null입니다.');
      return const Failure('로그인이 필요합니다.');
    }

    print('[DiaryRepository] saveEntry 시작: userId=$userId, date=${entry.date}');

    try {
      // Firestore 인스턴스 확인
      print('[DiaryRepository] Firestore 인스턴스 확인 중...');
      print('[DiaryRepository] _firestore 인스턴스 사용');
      print('[DiaryRepository] Firestore 앱: ${_firestore.app.name}');

      // 저장할 데이터 확인
      print('[DiaryRepository] 데이터 변환 시작...');
      final data = entry.toMap();
      print('[DiaryRepository] 저장할 데이터 준비 완료: ${data.keys.toList()}');
      print('[DiaryRepository] 데이터 크기: ${data.toString().length} bytes');

      // 저장 경로 확인
      print('[DiaryRepository] 저장 경로 구성 시작...');
      final collectionRef = _firestore.collection('entries');
      print('[DiaryRepository] collectionRef 생성 완료');

      final userDocRef = collectionRef.doc(userId);
      print('[DiaryRepository] userDocRef 생성 완료');

      final diariesCollectionRef = userDocRef.collection('diaries');
      print('[DiaryRepository] diariesCollectionRef 생성 완료');

      final entryDocRef = diariesCollectionRef.doc(entry.date);
      print('[DiaryRepository] entryDocRef 생성 완료');

      print('[DiaryRepository] 저장 경로: entries/$userId/diaries/${entry.date}');
      print('[DiaryRepository] Firestore에 저장 시작 (타임스탬프: ${DateTime.now()})...');
      print('[DiaryRepository] set() 메서드 호출 직전...');

      // 저장 실행 (타임아웃 없이 - 상위에서 처리)
      final startTime = DateTime.now();
      print('[DiaryRepository] await 시작: ${startTime}');

      await entryDocRef.set(data, SetOptions(merge: true));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('[DiaryRepository] ========== Firestore 저장 완료! ==========');
      print('[DiaryRepository] 소요 시간: ${duration.inMilliseconds}ms');
      print('[DiaryRepository] 완료 시간: ${endTime}');
      return const Success(null);
    } catch (e, stackTrace) {
      print('[DiaryRepository] ========== saveEntry 오류 발생 ==========');
      print('[DiaryRepository] 오류: $e');
      print('[DiaryRepository] 오류 타입: ${e.runtimeType}');
      print('[DiaryRepository] Stack trace: $stackTrace');
      return Failure('일기를 저장하는데 실패했습니다: $e', e);
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

  /// 모든 일기 가져오기 (백업용)
  Future<Result<List<DiaryEntry>>> getAllEntries() async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries')
          .orderBy('date', descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return Success(entries);
    } catch (e) {
      return Failure('일기 목록을 가져오는데 실패했습니다.', e);
    }
  }

  /// 여러 일기 일괄 저장 (복원용)
  Future<Result<void>> saveEntries(List<DiaryEntry> entries) async {
    final userId = _userId;
    if (userId == null) {
      return const Failure('로그인이 필요합니다.');
    }

    try {
      final batch = _firestore.batch();
      final diariesRef = _firestore
          .collection('entries')
          .doc(userId)
          .collection('diaries');

      for (final entry in entries) {
        final entryRef = diariesRef.doc(entry.date);
        batch.set(entryRef, entry.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure('일기를 저장하는데 실패했습니다: $e', e);
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
