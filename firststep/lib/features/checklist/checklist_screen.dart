import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';

class CheckListScreen extends ConsumerStatefulWidget {
  const CheckListScreen({super.key});

  @override
  ConsumerState<CheckListScreen> createState() => _CheckListScreenState();
}

class _CheckListScreenState extends ConsumerState<CheckListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Map<String, bool> _expanded = {
    '이력서': true,
    '자기소개서': true,
    '면접': true,
    '첫출근': true,
  };

  final List<String> _categories = const [
    '이력서',
    '자기소개서',
    '면접',
    '첫출근',
  ];

  double _progress(List tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isDone).length;
    return done / tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tasks = ref.watch(tasksProvider);
    final progress = _progress(tasks);
    final percent = (progress * 100).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 타이틀
          Text(
            'CheckList',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.navy,
              ),
          ),
          const SizedBox(height: 12),

          // 🔹 전체 진행률
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 25,
              backgroundColor: AppColors.lightGray,
              valueColor: const AlwaysStoppedAnimation(AppColors.navy),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$percent%'),
          ),

          const SizedBox(height: 16),

          // 🔹 아코디언 카테고리
          ..._categories.map((category) {
            final items =
                tasks.where((t) => t.category == category).toList();
            final isOpen = _expanded[category] ?? true;

            return _Accordion(
              title: category,
              isOpen: isOpen,
              onTap: () {
                setState(() {
                  _expanded[category] = !isOpen;
                });
              },
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '아직 항목이 없습니다.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: items.map((t) {
                        return Row(
                          children: [
                            Checkbox(
                              value: t.isDone,
                              activeColor: AppColors.navy,
                              onChanged: (_) {
                                ref
                                    .read(tasksProvider.notifier)
                                    .toggleDone(t.id);
                              },
                            ),
                            Expanded(child: Text(t.title)),
                          ],
                        );
                      }).toList(),
                    ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _Accordion extends StatelessWidget {
  final String title;
  final bool isOpen;
  final VoidCallback onTap;
  final Widget child;

  const _Accordion({
    required this.title,
    required this.isOpen,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(isOpen
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: child,
            ),
        ],
      ),
    );
  }
}