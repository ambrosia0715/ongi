import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/diary_repository.dart';
import '../data/diary_providers.dart';
import '../../ai/data/ai_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_card.dart';
import '../../core/result_extension.dart';
import '../../core/result.dart';
import '../../core/env.dart';

/// 일기 에디터 페이지
class DiaryEditorPage extends ConsumerStatefulWidget {
  const DiaryEditorPage({super.key});

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _noteController = TextEditingController();
  final List<TodoController> _todoControllers = [];
  
  String _selectedEmotion = 'warm';
  bool _isLoading = false;
  bool _isGeneratingAi = false;
  String? _aiComment;

  // 감정 아이콘 매핑
  final Map<String, Map<String, dynamic>> _emotions = {
    'warm': {
      'icon': Icons.favorite,
      'label': '따뜻함',
      'color': Colors.red.shade300,
    },
    'calm': {
      'icon': Icons.spa,
      'label': '편안함',
      'color': Colors.blue.shade300,
    },
    'neutral': {
      'icon': Icons.sentiment_neutral,
      'label': '무덤덤',
      'color': Colors.grey.shade400,
    },
    'cool': {
      'icon': Icons.ac_unit,
      'label': '차분',
      'color': Colors.cyan.shade300,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _noteController.dispose();
    for (var controller in _todoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 오늘 일기 로드
  Future<void> _loadTodayEntry() async {
    final diaryRepo = ref.read(diaryRepositoryProvider);
    final result = await diaryRepo.getTodayEntry();

    result.when(
      success: (entry) {
        if (entry != null) {
          setState(() {
            _selectedEmotion = entry.emotion;
            _goalController.text = entry.goal;
            _noteController.text = entry.note;
            _aiComment = entry.aiComment;
            
            _todoControllers.clear();
            for (var todo in entry.todos) {
              _todoControllers.add(TodoController(text: todo.text)
              ..done = todo.done);
            }
            // 기존 일기가 있으면 그대로 사용, 없으면 빈 상태로 시작
          });
        } else {
          // 새 일기 - 빈 상태로 시작 (추가 버튼으로 할 일 추가)
          // 초기에는 할 일이 없음
        }
      },
      failure: (message, error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );
  }

  /// 할 일 추가
  void _addTodo() {
    setState(() {
      _todoControllers.add(TodoController());
    });
  }

  /// 할 일 삭제
  void _removeTodo(int index) {
    if (_todoControllers.length > 1) {
      setState(() {
        _todoControllers[index].dispose();
        _todoControllers.removeAt(index);
      });
    }
  }

  /// 저장
  Future<void> _saveEntry() async {
    print('[_saveEntry] 저장 시작');
    
    // 이미 로딩 중이면 중복 실행 방지
    if (_isLoading) {
      print('[_saveEntry] 이미 저장 중입니다.');
      return;
    }
    
    // Form validation 체크 (필수 필드가 없으므로 항상 통과)
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      print('[_saveEntry] Form validation 실패');
      return;
    }

    // 로딩 상태 시작
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    print('[_saveEntry] 날짜: $date');

    final entry = DiaryEntry(
      date: date,
      emotion: _selectedEmotion,
      goal: _goalController.text.trim(),
      todos: _todoControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => TodoItem(text: c.text.trim(), done: c.done))
          .toList(),
      note: _noteController.text.trim(),
      aiComment: _aiComment,
      createdAt: now,
      updatedAt: now,
    );

    print('[_saveEntry] 일기 내용: emotion=${entry.emotion}, goal=${entry.goal}, note=${entry.note}');

    bool saveSuccess = false;
    String? errorMessage;

    try {
      final diaryRepo = ref.read(diaryRepositoryProvider);
      print('[_saveEntry] DiaryRepository 가져옴, 저장 시작...');
      
      // 타임아웃 추가 (30초로 증가 - Firestore 연결이 느릴 수 있음)
      final result = await diaryRepo.saveEntry(entry)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('[_saveEntry] 저장 타임아웃 발생 (30초 초과)');
              return const Failure('저장 시간이 초과되었습니다. 네트워크 연결과 Firestore 설정을 확인해주세요.');
            },
          );
      
      print('[_saveEntry] 저장 결과 받음');

      result.when(
        success: (_) {
          print('[_saveEntry] 저장 성공');
          saveSuccess = true;
        },
        failure: (message, error) {
          print('[_saveEntry] 저장 실패: $message, error: $error');
          errorMessage = message;
          saveSuccess = false;
        },
      );
    } catch (e, stackTrace) {
      print('[_saveEntry] 예외 발생: $e');
      print('[_saveEntry] Stack trace: $stackTrace');
      errorMessage = '저장 중 오류가 발생했습니다: $e';
      saveSuccess = false;
    } finally {
      // finally 블록에서 항상 로딩 상태 해제 (성공/실패/예외 관계없이)
      print('[_saveEntry] finally 블록 실행 - 로딩 상태 해제');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('[_saveEntry] 로딩 상태 해제 완료 (_isLoading = false)');
      } else {
        print('[_saveEntry] Widget이 unmount되어 setState 호출 불가');
      }
    }

    // mounted 체크 후 UI 업데이트
    if (!mounted) {
      print('[_saveEntry] Widget이 unmount됨 - UI 업데이트 중단');
      return;
    }

