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

    return ColoredBox(
      color: _bar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppleSeek(onSeek: (d) => playerProvider.seek(d)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
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
                  onPressed:
                      isLoading ? null : () => playerProvider.togglePlayPause(),
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
    );
  }
}

class _AppleSeek extends StatefulWidget {
  final void Function(Duration position) onSeek;
  const _AppleSeek({required this.onSeek});

  @override
  State<_AppleSeek> createState() => _AppleSeekState();
}

class _AppleSeekState extends State<_AppleSeek> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return ValueListenableBuilder<Duration>(
      valueListenable: player.durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: player.positionNotifier,
          builder: (context, position, __) {
            final actual = duration.inMilliseconds == 0
                ? 0.0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);
            final pct = _drag ?? actual;
            return SizedBox(
              height: 22,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: MiniPlayerSilverChrome._green,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  year2023: true,
                  padding: EdgeInsets.zero,
                  value: pct,
                  onChanged: (v) => setState(() => _drag = v),
                  onChangeEnd: (v) {
                    widget.onSeek(
                      Duration(milliseconds: (v * duration.inMilliseconds).round()),
                    );
                    setState(() => _drag = null);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}