class GuideItem {
  final String id;
  final String category;
  final String title;
  final String content;
  final bool isBookmarked;

  const GuideItem({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.isBookmarked,
  });

  GuideItem copyWith({
    String? id,
    String? category,
    String? title,
    String? content,
    bool? isBookmarked,
  }) {
    return GuideItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}