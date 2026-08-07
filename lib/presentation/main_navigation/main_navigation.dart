import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxtube/application/application.dart';
import 'package:fluxtube/core/colors.dart';
import 'package:fluxtube/core/deep_link_handler.dart';
import 'package:fluxtube/core/enums.dart';
import 'package:fluxtube/core/player/global_player_controller.dart';
import 'package:fluxtube/core/services/pip_service.dart';
import 'package:fluxtube/generated/l10n.dart';

import '../download/screen_downloads.dart';
import '../saved/screen_saved.dart';
import '../settings/screen_settings.dart';
import '../subscriptions/screen_subscriptions.dart';
import '../trending/screen_trending.dart';
import '../watch_now/screen_watch_now.dart';

ValueNotifier<int> indexChangeNotifier = ValueNotifier(0);

/// Notifier for downloads screen tab selection
/// 0 = Downloading, 1 = Completed, 2 = All
ValueNotifier<int?> downloadsTabNotifier = ValueNotifier(null);

/// Pending navigation info
String? _pendingNavigation;
int? _pendingDownloadsTab;

/// Navigate to the Downloads tab
/// [downloadsTabIndex] - optional tab index within Downloads screen (0=Downloading, 1=Completed, 2=All)
void navigateToDownloadsTab({int? downloadsTabIndex}) {
  _pendingNavigation = 'downloads';
  _pendingDownloadsTab = downloadsTabIndex;
  // Set the downloads tab notifier if specified
  if (downloadsTabIndex != null) {
    downloadsTabNotifier.value = downloadsTabIndex;
  }
  // Set index to a known downloads position (will be adjusted by MainNavigation if needed)
  // Downloads is at index 4 with trending, index 3 without
  // Use index 4, the MainNavigation will handle pending navigation and find correct index
  indexChangeNotifier.value = 4;
}

/// Get and clear pending navigation target
String? consumePendingNavigation() {
  final target = _pendingNavigation;
  _pendingNavigation = null;
  return target;
}

/// Get and clear pending downloads tab index
int? consumePendingDownloadsTab() {
  final tab = _pendingDownloadsTab;
  _pendingDownloadsTab = null;
  return tab;
}

/// Item simples pra navbar customizada (substitui o TabItem do
/// awesome_bottom_bar, que não é mais usado).
class _NavItem {
  final IconData icon;
  final String label;
  final String key;

  const _NavItem({required this.icon, required this.label, required this.key});
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  bool _hasShownInstanceFailedSnackbar = false;
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();
  bool? _previousShowTrending;
  final Map<String, Widget> _pageCache = {};

  List<Widget> _getPages(bool showTrending) {
    if (showTrending) {
      return [
        _cachedPage('home', const ScreenWatchNow()),
        _cachedPage('trending', const ScreenTrending()),
        _cachedPage('subscriptions', const ScreenSubscriptions()),
        _cachedPage('saved', const ScreenSaved()),
        _cachedPage('downloads', const ScreenDownloads()),
        _cachedPage('settings', const ScreenSettings()),
      ];
    } else {
      return [
        _cachedPage('home', const ScreenWatchNow()),
        _cachedPage('subscriptions', const ScreenSubscriptions()),
        _cachedPage('saved', const ScreenSaved()),
        _cachedPage('downloads', const ScreenDownloads()),
        _cachedPage('settings', const ScreenSettings()),
      ];
    }
  }

  Widget _cachedPage(String key, Widget page) {
    return _pageCache.putIfAbsent(key, () => page);
  }

