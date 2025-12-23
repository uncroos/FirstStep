import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../services/local_store.dart';

final _localStoreProvider = Provider((ref) => LocalStore());

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<TaskItem>>((ref) {
  final store = ref.read(_localStoreProvider);
  return TasksNotifier(store);
});

class TasksNotifier extends StateNotifier<List<TaskItem>> {
  final LocalStore _store;

  TasksNotifier(this._store) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await _store.loadTasks();
    if (loaded != null) {
      state = loaded;
    } else {
      // 처음 실행 기본값
      state = const [
        TaskItem(id: 't1', title: '면접 질문 1개 연습하기', isDone: false, category: '면접'),
        TaskItem(id: 't2', title: '이력서 점검', isDone: false, category: '이력서'),
      ];
      await _store.saveTasks(state);
    }
  }

  Future<void> _save() => _store.saveTasks(state);

  void toggleDone(String id) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(isDone: !t.isDone) else t
    ];
    _save();
  }

  void addTask({
    required String title,
    required String category, // ✅ 이제 4개 중 하나로만 들어오게 만들었지
  }) {
    final newItem = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      isDone: false,
      category: category,
    );
    state = [newItem, ...state];
    _save();
  }
}