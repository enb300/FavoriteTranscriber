import Foundation
import SwiftUI

@MainActor
class OpenAIWhisperService: ObservableObject, WhisperServiceProtocol {
    @Published var isTranscribing = false
    @Published var currentStatus = ""
    @Published var transcriptionProgress: Double = 0.0
    @Published var apiKey: String = ""
    
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    
    init() {
        loadAPIKey()
    }
    
    func updateAPIKey(_ newKey: String) {
        apiKey = newKey
        saveAPIKey()
    }
    
    func transcribeAudioFile(_ audioFile: AudioFile) async throws -> Transcription {
        guard !apiKey.isEmpty else {
            throw OpenAIWhisperError.missingAPIKey
        }
        
        isTranscribing = true
        currentStatus = "Preparing audio file..."
        transcriptionProgress = 0.1
        
        // Read audio file data
        let audioData = try Data(contentsOf: audioFile.url)
        
        currentStatus = "Uploading to OpenAI..."
        transcriptionProgress = 0.3
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioFile.name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(audioFile.format)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        // Add timestamp granularities
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
        body.append("word\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        currentStatus = "Processing with OpenAI Whisper..."
        transcriptionProgress = 0.6
        
        // Make the request
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        currentStatus = "Parsing response..."
        transcriptionProgress = 0.9
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIWhisperError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIWhisperError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse the response
        let whisperResponse = try JSONDecoder().decode(OpenAIWhisperResponse.self, from: data)
        
        currentStatus = "Transcription complete!"
        transcriptionProgress = 1.0
        
        let transcription = Transcription(
            audioFileId: audioFile.id,
            text: whisperResponse.text,
            language: whisperResponse.language ?? "en",
            confidence: calculateAverageConfidence(from: whisperResponse.words),
            processingTime: processingTime,
            modelUsed: "whisper-1",
            serviceType: "OpenAI API"
        )
        
        isTranscribing = false
        return transcription
    }
    
    private func calculateAverageConfidence(from words: [OpenAIWord]?) -> Double {
        guard let words = words, !words.isEmpty else { return 0.0 }
        let totalConfidence = words.compactMap { $0.confidence }.reduce(0, +)
        return totalConfidence / Double(words.count)
    }
    
    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    private func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
    }
}

// MARK: - OpenAI API Models

struct OpenAIWhisperResponse: Codable {
    let text: String
    let language: String?
    let duration: Double?
    let words: [OpenAIWord]?
    let segments: [OpenAISegment]?
}

struct OpenAIWord: Codable {
    let word: String
    let start: Double
    let end: Double
    let confidence: Double?
}

struct OpenAISegment: Codable {
    let id: Int
    let seek: Double
    let start: Double
    let end: Double
    let text: String
    let tokens: [Int]
    let temperature: Double
    let avg_logprob: Double
    let compression_ratio: Double
    let no_speech_prob: Double
}

enum OpenAIWhisperError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is required. Please add your API key in the settings."
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let statusCode, let message):
            return "OpenAI API Error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
