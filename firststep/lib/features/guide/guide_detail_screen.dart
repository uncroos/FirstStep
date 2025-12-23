import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/guides_provider.dart';
import '../../state/recent_guides_provider.dart';
import '../../theme/app_colors.dart';

class GuideDetailScreen extends ConsumerStatefulWidget {
  final String guideId;
  const GuideDetailScreen({super.key, required this.guideId});

  @override
  ConsumerState<GuideDetailScreen> createState() =>
      _GuideDetailScreenState();
}

class _GuideDetailScreenState
    extends ConsumerState<GuideDetailScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ build 이후에 provider 수정
    Future.microtask(() {
      ref
          .read(recentGuidesProvider.notifier)
          .viewed(widget.guideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref
        .watch(guidesProvider)
        .firstWhere((g) => g.id == widget.guideId);

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
        actions: [
          IconButton(
            icon: Icon(
              guide.isBookmarked
                  ? Icons.star
                  : Icons.star_border,
            ),
            onPressed: () {
              ref
                  .read(guidesProvider.notifier)
                  .toggleBookmark(widget.guideId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: '요약', content: guide.content),
            _Section(title: 'Do', content: '실제 가이드 내용'),
            _Section(title: 'Don’t', content: '실제 가이드 내용'),
            _Section(title: '예시', content: '실제 가이드 내용'),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(content),
        ],
      ),
    );
  }
}