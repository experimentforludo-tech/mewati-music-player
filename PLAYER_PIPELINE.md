# APK sound lock — Media3 PCM hook is IN

## Pipeline (locked)

```dart
audioPipeline: const AudioPipeline(androidAudioEffects: []),
```

`EqualizerService().androidAudioEffects` also returns `[]`. Both stay empty. Never `AndroidEqualizer` / `AndroidLoudnessEnhancer`.

## How the TM sound actually hits the speaker

`just_audio` 0.9.46 is a **local fork** (`packages/just_audio`) so we can put a Media3 `AudioProcessor` on ExoPlayer's `DefaultAudioSink`.

1. Dart `EqualizerService` → MethodChannel `mewati.sound/dsp`
2. `SoftwareEqEngine` (app) holds 10-band biquads + TruBass + width + Haas
3. `SoftwareEqAudioProcessor` (fork) sits in the PCM chain and calls `Engine.processInterleaved`
4. Bluetooth A2DP still gets processed PCM (device EQ is never used)

Audio **offload is disabled** in the fork. Offload skips `AudioProcessor` and would make every TM preset sound identical.

If the native `init`/`apply` throws: playback stays **dry**. App does not crash.

## Files

| Path | Role |
|---|---|
| `packages/just_audio` | just_audio 0.9.46 + PCM hook |
| `android/.../SoftwareEqEngine.kt` | DSP + MethodChannel |
| `packages/just_audio/.../SoftwareEqAudioProcessor.java` | Media3 BaseAudioProcessor |
| `packages/just_audio/.../AudioPlayer.java` | `RenderersFactory` + offload off |
| `lib/services/equalizer_service.dart` | Dart API |
| `SOUND_LOCK.json` | Preset numbers |

## pubspec

```yaml
dependency_overrides:
  just_audio:
    path: packages/just_audio
```

Do not bump just_audio to 0.10.x without re-applying the AudioPlayer hook. `just_audio_background` stays on 0.9.x.

## ThemeProvider

`applyPreset` / drawer must include `'wow'` (Mewati Boom™) next to `mewati-bass` and `beats`.

If `EqualizerService().shouldHintHeadphones(id)` → snackbar:

`Please use your headphones for premium sound quality`
