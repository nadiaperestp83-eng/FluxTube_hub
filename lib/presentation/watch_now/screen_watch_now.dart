import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxtube/application/application.dart';
import 'package:fluxtube/core/colors.dart';
import 'package:fluxtube/core/constants.dart';
import 'package:fluxtube/core/enums.dart';
import 'package:fluxtube/core/operations/math_operations.dart';
import 'package:fluxtube/domain/watch/models/basic_info.dart';
import 'package:fluxtube/generated/l10n.dart';
import 'package:fluxtube/widgets/thumbnail_image.dart';
import 'package:fluxtube/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

/// Tela "Watch Now" — mesma lógica de dados real do ScreenHome original
/// (TrendingBloc / SubscribeBloc / SettingsBloc), com layout estilo Apple TV:
/// card grande "Up Next" + fileira horizontal "What to Watch", em vez de
/// lista vertical tipo feed.
class ScreenWatchNow extends StatefulWidget {
  const ScreenWatchNow({super.key});

  @override
  State<ScreenWatchNow> createState() => _ScreenWatchNowState();
}

class _ScreenWatchNowState extends State<ScreenWatchNow> {
  int _selectedChip = 0;
  static const _chipLabels = ['Para você', 'Vídeos', 'Séries', 'Esportes'];

  @override
  Widget build(BuildContext context) {
    final trendingBloc = BlocProvider.of<TrendingBloc>(context);
    final locals = S.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          previous.ytService != current.ytService ||
          previous.defaultRegion != current.defaultRegion ||
          previous.homeFeedMode != current.homeFeedMode,
      builder: (context, settingsState) {
        return SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _buildHeaderBar(context)),
            ],
            body: BlocBuilder<SubscribeBloc, SubscribeState>(
              buildWhen: (previous, current) =>
                  previous.subscribedChannels.length !=
                  current.subscribedChannels.length,
              builder: (context, subscribeState) {
                if (subscribeState.subscribedChannels.isNotEmpty &&
                    subscribeState.oldList.length !=
                        subscribeState.subscribedChannels.length) {
                  log("oldList: ${subscribeState.oldList.length} & subscribedChannels: ${subscribeState.subscribedChannels.length}");
                  if (settingsState.ytService != YouTubeServices.newpipe.name) {
                    trendingBloc.add(GetForcedHomeFeedData(
                        channels: subscribeState.subscribedChannels));
                  }
                  BlocProvider.of<SubscribeBloc>(context).add(
                      SubscribeEvent.updateSubscribeOldList(
                          subscribedChannels:
                              subscribeState.subscribedChannels));
                }
                return BlocBuilder<TrendingBloc, TrendingState>(
                  buildWhen: (previous, current) {
                    return previous.fetchTrendingStatus !=
                            current.fetchTrendingStatus ||
                        previous.fetchInvidiousTrendingStatus !=
                            current.fetchInvidiousTrendingStatus ||
                        previous.fetchNewPipeTrendingStatus !=
                            current.fetchNewPipeTrendingStatus ||
                        previous.fetchFeedStatus != current.fetchFeedStatus ||
                        previous.fetchNewPipeFeedStatus !=
                            current.fetchNewPipeFeedStatus ||
                        previous.newPipeFeedResult !=
                            current.newPipeFeedResult ||
                        previous.fetchPersonalizedFeedStatus !=
                            current.fetchPersonalizedFeedStatus ||
                        previous.personalizedFeedResult !=
                            current.personalizedFeedResult ||
                        previous.personalizedFeedDisplayCount !=
                            current.personalizedFeedDisplayCount ||
                        previous.isLoadingMorePersonalizedFeed !=
                            current.isLoadingMorePersonalizedFeed ||
                        previous.hasMorePersonalizedContent !=
                            current.hasMorePersonalizedContent ||
                        previous.feedDisplayCount != current.feedDisplayCount ||
                        previous.isLoadingMoreFeed !=
                            current.isLoadingMoreFeed ||
                        previous.newPipeFeedDisplayCount !=
                            current.newPipeFeedDisplayCount ||
                        previous.isLoadingMoreNewPipeFeed !=
                            current.isLoadingMoreNewPipeFeed ||
                        previous.trendingDisplayCount !=
                            current.trendingDisplayCount ||
                        previous.isLoadingMoreTrending !=
                            current.isLoadingMoreTrending ||
                        previous.newPipeTrendingDisplayCount !=
                            current.newPipeTrendingDisplayCount ||
                        previous.isLoadingMoreNewPipeTrending !=
                            current.isLoadingMoreNewPipeTrending ||
                        previous.invidiousTrendingDisplayCount !=
                            current.invidiousTrendingDisplayCount ||
                        previous.isLoadingMoreInvidiousTrending !=
                            current.isLoadingMoreInvidiousTrending;
                  },
                  builder: (context, trendingState) {
                    if (settingsState.ytService ==
                        YouTubeServices.newpipe.name) {
                      return _buildNewPipeTrendingOrFeedSection(
                        trendingState,
                        locals,
                        context,
                        subscribeState,
                        trendingBloc,
                        settingsState,
                      );
                    } else if (settingsState.ytService ==
                        YouTubeServices.invidious.name) {
                      return _buildInvidiousTrendingOrFeedSection(
                        trendingState,
                        locals,
                        context,
                        subscribeState,
                        trendingBloc,
                        settingsState,
                      );
                    } else {
                      return _buildPipedTrendingOrFeedSection(
                        trendingState,
                        locals,
                        context,
                        subscribeState,
                        trendingBloc,
                        settingsState,
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Header: barra preta + título + avatar + pílulas de categoria
  // ---------------------------------------------------------------------

  Widget _buildHeaderBar(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Watch Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          _buildChips(),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chipLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedChip;
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kRedColor : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? null
                    : Border.all(color: Colors.white24, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                _chipLabels[index],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Branching de dados por serviço (Piped / NewPipe / Invidious) — mesma
  // lógica real do app original, só troca o widget final de renderização.
  // ---------------------------------------------------------------------

  Widget _buildPipedTrendingOrFeedSection(
      TrendingState trendingState,
      S locals,
      BuildContext context,
      SubscribeState subscribeState,
      TrendingBloc trendingBloc,
      SettingsState settingsState) {
    final homeFeedMode = settingsState.homeFeedMode;

    if (trendingState.trendingResult.isEmpty &&
        !(trendingState.fetchTrendingStatus == ApiStatus.error)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trendingBloc.add(TrendingEvent.getTrendingData(
            serviceType: settingsState.ytService,
            region: settingsState.defaultRegion));
      });
    }

    if (trendingState.fetchTrendingStatus == ApiStatus.loading ||
        trendingState.fetchTrendingStatus == ApiStatus.initial) {
      return _buildLoadingState();
    }

    if (homeFeedMode == HomeFeedMode.trendingOnly.name) {
      return _buildErrorOrTrendingSection(
        context,
        trendingState,
        settingsState,
      );
    }

    if (homeFeedMode == HomeFeedMode.feedOnly.name) {
      if (trendingState.fetchFeedStatus == ApiStatus.loading) {
        return _buildLoadingState();
      }
      if (trendingState.feedResult.isEmpty) {
        return _buildEmptySubscriptionState(context, locals);
      }
      return _buildFeedLayout(trendingState, trendingBloc, subscribeState);
    }

    if (trendingState.fetchFeedStatus == ApiStatus.loading) {
      return _buildLoadingState();
    }

    if (trendingState.feedResult.isEmpty ||
        trendingState.fetchFeedStatus == ApiStatus.error) {
      log("Feed Error or empty - showing trending");
      return _buildErrorOrTrendingSection(
        context,
        trendingState,
        settingsState,
      );
    }

    return _buildFeedLayout(trendingState, trendingBloc, subscribeState);
  }

  Widget _buildNewPipeTrendingOrFeedSection(
    TrendingState trendingState,
    S locals,
    BuildContext context,
    SubscribeState subscribeState,
    TrendingBloc trendingBloc,
    SettingsState settingsState,
  ) {
    if (trendingState.personalizedFeedResult.isEmpty &&
        trendingState.fetchPersonalizedFeedStatus == ApiStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trendingBloc.add(TrendingEvent.getPersonalizedFeed(
          profileName: settingsState.currentProfile,
          serviceType: settingsState.ytService,
        ));
      });
    }

    if (trendingState.fetchPersonalizedFeedStatus == ApiStatus.loading ||
        trendingState.fetchPersonalizedFeedStatus == ApiStatus.initial) {
      return _buildLoadingState();
    }

    if (trendingState.fetchPersonalizedFeedStatus == ApiStatus.error ||
        (trendingState.personalizedFeedResult.isEmpty &&
            trendingState.fetchPersonalizedFeedStatus == ApiStatus.loaded)) {
      log("Personalized feed error/empty - falling back to trending");
      if (trendingState.newPipeTrendingResult.isEmpty &&
          trendingState.fetchNewPipeTrendingStatus != ApiStatus.loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          trendingBloc.add(TrendingEvent.getTrendingData(
              serviceType: settingsState.ytService,
              region: settingsState.defaultRegion));
        });
      }
      return RefreshIndicator(
        onRefresh: () async {
          trendingBloc.add(TrendingEvent.getForcedPersonalizedFeed(
            profileName: settingsState.currentProfile,
            serviceType: settingsState.ytService,
          ));
        },
        child: _buildErrorOrTrendingSection(
          context,
          trendingState,
          settingsState,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        trendingBloc.add(TrendingEvent.getForcedPersonalizedFeed(
          profileName: settingsState.currentProfile,
          serviceType: settingsState.ytService,
        ));
      },
      child: _buildVideoLayout(
        context,
        trendingState.personalizedFeedResult,
      ),
    );
  }

  Widget _buildInvidiousTrendingOrFeedSection(
    TrendingState trendingState,
    S locals,
    BuildContext context,
    SubscribeState subscribeState,
    TrendingBloc trendingBloc,
    SettingsState settingsState,
  ) {
    final homeFeedMode = settingsState.homeFeedMode;

    if (trendingState.invidiousTrendingResult.isEmpty &&
        !(trendingState.fetchInvidiousTrendingStatus == ApiStatus.error)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trendingBloc.add(TrendingEvent.getTrendingData(
            serviceType: settingsState.ytService,
            region: settingsState.defaultRegion));
      });
    }

    if (trendingState.fetchInvidiousTrendingStatus == ApiStatus.loading ||
        trendingState.fetchInvidiousTrendingStatus == ApiStatus.initial) {
      return _buildLoadingState();
    }

    if (homeFeedMode == HomeFeedMode.trendingOnly.name) {
      return _buildErrorOrTrendingSection(
        context,
        trendingState,
        settingsState,
      );
    }

    if (homeFeedMode == HomeFeedMode.feedOnly.name) {
      if (trendingState.fetchFeedStatus == ApiStatus.loading) {
        return _buildLoadingState();
      }
      if (trendingState.feedResult.isEmpty) {
        return _buildEmptySubscriptionState(context, locals);
      }
      return _buildFeedLayout(trendingState, trendingBloc, subscribeState);
    }

    if (trendingState.fetchFeedStatus == ApiStatus.loading) {
      return _buildLoadingState();
    }

    if (trendingState.feedResult.isEmpty ||
        trendingState.fetchFeedStatus == ApiStatus.error) {
      return _buildErrorOrTrendingSection(
        context,
        trendingState,
        settingsState,
      );
    }

    return _buildFeedLayout(trendingState, trendingBloc, subscribeState);
  }

  Widget _buildFeedLayout(
    TrendingState trendingState,
    TrendingBloc trendingBloc,
    SubscribeState subscribeState,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        trendingBloc.add(TrendingEvent.getForcedHomeFeedData(
          channels: subscribeState.subscribedChannels,
        ));
      },
      child: _buildVideoLayout(context, trendingState.feedResult),
    );
  }

  Widget _buildErrorOrTrendingSection(
    BuildContext context,
    TrendingState trendingState,
    SettingsState settingsState,
  ) {
    if (settingsState.ytService == YouTubeServices.newpipe.name) {
      if (trendingState.fetchNewPipeTrendingStatus == ApiStatus.error ||
          trendingState.newPipeTrendingResult.isEmpty) {
        return ErrorRetryWidget(
          lottie: 'assets/dog.zip',
          onTap: () => BlocProvider.of<TrendingBloc>(context).add(
            TrendingEvent.getForcedTrendingData(
                serviceType: settingsState.ytService,
                region: settingsState.defaultRegion),
          ),
        );
      }
      return _buildVideoLayout(context, trendingState.newPipeTrendingResult);
    } else if (settingsState.ytService == YouTubeServices.invidious.name) {
      if (trendingState.fetchInvidiousTrendingStatus == ApiStatus.error ||
          trendingState.invidiousTrendingResult.isEmpty) {
        return ErrorRetryWidget(
          lottie: 'assets/dog.zip',
          onTap: () => BlocProvider.of<TrendingBloc>(context).add(
            TrendingEvent.getForcedTrendingData(
                serviceType: settingsState.ytService,
                region: settingsState.defaultRegion),
          ),
        );
      }
      return _buildVideoLayout(context, trendingState.invidiousTrendingResult);
    } else {
      if (trendingState.fetchTrendingStatus == ApiStatus.error ||
          trendingState.trendingResult.isEmpty) {
        return ErrorRetryWidget(
          lottie: 'assets/dog.zip',
          onTap: () => BlocProvider.of<TrendingBloc>(context).add(
            TrendingEvent.getForcedTrendingData(
                serviceType: settingsState.ytService,
                region: settingsState.defaultRegion),
          ),
        );
      }
      return _buildVideoLayout(context, trendingState.trendingResult);
    }
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE8E8E8),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        ShimmerHomeVideoInfoCard(),
        ShimmerHomeVideoInfoCard(),
      ],
    );
  }

  Widget _buildEmptySubscriptionState(BuildContext context, S locals) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            kHeightBox20,
            Text(
              locals.noSubscriptions,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            kHeightBox10,
            Text(
              locals.noSubscriptionsHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Layout estilo Apple TV: card grande "Up Next" + fileira horizontal
  // "What to Watch". Usa os mesmos campos que HomeVideoInfoCardWidget já
  // usa em qualquer backend (title, thumbnail, duration, views,
  // uploadedDate, uploaderName, uploaderAvatar, url, uploaderUrl) —
  // então funciona igual em Piped/NewPipe/Invidious sem quebrar.
  // ---------------------------------------------------------------------

  Widget _buildVideoLayout(BuildContext context, List<dynamic> videos) {
    if (videos.isEmpty) {
      return const Center(child: Text('Nada por aqui ainda.'));
    }

    final upNext = videos.first;
    final rest = videos.length > 1 ? videos.sublist(1) : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _FeaturedVideoCard(
            video: upNext,
            onTap: () => _openVideo(context, upNext),
          ),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'What to Watch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final video = rest[index];
                return _VideoRowTile(
                  video: video,
                  onTap: () => _openVideo(context, video),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openVideo(BuildContext context, dynamic video) {
    final String? url = _safe(() => video.url as String?);
    final String? uploaderUrl = _safe(() => video.uploaderUrl as String?);
    final String? videoId = url?.split('=').last;
    final String? channelId = uploaderUrl?.split('/').last;
    if (videoId == null || channelId == null || videoId.isEmpty) return;

    BlocProvider.of<WatchBloc>(context).add(
      WatchEvent.setSelectedVideoBasicDetails(
        details: VideoBasicInfo(
          id: videoId,
          title: _safe(() => video.title as String?),
          thumbnailUrl: _safe(() => video.thumbnail as String?),
          channelName: _safe(() => video.uploaderName as String?),
          channelThumbnailUrl: _safe(() => video.uploaderAvatar as String?),
          channelId: channelId,
          uploaderVerified: _safe(() => video.uploaderVerified as bool?),
        ),
      ),
    );
    context.goNamed('watch', pathParameters: {
      'videoId': videoId,
      'channelId': channelId,
    });
  }
}

/// Tenta ler um campo dinâmico sem derrubar a tela se ele não existir
/// nesse model específico (NewPipe/Piped/Invidious têm classes diferentes).
/// Em caso de erro, retorna null em vez de propagar a exceção.
T? _safe<T>(T? Function() getter) {
  try {
    return getter();
  } catch (_) {
    return null;
  }
}

/// Card grande em destaque ("Up Next"), thumbnail cheia + gradiente escuro
/// + título/canal sobrepostos, igual ao topo da tela Watch Now da Apple TV.
class _FeaturedVideoCard extends StatelessWidget {
  final dynamic video;
  final VoidCallback onTap;

  const _FeaturedVideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locals = S.of(context);
    final rawDuration = _safe(() => video.duration);
    final duration = _safe(() => formatDuration(rawDuration as int?)) ?? '';
    final thumbnail = _safe(() => video.thumbnail as String?);
    final title = _safe(() => video.title as String?) ?? locals.noVideoTitle;
    final uploaderName =
        _safe(() => video.uploaderName as String?) ?? locals.noUploaderName;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null)
                ThumbnailImage(url: thumbnail)
              else
                Container(color: const Color(0xFFE8E8E8)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              if (duration.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card menor usado na fileira horizontal "What to Watch".
class _VideoRowTile extends StatelessWidget {
  final dynamic video;
  final VoidCallback onTap;

  const _VideoRowTile({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locals = S.of(context);
    final rawDuration = _safe(() => video.duration);
    final duration = _safe(() => formatDuration(rawDuration as int?)) ?? '';
    final thumbnail = _safe(() => video.thumbnail as String?);
    final title = _safe(() => video.title as String?) ?? locals.noVideoTitle;
    final uploaderName =
        _safe(() => video.uploaderName as String?) ?? locals.noUploaderName;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnail != null)
                      ThumbnailImage(url: thumbnail)
                    else
                      Container(color: const Color(0xFFE8E8E8)),
                    if (duration.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kBlackColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              color: kWhiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              uploaderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: kGreyColor!),
            ),
          ],
        ),
      ),
    );
  }
}
