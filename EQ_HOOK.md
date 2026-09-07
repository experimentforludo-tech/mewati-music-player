# EQ hook — done (just_audio 0.9.46, not just_audio_android)

`just_audio_android` exists only on just_audio **0.10+**. This app is locked to
**0.9.46** because `just_audio_background` 0.0.1-beta.17 needs 0.9.x.
0.10 also had a known release-APK silence bug.

Equivalent of your 7 steps:

| Your step | What we did |
|---|---|
| 1. fork `just_audio_android` | Fork whole `just_audio` 0.9.46 → `packages/just_audio` |
| 1. pubspec override | `just_audio: path: packages/just_audio` |
| 2. find ExoPlayer.Builder | `packages/just_audio/android/.../AudioPlayer.java` `ensurePlayerInitialized()` |
| 3. BaseAudioProcessor | `SoftwareEqAudioProcessor.java` + DSP still in `SoftwareEqEngine.kt` |
| 4. plug into sink | `DefaultAudioSink.Builder.setAudioProcessors(new SoftwareEqAudioProcessor())` |
| 5–6. test | Offload off; `onFlush`/`onReset` call `Engine.reset()`; errors stay dry |
| 7. commit | `packages/just_audio/` is in the repo |

Signal path:

`EqualizerService` → MethodChannel `mewati.sound/dsp` → `SoftwareEqEngine.apply`
→ `SoftwareEqAudioProcessor.queueInput` → `processInterleaved` → AudioTrack / BT.

Never `AndroidEqualizer`. Empty `AudioPipeline(androidAudioEffects: [])`.
