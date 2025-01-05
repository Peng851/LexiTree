import Foundation
import AVFoundation

enum AudioError: Error {
    case invalidURL
    case playbackError(Error)
    case noAudioData
}

@MainActor
final class AudioService: ObservableObject {
    static let shared = AudioService()
    
    @Published private(set) var isPlaying = false
    private var audioPlayer: AVPlayer?
    private var audioCache: [String: Data] = [:]
    
    private init() {}
    
    @MainActor
    func playWord(_ word: String, accent: String = "en-US") async throws {
        guard !isPlaying else { return }
        
        isPlaying = true
        defer { isPlaying = false }
        
        // 检查缓存
        if let cachedData = audioCache["\(word)-\(accent)"] {
            try await playAudioData(cachedData)
            return
        }
        
        // 构建 Google TTS API URL
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        guard let url = URL(string: "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedWord)&tl=\(accent)&client=tw-ob") else {
            throw AudioError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            audioCache["\(word)-\(accent)"] = data
            try await playAudioData(data)
        } catch {
            throw AudioError.playbackError(error)
        }
    }
    
    private func playAudioData(_ data: Data) async throws {
        guard let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw AudioError.noAudioData
        }
        
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".mp3")
        try data.write(to: tempFile)
        
        let playerItem = AVPlayerItem(url: tempFile)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        await MainActor.run {
            audioPlayer?.play()
        }
    }
    
    func stopPlayback() {
        audioPlayer?.pause()
    }
} 