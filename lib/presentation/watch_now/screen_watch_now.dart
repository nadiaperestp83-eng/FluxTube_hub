import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxtube/application/application.dart';
import 'package:fluxtube/core/colors.dart';
import 'package:fluxtube/core/enums.dart';
import 'package:fluxtube/generated/l10n.dart';
import 'package:fluxtube/widgets/thumbnail_image.dart';
import 'package:go_router/go_router.dart';

/// Tela de busca dedicada, estilo YouTube: campo de busca focado no topo,
/// sugestões enquanto digita, histórico quando vazio, resultados em lista
/// vertical com paginação. 100% conectada ao SearchBloc/SearchService real
/// — nenhum dado mockado.
///
/// Abra com:
///   Navigator.of(context, rootNavigator: true).push(
///     MaterialPageRoute(builder: (_) => const ScreenSearchNow()),
///   );
class ScreenSearchNow extends StatefulWidget {
  const ScreenSearchNow({super.key});

  @override
  State<ScreenSearchNow> createState() => _ScreenSearchNowState();
}

class _ScreenSearchNowState extends State<ScreenSearchNow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasSearched = false;
  String _lastSubmittedQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      final settings = context.read<SettingsBloc>().state;
      context.read<SearchBloc>().add(
            SearchEvent.getSearchHistory(
              profileName: settings.currentProfile,
              limit: 15,
            ),
          );
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    EasyDebounce.cancel('search-suggestions');
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasSearched) return;
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll - 300) {
      _loadMore();
    }
  }

  String get _serviceType =>
      context.read<SettingsBloc>().state.ytService;

  void _onQueryChanged(String value) {
    setState(() {}); // atualiza o botão de limpar / troca histórico<->sugestão
    if (value.trim().isEmpty) return;
    EasyDebounce.debounce(
      'search-suggestions',
      const Duration(milliseconds: 350),
      () {
        context.read<SearchBloc>().add(
              SearchEvent.getSearchSuggestion(
                query: value.trim(),
                serviceType: _serviceType,
              ),
            );
      },
    );
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    EasyDebounce.cancel('search-suggestions');
    _focusNode.unfocus();
    setState(() {
      _hasSearched = true;
      _lastSubmittedQuery = trimmed;
    });
    final settings = context.read<SettingsBloc>().state;
    context
        .read<SearchBloc>()
        .add(SearchEvent.getSearchResult(query: trimmed, serviceType: _serviceType));
    context.read<SearchBloc>().add(
          SearchEvent.saveSearchQuery(
            query: trimmed,
            profileName: settings.currentProfile,
          ),
        );
  }

  void _loadMore() {
    final state = context.read<SearchBloc>().state;
    if (_serviceType == YouTubeServices.newpipe.name) {
      if (state.isMoreNewPipeFetchCompleted ||
          state.fetchMoreNewPipeSearchResultStatus == ApiStatus.loading) {
        return;
      }
      context.read<SearchBloc>().add(SearchEvent.getMoreSearchResult(
            query: _lastSubmittedQuery,
            serviceType: _serviceType,
            nextPage: state.newPipeSearchResult?.nextPage,
          ));
    } else if (_serviceType == YouTubeServices.invidious.name) {
      if (state.isMoreInvidiousFetchCompleted ||
          state.fetchMoreInvidiousSearchResultStatus == ApiStatus.loading) {
        return;
      }
      context.read<SearchBloc>().add(SearchEvent.getMoreSearchResult(
            query: _lastSubmittedQuery,
            serviceType: _serviceType,
          ));
    } else {
      if (state.isMoreFetchCompleted ||
          state.fetchMoreSearchResultStatus == ApiStatus.loading) {
        return;
      }
      context.read<SearchBloc>().add(SearchEvent.getMoreSearchResult(
            query: _lastSubmittedQuery,
            serviceType: _serviceType,
            nextPage: state.result?.nextpage,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locals = S.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(locals),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (!_hasSearched) {
                    return _buildSuggestionsOrHistory(context, state, locals);
                  }
                  return _buildResults(context, state, locals);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(S locals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: locals.search,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {
                          _hasSearched = false;
                        });
                      },
                      child: const Icon(Icons.close, size: 18, color: Colors.black45),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Sugestões (digitando) / Histórico (campo vazio)
  // -------------------------------------------------------------------

  Widget _buildSuggestionsOrHistory(
      BuildContext context, SearchState state, S locals) {
    final typing = _controller.text.trim().isNotEmpty;

    if (typing) {
      final suggestions = _currentSuggestions(state);
      if (suggestions.isEmpty) {
        return const SizedBox.shrink();
      }
      return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index].toString();
          return ListTile(
            leading: const Icon(Icons.search, color: Colors.black45),
            title: Text(suggestion),
            trailing: const Icon(Icons.north_west, size: 18, color: Colors.black38),
            onTap: () {
              _controller.text = suggestion;
              _submitSearch(suggestion);
            },
          );
        },
      );
    }

    // Histórico
    final history = state.searchHistory;
    if (history.isEmpty) {
      return Center(
        child: Text(
          locals.noSearchHistory,
          style: const TextStyle(color: Colors.black45),
        ),
      );
    }
    final settings = context.read<SettingsBloc>().state;
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.black45),
          title: Text(entry.query),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black38),
            onPressed: () {
              context.read<SearchBloc>().add(SearchEvent.deleteSearchQuery(
                    query: entry.query,
                    profileName: settings.currentProfile,
                  ));
            },
          ),
          onTap: () {
            _controller.text = entry.query;
            _submitSearch(entry.query);
          },
        );
      },
    );
  }

  List<dynamic> _currentSuggestions(SearchState state) {
    if (_serviceType == YouTubeServices.newpipe.name) {
      return state.newPipeSuggestionResult;
    } else if (_serviceType == YouTubeServices.invidious.name) {
      return state.invidiousSuggestionResult;
    }
    return state.suggestions;
  }

  // -------------------------------------------------------------------
  // Resultados
  // -------------------------------------------------------------------

  Widget _buildResults(BuildContext context, SearchState state, S locals) {
    final loading = _isLoadingResults(state);
    final items = _currentResultItems(state);

    if (loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          locals.noResultsFound,
          style: const TextStyle(color: Colors.black45),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length + (loading ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final item = items[index];
        return _SearchResultTile(
          item: item,
          onTap: () => _openResult(context, item),
        );
      },
    );
  }

  bool _isLoadingResults(SearchState state) {
    if (_serviceType == YouTubeServices.newpipe.name) {
      return state.fetchNewPipeSearchResultStatus == ApiStatus.loading;
    } else if (_serviceType == YouTubeServices.invidious.name) {
      return state.fetchInvidiousSearchResultStatus == ApiStatus.loading;
    }
    return state.fetchSearchResultStatus == ApiStatus.loading;
  }

  List<dynamic> _currentResultItems(SearchState state) {
    if (_serviceType == YouTubeServices.newpipe.name) {
      return state.newPipeSearchResult?.items ?? const [];
    } else if (_serviceType == YouTubeServices.invidious.name) {
      return state.invidiousSearchResult;
    }
    return state.result?.items ?? const [];
  }

  void _openResult(BuildContext context, dynamic item) {
    final videoId = _extractVideoId(item);
    final channelId = _extractChannelId(item);
    if (videoId == null || channelId == null || videoId.isEmpty) return;

    context.read<WatchBloc>().add(
          WatchEvent.setSelectedVideoBasicDetails(
            details: VideoBasicInfo(
              id: videoId,
              title: _extractTitle(item),
              thumbnailUrl: _extractThumbnail(item),
              channelName: _safe(() => item.uploaderName as String?),
              channelThumbnailUrl: _extractUploaderAvatar(item),
              channelId: channelId,
              uploaderVerified: _safe(() => item.uploaderVerified as bool?),
            ),
          ),
        );
    context.goNamed('watch', pathParameters: {
      'videoId': videoId,
      'channelId': channelId,
    });
  }
}

