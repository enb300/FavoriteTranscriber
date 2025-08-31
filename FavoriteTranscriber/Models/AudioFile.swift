import Foundation
import AVFoundation

struct AudioFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let duration: TimeInterval
    let fileSize: Int64
    let format: String
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.duration = 0
        self.fileSize = 0
        self.format = url.pathExtension.lowercased()
    }
    
    init(url: URL, duration: TimeInterval, fileSize: Int64, format: String) {
        self.url = url
        self.name = url.lastPathComponent
        self.duration = duration
        self.fileSize = fileSize
        self.format = format
    }
}

struct Transcription: Identifiable, Equatable, Codable {
    let id = UUID()
    let audioFileId: UUID
    var text: String
    let language: String
    let confidence: Double
    let timestamp: Date
    let processingTime: TimeInterval
    let modelUsed: String
    let serviceType: String
    let wordCount: Int
    let sentenceCount: Int
    let averageWordsPerSentence: Double
    var customName: String?
    
    init(audioFileId: UUID, text: String, language: String = "en", confidence: Double = 0.0, processingTime: TimeInterval = 0.0, modelUsed: String = "unknown", serviceType: String = "Local Whisper") {
        self.audioFileId = audioFileId
        self.text = text
        self.language = language
        self.confidence = confidence
        self.timestamp = Date()
        self.processingTime = processingTime
        self.modelUsed = modelUsed
        self.serviceType = serviceType
        
        // Calculate text statistics
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        self.wordCount = words.count
        
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        self.sentenceCount = max(1, sentences.count)
        
        self.averageWordsPerSentence = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0.0
    }
}
