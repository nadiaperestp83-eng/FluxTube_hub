import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/watch_now_video.dart';
import '../theme/watch_now_theme.dart';

/// Card grande de destaque, tipo "Up Next" da Apple TV.
/// Ocupa quase toda a largura, thumbnail em cima, gradiente escuro
/// embaixo com título/legenda sobrepostos e um selo (badge) opcional.
class FeaturedCard extends StatelessWidget {
  final WatchNowVideo video;
  final VoidCallback? onTap;

  const FeaturedCard({super.key, required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WatchNowRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: WatchNowColors.surface);
                },
                errorBuilder: (context, error, stack) =>
                    Container(color: WatchNowColors.surface),
              ),
              // Gradiente escuro na base para legibilidade do texto.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              if (video.badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _GlassBadge(text: video.badge!),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(video.title, style: WatchNowTextStyles.cardTitle),
                    if (video.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        video.subtitle!,
                        style: WatchNowTextStyles.cardSubtitle,
                      ),
                    ],
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

/// Selo com efeito "vidro fosco" flutuando sobre a miniatura.
class _GlassBadge extends StatelessWidget {
  final String text;
  const _GlassBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WatchNowRadius.badge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(WatchNowRadius.badge),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
