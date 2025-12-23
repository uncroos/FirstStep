import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_store.dart';

final _localStoreProvider = Provider((ref) => LocalStore());

final recentGuidesProvider =
    StateNotifierProvider<RecentGuidesNotifier, List<String>>((ref) {
  final store = ref.read(_localStoreProvider);
  return RecentGuidesNotifier(store);
});

class RecentGuidesNotifier extends StateNotifier<List<String>> {
  final LocalStore _store;

  RecentGuidesNotifier(this._store) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await _store.loadRecentGuides();
    if (loaded != null) state = loaded;
  }

  Future<void> _save() => _store.saveRecentGuides(state);

  void viewed(String guideId) {
    final next = <String>[guideId, ...state.where((id) => id != guideId)];
    state = next.take(2).toList();
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}