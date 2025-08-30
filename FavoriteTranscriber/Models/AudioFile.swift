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
    let text: String
    let language: String
    let confidence: Double
    let timestamp: Date
    let processingTime: TimeInterval
    
    init(audioFileId: UUID, text: String, language: String = "en", confidence: Double = 0.0, processingTime: TimeInterval = 0.0) {
        self.audioFileId = audioFileId
        self.text = text
        self.language = language
        self.confidence = confidence
        self.timestamp = Date()
        self.processingTime = processingTime
    }
}
