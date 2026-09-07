import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/song.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/app_cache_manager.dart';
import '../mini_player_data.dart';

/// Apple Green Spotify-style mini: art + title, heart, play. No full-screen overlay.
class MiniPlayerSilverChrome extends StatelessWidget {
  final MiniPlayerData data;

  const MiniPlayerSilverChrome({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Song song = data.song as Song;
    final isPlaying = data.isPlaying;
    final isLoading = data.isLoading;
    final playerProvider = data.playerProvider;
    final cover = song.coverImageUrl;
    final singer = song.singerName ?? '';
    final favs = context.watch<FavoritesProvider>();
    final isFav = favs.isFavoriteSync(song.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Material(
        color: const Color(0xFF1C3324),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => AppRouter.navigatorKey.currentState
                    ?.pushNamed(RouteNames.nowPlaying),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: cover != null && cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            cacheManager: AppCacheManager.instance,
                            memCacheWidth: 112,
                            memCacheHeight: 112,
                          )
                        : const ColoredBox(
                            color: Color(0xFF0B1610),
                            child: Icon(Icons.music_note, color: Color(0xFF8FDB5A)),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => AppRouter.navigatorKey.currentState
                      ?.pushNamed(RouteNames.nowPlaying),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (singer.isNotEmpty)
                        Text(
                          singer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Favorite',
                onPressed: () => favs.toggleFavorite(song),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? const Color(0xFF8FDB5A) : Colors.white,
                ),
              ),
              IconButton(
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: isLoading ? null : () => playerProvider.togglePlayPause(),
                icon: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
