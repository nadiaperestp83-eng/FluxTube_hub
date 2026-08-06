import 'package:flutter/material.dart';
import '../models/watch_now_video.dart';
import '../theme/watch_now_theme.dart';
import 'video_tile.dart';

/// Column (título + "See All") + ListView.builder horizontal com os cards.
/// Use isso pra qualquer seção tipo "What to Watch" ou "Trending".
class HorizontalSection extends StatelessWidget {
  final String title;
  final List<WatchNowVideo> videos;
  final VoidCallback? onSeeAll;
  final ValueChanged<WatchNowVideo>? onVideoTap;

  const HorizontalSection({
    super.key,
    required this.title,
    required this.videos,
    this.onSeeAll,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: WatchNowTextStyles.sectionHeader),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text('See All', style: WatchNowTextStyles.seeAll),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: VideoTile(
                  video: video,
                  onTap: onVideoTap == null ? null : () => onVideoTap!(video),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
