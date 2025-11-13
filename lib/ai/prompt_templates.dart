import '../../diary/data/diary_repository.dart';

/// 프롬프트 템플릿 클래스
class PromptTemplates {
  PromptTemplates._();

  /// 감정 한글 변환
  static String _emotionToKorean(String emotion) {
    return switch (emotion) {
      'warm' => '따뜻함',
      'calm' => '편안함',
      'neutral' => '무덤덤',
      'cool' => '차분',
      _ => emotion,
    };
  }

  /// 일기 코멘트 생성 프롬프트 (전체 일기 기반)
  static String buildDiaryCommentPrompt(DiaryEntry entry) {
    final emotionKr = _emotionToKorean(entry.emotion);
    final todosText = entry.todos
        .map((t) => '${t.done ? "✓" : "○"} ${t.text}')
        .join('\n');

    return '''
사용자의 하루 기록을 읽고, 따뜻하고 공감적인 한 문단 코멘트를 한국어로 작성해주세요.
조언이나 지시보다 위로와 격려를 우선하세요.

[오늘의 기록]
- 감정: $emotionKr
- 작은 목표: ${entry.goal.isEmpty ? "(없음)" : entry.goal}
- 할 일:
$todosText
- 마음 한 줄: ${entry.note.isEmpty ? "(없음)" : entry.note}

위 기록을 바탕으로, 따뜻하고 공감적인 코멘트를 작성해주세요. 교정이나 훈계는 하지 말고, 사용자의 감정을 인정하고 위로해주세요.
''';
  }

  /// 마음 한 줄 기반 AI 코멘트 생성 프롬프트
  static String buildNoteCommentPrompt(String note) {
    if (note.trim().isEmpty) {
      return '''
사용자가 아직 마음을 적지 않았습니다. 사용자에게 따뜻하게 마음을 적어보라고 격려하는 한 문장을 한국어로 작성해주세요.
''';
    }

    return '''
사용자가 적은 마음 한 줄을 읽고, 따뜻하고 공감적인 한 문단 코멘트를 한국어로 작성해주세요.
조언이나 지시보다 위로와 격려를 우선하세요.

[사용자의 마음 한 줄]
$note

위 내용을 바탕으로, 따뜻하고 공감적인 코멘트를 작성해주세요. 교정이나 훈계는 하지 말고, 사용자의 감정을 인정하고 위로해주세요.
''';
  }
}

