import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/themes/app_theme_id.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/theme_provider.dart';

class HomeTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeTabs({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  static const _labels = [
    AppStrings.navSongs,
    AppStrings.navSingers,
    AppStrings.navTrending,
    AppStrings.navFavorites,
    AppStrings.navDownloads,
  ];

  static const _icons = [
    Icons.music_note,
    Icons.mic,
    Icons.trending_up,
    Icons.favorite,
    Icons.download,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    if (t.id == AppThemeId.silverChrome) {
      final playing = context.select<PlayerProvider, bool>((p) => p.hasSong);
      final inset = playing ? 0.0 : MediaQuery.of(context).padding.bottom;
      return Container(
        height: 44 + inset,
        padding: EdgeInsets.only(bottom: inset),
        decoration: BoxDecoration(
          color: t.background,
          border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        ),
        child: Row(
          children: List.generate(_labels.length, (index) {
            final on = index == currentIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: on,
                label: _labels[index],
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  child: Icon(
                    _icons[index],
                    size: 26,
                    color: on ? t.accent : t.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    final deep = t.id == AppThemeId.cyberBlack;
    final activeColor = deep ? t.accent : t.textPrimary;
    final idleColor = t.textPrimary.withOpacity(0.63);
    final underline = deep ? t.accent : t.textPrimary;

    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: t.textPrimary.withOpacity(0.18), width: 2),
        ),
      ),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isActive = index == currentIndex;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isActive,
              label: _labels[index],
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _labels[index],
                          maxLines: 1,
                          style: TextStyle(
                            color: isActive ? activeColor : idleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        height: 4,
                        margin: const EdgeInsets.only(bottom: -2),
                        decoration: BoxDecoration(
                          color: underline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}