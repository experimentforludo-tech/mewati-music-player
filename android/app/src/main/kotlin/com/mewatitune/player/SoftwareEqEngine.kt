package com.mewatitune.player

import com.ryanheise.just_audio.SoftwareEqAudioProcessor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sign
import kotlin.math.sin
import kotlin.math.tanh

/**
 * 10-band + TruBass + M/S width + Haas + focus/definition.
 * Registered as the Media3 AudioProcessor engine (just_audio fork).
 * Never uses AudioEffect.EQUALIZER (Bluetooth A2DP skips that).
 *
 * If [init]/[apply] throws, Dart keeps playback dry.
 */
class SoftwareEqEngine : FlutterPlugin, MethodChannel.MethodCallHandler, SoftwareEqAudioProcessor.Engine {
    private var channel: MethodChannel? = null

    @Volatile private var enabled = false
    @Volatile private var bypass = true
    private val bands = Array(10) { Biquad() }
    private val focusBand = Biquad()
    private val defBand = Biquad()
    private val freqs = doubleArrayOf(32.0, 64.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0)
    private var lastGains = DoubleArray(10)
    @Volatile private var bassLin = 1.0
    @Volatile private var width = 1.0
    @Volatile private var truBass = 0.0
    @Volatile private var focusDb = 0.0
    @Volatile private var defDb = 0.0
    @Volatile private var makeupLin = 1.0
    @Volatile private var compress = false
    @Volatile private var haasSamples = 0
    @Volatile private var sampleRate = 44100
    private var haasBuf = FloatArray(96)
    private var haasWrite = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mewati.sound/dsp")
        channel?.setMethodCallHandler(this)
        SoftwareEqAudioProcessor.setEngine(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (SoftwareEqAudioProcessor.getEngine() === this) {
            SoftwareEqAudioProcessor.setEngine(null)
        }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> {
                    enabled = true
                    SoftwareEqAudioProcessor.setEngine(this)
                    result.success(true)
                }
                "apply" -> {
                    apply(call.arguments as Map<*, *>)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            enabled = false
            bypass = true
            result.success(false)
        }
    }

    override fun isEnabled(): Boolean = enabled && !bypass

    override fun reset() {
        for (b in bands) b.reset()
        focusBand.reset()
        defBand.reset()
        haasBuf.fill(0f)
        haasWrite = 0
    }

    private fun apply(args: Map<*, *>) {
        val gains = (args["gains"] as List<*>).map { (it as Number).toDouble() }
        var allFlat = true
        for (i in freqs.indices) {
            val g = (gains.getOrNull(i) ?: 0.0).coerceIn(-15.0, 15.0)
            lastGains[i] = g
            if (abs(g) > 0.05) allFlat = false
        }
        val bassDb = ((args["bass"] as Number?)?.toDouble() ?: 0.0).coerceIn(0.0, 6.0)
        bassLin = 10.0.pow(bassDb / 20.0)
        width = ((args["width"] as Number?)?.toDouble() ?: 1.0).coerceIn(0.85, 1.85)
        truBass = ((args["truBass"] as Number?)?.toDouble() ?: 0.0).coerceIn(0.0, 1.0)
        focusDb = ((args["focus"] as Number?)?.toDouble() ?: 0.0).coerceIn(-12.0, 12.0)
        defDb = ((args["definition"] as Number?)?.toDouble() ?: 0.0).coerceIn(-12.0, 12.0)
        makeupLin = 10.0.pow(((args["makeup"] as Number?)?.toDouble() ?: 0.0) / 20.0)
        compress = args["compress"] as Boolean? ?: false
        val haas = ((args["haas"] as Number?)?.toDouble() ?: 0.0).coerceIn(0.0, 0.0022)
        haasSamples = (haas * sampleRate).toInt().coerceIn(0, haasBuf.size - 1)
        rebuildFilters()
        bypass = allFlat &&
            bassDb < 0.05 &&
            truBass < 0.01 &&
            abs(width - 1.0) < 0.01 &&
            abs(focusDb) < 0.05 &&
            abs(defDb) < 0.05 &&
            abs(makeupLin - 1.0) < 0.01 &&
            !compress &&
            haasSamples == 0
        enabled = true
        SoftwareEqAudioProcessor.setEngine(this)
    }

