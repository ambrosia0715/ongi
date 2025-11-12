import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/diary_repository.dart';
import '../../ai/data/ai_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../core/result_extension.dart';
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
            if (_todoControllers.isEmpty) {
              _todoControllers.add(TodoController());
            }
          });
        } else {
          // 새 일기 - 할 일 하나 추가
          _todoControllers.add(TodoController());
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
      aiComment: _aiComment,
      createdAt: now,
      updatedAt: now,
    );

    final diaryRepo = ref.read(diaryRepositoryProvider);
    final result = await diaryRepo.saveEntry(entry);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일기가 저장되었습니다.')),
        );
        context.pop();
      },
      failure: (message, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  /// AI 코멘트 생성
  Future<void> _generateAiComment() async {
    // 제한 체크
    final usageState = ref.read(dailyAiUsageProvider);
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
      createdAt: now,
      updatedAt: now,
    );

    final aiRepo = ref.read(aiRepositoryProvider);
    final result = await aiRepo.generateComment(entry);

    setState(() => _isGeneratingAi = false);

    if (!mounted) return;

    result.when(
      success: (comment) {
        setState(() => _aiComment = comment);
        
        // Firestore에 저장
        final diaryRepo = ref.read(diaryRepositoryProvider);
        diaryRepo.updateAiComment(date, comment);
        
        // 사용 기록
        ref.read(dailyAiUsageProvider.notifier).recordUsage();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 코멘트가 생성되었습니다.')),
        );
      },
      failure: (message, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 기록'),
        actions: [
          if (_aiComment == null)
            TextButton(
              onPressed: _isGeneratingAi ? null : _generateAiComment,
              child: _isGeneratingAi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('AI 코멘트'),
            ),
        ],
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
              AppTextField(
                controller: _noteController,
                label: '마음 한 줄 적기',
                hint: '오늘의 마음을 자유롭게 적어보세요',
                maxLines: 5,
                minLines: 3,
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
                            'AI 코멘트',
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
              
              // 저장 버튼
              AppButton(
                onPressed: _isLoading ? null : _saveEntry,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('저장하기'),
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

