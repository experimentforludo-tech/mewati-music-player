# Mewati patch on just_audio 0.9.46

Upstream tag: `just_audio-v0.9.46` (Media3 ExoPlayer 1.4.1).

There is **no** `just_audio_android` pub package on 0.9.46. Android code is
`packages/just_audio/android/`. Overriding `just_audio_android` would no-op.

## Changes

1. `SoftwareEqAudioProcessor.java` — Media3 `BaseAudioProcessor`. Forwards
   16-bit PCM to app DSP (`SoftwareEqEngine` via `SoftwareEqAudioProcessor.Engine`).
2. `AudioPlayer.ensurePlayerInitialized` — `DefaultRenderersFactory.buildAudioSink`
   installs that processor. Float output off. **Audio offload DISABLED**
   (offload skips AudioProcessors; TM presets would all sound identical).

`onFlush` / `onReset` clear DSP delay lines (seek / next track).

Dart API of just_audio is unchanged.
