import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/tasks_provider.dart';
import '../../state/guides_provider.dart';
import '../../state/recent_guides_provider.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _addBtnLocked = false;

  double _progress(List tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isDone == true).length;
    return done / tasks.length;
  }

  Future<void> _openAddTaskModal() async {
    if (_addBtnLocked) return;
    setState(() => _addBtnLocked = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _addBtnLocked = false);
    });

    final titleController = TextEditingController();
    String category = '이력서';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('할 일 추가', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '예) 면접 질문 1개 연습하기',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setLocal) {
                  return Row(
                    children: [
                      const Text('카테고리: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: category,
                        items: const [
                          DropdownMenuItem(value: '이력서', child: Text('이력서')),
                          DropdownMenuItem(value: '자기소개서', child: Text('자기소개서')),
                          DropdownMenuItem(value: '면접', child: Text('면접')),
                          DropdownMenuItem(value: '첫출근', child: Text('첫출근')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() => category = v);
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      Navigator.pop(ctx);
                      return;
                    }
                    ref.read(tasksProvider.notifier).addTask(
                          title: title,
                          category: category,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('추가하기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tasks = ref.watch(tasksProvider);
    final guides = ref.watch(guidesProvider);
    final recentIds = ref.watch(recentGuidesProvider);

    final progress = _progress(tasks);
    final percent = (progress * 100).round();

    final recentGuides = recentIds
        .map((id) => guides.where((g) => g.id == id).toList())
        .expand((x) => x)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FirstStep',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.navy,
                ),
              ),
            
            const SizedBox(height: 12),

            // ToDo 카드
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ToDo List', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),

                  if (tasks.isEmpty)
                    const _EmptyLine(text: '첫 걸음을 내디뎌 보세요!')
                  else
                    ...tasks.take(3).map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Checkbox(
                              value: t.isDone,
                              onChanged: (_) => ref.read(tasksProvider.notifier).toggleDone(t.id),
                              activeColor: AppColors.navy,
                            ),
                            Expanded(child: Text(t.title)),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _addBtnLocked ? null : _openAddTaskModal,
                      icon: const Icon(Icons.add),
                      label: const Text('추가하기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.lightGray,
                      valueColor: const AlwaysStoppedAnimation(AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('$percent%'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 최근 본 가이드
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최근 본 가이드', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (recentGuides.isEmpty)
                    const _EmptyLine(text: '가이드를 열어보면 여기에 최근 2개가 뜹니다.')
                  else
                    ...recentGuides.map((g) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('• ${g.title}'),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // (MVP) 면접 시작 버튼 (지금은 이동만/나중에 Interview 탭 연결)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // 다음 단계에서 Interview 탭 상세 로직 연결
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('면접 연습은 6단계에서 완성됩니다.')),
                  );
                },
                child: const Text('면접 연습 시작하기'),
              ),
            ),

            const SizedBox(height: 24),

            // 개발 확인용: 최근 가이드 강제 주입 버튼(나중에 삭제)
            TextButton(
              onPressed: () {
                // Guide 상세 들어가기 전이라, 동작 확인용으로 2개 찍어줌
                ref.read(recentGuidesProvider.notifier).viewed('g1');
                ref.read(recentGuidesProvider.notifier).viewed('g2');
              },
              child: const Text('(개발용) 최근 가이드 샘플 넣기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}