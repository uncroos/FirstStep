import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'guides_provider.dart';

final bookmarksProvider = Provider<List<String>>((ref) {
  final guides = ref.watch(guidesProvider);
  return guides.where((g) => g.isBookmarked).map((g) => g.id).toList();
});