    private fun rebuildFilters() {
        val sr = sampleRate.toDouble().coerceAtLeast(8000.0)
        for (i in freqs.indices) {
            val type = when (i) {
                0 -> Biquad.Type.LOWSHELF
                freqs.lastIndex -> Biquad.Type.HIGHSHELF
                else -> Biquad.Type.PEAK
            }
            bands[i].set(type, freqs[i], lastGains[i], sr)
        }
        focusBand.set(Biquad.Type.PEAK, 3200.0, focusDb, sr)
        defBand.set(Biquad.Type.HIGHSHELF, 8000.0, defDb, sr)
        val haas = haasSamples.toDouble() / sampleRate.coerceAtLeast(1)
        haasSamples = (haas * sampleRate).toInt().coerceIn(0, haasBuf.size - 1)
    }

    override fun processInterleaved(pcm: ShortArray, frames: Int, channels: Int, sr: Int) {
        if (!isEnabled()) return
        if (sr > 0 && sr != sampleRate) {
            sampleRate = sr
            rebuildFilters()
        }
        if (frames <= 0 || channels <= 0) return
        if (channels == 1) {
            processMono(pcm, frames)
        } else {
            processStereo(pcm, frames, channels)
        }
    }

    /**
     * Soft-knee limiter. Below 0.9 the signal passes untouched; above that it
     * eases toward the ceiling instead of being hard-cut, which is what was
     * causing audible "fatna" (crackle) when bands/bass/makeup stacked up.
     */
    private fun limiter(x: Float): Float {
        val threshold = 0.9f
        val ax = abs(x)
        if (ax <= threshold) return x
        val over = ax - threshold
        val headroom = 1f - threshold
        val eased = threshold + tanh(over / headroom) * headroom
        return if (x < 0f) -eased else eased
    }

    private fun processMono(pcm: ShortArray, frames: Int) {
        val tb = truBass * 0.92
        val mk = makeupLin.toFloat()
        val bass = bassLin.toFloat()
        for (n in 0 until frames) {
            var s = pcm[n].toFloat() / 32768f
            for (b in bands) s = b.tickL(s)
            s = focusBand.tickL(s)
            s = defBand.tickL(s)
            s *= bass
            if (tb > 0.001) {
                s += (tanh(s * 1.15f + 0.62f * s * s * sign(s) + 0.06f * s * s * s) * tb.toFloat())
            }
            s *= mk
            if (compress) s = tanh(s * 1.15f)
            s = limiter(s)
            pcm[n] = (s.coerceIn(-1f, 1f) * 32767f).toInt().toShort()
        }
    }

    private fun processStereo(pcm: ShortArray, frames: Int, channels: Int) {
        val tb = truBass * 0.92
        val w = width
        val delay = haasSamples
        val mk = makeupLin.toFloat()
        val bass = bassLin.toFloat()
        var i = 0
        for (n in 0 until frames) {
            var l = pcm[i].toFloat() / 32768f
            var r = pcm[i + 1].toFloat() / 32768f
            for (b in bands) {
                l = b.tickL(l)
                r = b.tickR(r)
            }
            l = focusBand.tickL(l)
            r = focusBand.tickR(r)
            l = defBand.tickL(l)
            r = defBand.tickR(r)
            l *= bass
            r *= bass
            if (tb > 0.001) {
                val mono = (l + r) * 0.5f
                val harm = tanh(mono * 1.15f + 0.62f * mono * mono * sign(mono) + 0.06f * mono * mono * mono)
                val add = harm * tb.toFloat()
                l += add
                r += add
            }
            val mid = (l + r) * 0.5f
            var side = (l - r) * 0.5f * w.toFloat()
            if (delay > 0) {
                val idx = (haasWrite + haasBuf.size - delay) % haasBuf.size
                val delayed = haasBuf[idx]
                haasBuf[haasWrite] = side
                haasWrite = (haasWrite + 1) % haasBuf.size
                side = delayed
            }
            var ol = (mid + side) * mk
            var orr = (mid - side) * mk
            if (compress) {
                ol = tanh(ol * 1.15f)
                orr = tanh(orr * 1.15f)
            }
            ol = limiter(ol)
            orr = limiter(orr)
            pcm[i] = (ol.coerceIn(-1f, 1f) * 32767f).toInt().toShort()
            pcm[i + 1] = (orr.coerceIn(-1f, 1f) * 32767f).toInt().toShort()
            i += channels
        }
    }

