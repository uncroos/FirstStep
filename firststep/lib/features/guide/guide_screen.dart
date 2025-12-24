import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/guides_provider.dart';
import '../../theme/app_colors.dart';
import 'guide_detail_screen.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _query = '';
  String _selectedCategory = '전체';

  final List<String> _categories = const ['전체', '이력서', '자기소개서', '면접', '첫출근'];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final guides = ref.watch(guidesProvider);
    final categories = [
      '전체',
      ...{for (final g in guides) g.category}.toList(),
    ];

    final filtered = guides.where((g) {
      final matchQuery = g.title.toLowerCase().contains(_query.toLowerCase());
      final matchCategory =
          _selectedCategory == '전체' || g.category == _selectedCategory;
      return matchQuery && matchCategory;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 타이틀
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Guide',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: AppColors.navy),
            ),
          ),

          // 🔹 검색
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '가이드 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 카테고리 필터
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = c == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 리스트
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final g = filtered[i];
                      return _GuideCard(
                        title: g.title,
                        category: g.category,
                        bookmarked: g.isBookmarked,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuideDetailScreen(guideId: g.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String category;
  final bool bookmarked;
  final VoidCallback onTap;

  const _GuideCard({
    required this.title,
    required this.category,
    required this.bookmarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              bookmarked ? Icons.star : Icons.star_border,
              color: bookmarked ? Colors.amber : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
