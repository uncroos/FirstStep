import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guide_item.dart';
import '../services/local_store.dart';

final _localStoreProvider = Provider((ref) => LocalStore());

final guidesProvider =
    StateNotifierProvider<GuidesNotifier, List<GuideItem>>((ref) {
  final store = ref.read(_localStoreProvider);
  return GuidesNotifier(store);
});

class GuidesNotifier extends StateNotifier<List<GuideItem>> {
  final LocalStore _store;

  GuidesNotifier(this._store) : super(const []) {
    _load();
  }

  List<GuideItem> _defaults() => const [
        GuideItem(
          id: 'g1',
          category: '면접',
          title: '면접 이후 감사 메일 예절',
          content: '면접 후 감사 메일은 24시간 내 보내는 게 베스트.',
          isBookmarked: false,
        ),
        GuideItem(
          id: 'g2',
          category: '이력서',
          title: '이력서 한 장으로 임팩트 주는 법',
          content: '핵심 성과를 숫자로 보여주면 설득력이 올라감.',
          isBookmarked: false,
        ),
        GuideItem(
          id: 'g3',
          category: '자기소개서',
          title: '자기소개서 문항 접근 전략',
          content: '문항 의도 → 경험 매칭 → 결과/배움 순으로 쓰면 안정적.',
          isBookmarked: false,
        ),
        GuideItem(
          id: 'g4',
          category: '첫출근',
          title: '첫 출근 전 체크리스트',
          content: '시간/복장/말투/메모 습관만 챙겨도 1주차가 편해짐.',
          isBookmarked: false,
        ),
      ];

  Future<void> _load() async {
    final bookmarks = await _store.loadBookmarks() ?? const <String>[];
    final base = _defaults();

    state = [
      for (final g in base)
        g.copyWith(isBookmarked: bookmarks.contains(g.id))
    ];
  }

  Future<void> _saveBookmarks() async {
    final ids = state.where((g) => g.isBookmarked).map((g) => g.id).toList();
    await _store.saveBookmarks(ids);
  }

  void toggleBookmark(String id) {
    state = [
      for (final g in state)
        if (g.id == id) g.copyWith(isBookmarked: !g.isBookmarked) else g
    ];
    _saveBookmarks();
  }
}