    private class Biquad {
        enum class Type { PEAK, LOWSHELF, HIGHSHELF }

        private data class Coeffs(
            val b0: Double,
            val b1: Double,
            val b2: Double,
            val a1: Double,
            val a2: Double,
        )

        private val coeffs = java.util.concurrent.atomic.AtomicReference(
            Coeffs(1.0, 0.0, 0.0, 0.0, 0.0),
        )
        private var x1l = 0.0; private var x2l = 0.0; private var y1l = 0.0; private var y2l = 0.0
        private var x1r = 0.0; private var x2r = 0.0; private var y1r = 0.0; private var y2r = 0.0

        fun reset() {
            x1l = 0.0; x2l = 0.0; y1l = 0.0; y2l = 0.0
            x1r = 0.0; x2r = 0.0; y1r = 0.0; y2r = 0.0
        }

        fun set(type: Type, hz: Double, gainDb: Double, sr: Double) {
            val a = 10.0.pow(gainDb / 40.0)
            val w0 = 2.0 * PI * hz / sr
            val cosw = cos(w0)
            val sinw = sin(w0)
            val q = 1.0
            val alpha = sinw / (2.0 * q)
            val next: Coeffs = when (type) {
                Type.PEAK -> {
                    val a0 = 1 + alpha / a
                    Coeffs(
                        b0 = (1 + alpha * a) / a0,
                        b1 = -2 * cosw / a0,
                        b2 = (1 - alpha * a) / a0,
                        a1 = -2 * cosw / a0,
                        a2 = (1 - alpha / a) / a0,
                    )
                }
                Type.LOWSHELF -> {
                    val sqrtA = kotlin.math.sqrt(a)
                    val a0 = (a + 1) + (a - 1) * cosw + 2 * sqrtA * alpha
                    Coeffs(
                        b0 = a * ((a + 1) - (a - 1) * cosw + 2 * sqrtA * alpha) / a0,
                        b1 = 2 * a * ((a - 1) - (a + 1) * cosw) / a0,
                        b2 = a * ((a + 1) - (a - 1) * cosw - 2 * sqrtA * alpha) / a0,
                        a1 = -2 * ((a - 1) + (a + 1) * cosw) / a0,
                        a2 = ((a + 1) + (a - 1) * cosw - 2 * sqrtA * alpha) / a0,
                    )
                }
                Type.HIGHSHELF -> {
                    val sqrtA = kotlin.math.sqrt(a)
                    val a0 = (a + 1) - (a - 1) * cosw + 2 * sqrtA * alpha
                    Coeffs(
                        b0 = a * ((a + 1) + (a - 1) * cosw + 2 * sqrtA * alpha) / a0,
                        b1 = -2 * a * ((a - 1) + (a + 1) * cosw) / a0,
                        b2 = a * ((a + 1) + (a - 1) * cosw - 2 * sqrtA * alpha) / a0,
                        a1 = 2 * ((a - 1) - (a + 1) * cosw) / a0,
                        a2 = ((a + 1) - (a - 1) * cosw - 2 * sqrtA * alpha) / a0,
                    )
                }
            }
            coeffs.set(next)
        }

        fun tickL(x: Float): Float {
            val c = coeffs.get()
            val y = c.b0 * x + c.b1 * x1l + c.b2 * x2l - c.a1 * y1l - c.a2 * y2l
            x2l = x1l; x1l = x.toDouble(); y2l = y1l; y1l = y
            return y.toFloat()
        }

        fun tickR(x: Float): Float {
            val c = coeffs.get()
            val y = c.b0 * x + c.b1 * x1r + c.b2 * x2r - c.a1 * y1r - c.a2 * y2r
            x2r = x1r; x1r = x.toDouble(); y2r = y1r; y1r = y
            return y.toFloat()
        }
    }
}
