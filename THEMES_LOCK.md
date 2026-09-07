# Final themes (APK)

Internal ids stay the same so saved prefs still load. Labels + colours are the lock.

| Drawer name | Internal id | Background | Accent |
|---|---|---|---|
| **Deep Black** | `cyberBlack` | `#000000` | `#FF6600` |
| **Golden Byte** | `walkmanOrange` (default) | `#1C1912` | `#FFD24A` |
| **Apple Green** | `silverChrome` | `#0B1610` | `#8FDB5A` |
| Theme Customization | `custom` | user | user |

Layouts stay **separate files** (not a colour swap):

- Deep Black → `mini_player_cyber_black.dart`, `cyber_black_player_controls.dart`, `cyber_black_seek_bar.dart`
- Golden Byte → `mini_player_default.dart`, `walkman_orange_player_controls.dart`, `walkman_orange_seek_bar.dart`
- Apple Green → `mini_player_silver_chrome.dart` (Spotify mini), `silver_chrome_player_controls.dart`, `silver_chrome_seek_bar.dart`, bottom icon tabs + tab-name title bar

Apple Green home stack: BrandRow (selected tab name) → list → mini → icon tab bar.

Universal (all themes):

- Playlist icon on Now Playing jumps to the current Serial No. in the home list (`HomeNav.showCurrentSongInList`)
- Home category swipe + drawer MUSIC shortcuts
- Download confirm before start
- Drive Mode has a volume bar (Deep Black: under Exit; Golden Byte / Apple Green: under seek)

Sound: see `SOUND_LOCK.json` + `PLAYER_PIPELINE.md`. `AudioPipeline` effects list is empty. TM EQ is software.

Drawer overlay: mount only while open (no full-screen hit layer when closed).
