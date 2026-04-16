import AVFoundation

/// Proceduraler sphärischer Ambient-Synthesizer.
///
/// Erzeugt einen warmen Drone aus vier leicht verstimmten Sinusoszillatoren
/// (55 Hz, 110 Hz, 165 Hz, 220 Hz) mit langsamem LFO-Atemeffekt und großem
/// Hall – vollständig lokal, ohne Audiodateien.
///
/// Die Intensität reagiert auf die Anzahl der Satelliten und steigt sanft an.
final class ZenAmbientSoundEngine {

    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private var sourceNode: AVAudioSourceNode?
    private var isRunning = false

    // Oszillator-Phasen – nur vom Audio-Render-Thread geschrieben/gelesen
    private var phase1: Float = 0
    private var phase2: Float = 0
    private var phase3: Float = 0
    private var phase4: Float = 0
    private var lfoPhase: Float = 0
    private var currentAmplitude: Float = 0

    // Ziel-Amplitude: vom Main-Thread geschrieben, vom Audio-Thread gelesen.
    // Float-Zugriffe sind auf arm64 atomar genug für diesen Anwendungsfall.
    private var targetAmplitude: Float = 0.2

    private let sampleRate: Float = 44100

    // Leicht verstimmte Harmonische für warmen Schwebungseffekt
    private let freq1: Float = 55.3    // ~A1
    private let freq2: Float = 110.1   // ~A2
    private let freq3: Float = 164.7   // ~E3
    private let freq4: Float = 219.8   // ~A3

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true

        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!

        let node = AVAudioSourceNode(format: format) { [self] _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard buffers.count >= 2,
                  let left  = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                  let right = buffers[1].mData?.assumingMemoryBound(to: Float.self)
            else { return noErr }

            let sr = self.sampleRate
            let inc1   = 2 * Float.pi * self.freq1 / sr
            let inc2   = 2 * Float.pi * self.freq2 / sr
            let inc3   = 2 * Float.pi * self.freq3 / sr
            let inc4   = 2 * Float.pi * self.freq4 / sr
            // ~12,5 s Atemzyklus
            let lfoInc = 2 * Float.pi * 0.08 / sr

            let tgt    = self.targetAmplitude
            var amp    = self.currentAmplitude
            // Sanftes Fade über ~0,5 s
            let smooth: Float = 1.0 / (sr * 0.5)

            for frame in 0..<Int(frameCount) {
                amp += (tgt - amp) * smooth

                // LFO: Amplitude atmet sanft zwischen 0,76 und 1,0
                let lfo    = sin(self.lfoPhase) * 0.12 + 0.88
                let sample = (sin(self.phase1) * 0.45
                            + sin(self.phase2) * 0.28
                            + sin(self.phase3) * 0.18
                            + sin(self.phase4) * 0.09) * lfo * amp

                left[frame]  = sample
                right[frame] = sample

                self.phase1   = self.wrap(self.phase1   + inc1)
                self.phase2   = self.wrap(self.phase2   + inc2)
                self.phase3   = self.wrap(self.phase3   + inc3)
                self.phase4   = self.wrap(self.phase4   + inc4)
                self.lfoPhase = self.wrap(self.lfoPhase + lfoInc)
            }
            self.currentAmplitude = amp
            return noErr
        }

        sourceNode = node

        reverb.loadFactoryPreset(.largeChamber)
        reverb.wetDryMix = 65

        engine.attach(node)
        engine.attach(reverb)
        engine.connect(node, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        engine.detach(reverb)
        isRunning = false
        currentAmplitude = 0
    }

    // MARK: - Dynamische Intensität

    /// Passt die Lautstärke des Drones an die Satelliten-Anzahl an.
    /// Immer eine leise Grundlautstärke, wächst mit mehr Satelliten.
    func updateIntensity(satelliteCount: Int) {
        let base: Float  = 0.18
        let extra: Float = satelliteCount > 0
            ? min(Float(satelliteCount) / 15.0, 1.0) * 0.35
            : 0
        targetAmplitude = base + extra
    }

    // MARK: - Hilfsfunktionen

    @inline(__always)
    private func wrap(_ phase: Float) -> Float {
        phase > 2 * .pi ? phase - 2 * .pi : phase
    }
}