    // 성공 처리
    if (saveSuccess) {
      print('[_saveEntry] 성공 처리 시작');
      
      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기가 저장되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 일기 목록 provider 무효화
      ref.invalidate(diaryEntriesProvider);
      print('[_saveEntry] diaryEntriesProvider 무효화 완료');
      
      // 짧은 딜레이 후 대시보드로 이동
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) {
          print('[_saveEntry] 이동 전 unmount 확인');
          return;
        }
        
        print('[_saveEntry] 대시보드로 이동 시도');
        try {
          context.go('/dashboard');
          print('[_saveEntry] 대시보드로 이동 완료');
        } catch (e) {
          print('[_saveEntry] 네비게이션 오류: $e');
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      });
    } else {
      // 실패 처리
      print('[_saveEntry] 실패 처리 시작');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? '저장에 실패했습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// AI 코멘트 생성 (목표, 할일, 마음 한 줄 종합)
  Future<void> _generateAiComment() async {
    print('[_generateAiComment] AI 코멘트 생성 시작');
    
    if (_isGeneratingAi) return;
    
    // 제한 체크
    final usageState = ref.read(dailyAiUsageProvider);
    print('[_generateAiComment] 사용 상태: count=${usageState.count}, canUseToday=${usageState.canUseToday}');
    
    if (!usageState.canUseToday) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오늘은 이미 AI 코멘트를 ${Env.dailyFreeAiLimit}회 사용하셨습니다.'),
        ),
      );
      return;
    }

    setState(() => _isGeneratingAi = true);

    try {
      // 전체 일기 내용으로 Entry 생성
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final entry = DiaryEntry(
        date: date,
        emotion: _selectedEmotion,
        goal: _goalController.text.trim(),
        todos: _todoControllers
            .where((c) => c.text.trim().isNotEmpty)
            .map((c) => TodoItem(text: c.text.trim(), done: c.done))
            .toList(),
        note: _noteController.text.trim(),
        aiComment: null, // 아직 생성 전
        createdAt: now,
        updatedAt: now,
      );
      
      print('[_generateAiComment] 일기 내용: emotion=${entry.emotion}, goal=${entry.goal}, todos=${entry.todos.length}, note=${entry.note}');

      final aiRepo = ref.read(aiRepositoryProvider);
      print('[_generateAiComment] AiRepository 가져옴, API 호출 시작...');
      // 전체 일기 내용을 사용하는 generateComment 메서드 사용
      final result = await aiRepo.generateComment(entry);
      print('[_generateAiComment] API 응답 받음');

      setState(() => _isGeneratingAi = false);

      if (!mounted) {
        print('[_generateAiComment] Widget이 unmount됨');
        return;
      }

      result.when(
        success: (comment) {
          print('[_generateAiComment] AI 코멘트 생성 성공: $comment');
          setState(() => _aiComment = comment);
          
          // 사용 기록
          ref.read(dailyAiUsageProvider.notifier).recordUsage();
          print('[_generateAiComment] 사용 기록 업데이트 완료');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI 코멘트가 생성되었습니다.')),
          );
        },
        failure: (message, error) {
          print('[_generateAiComment] AI 코멘트 생성 실패: $message, error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );
    } catch (e, stackTrace) {
      print('[_generateAiComment] 예외 발생: $e');
      print('[_generateAiComment] Stack trace: $stackTrace');
      setState(() => _isGeneratingAi = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 코멘트 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 기록'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 감정 선택
              Text(
                '오늘의 감정',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _emotions.entries.map((entry) {
                  final isSelected = _selectedEmotion == entry.key;
                  final data = entry.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmotion = entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (data['color'] as Color).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? data['color'] as Color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            data['icon'] as IconData,
                            color: data['color'] as Color,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['label'] as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // 작은 목표
              AppTextField(
                controller: _goalController,
                label: '오늘의 작은 목표',
                hint: '오늘 이루고 싶은 작은 목표를 적어보세요',
              ),
              const SizedBox(height: 24),
              
              // 할 일
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '오늘의 할 일',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _addTodo,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 할 일이 없으면 빈 상태 메시지 표시
              if (_todoControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '할 일을 추가해보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ...List.generate(_todoControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _todoControllers[index].done,
                        onChanged: (value) {
                          setState(() {
                            _todoControllers[index].done = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _todoControllers[index],
                          decoration: const InputDecoration(
                            hintText: '할 일을 입력하세요',
                          ),
                        ),
                      ),
                      if (_todoControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeTodo(index),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              
              // 마음 한 줄
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '마음 한 줄 적기',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: '오늘의 마음을 자유롭게 적어보세요',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // AI 코멘트 표시
              if (_aiComment != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, 
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '마음을 위한 한마디',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _aiComment!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // AI 코멘트 생성 버튼과 저장 버튼 (나란히 배치)
              Row(
                children: [
                  // AI 코멘트 생성 버튼
                  if (_aiComment == null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingAi ? null : _generateAiComment,
                        icon: _isGeneratingAi
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('마음을 위한 한마디'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(0, 48), // 최소 높이 설정
                        ),
                      ),
                    ),
                  if (_aiComment == null) const SizedBox(width: 12),
                  // 저장 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 48), // AI 코멘트 버튼과 동일한 높이
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('저장하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 할 일 컨트롤러
class TodoController extends TextEditingController {
  bool done = false;
  
  TodoController({String? text}) : super(text: text ?? '');
}