  List<_NavItem> _getTabItems(S locals, bool showTrending) {
    if (showTrending) {
      return [
        _NavItem(icon: CupertinoIcons.house_fill, label: locals.home, key: "home"),
        _NavItem(icon: CupertinoIcons.flame_fill, label: locals.trending, key: "trending"),
        _NavItem(icon: CupertinoIcons.person_2_fill, label: locals.subscriptions, key: "subscriptions"),
        _NavItem(icon: CupertinoIcons.bookmark_fill, label: locals.saved, key: "saved"),
        _NavItem(icon: CupertinoIcons.arrow_down_circle_fill, label: locals.downloads, key: "downloads"),
        _NavItem(icon: CupertinoIcons.settings, label: locals.settings, key: "settings"),
      ];
    } else {
      return [
        _NavItem(icon: CupertinoIcons.house_fill, label: locals.home, key: "home"),
        _NavItem(icon: CupertinoIcons.person_2_fill, label: locals.subscriptions, key: "subscriptions"),
        _NavItem(icon: CupertinoIcons.bookmark_fill, label: locals.saved, key: "saved"),
        _NavItem(icon: CupertinoIcons.arrow_down_circle_fill, label: locals.downloads, key: "downloads"),
        _NavItem(icon: CupertinoIcons.settings, label: locals.settings, key: "settings"),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkHandler.init(context);
    });
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locals = S.of(context);

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          previous.ytService != current.ytService ||
          previous.userInstanceFailed != current.userInstanceFailed,
      builder: (context, settingsState) {
        // Disable trending tab for NewPipe Extractor service
        final showTrending =
            settingsState.ytService != YouTubeServices.newpipe.name;
        final pages = _getPages(showTrending);
        final items = _getTabItems(locals, showTrending);

        final maxIndex = pages.length - 1;

        // Adjust index when transitioning between services with different tab counts
        if (_previousShowTrending != null &&
            _previousShowTrending != showTrending) {
          final currentIndex = indexChangeNotifier.value;
          int newIndex;

          if (showTrending && !_previousShowTrending!) {
            newIndex = currentIndex == 0 ? 0 : currentIndex + 1;
          } else {
            if (currentIndex <= 1) {
              newIndex = 0;
            } else {
              newIndex = currentIndex - 1;
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            indexChangeNotifier.value = newIndex;
          });
        }
        _previousShowTrending = showTrending;

        return BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) =>
              !previous.userInstanceFailed && current.userInstanceFailed,
          listener: (context, state) {
            if (state.userInstanceFailed && !_hasShownInstanceFailedSnackbar) {
              _hasShownInstanceFailedSnackbar = true;
              final failedName =
                  state.failedInstanceName ?? 'Your preferred instance';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$failedName is not responding. Switched to a working instance.',
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          },
          child: ValueListenableBuilder(
            valueListenable: indexChangeNotifier,
            builder: (BuildContext context, int index, Widget? _) {
              final pendingNav = consumePendingNavigation();
              if (pendingNav == 'downloads') {
                final downloadsIndex =
                    items.indexWhere((item) => item.key == 'downloads');
                if (downloadsIndex >= 0) {
                  final pendingDownloadsTab = consumePendingDownloadsTab();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    indexChangeNotifier.value = downloadsIndex;
                    if (pendingDownloadsTab != null) {
                      downloadsTabNotifier.value = pendingDownloadsTab;
                    }
                  });
                }
              }

              final safeIndex = index.clamp(0, maxIndex);
              if (index != safeIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  indexChangeNotifier.value = safeIndex;
                });
              }
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) return;
                  final watchState = context.read<WatchBloc>().state;
                  if (watchState.isPipEnabled &&
                      watchState.selectedVideoBasicDetails != null) {
                    final pipService = PipService();
                    await pipService.setVideoPlaying(true);
                    await pipService.setAspectRatio(16, 9);
                    final entered = await pipService.enterPipMode();
                    if (entered) return;
                  }
                  final globalPlayer = GlobalPlayerController();
                  if (globalPlayer.hasActivePlayer) {
                    globalPlayer.disposePlayer();
                    await Future.delayed(const Duration(milliseconds: 100));
                  }
                  SystemNavigator.pop();
                },
                child: Scaffold(
                  extendBody: true,
                  body: Stack(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: _LazyIndexedStack(
                          index: safeIndex,
                          children: pages,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _GlassPillNavBar(
                          items: items,
                          selectedIndex: safeIndex,
                          onTap: (i) => indexChangeNotifier.value = i,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Navbar flutuante em formato de pílula com efeito de vidro fosco
/// (BackdropFilter + blur), substituindo a BottomBarSalomon.
class _GlassPillNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _GlassPillNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavPillItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? kRedColor?.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? kRedColor : kGreyColor,
              ),
              if (selected) ...[
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kRedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LazyIndexedStack extends StatefulWidget {
  const _LazyIndexedStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late List<bool> _built;

  @override
  void initState() {
    super.initState();
    _built = List<bool>.filled(widget.children.length, false);
    _built[widget.index] = true;
  }

  @override
  void didUpdateWidget(covariant _LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_built.length != widget.children.length) {
      _built = List<bool>.generate(
        widget.children.length,
        (index) => index < oldWidget.children.length && index < _built.length
            ? _built[index]
            : false,
      );
    }
    _built[widget.index] = true;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _built[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
