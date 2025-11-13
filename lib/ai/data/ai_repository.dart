import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../core/env.dart';
import '../../diary/data/diary_repository.dart';
import '../prompt_templates.dart';

/// AI Repository Provider
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

/// OpenAI API 연동 클래스
class AiRepository {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// 일기 기반 AI 코멘트 생성
  Future<Result<String>> generateComment(DiaryEntry entry) async {
    final apiKey = Env.openAiApiKey;
    if (apiKey.isEmpty) {
      return const Failure('OpenAI API 키가 설정되지 않았습니다.');
    }

    try {
      // 프롬프트 생성
      final prompt = PromptTemplates.buildDiaryCommentPrompt(entry);

      // OpenAI API 호출
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '당신은 따뜻하고 공감적인 일기 코멘터입니다.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return Success(content.trim());
        }
        return const Failure('AI 응답이 비어있습니다.');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error']?['message'] as String? ?? '알 수 없는 오류';
        return Failure('AI 코멘트 생성 실패: $errorMessage');
      }
    } catch (e) {
      return Failure('AI 코멘트를 생성하는데 실패했습니다.', e);
    }
  }

  /// 마음 한 줄 기반 AI 코멘트 생성
  Future<Result<String>> generateNoteComment(String note) async {
    String apiKey;
    try {
      apiKey = Env.openAiApiKey;
    } catch (e) {
      print('Error getting OpenAI API key: $e');
      return const Failure('OpenAI API 키를 읽는 중 오류가 발생했습니다. .env 파일을 확인해주세요.');
    }
    
    if (apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
      return const Failure('OpenAI API 키가 설정되지 않았습니다. 프로젝트 루트에 .env 파일을 생성하고 OPENAI_API_KEY를 설정해주세요.');
    }

    try {
      // 프롬프트 생성
      final prompt = PromptTemplates.buildNoteCommentPrompt(note);

      // OpenAI API 호출
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '당신은 따뜻하고 공감적인 일기 코멘터입니다.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return Success(content.trim());
        }
        return const Failure('AI 응답이 비어있습니다.');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error']?['message'] as String? ?? '알 수 없는 오류';
        return Failure('AI 코멘트 생성 실패: $errorMessage');
      }
    } catch (e) {
      return Failure('AI 코멘트를 생성하는데 실패했습니다.', e);
    }
  }
}

/// 일일 AI 사용 제한 상태
class DailyAiUsageState {
  final int count;
  final DateTime? lastUsageDate;
  final bool isPremium;

  DailyAiUsageState({
    required this.count,
    this.lastUsageDate,
    required this.isPremium,
  });

  /// 오늘 사용 가능 여부
  bool get canUseToday {
    if (isPremium) return true; // Premium은 제한 없음
    if (lastUsageDate == null) return true;
    
    final today = DateTime.now();
    final lastDate = lastUsageDate!;
    
    // 같은 날이 아니면 리셋
    if (today.year != lastDate.year ||
        today.month != lastDate.month ||
        today.day != lastDate.day) {
      return true;
    }
    
    // 같은 날이면 제한 체크
    return count < Env.dailyFreeAiLimit;
  }
}

/// 일일 AI 사용 제한 Notifier
class DailyAiUsageNotifier extends Notifier<DailyAiUsageState> {
  @override
  DailyAiUsageState build() {
    return DailyAiUsageState(count: 0, isPremium: false);
  }
  
  void recordUsage() {
    final today = DateTime.now();
    final currentState = state;
    final lastDate = currentState.lastUsageDate;
    
    // 날짜가 바뀌었으면 리셋
    if (lastDate == null ||
        today.year != lastDate.year ||
        today.month != lastDate.month ||
        today.day != lastDate.day) {
      state = DailyAiUsageState(
        count: 1,
        lastUsageDate: today,
        isPremium: currentState.isPremium,
      );
    } else {
      state = DailyAiUsageState(
        count: currentState.count + 1,
        lastUsageDate: today,
        isPremium: currentState.isPremium,
      );
    }
  }
  
  void setPremium(bool isPremium) {
    state = DailyAiUsageState(
      count: state.count,
      lastUsageDate: state.lastUsageDate,
      isPremium: isPremium,
    );
  }
}

/// 일일 AI 사용 제한 체크 Provider
final dailyAiUsageProvider = NotifierProvider<DailyAiUsageNotifier, DailyAiUsageState>(
  DailyAiUsageNotifier.new,
);


