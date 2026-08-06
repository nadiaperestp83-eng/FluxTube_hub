import '../models/watch_now_video.dart';

/// Contrato de dados que a tela Watch Now consome.
///
/// A tela NUNCA fala diretamente com NewPipeExtractor/Piped/Invidious.
/// Ela só conhece essa interface. Isso permite:
///  - trocar de serviço sem tocar na UI
///  - testar a UI com dados falsos (mock) sem depender de rede
///  - plugar os dados reais depois, só implementando esta classe
abstract class WatchNowRepository {
  /// Vídeo grande em destaque no topo ("Up Next").
  Future<WatchNowVideo?> fetchUpNext();

  /// Lista "What to Watch" / "New & Noteworthy".
  Future<List<WatchNowVideo>> fetchWhatToWatch();

  /// Lista "Trending".
  Future<List<WatchNowVideo>> fetchTrending();

  /// Categorias disponíveis nas pílulas do topo.
  Future<List<WatchNowCategoryItem>> fetchCategories();
}

/// -----------------------------------------------------------------------
/// IMPLEMENTAÇÃO MOCK — usada até conectarmos no backend real do FluxTube.
///
/// Troque esta classe por algo como `FluxTubeWatchNowRepository`, que
/// internamente chama o teu serviço de trending/subscrições já existente
/// (NewPipeExtractorService / PipedService / InvidiousService) e mapeia o
/// resultado para `WatchNowVideo`. Como não tenho acesso ao código-fonte
/// real do teu app pra ler os nomes exatos dos métodos, deixei esse mock
/// pronto pra você (ou eu, se você colar o arquivo do teu serviço aqui)
/// completar sem risco de quebrar nada.
/// -----------------------------------------------------------------------
class MockWatchNowRepository implements WatchNowRepository {
  @override
  Future<WatchNowVideo?> fetchUpNext() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const WatchNowVideo(
      id: 'up-next-1',
      title: 'This Is Us',
      subtitle: 'NEW · S3, E17',
      badge: 'hulu',
      thumbnailUrl: 'https://picsum.photos/seed/thisisus/800/500',
    );
  }

  @override
  Future<List<WatchNowVideo>> fetchWhatToWatch() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      WatchNowVideo(
        id: 'wtw-1',
        title: 'Into the Badlands',
        thumbnailUrl: 'https://picsum.photos/seed/badlands/500/700',
        category: 'DRAMA',
      ),
      WatchNowVideo(
        id: 'wtw-2',
        title: 'The Voice',
        thumbnailUrl: 'https://picsum.photos/seed/thevoice/500/700',
        category: 'REALITY',
      ),
      WatchNowVideo(
        id: 'wtw-3',
        title: 'Brockmire',
        subtitle: 'Watch the Season 3 premiere before it airs.',
        thumbnailUrl: 'https://picsum.photos/seed/brockmire/500/700',
        category: 'COMEDY',
      ),
    ];
  }

  @override
  Future<List<WatchNowVideo>> fetchTrending() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      WatchNowVideo(
        id: 'trend-1',
        title: 'If Beale Street Could Talk',
        thumbnailUrl: 'https://picsum.photos/seed/bealestreet/500/700',
      ),
      WatchNowVideo(
        id: 'trend-2',
        title: 'This Is Us',
        thumbnailUrl: 'https://picsum.photos/seed/thisisus2/500/700',
      ),
    ];
  }

  @override
  Future<List<WatchNowCategoryItem>> fetchCategories() async {
    return const [
      WatchNowCategoryItem(type: WatchNowCategory.all, label: 'Para você'),
      WatchNowCategoryItem(type: WatchNowCategory.videos, label: 'Vídeos'),
      WatchNowCategoryItem(type: WatchNowCategory.series, label: 'Séries'),
      WatchNowCategoryItem(type: WatchNowCategory.sports, label: 'Esportes'),
    ];
  }
}
