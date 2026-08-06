/// Modelo genérico usado pela UI da tela "Watch Now".
///
/// Este modelo é intencionalmente independente do model de vídeo real do
/// FluxTube (que provavelmente já existe em algo como `lib/models/video.dart`
/// ou equivalente, vindo do NewPipeExtractor/Piped/Invidious).
///
/// Para conectar de verdade, crie uma função `toWatchNowVideo()` no seu
/// model existente (extension) ou um mapper no repositório — assim você
/// não precisa alterar nada do model original.
class WatchNowVideo {
  final String id;
  final String title;
  final String thumbnailUrl;

  /// Selo pequeno tipo "hulu", "NEW", "HBO" etc. Opcional.
  final String? badge;

  /// Linha secundária, ex: "S3, E17" ou nome do canal.
  final String? subtitle;

  /// Categoria/etiqueta, ex: "COMEDY", "SPORTS".
  final String? category;

  /// Descrição curta usada nos cards grandes (Up Next / New & Noteworthy).
  final String? description;

  final Duration? duration;
  final DateTime? publishedAt;

  const WatchNowVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.badge,
    this.subtitle,
    this.category,
    this.description,
    this.duration,
    this.publishedAt,
  });
}

/// Categorias mostradas nas "pílulas" no topo da Home.
enum WatchNowCategory { all, videos, series, sports, custom }

class WatchNowCategoryItem {
  final WatchNowCategory type;
  final String label;
  final String? customId; // usado quando type == custom (ex: API própria)

  const WatchNowCategoryItem({
    required this.type,
    required this.label,
    this.customId,
  });
}
