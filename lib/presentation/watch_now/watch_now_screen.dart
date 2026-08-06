import 'package:flutter/material.dart';

import 'data/watch_now_repository.dart';
import 'models/watch_now_video.dart';
import 'theme/watch_now_theme.dart';
import 'widgets/category_chips.dart';
import 'widgets/featured_card.dart';
import 'widgets/horizontal_section.dart';

/// Tela "Watch Now" — 

class WatchNowScreen extends StatefulWidget {
  final WatchNowRepository repository;
  final String? userAvatarUrl;

  const WatchNowScreen({
    super.key,
    this.repository = const _DefaultRepo(),
    this.userAvatarUrl,
  });

  @override
  State<WatchNowScreen> createState() => _WatchNowScreenState();
}

// Permite usar `const` no construtor mesmo com o mock (que não é const).
class _DefaultRepo implements WatchNowRepository {
  const _DefaultRepo();
  static final _delegate = MockWatchNowRepository();

  @override
  Future<WatchNowVideo?> fetchUpNext() => _delegate.fetchUpNext();
  @override
  Future<List<WatchNowVideo>> fetchWhatToWatch() => _delegate.fetchWhatToWatch();
  @override
  Future<List<WatchNowVideo>> fetchTrending() => _delegate.fetchTrending();
  @override
  Future<List<WatchNowCategoryItem>> fetchCategories() => _delegate.fetchCategories();
}

class _WatchNowScreenState extends State<WatchNowScreen> {
  late Future<_WatchNowData> _future;
  WatchNowCategory _selectedCategory = WatchNowCategory.all;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WatchNowData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchUpNext(),
      widget.repository.fetchWhatToWatch(),
      widget.repository.fetchTrending(),
      widget.repository.fetchCategories(),
    ]);
    return _WatchNowData(
      upNext: results[0] as WatchNowVideo?,
      whatToWatch: results[1] as List<WatchNowVideo>,
      trending: results[2] as List<WatchNowVideo>,
      categories: results[3] as List<WatchNowCategoryItem>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WatchNowColors.background,
      body: SafeArea(
        child: FutureBuilder<_WatchNowData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  _Header(avatarUrl: widget.userAvatarUrl),
                  const SizedBox(height: 16),
                  CategoryChips(
                    categories: data.categories,
                    selected: _selectedCategory,
                    onSelected: (item) =>
                        setState(() => _selectedCategory = item.type),
                  ),
                  const SizedBox(height: 20),
                  if (data.upNext != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FeaturedCard(video: data.upNext!),
                    ),
                    const SizedBox(height: 28),
                  ],
                  HorizontalSection(
                    title: 'What to Watch',
                    videos: data.whatToWatch,
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 28),
                  HorizontalSection(
                    title: 'Trending',
                    videos: data.trending,
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? avatarUrl;
  const _Header({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Watch Now', style: WatchNowTextStyles.title),
          CircleAvatar(
            radius: 20,
            backgroundColor: WatchNowColors.surface,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: WatchNowColors.textSecondary)
                : null,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Não foi possível carregar o conteúdo.',
            style: TextStyle(color: WatchNowColors.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}

class _WatchNowData {
  final WatchNowVideo? upNext;
  final List<WatchNowVideo> whatToWatch;
  final List<WatchNowVideo> trending;
  final List<WatchNowCategoryItem> categories;

  _WatchNowData({
    required this.upNext,
    required this.whatToWatch,
    required this.trending,
    required this.categories,
  });
}
