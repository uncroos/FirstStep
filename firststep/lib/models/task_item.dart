class TaskItem {
  final String id;
  final String title;
  final bool isDone;
  final String category;

  const TaskItem({
    required this.id,
    required this.title,
    required this.isDone,
    required this.category,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    String? category,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'category': category,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
      category: json['category'] as String,
    );
  }
}