class _SearchResultTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _SearchResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locals = S.of(context);
    final thumbnail = _extractThumbnail(item);
    final title = _extractTitle(item) ?? locals.noVideoTitle;
    final uploaderName =
        _safe(() => item.uploaderName as String?) ?? locals.noUploaderName;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 140,
                height: 79,
                child: thumbnail != null
                    ? ThumbnailImage(url: thumbnail)
                    : Container(color: const Color(0xFFE8E8E8)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uploaderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: kGreyColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Extratores seguros (mesmo padrão do screen_watch_now.dart): tentam os
// nomes de campo de cada backend (Piped/.title, NewPipe/.name, etc.) sem
// derrubar a tela se um deles não existir na classe.
//
// NOTA: cobre Piped e NewPipe Extractor, que já validamos. O model do
// Invidious ainda não foi conferido — se título/thumbnail vierem em
// branco só nesse serviço, manda o arquivo do InvidiousSearchResp que eu
// completo o fallback.
// ---------------------------------------------------------------------

T? _safe<T>(T? Function() getter) {
  try {
    return getter();
  } catch (_) {
    return null;
  }
}

String? _extractTitle(dynamic v) =>
    _safe(() => v.title as String?) ?? _safe(() => v.name as String?);

String? _extractThumbnail(dynamic v) =>
    _safe(() => v.thumbnail as String?) ??
    _safe(() => v.thumbnailUrl as String?);

String? _extractUploaderAvatar(dynamic v) =>
    _safe(() => v.uploaderAvatar as String?) ??
    _safe(() => v.uploaderAvatarUrl as String?);

String? _extractVideoId(dynamic v) {
  final ready = _safe(() => v.videoId as String?);
  if (ready != null && ready.isNotEmpty) return ready;
  final url = _safe(() => v.url as String?);
  if (url == null) return null;
  final uri = Uri.tryParse(url);
  return uri?.queryParameters['v'] ?? uri?.pathSegments.lastOrNull;
}

String? _extractChannelId(dynamic v) {
  final ready = _safe(() => v.channelId as String?);
  if (ready != null && ready.isNotEmpty) return ready;
  final uploaderId = _safe(() => v.uploaderId as String?);
  if (uploaderId != null && uploaderId.isNotEmpty) return uploaderId;
  final uploaderUrl = _safe(() => v.uploaderUrl as String?);
  if (uploaderUrl == null) return null;
  final uri = Uri.tryParse(uploaderUrl);
  if (uri == null) return null;
  if (uri.pathSegments.contains('channel')) {
    final idx = uri.pathSegments.indexOf('channel');
    if (idx + 1 < uri.pathSegments.length) return uri.pathSegments[idx + 1];
  }
  return uri.pathSegments.lastOrNull;
}
