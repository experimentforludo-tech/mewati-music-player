import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/song.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/player_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/app_cache_manager.dart';
import '../mini_player_data.dart';

class MiniPlayerSilverChrome extends StatelessWidget {
  final MiniPlayerData data;
  const MiniPlayerSilverChrome({Key? key, required this.data}) : super(key: key);

  static const _green = Color(0xFF8FDB5A);
  static const _bar = Color(0xFF1C3324);

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
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: _bar,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 128),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              _AppleTimes(),
              _AppleSeek(onSeek: (d) => playerProvider.seek(d)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => AppRouter.navigatorKey.currentState
                          ?.pushNamed(RouteNames.nowPlaying),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
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
                                  child: Icon(Icons.music_note, color: _green),
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
                                decoration: TextDecoration.none,
                              ),
                            ),
                            if (singer.isNotEmpty)
                              Text(
                                singer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0x8CFFFFFF),
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
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
                        color: isFav ? _green : Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: isLoading
                          ? null
                          : () => playerProvider.togglePlayPause(),
                      icon: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleTimes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return ValueListenableBuilder<Duration>(
      valueListenable: player.durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: player.positionNotifier,
          builder: (context, position, __) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
              child: Row(
                children: [
                  Text(
                    _fmt(position),
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmt(duration),
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class _AppleSeek extends StatelessWidget {
  final void Function(Duration position) onSeek;
  const _AppleSeek({required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return ValueListenableBuilder<Duration>(
      valueListenable: player.durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: player.positionNotifier,
          builder: (context, position, __) {
            final total = duration.inMilliseconds;
            final pct = total <= 0
                ? 0.0
                : (position.inMilliseconds / total).clamp(0.0, 1.0);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _seek(d.localPosition.dx, context, total),
              onHorizontalDragUpdate: (d) =>
                  _seek(d.localPosition.dx, context, total),
              child: SizedBox(
                height: 28,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            const ColoredBox(
                              color: Color(0x33FFFFFF),
                              child: SizedBox.expand(),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: const ColoredBox(
                                color: MiniPlayerSilverChrome._green,
                                child: SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _seek(double dx, BuildContext context, int totalMs) {
    if (totalMs <= 0) return;
    final w = context.size?.width ?? 1;
    final p = (dx / w).clamp(0.0, 1.0);
    onSeek(Duration(milliseconds: (p * totalMs).round()));
  }
}