//
//  AudioManager.swift
//  MahSafe
//
//  程序化音效：离线合成短促波形 + 生成式背景音乐，零音频文件。
//  播放刻意走 AVAudioPlayer（文件级通道），避开 AVAudioEngine ——
//  后者的 AVAudioPlayerNode.play() 在引擎尚未建立 IO 循环时会触发
//  "player did not see an IO cycle" 断言崩溃（模拟器与真机都会偶发）。
//  每个音效是几段正弦/方波叠加，配合衰减包络，模拟机械感。
//

import AVFoundation
import Foundation

final class AudioManager {

    static let shared = AudioManager()

    enum Effect: CaseIterable {
        case tap, rotate, flip, swap, wrong, correct, click, bolt, doorOpen, victory, star
    }

    private let sampleRate: Double = 44100
    private var players: [Effect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var sessionConfigured = false

    private init() {
        // 启动时一次性把每个音效合成成 WAV，之后 play 只需复位重播。
        for effect in Effect.allCases {
            let buffer = makeBuffer(for: effect)
            if let data = wavData(from: buffer) {
                let player = try? AVAudioPlayer(data: data)
                player?.prepareToPlay()
                players[effect] = player
            }
        }
    }

    /// 启动时调用一次：配置音频会话，让音效与其它 App 混音。
    func prepare() {
        configureSession()
    }

    private func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // 音频会话不可用时静默降级，游戏不受影响。
        }
    }

    func play(_ effect: Effect) {
        guard SaveManager.soundEnabled else { return }
        configureSession()
        let player = players[effect]
        player?.currentTime = 0
        player?.play()
    }

    // MARK: - 背景音乐

    /// 启动循环播放的生成式背景音乐（仅当音乐开关打开）。
    func startMusic() {
        guard SaveManager.musicEnabled else { return }
        configureSession()
        if musicPlayer == nil {
            let buffer = makeMusicLoop()
            if let data = wavData(from: buffer) {
                musicPlayer = try? AVAudioPlayer(data: data)
                musicPlayer?.numberOfLoops = -1   // 无限循环
            }
        }
        musicPlayer?.prepareToPlay()
        musicPlayer?.play()
    }

    /// 停止背景音乐（切开关时调用）。
    func stopMusic() {
        musicPlayer?.stop()
    }

    /// 生成一整段可循环的旋律：Am–F–C–G 和声进行 + 稀疏的五声音阶旋律。
    private func makeMusicLoop() -> AVAudioPCMBuffer {
        let barDuration: Double = 3.2
        let barCount = 4
        let duration = barDuration * Double(barCount)
        let totalFrames = Int(duration * sampleRate)
        let buffer = silentBuffer(duration: duration)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        // 每个小节的和弦（三音）与旋律音符。
        let chords: [[Double]] = [
            [220.0, 261.63, 329.63],   // Am
            [174.61, 220.0, 261.63],   // F
            [261.63, 329.63, 392.0],   // C
            [196.0, 246.94, 293.66]    // G
        ]
        let melodies: [[Double]] = [
            [329.63, 440.0, 523.25],   // Am: E4 A4 C5
            [349.23, 440.0, 523.25],   // F:  F4 A4 C5
            [329.63, 392.0, 523.25],   // C:  E4 G4 C5
            [293.66, 392.0, 493.88]    // G:  D4 G4 B4
        ]

        func mixNote(start: Double, frequency: Double, length: Double, gain: Double, pluck: Bool) {
            let startSample = Int(start * sampleRate)
            let noteFrames = Int(length * sampleRate)
            for i in 0..<noteFrames {
                let idx = startSample + i
                guard idx < totalFrames else { break }
                let t = Double(i) / sampleRate
                let attack = min(1.0, t / 0.02)
                let release = min(1.0, (length - t) / 0.35)
                var env = attack * release
                if pluck {
                    env *= exp(-t * 3.2 / length)
                }
                var sample = sin(2 * .pi * frequency * t) * 0.6
                sample += sin(2 * .pi * frequency * 2 * t) * 0.28
                sample += sin(2 * .pi * frequency * 3 * t) * 0.12
                data[idx] += Float(sample * env * gain)
            }
        }

        for bar in 0..<barCount {
            let barStart = Double(bar) * barDuration
            // 和弦铺底：持续整小节，低音量。
            for f in chords[bar] {
                mixNote(start: barStart, frequency: f, length: barDuration, gain: 0.055, pluck: false)
            }
            // 旋律：三个音符，错开排布。
            for (i, f) in melodies[bar].enumerated() {
                let start = barStart + Double(i) * (barDuration / 3.0) + 0.1
                mixNote(start: start, frequency: f, length: 0.9, gain: 0.10, pluck: true)
            }
        }
        return buffer
    }

    // MARK: - 波形合成

    private func makeBuffer(for effect: Effect) -> AVAudioPCMBuffer {
        switch effect {
        case .tap: return tone(frequency: 1800, duration: 0.035, wave: .sine, gain: 0.5)
        case .rotate: return tone(frequency: 720, duration: 0.05, wave: .sine, gain: 0.45)
        case .flip: return sweep(from: 260, to: 760, duration: 0.09, gain: 0.4)
        case .swap: return chirp(frequencies: [1100, 1400], duration: 0.04, gain: 0.4)
        case .wrong: return tone(frequency: 170, duration: 0.22, wave: .square, gain: 0.4)
        case .correct: return chord(frequencies: [880, 1318], duration: 0.16, gain: 0.4)
        case .click: return tone(frequency: 1350, duration: 0.03, wave: .sine, gain: 0.5)
        case .bolt: return tone(frequency: 210, duration: 0.07, wave: .square, gain: 0.5)
        case .doorOpen: return sweep(from: 120, to: 340, duration: 0.45, gain: 0.4)
        case .victory: return arpeggio([523.25, 659.25, 783.99, 1046.5], step: 0.09, gain: 0.42)
        case .star: return tone(frequency: 1568, duration: 0.1, wave: .sine, gain: 0.45)
        }
    }

    private enum Wave {
        case sine
        case square
    }

    private func tone(frequency: Double, duration: Double, wave: Wave, gain: Double) -> AVAudioPCMBuffer {
        let buffer = silentBuffer(duration: duration)
        guard let data = buffer.floatChannelData?[0] else { return buffer }
        let frameCount = Int(duration * sampleRate)
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let phase = 2 * .pi * frequency * t
            var sample: Double
            switch wave {
            case .sine: sample = sin(phase)
            case .square: sample = sin(phase) >= 0 ? 1 : -1
            }
            let env = exp(-t * 14 / duration)
            data[i] = Float(sample * env * gain)
        }
        return buffer
    }

    private func sweep(from: Double, to: Double, duration: Double, gain: Double) -> AVAudioPCMBuffer {
        let buffer = silentBuffer(duration: duration)
        guard let data = buffer.floatChannelData?[0] else { return buffer }
        let frameCount = Int(duration * sampleRate)
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let k = t / duration
            let freq = from + (to - from) * k
            let phase = 2 * .pi * freq * t
            let env = sin(.pi * k)
            data[i] = Float(sin(phase) * env * gain)
        }
        return buffer
    }

    private func chirp(frequencies: [Double], duration: Double, gain: Double) -> AVAudioPCMBuffer {
        let total = duration * Double(frequencies.count)
        let buffer = silentBuffer(duration: total)
        guard let data = buffer.floatChannelData?[0] else { return buffer }
        let per = Int(duration * sampleRate)
        for (n, freq) in frequencies.enumerated() {
            for i in 0..<per {
                let t = Double(i) / sampleRate
                let idx = n * per + i
                guard idx < Int(total * sampleRate) else { continue }
                let env = exp(-t * 14 / duration)
                data[idx] = Float(sin(2 * .pi * freq * t) * env * gain)
            }
        }
        return buffer
    }

    private func chord(frequencies: [Double], duration: Double, gain: Double) -> AVAudioPCMBuffer {
        let buffer = silentBuffer(duration: duration)
        guard let data = buffer.floatChannelData?[0] else { return buffer }
        let frameCount = Int(duration * sampleRate)
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample = 0.0
            for freq in frequencies {
                sample += sin(2 * .pi * freq * t)
            }
            let env = exp(-t * 9 / duration)
            data[i] = Float(sample / Double(frequencies.count) * env * gain)
        }
        return buffer
    }

    private func arpeggio(_ frequencies: [Double], step: Double, gain: Double) -> AVAudioPCMBuffer {
        let duration = step * Double(frequencies.count)
        let buffer = silentBuffer(duration: duration)
        guard let data = buffer.floatChannelData?[0] else { return buffer }
        let per = Int(step * sampleRate)
        for (n, freq) in frequencies.enumerated() {
            for i in 0..<per {
                let t = Double(i) / sampleRate
                let idx = n * per + i
                guard idx < Int(duration * sampleRate) else { continue }
                let env = exp(-t * 6 / step)
                data[idx] = Float(sin(2 * .pi * freq * t) * env * gain)
            }
        }
        return buffer
    }

    /// 生成一段静音（实际是已清零）的单声道 buffer，供各合成函数填充。
    private func silentBuffer(duration: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        // 标定有效帧数，否则播放器读到的是 0 帧（无声）。
        buffer.frameLength = frameCount
        // 合成函数用 += 累加写入，先清零避免读到未初始化内存。
        if let data = buffer.floatChannelData?[0] {
            data.initialize(repeating: 0, count: Int(frameCount))
        }
        return buffer
    }

    // MARK: - WAV 编码

    /// 把单声道 float32 PCM buffer 编码成 16-bit PCM WAV（内存 Data）。
    /// AVAudioPlayer 需要文件级数据（WAV 即可），不能直接喂 PCM buffer。
    private func wavData(from buffer: AVAudioPCMBuffer) -> Data? {
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return nil }

        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = Int(bitsPerSample / 8)
        let dataSize = UInt32(frameCount * bytesPerSample)
        let sampleRate32 = UInt32(sampleRate)

        var data = Data()
        data.reserveCapacity(44 + frameCount * bytesPerSample)

        func append(_ bytes: [UInt8]) { data.append(contentsOf: bytes) }
        func appendLE<T: FixedWidthInteger>(_ value: T) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        // RIFF / fmt / data 三段标准头。
        append(Array("RIFF".utf8))
        appendLE(UInt32(36) + dataSize)
        append(Array("WAVE".utf8))
        append(Array("fmt ".utf8))
        appendLE(UInt32(16))
        appendLE(UInt16(1))                                        // PCM
        appendLE(channels)
        appendLE(sampleRate32)
        appendLE(sampleRate32 * UInt32(bytesPerSample))            // 字节率
        appendLE(channels * UInt16(bytesPerSample))                // 块对齐
        appendLE(bitsPerSample)
        append(Array("data".utf8))
        appendLE(dataSize)

        // 样本：float → 16-bit 有符号，限制在 [-1, 1]。
        for i in 0..<frameCount {
            let clamped = max(-1.0, min(1.0, channel[i]))
            appendLE(Int16(clamped * 32767.0))
        }
        return data
    }
}
