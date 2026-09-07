import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/themes/app_theme_id.dart';
import '../../../providers/theme_provider.dart';

class BrandRow extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final int tabIndex;

  const BrandRow({
    Key? key,
    required this.onMenuTap,
    required this.onSearchTap,
    this.tabIndex = 0,
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
    final apple = t.id == AppThemeId.silverChrome;
    final i = tabIndex < 0
        ? 0
        : (tabIndex >= _labels.length ? _labels.length - 1 : tabIndex);
    final title = apple ? _labels[i] : AppStrings.appName;
    final leadingIcon = apple ? _icons[i] : Icons.music_note;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, apple ? 8 : 6, 8, apple ? 8 : 0),
      child: SizedBox(
        height: apple ? 56 : 48,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: t.textPrimary, size: apple ? 28 : 24),
              onPressed: onMenuTap,
            ),
            Icon(leadingIcon, color: t.accent, size: apple ? 28 : 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: apple ? 26 : 20,
                  fontWeight: apple ? FontWeight.w500 : FontWeight.w600,
                  fontStyle: apple ? FontStyle.normal : FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.search, color: t.textPrimary, size: apple ? 28 : 24),
              onPressed: onSearchTap,
            ),
          ],
        ),
      ),
    );
  }
}
